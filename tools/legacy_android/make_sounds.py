#!/usr/bin/env python3
"""
همه‌ی فایل‌های صوتی بازی را می‌سازد و در app/src/main/assets/sfx/ می‌گذارد.

صداها با سنتز ساخته می‌شوند (numpy) و با ffmpeg به MP3 تبدیل می‌شوند —
هیچ فایل بیرونی و هیچ دانلودی لازم نیست.

    python3 tools/make_sounds.py                 همه
    python3 tools/make_sounds.py animals_lion    فقط یکی
    python3 tools/make_sounds.py --wav           خروجی WAV هم نگه دار
    python3 tools/make_sounds.py --check         فقط بررسی هماهنگی با levels.json
"""
import json
import os
import subprocess
import sys
import wave

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
sys.path.insert(0, HERE)

from synth import SR                     # noqa: E402
from sounds_animals import ANIMALS       # noqa: E402
from sounds_world import WORLD           # noqa: E402

RECIPES = {**ANIMALS, **WORLD}
OUT_DIR = os.path.join(ROOT, "app", "src", "main", "assets", "sfx")
LEVELS = os.path.join(ROOT, "app", "src", "main", "assets", "levels.json")


def write_wav(path, samples):
    pcm = np.int16(np.clip(samples, -1.0, 1.0) * 32767)
    with wave.open(path, "wb") as fh:
        fh.setnchannels(1)
        fh.setsampwidth(2)
        fh.setframerate(SR)
        fh.writeframes(pcm.tobytes())


def to_mp3(wav_path, mp3_path):
    subprocess.run(
        ["ffmpeg", "-y", "-loglevel", "error", "-i", wav_path,
         "-codec:a", "libmp3lame", "-qscale:a", "4", "-ar", "44100", "-ac", "1",
         mp3_path],
        check=True,
    )


def expected_names():
    """نام فایل‌هایی که levels.json انتظار دارد."""
    with open(LEVELS, encoding="utf-8") as fh:
        data = json.load(fh)
    return {s["audio"].split("/")[-1].replace(".mp3", "") for s in data["sounds"]}


def check():
    want = expected_names()
    have = set(RECIPES) - {"ui_success", "ui_fail", "ui_tap"}
    missing, extra = want - have, have - want
    if missing:
        print(f"❌ {len(missing)} صدا در levels.json هست ولی دستور ساختش نیست:")
        for name in sorted(missing):
            print("   - " + name)
    if extra:
        print(f"⚠  {len(extra)} صدا ساخته می‌شود ولی در levels.json نیست:")
        for name in sorted(extra):
            print("   - " + name)
    if not missing and not extra:
        print(f"✅ هماهنگ است: {len(want)} صدای بازی + ۳ صدای رابط کاربری.")
    return not missing


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    keep_wav = "--wav" in sys.argv

    if "--check" in sys.argv:
        sys.exit(0 if check() else 1)
    if not check():
        print()

    names = args or sorted(RECIPES)
    unknown = [n for n in names if n not in RECIPES]
    if unknown:
        sys.exit("صدای ناشناخته: " + ", ".join(unknown))

    os.makedirs(OUT_DIR, exist_ok=True)
    tmp_dir = os.path.join(ROOT, "build", "sfx-wav")
    os.makedirs(tmp_dir, exist_ok=True)

    total = 0
    for i, name in enumerate(names, 1):
        samples = RECIPES[name]()
        wav_path = os.path.join(tmp_dir, name + ".wav")
        mp3_path = os.path.join(OUT_DIR, name + ".mp3")
        write_wav(wav_path, samples)
        to_mp3(wav_path, mp3_path)
        if not keep_wav:
            os.remove(wav_path)
        size = os.path.getsize(mp3_path)
        total += size
        print(f"[{i}/{len(names)}] ✅ {name:22} {len(samples) / SR:5.2f}s  {size // 1024:3d} KB")

    print(f"\n{len(names)} فایل، مجموعاً {total / 1024:.0f} کیلوبایت، در "
          f"{os.path.relpath(OUT_DIR, ROOT)}")


if __name__ == "__main__":
    main()
