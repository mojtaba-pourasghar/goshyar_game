#!/usr/bin/env python3
"""Finds real recordings for the sounds in assets/content/levels.json.

The 46 effects carried over from the Java version were synthesised. This replaces them with
real recordings under a free licence, from two places:

  1. Wikimedia Commons (API, licence read from each file's metadata)
  2. Freesound, CC0 only (the search page; the preview MP3 on cdn.freesound.org)

Each pick is cleaned with the same ffmpeg chain the voice studio uses for effects (silence
trimmed, at most N seconds with a fade-out, mono, −14 LUFS, MP3) and written over the file the
app already plays. Where it came from and under what licence goes into
docs/audio/sfx_sources.json, which the studio reads too.

    python3 tools/sfx/fetch_sounds.py --list            # candidates only, nothing written
    python3 tools/sfx/fetch_sounds.py                   # every sound still synthetic
    python3 tools/sfx/fetch_sounds.py cow dog --force   # these, even if already replaced

Needs network access to commons.wikimedia.org, upload.wikimedia.org, freesound.org and
cdn.freesound.org, and ffmpeg on PATH.
"""

from __future__ import annotations

import argparse
import html
import json
import re
import subprocess
import sys
import tempfile
import time
import urllib.parse
import urllib.request
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
LEVELS = ROOT / "assets/content/levels.json"
SOURCES = ROOT / "docs/audio/sfx_sources.json"
UA = "GoshyarSoundFetcher/1.0 (kids listening game; tools/sfx/fetch_sounds.py)"

# What to search for, most specific first. Commons titles are English; the second list is for
# Freesound. A word in `avoid` anywhere in the title or tags rules a candidate out (music
# loops, remixes, people imitating animals…).
QUERIES: dict[str, tuple[list[str], list[str]]] = {
    "lion": (["lion roar"], ["lion roar"]),
    "cow": (["cow moo", "cow mooing"], ["cow moo"]),
    "dog": (["dog barking", "dog bark"], ["dog bark"]),
    "cat": (["cat meow", "cat meowing"], ["cat meow"]),
    "rabbit": (["rabbit sound", "rabbit eating"], ["rabbit eating carrot", "rabbit"]),
    "bird": (["bird song", "songbird"], ["bird chirping"]),
    "sheep": (["sheep bleat", "sheep"], ["sheep baa"]),
    "horse": (["horse neigh", "horse whinny"], ["horse neigh"]),
    "duck": (["duck quack", "mallard quack"], ["duck quack"]),
    "frog": (["frog croak", "frog call"], ["frog croak"]),
    "elephant": (["elephant trumpet", "elephant"], ["elephant trumpet"]),
    "rooster": (["rooster crow", "rooster crowing"], ["rooster crow"]),
    "doorbell": (["doorbell"], ["doorbell ding dong"]),
    "clock": (["clock ticking", "clock tick"], ["clock ticking"]),
    "phone": (["telephone ringing", "phone ring"], ["phone ringing"]),
    "vacuum": (["vacuum cleaner"], ["vacuum cleaner"]),
    "kettle": (["kettle whistle", "whistling kettle"], ["kettle whistle"]),
    "washer": (["washing machine"], ["washing machine"]),
    "tap": (["water tap running", "faucet"], ["water tap running", "faucet"]),
    "door": (["door knock", "knocking on door"], ["door knock"]),
    "rain": (["rain"], ["rain"]),
    "thunder": (["thunder"], ["thunder"]),
    "wind": (["wind"], ["wind howling"]),
    "sea": (["sea waves", "ocean waves"], ["ocean waves"]),
    "river": (["river stream", "creek"], ["stream water"]),
    "fire": (["campfire", "fire crackling"], ["campfire crackling"]),
    "waterfall": (["waterfall"], ["waterfall"]),
    "drum": (["drum", "bass drum"], ["drum hit"]),
    "piano": (["piano"], ["piano melody"]),
    "guitar": (["acoustic guitar", "guitar strum"], ["acoustic guitar strum"]),
    "violin": (["violin"], ["violin"]),
    "flute": (["flute"], ["flute"]),
    "bell": (["hand bell", "bell ringing"], ["small bell"]),
    "tambourine": (["daf frame drum", "tambourine"], ["frame drum", "tambourine"]),
    "hammer": (["hammering", "hammer nail"], ["hammer nail"]),
    "saw": (["hand saw", "sawing wood"], ["sawing wood"]),
    "ambulance": (["ambulance siren"], ["ambulance siren"]),
    "firetruck": (["fire engine siren", "fire truck siren"], ["fire truck siren"]),
    "police": (["police siren"], ["police siren"]),
    "scissors": (["scissors cutting", "scissors"], ["scissors cutting paper"]),
    "typing": (["typing keyboard", "typewriter"], ["keyboard typing"]),
    "rocket": (["rocket launch"], ["rocket launch"]),
    "robot": (["robot"], ["robot voice beep", "robot"]),
    "spaceship": (["spaceship"], ["spaceship engine"]),
    "satellite": (["satellite beep", "sputnik"], ["satellite beep"]),
    "laser": (["laser"], ["laser shot"]),
}
AVOID = re.compile(r"\b(remix|loop|song by|imitation|imitating|speech|spoken|pronunciation|"
                   r"music video|ringtone|parody|human)\b", re.I)
