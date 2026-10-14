#!/usr/bin/env python3
"""
تصویرهای نهایی را از art/incoming/ به res/drawable/ منتقل می‌کند
و گزارش می‌دهد کدام تصویرهای art_manifest.json هنوز کم است.

اجرا:  python3 tools/install_art.py
"""
import json
import os
import shutil
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MANIFEST = os.path.join(ROOT, "art", "art_manifest.json")
INCOMING = os.path.join(ROOT, "art", "incoming")
DRAWABLE = os.path.join(ROOT, "app", "src", "main", "res", "drawable")
EXTS = (".png", ".webp", ".jpg", ".jpeg")

def main():
    with open(MANIFEST, encoding="utf-8") as f:
        items = json.load(f)["items"]

    os.makedirs(INCOMING, exist_ok=True)
    os.makedirs(DRAWABLE, exist_ok=True)

    installed, missing = [], []
    for item in items:
        target = item["target"]
        src = next((os.path.join(INCOMING, target + e)
                    for e in EXTS
                    if os.path.exists(os.path.join(INCOMING, target + e))), None)
        if src is None:
            # اگر از قبل در drawable هست، کم نیست
            if any(os.path.exists(os.path.join(DRAWABLE, target + e)) for e in EXTS):
                continue
            missing.append(target)
            continue
        ext = os.path.splitext(src)[1].lower()
        ext = ".png" if ext in (".jpg", ".jpeg") else ext
        dst = os.path.join(DRAWABLE, target + ext)
        shutil.move(src, dst)
        installed.append(target + ext)

    for name in installed:
        print(f"✅ نصب شد: {name}")
    print(f"\nنصب‌شده: {len(installed)}   |   هنوز کم: {len(missing)}")
    if missing:
        print("\nتصویرهای کم (نام فایل را دقیقاً همین بگذارید):")
        for name in missing:
            print("  - " + name)
        sys.exit(1)

if __name__ == "__main__":
    main()
