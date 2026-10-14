#!/usr/bin/env python3
"""
تصویرهای بازی را از خودِ اینفوگرافیک‌های مرجع می‌بُرد.

کاربر خواست گرافیک «عین عکس خودم» باشد، پس به‌جای بازکشیدن، همان عنصرها از
دو اینفوگرافیک در art/reference/ بریده و بزرگ می‌شوند. نتیجه دقیقاً همان
سبک است، چون همان تصویر است.

    python3 tools/extract_art.py            نصب در res/drawable
    python3 tools/extract_art.py --preview  نوشتن در build/art-preview

محدودیت: فقط چیزهایی که در این دو عکس هستند. فهرست کم‌وکاست‌ها را
--report چاپ می‌کند.
"""
import json
import os
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
REF = os.path.join(ROOT, "art", "reference")
A = os.path.join(REF, "infographic-goshyar.webp")   # اینفوگرافیک گوش‌یار
B = os.path.join(REF, "infographic-ears.webp")      # اینفوگرافیک بازی با گوش‌ها
SCALE = 400                                          # درصد بزرگ‌نمایی

# (نام مقصد, فایل مرجع, «عرض×ارتفاع+x+y»)
CROPS = [
    # ── ماسکوت ──
    ("mascot_idle",        A, "100x125+55+630"),
    ("mascot_listening",   A, "100x125+55+630"),
    ("mascot_encouraging", A, "118x135+235+632"),
    ("mascot_happy",       A, "118x135+235+632"),

    # ── حیوانات ──
    ("img_lion",   A, "105x105+633+582"),
    ("img_rabbit", A, "66x72+804+707"),
    ("img_cow",    A, "78x58+284+992"),
    ("img_dog",    B, "69x57+634+557"),
    ("img_cat",    B, "69x50+719+501"),
    ("img_bird",   A, "57x67+583+989"),

    # ── موسیقی ──
    ("img_bell", A, "54x67+511+989"),
    ("img_drum", A, "58x67+655+989"),

    # ── طبیعت و فضا ──
    ("img_rain",   B, "55x52+253+1070"),
    ("img_rocket", B, "43x57+590+1065"),

    # ── مکان‌ها ──
    ("img_place_forest", B, "69x56+427+501"),
    ("img_place_cave",   B, "66x56+505+501"),
    ("img_place_river",  B, "69x56+427+567"),
    ("img_place_house",  B, "66x56+505+567"),

    # ── پس‌زمینه‌ها ──
    ("bg_sunny_forest", A, "180x122+40+988"),
    ("bg_night_forest", A, "202x122+774+988"),
]


def needed():
    """نام تصویرهایی که levels.json انتظار دارد."""
    with open(os.path.join(ROOT, "app/src/main/assets/levels.json"), encoding="utf-8") as fh:
        data = json.load(fh)
    names = {s["image"] for s in data["sounds"]}
    names |= {p["image"] for p in data["places"]}
    for mode in data["modes"]:
        for lvl in mode["levels"]:
            if lvl.get("background"):
                names.add(lvl["background"])
    return names


def report():
    have = {name for name, _, _ in CROPS}
    want = needed()
    missing = sorted(want - have)
    print(f"از مرجع استخراج می‌شود: {len(have & want)} از {len(want)}")
    print(f"\nدر عکس‌های مرجع نیست ({len(missing)} تصویر) — برای این‌ها مدل تصویر لازم است:")
    for name in missing:
        print("  - " + name)


def main():
    if "--report" in sys.argv:
        report()
        return

    out = (os.path.join(ROOT, "build", "art-preview") if "--preview" in sys.argv
           else os.path.join(ROOT, "app/src/main/res/drawable"))
    os.makedirs(out, exist_ok=True)

    for name, src, box in CROPS:
        dst = os.path.join(out, name + ".png")
        subprocess.run(
            ["convert", src, "-crop", box, "+repage",
             "-filter", "Lanczos", "-resize", f"{SCALE}%", dst],
            check=True,
        )
        print(f"✅ {name}.png  {os.path.getsize(dst) // 1024} KB")

    print(f"\n{len(CROPS)} تصویر در {os.path.relpath(out, ROOT)}")
    print()
    report()


if __name__ == "__main__":
    main()