FREE_LICENCES = re.compile(r"^(cc0|public domain|pd|cc[ -]by(-sa)?( \d\.\d)?)", re.I)


def get(url: str, *, raw: bool = False, timeout: int = 40):
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    with urllib.request.urlopen(req, timeout=timeout) as res:
        body = res.read()
    return body if raw else body.decode("utf-8", "replace")


# ── Wikimedia Commons ─────────────────────────────────────────────────────────
def commons(query: str, limit: int = 12) -> list[dict]:
    params = {
        "action": "query", "format": "json", "generator": "search",
        "gsrsearch": f"{query} filetype:audio", "gsrnamespace": "6", "gsrlimit": str(limit),
        "prop": "imageinfo", "iiprop": "url|extmetadata|mime|size",
        "iiextmetadatafilter": "LicenseShortName|Artist|ImageDescription|ObjectName",
    }
    data = json.loads(get("https://commons.wikimedia.org/w/api.php?" + urllib.parse.urlencode(params)))
    found = []
    for page in sorted((data.get("query") or {}).get("pages", {}).values(), key=lambda p: p.get("index", 99)):
        info = (page.get("imageinfo") or [{}])[0]
        meta = info.get("extmetadata") or {}
        licence = (meta.get("LicenseShortName") or {}).get("value", "")
        artist = re.sub(r"<[^>]+>", "", (meta.get("Artist") or {}).get("value", "")).strip()
        found.append({
            "from": "commons",
            "title": page.get("title", ""),
            "url": info.get("url", ""),
            "page": info.get("descriptionurl", ""),
            "licence": licence,
            "author": html.unescape(artist),
            "size": info.get("size", 0),
        })
    return found


# ── Freesound (CC0 only, no API key: the search page and its preview MP3s) ──────
def freesound(query: str) -> list[dict]:
    url = ("https://freesound.org/search/?" + urllib.parse.urlencode({
        "q": query, "f": 'license:"Creative Commons 0"', "s": "Rating descending"}))
    page = get(url)
    found = []
    # each result carries its preview in a data attribute; the sound page link sits nearby
    for m in re.finditer(r'data-mp3="(https://cdn\.freesound\.org/previews/[^"]+?)"', page):
        mp3 = m.group(1).replace("-lq.mp3", "-hq.mp3")
        near = page[max(0, m.start() - 3000): m.end() + 3000]
        link = re.search(r'href="(/people/[^/"]+/sounds/(\d+)/)"', near)
        title = re.search(r'data-title="([^"]+)"', near) or re.search(r'title="([^"]+)"', near)
        found.append({
            "from": "freesound",
            "title": html.unescape(title.group(1)) if title else "",
            "url": mp3,
            "page": "https://freesound.org" + link.group(1) if link else "",
            "licence": "CC0",
            "author": link.group(1).split("/")[2] if link else "",
            "size": 0,
        })
    return found


# ── cleaning ─────────────────────────────────────────────────────────────────
def clean(src: Path, dst: Path, seconds: float) -> None:
    chain = ("silenceremove=start_periods=1:start_threshold=-50dB:start_silence=0.02,"
             "areverse,silenceremove=start_periods=1:start_threshold=-50dB:start_silence=0.05,areverse,"
             f"atrim=0:{seconds},afade=t=out:st={max(0, seconds - 0.4)}:d=0.4,"
             "apad=pad_dur=0.1,loudnorm=I=-14:TP=-1.5:LRA=11")
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-t", "60", "-i", str(src), "-vn",
                    "-ac", "1", "-ar", "44100", "-af", chain, "-c:a", "libmp3lame", "-b:a", "128k",
                    str(dst)], check=True, stdin=subprocess.DEVNULL, timeout=120)


