#!/usr/bin/env python3
"""
Builds the CDN upload tree and the pack index (packs.json) for the Flutter app.

    python3 cloudflare/scripts/build_packs.py --version v1 [--voice-dir path/to/recorded/voice]

Output: cloudflare/dist/goshyar/<version>/...
  packs.json            index read by the app's DownloadManager (sha256 + size per file)
  audio/voice/*.mp3     recorded narrator lines   -> pack "voice-fa"
  audio/sfx/*.mp3       sound effects              -> pack "sounds-hq"
  images/**/*.webp      card art and scenes        -> pack "images-hq"

Paths match the app's logical asset paths, so a downloaded file simply overrides the
bundled one (see lib/core/assets/asset_resolver.dart). Packs are optional: the APK
already contains everything needed offline except the recorded voice.
"""
import argparse
import hashlib
import json
import os
import shutil

HERE = os.path.dirname(os.path.abspath(__file__))
APP = os.path.dirname(os.path.dirname(HERE))
ASSETS = os.path.join(APP, "assets")

PACKS = [
    ("voice-fa", "صدای گوینده", "جمله‌های ضبط‌شده‌ی گوش‌یار", "audio/voice", (".mp3",)),
    ("sounds-hq", "صداهای بازی", "صدای حیوان‌ها، وسایل و طبیعت", "audio/sfx", (".mp3",)),
    ("images-hq", "تصویرها", "تصویر کارت‌ها و صحنه‌ها", "images", (".webp", ".png")),
]


def sha256(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 16), b""):
            h.update(chunk)
    return h.hexdigest()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--version", default="v1")
    ap.add_argument("--voice-dir", help="folder with recorded voice mp3s (default: assets/audio/voice)")
    args = ap.parse_args()

    root = os.path.join(APP, "cloudflare", "dist", "goshyar", args.version)
    if os.path.isdir(root):
        shutil.rmtree(root)
    os.makedirs(root)

    index = {"version": args.version, "packs": []}
    for pack_id, title, desc, rel, exts in PACKS:
        src_dir = args.voice_dir if (pack_id == "voice-fa" and args.voice_dir) else os.path.join(ASSETS, rel)
        files = []
        for dirpath, _, names in os.walk(src_dir):
            for n in sorted(names):
                if not n.lower().endswith(exts):
                    continue
                src = os.path.join(dirpath, n)
                logical = os.path.join(rel, os.path.relpath(src, src_dir)).replace(os.sep, "/")
                dst = os.path.join(root, logical)
                os.makedirs(os.path.dirname(dst), exist_ok=True)
                shutil.copyfile(src, dst)
                files.append({"path": logical, "size": os.path.getsize(src), "sha256": sha256(src)})
        if files:
            index["packs"].append({"id": pack_id, "title": title, "description": desc, "files": files})
        print("%-10s %4d files" % (pack_id, len(files)))

    with open(os.path.join(root, "packs.json"), "w", encoding="utf-8") as f:
        json.dump(index, f, ensure_ascii=False, indent=1)
    print("wrote", os.path.relpath(root, APP))


if __name__ == "__main__":
    main()
