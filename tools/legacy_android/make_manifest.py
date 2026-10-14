#!/usr/bin/env python3
"""
فایل سه‌ستونی گفتارها را از tools/narration.py می‌سازد:

    app/src/main/res/raw/audio_manifest.txt

ستون‌ها:  <کلید> | <متنی که گوش‌یار می‌گوید> | <تلفظ آوایی برای ضبط صدا>

ستون سوم با همان ابزار پروژه «هوهو ریاضی» ساخته می‌شود (tools/pronounce.py و
tools/vowels.py) به‌علاوه‌ی واژه‌های مخصوص این بازی در tools/vowels_goshyar.py،
تا استودیوی صداگذاری بتواند همین فایل را مستقیم بخواند.

    python3 tools/make_manifest.py
    python3 tools/make_manifest.py --plain    # ستون سوم بدون اعراب
    python3 tools/make_manifest.py --check    # فقط گزارش واژه‌های بدون اعراب
"""
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
sys.path.insert(0, HERE)

import vowels as _vowels                       # noqa: E402
from vowels_goshyar import VOWELS_GOSHYAR      # noqa: E402

# واژه‌های این بازی روی جدول عمومی سوار می‌شوند، قبل از وارد کردن pronounce
_vowels.VOWELS.update(VOWELS_GOSHYAR)

import narration as n                          # noqa: E402
from pronounce import spoken as _spoken        # noqa: E402

VOWELS_ON = "--plain" not in sys.argv
CHECK_ONLY = "--check" in sys.argv
OUT = os.path.join(ROOT, "app", "src", "main", "res", "raw", "audio_manifest.txt")

HEADER = """\
# فهرست گفتارهای گوش‌یار
#
# هر خط سه ستون دارد:
#     <نام فایل> | <متنی که گوش‌یار می‌گوید> | <تلفظ آوایی برای ضبط صدا>
#
# ستون دوم همان چیزی است که در اپ خوانده می‌شود.
# ستون سوم فقط برای ساختِ صداست: واژه‌هایی که موتور گفتار اشتباه می‌خواند با اعراب
# نوشته شده‌اند. اپ این ستون را نمی‌خواند.
# اگر واژه‌ای بد تلفظ شد، آن را در tools/vowels_goshyar.py اصلاح کن.
#
# قرارداد کلیدها:
#     xxx     پرسش یا جمله‌ی اصلی
#     xxx_x   راهنمای بیشتر، وقتی کودک مکث می‌کند یا دکمه‌ی راهنما را می‌زند
#     xxx_f   بازخورد بعد از پاسخ درست
#
# گروه‌ها:
#     ui_   صفحه‌ها        cat_  دسته‌بندی‌ها     snd_  نام صداها
#     fs    پیدا کردن منبع صدا    wm   این صدا مال کیه؟
#     sq    ترتیب صداها           am   مأموریت شنیداری
#     fb_   بازخورد عمومی        bdg_  مدال‌ها
#
# این فایل با دست نوشته نمی‌شود — از tools/narration.py ساخته می‌شود:
#     python3 tools/make_manifest.py
"""


def spoken(text):
    return _spoken(text, vowels=VOWELS_ON)


def clean(text):
    """متن چندخطی پایتون را به یک خط صاف تبدیل می‌کند."""
    return re.sub(r"\s+", " ", text).strip()


def rows():
    """همه‌ی خط‌ها به ترتیبِ خواندنی، با عنوان هر بخش."""
    yield "section", "صفحه‌ها"
    for key, text in n.UI:
        yield key, text

    yield "section", "دسته‌بندی‌ها"
    for key, text in n.CATEGORIES:
        yield key, text

    yield "section", "نام صداها — بعد از پاسخ درست"
    for sid, text in n.SOUNDS:
        yield "snd_" + sid, text

    for title, prefix, group in (
        ("بازی ۱ — پیدا کردن منبع صدا", "fs", n.FIND_SOURCE),
        ("بازی ۲ — این صدا مال کیه؟", "wm", n.WHO_MADE),
        ("بازی ۳ — ترتیب صداها", "sq", n.SEQUENCE),
        ("بازی ۴ — مأموریت شنیداری", "am", n.MISSION),
    ):
        yield "section", title
        for num, question, hint, feedback in group:
            base = f"{prefix}{num:02d}"
            yield base, question
            yield base + "_x", hint
            yield base + "_f", feedback

    yield "section", "بازخوردهای عمومی"
    for key, text in n.FEEDBACK:
        yield key, text

    yield "section", "مدال‌ها"
    for key, text in n.BADGES:
        yield key, text


def main():
    lines, keys, bare = [HEADER], set(), {}
    count = 0

    for key, text in rows():
        if key == "section":
            lines.append("\n# ── " + text + " " + "─" * max(0, 60 - len(text)))
            continue
        if key in keys:
            sys.exit(f"کلید تکراری: {key}")
        keys.add(key)

        plain = clean(text)
        said = spoken(plain)
        lines.append(f"{key} | {plain} | {said}")
        count += 1

        # واژه‌هایی که در هیچ جدولی نبودند و بدون اعراب رفته‌اند
        if VOWELS_ON:
            for word in re.findall(r"[ء-ی‌]+", plain):
                if word not in _vowels.VOWELS and len(word) > 2:
                    bare.setdefault(word, 0)
                    bare[word] += 1

    if bare:
        top = sorted(bare.items(), key=lambda kv: -kv[1])
        print(f"⚠  {len(bare)} واژه بدون اعراب رفت (پرتکرارترین‌ها):")
        for word, times in top[:25]:
            print(f"   {word}  ×{times}")
        print("   برای اصلاح، به tools/vowels_goshyar.py اضافه کن.\n")

    if CHECK_ONLY:
        print(f"بررسی شد: {count} خط.")
        return

    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, "w", encoding="utf-8") as fh:
        fh.write("\n".join(lines).rstrip() + "\n")
    print(f"✅ {count} خط نوشته شد در {os.path.relpath(OUT, ROOT)}")


if __name__ == "__main__":
    main()
