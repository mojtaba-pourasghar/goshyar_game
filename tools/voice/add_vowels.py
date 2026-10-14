#!/usr/bin/env python3
"""آواگذاری: writes the vowelled spelling of every line into the `spoken` field of
assets/content/voice_lines.json, for the TTS service to read.

Persian leaves the short vowels out and a speech engine guesses them, often wrongly
(صدا as «sedā» or «sadā»). The voice studio sends `spoken` instead of `text` when
«با اعراب» is on; the app itself only ever shows `text`.

The spellings come from three tables, later ones winning:
  tools/legacy_android/vowels.py          — the general table from the earlier projects
  tools/legacy_android/vowels_goshyar.py  — the world of sounds and animals
  VOWELS_EXTRA below                      — words of the new Flutter lines

    python3 tools/voice/add_vowels.py          # fill `spoken` for every line
    python3 tools/voice/add_vowels.py --check  # list words no table knows; writes nothing

A line whose `spoken` was set by hand in the studio («متن» button) is left alone unless
--force is given; tools/voice/voice-overrides.json lists those.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
LINES = ROOT / "assets/content/voice_lines.json"
OVERRIDES = ROOT / "tools/voice/voice-overrides.json"
sys.path.insert(0, str(ROOT / "tools/legacy_android"))

import pronounce  # noqa: E402  (its VOWELS is the same dict object as vowels.VOWELS)
from vowels_goshyar import VOWELS_GOSHYAR  # noqa: E402

VOWELS_EXTRA = {
    "درسته": "دُرُستِه", "عکس‌ها": "عَکس‌ها", "بوم": "بوم", "منتظر": "مُنتَظِر",
    "حافظه‌ات": "حافِظه‌اَت", "موج‌های": "موج‌های", "ابرها": "اَبرها", "صاحبش": "صاحِبَش",
    "غرش": "غُرِّش", "کوآک": "کوآک", "جرینگ": "جِرینگ", "کوچولوی": "کوچولوی",
    "گوش‌هایمان": "گوش‌هایِمان", "آماده‌اند": "آماده‌اَند", "کم‌رنگ": "کَم‌رَنگ",
    "تصویرهایی": "تَصویرهایی", "ذخیره": "ذَخیره", "سازها": "سازها", "صدایشان": "صِدایِشان",
    "بشناسیم": "بِشناسیم", "مخفی": "مَخفی", "هیس": "هیس", "کی": "کی", "درآورد": "دَرآوَرد",
    "ای": "ای", "ول": "وَل", "باریکلا": "باریکَلّا", "هورا": "هورا", "نشنیدی": "نَشِنیدی",
    "ستاره‌هایت": "سِتاره‌هایَت", "امتیازهایت": "اِمتیازهایَت", "آماده‌ی": "آماده‌ی",
    "مرحله‌های": "مَرحَله‌های", "مرحله‌ها": "مَرحَله‌ها", "خداحافظ": "خُداحافِظ",
    "می‌پزیم": "می‌پَزیم", "چای": "چای", "وای": "وای", "وزش": "وَزِش", "دل": "دِل",
    "کاموا": "کاموا", "سلطان": "سُلطان", "مادربزرگ": "مادَربُزُرگ", "می‌نوازد": "می‌نَوازَد",
    "چراغ‌های": "چِراغ‌های", "صداهایی": "صِداهایی", "بخیر": "بِخِیر", "حیوان‌های": "حِیوان‌های",
    "خانه‌ایم": "خانه‌ایم", "آرام‌اند": "آرام‌اَند", "ماغ": "ماغ", "هاپ‌هاپ": "هاپ‌هاپ",
    "می‌ریزند": "می‌ریزَند", "ترق‌ترق": "تَرَق‌تَرَق", "بیمار": "بیمار",
    "آتش‌نشان‌ها": "آتَش‌نِشان‌ها", "لطفا": "لُطفاً",
}

pronounce.VOWELS.update(VOWELS_GOSHYAR)
pronounce.VOWELS.update(VOWELS_EXTRA)
WORD = re.compile("[ء-غف-يپچژکگی‌]+")


def unknown(text: str) -> list[str]:
    return [w for w in (t.strip("‌") for t in WORD.findall(text)) if w and w not in pronounce.VOWELS]


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--check", action="store_true", help="list unknown words, write nothing")
    ap.add_argument("--force", action="store_true", help="also rewrite lines fixed by hand in the studio")
    args = ap.parse_args()

    original = LINES.read_text(encoding="utf-8")
    data = json.loads(original)
    by_hand = set(json.loads(OVERRIDES.read_text(encoding="utf-8"))) if OVERRIDES.exists() else set()
    missing: dict[str, int] = {}
    changed = 0
    for line in data["lines"]:
        for w in unknown(line["text"]):
            missing[w] = missing.get(w, 0) + 1
        key = Path(line.get("file") or line["id"].replace(".", "_")).stem
        if args.check or (key in by_hand and not args.force):
            continue
        said = pronounce.spoken(line["text"])
        if said != line.get("spoken"):
            line["spoken"] = said
            changed += 1

    if missing:
        print("واژه‌هایی که در جدول نیستند (بی‌اعراب خوانده می‌شوند):")
        print("  " + " ".join(sorted(missing, key=lambda w: -missing[w])))
    if args.check:
        return 1 if missing else 0
    LINES.write_text(json.dumps(data, ensure_ascii=False, indent=2) + ("\n" if original.endswith("\n") else ""),
                     encoding="utf-8")
    print(f"{changed} جمله آواگذاری شد ← {LINES.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