def duration(path: Path) -> float:
    out = subprocess.run(["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of",
                          "csv=p=0", str(path)], capture_output=True, text=True, timeout=30)
    try:
        return float(out.stdout.strip())
    except ValueError:
        return 0.0


def candidates(sound_id: str) -> list[dict]:
    commons_q, freesound_q = QUERIES.get(sound_id, ([sound_id], [sound_id]))
    found: list[dict] = []
    for q in commons_q:
        try:
            found += commons(q)
        except Exception as err:  # noqa: BLE001 — one source failing must not stop the other
            print(f"   commons «{q}»: {err}", file=sys.stderr)
        time.sleep(0.5)
    for q in freesound_q:
        try:
            found += freesound(q)
        except Exception as err:  # noqa: BLE001
            print(f"   freesound «{q}»: {err}", file=sys.stderr)
        time.sleep(1)
    keep, seen = [], set()
    for c in found:
        if not c["url"] or c["url"] in seen:
            continue
        seen.add(c["url"])
        if AVOID.search(c["title"]):
            continue
        if not FREE_LICENCES.match(c["licence"].strip()):
            continue
        if c["size"] and c["size"] > 40_000_000:
            continue
        keep.append(c)
    return keep


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("ids", nargs="*", help="sound ids (default: every one still synthetic)")
    ap.add_argument("--list", action="store_true", help="show candidates, write nothing")
    ap.add_argument("--force", action="store_true", help="replace even sounds already replaced")
    ap.add_argument("--pick", type=int, default=0, help="which candidate to use (0 = first that works)")
    ap.add_argument("--seconds", type=float, default=5.0, help="longest clip kept (default 5)")
    args = ap.parse_args()

    sounds = json.loads(LEVELS.read_text(encoding="utf-8"))["sounds"]
    sources = (json.loads(SOURCES.read_text(encoding="utf-8")) if SOURCES.exists() else
               {"note": "صدای حیوان‌ها و وسایل که با فایل واقعی جایگزین شده‌اند. صدایی که اینجا "
                        "نیست هنوز همان صدای سنتزیِ نسخه‌ی قبلی است.", "files": {}})
    wanted = [s for s in sounds if (not args.ids or s["id"] in args.ids)
              and (args.force or args.ids or s["id"] not in sources["files"])]

    done, missed = 0, []
    for sound in wanted:
        sid = sound["id"]
        print(f"• {sid} ({sound['title']})")
        found = candidates(sid)
        if args.list:
            for i, c in enumerate(found[:8]):
                print(f"   [{i}] {c['from']:9} {c['licence']:14} {c['title'][:70]}  {c['page']}")
            if not found:
                print("   — چیزی پیدا نشد")
            continue

        target = ROOT / "assets" / sound["audio"]
        ok = False
        for c in found[args.pick:]:
            with tempfile.TemporaryDirectory() as tmp:
                src = Path(tmp) / ("in" + (Path(urllib.parse.urlparse(c["url"]).path).suffix or ".bin"))
                out = Path(tmp) / "out.mp3"
                try:
                    src.write_bytes(get(c["url"], raw=True, timeout=120))
                    clean(src, out, args.seconds)
                except Exception as err:  # noqa: BLE001
                    print(f"   ✗ {c['title'][:60]}: {err}")
                    continue
                length = duration(out)
                if length < 0.4 or out.stat().st_size < 4000:
                    print(f"   ✗ {c['title'][:60]}: خروجی خیلی کوتاه است ({length:.1f}s)")
                    continue
                target.write_bytes(out.read_bytes())
            sources["files"][sid] = {
                "file": sound["audio"],
                "original": c["title"],
                "source": c["page"] or c["url"],
                "license": c["licence"],
                "author": c["author"],
                "via": "tools/sfx/fetch_sounds.py",
                "at": datetime.now(timezone.utc).isoformat(timespec="seconds"),
            }
            print(f"   ✓ {c['from']} · {c['licence']} · {c['title'][:60]} → {sound['audio']} ({length:.1f}s)")
            ok = True
            break
        if ok:
            done += 1
            SOURCES.parent.mkdir(parents=True, exist_ok=True)
            files = dict(sorted(sources["files"].items()))
            SOURCES.write_text(json.dumps({**sources, "files": files}, ensure_ascii=False, indent=2) + "\n",
                               encoding="utf-8")
        else:
            missed.append(sid)

    if not args.list:
        print(f"\n{done} صدا جایگزین شد." + (f" پیدا نشد: {', '.join(missed)}" if missed else ""))
    return 0 if not missed else 1


if __name__ == "__main__":
    sys.exit(main())
