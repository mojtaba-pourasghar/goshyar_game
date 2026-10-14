#!/usr/bin/env python3
"""
دارایی‌های نسخه‌ی Flutter را از دو منبع می‌سازد:

1. پروژه‌ی قدیمی اندروید (goshyar_game، کامیت 7fd09f8): تصویر صداها، مکان‌ها،
   صحنه‌ها و فایل‌های صوتی sfx.
2. art/source/canva/: تصویرهای ماسکوت که با Canva ساخته شده‌اند (پیش‌نمایش ۲۰۰×۲۰۰).
   پس‌زمینه‌ی سفیدشان شفاف و اندازه‌شان با Lanczos به ۵۱۲ بزرگ می‌شود.

    python3 tools/prepare_assets.py --legacy legacy/android

خروجی‌ها در assets/images و assets/audio نوشته می‌شوند و فایل‌های موجود بازنویسی می‌شوند.
"""
import argparse
import json
import os
import shutil
import sys

from PIL import Image, ImageDraw, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
ASSETS = os.path.join(ROOT, "assets")

CARD_SIZE = 384
SCENE_WIDTH = 960
MASCOT_SIZE = 512

# صحنه‌هایی که در نسخه‌ی قدیمی دکمه‌ی پخش رویشان «پخته» شده بود کنار گذاشته شده‌اند
# (bg_sunny_forest و bg_night_forest)؛ جنگل روز و شب حالا در Flutter نقاشی می‌شوند.
SCENES = ["bg_farm", "bg_home", "bg_city"]

MASCOTS = ["bear_listening", "bear_wave", "bear_celebrate", "bear_think", "bear_cheer"]


def save_webp(img, path, quality=86):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img.save(path, "WEBP", quality=quality, method=6)


def card_image(src, dst):
    img = Image.open(src).convert("RGB")
    w, h = img.size
    side = min(w, h)
    img = img.crop(((w - side) // 2, (h - side) // 2, (w + side) // 2, (h + side) // 2))
    img = img.resize((CARD_SIZE, CARD_SIZE), Image.LANCZOS)
    save_webp(img, dst)


def scene_image(src, dst):
    img = Image.open(src).convert("RGB")
    w, h = img.size
    if w > SCENE_WIDTH:
        img = img.resize((SCENE_WIDTH, round(h * SCENE_WIDTH / w)), Image.LANCZOS)
    save_webp(img, dst, quality=82)


def cut_white_background(img):
    """پس‌زمینه‌ی سفیدِ متصل به لبه‌ها را شفاف می‌کند؛ سفیدیِ داخل شخصیت می‌ماند."""
    rgb = img.convert("RGB")
    w, h = rgb.size
    px = rgb.load()
    mask = Image.new("L", (w, h), 0)
    mp = mask.load()
    for y in range(h):
        for x in range(w):
            r, g, b = px[x, y]
            if r > 222 and g > 222 and b > 222 and max(r, g, b) - min(r, g, b) < 24:
                mp[x, y] = 255
    for x in range(w):
        for y in (0, h - 1):
            if mp[x, y] == 255:
                ImageDraw.floodfill(mask, (x, y), 128)
    for y in range(h):
        for x in (0, w - 1):
            if mp[x, y] == 255:
                ImageDraw.floodfill(mask, (x, y), 128)
    alpha = mask.point(lambda v: 0 if v == 128 else 255)
    alpha = alpha.filter(ImageFilter.GaussianBlur(0.8))
    out = rgb.convert("RGBA")
    out.putalpha(alpha)
    return out


def mascot_image(src, dst):
    img = Image.open(src)
    img = img.resize((MASCOT_SIZE, MASCOT_SIZE), Image.LANCZOS)
    img = img.filter(ImageFilter.UnsharpMask(radius=1.6, percent=60, threshold=2))
    save_webp(cut_white_background(img), dst, quality=90)


def launcher_icon(src, dst_png):
    """آیکون برنامه: خرس روی دایره‌ی نارنجی روشن، ۵۱۲×۵۱۲."""
    bear = cut_white_background(Image.open(src).resize((MASCOT_SIZE, MASCOT_SIZE), Image.LANCZOS))
    icon = Image.new("RGBA", (512, 512), (0, 0, 0, 0))
    bg = Image.new("RGBA", (512, 512), (255, 183, 77, 255))
    circle = Image.new("L", (512, 512), 0)
    ImageDraw.Draw(circle).ellipse((0, 0, 511, 511), fill=255)
    icon.paste(bg, (0, 0), circle)
    bear = bear.resize((470, 470), Image.LANCZOS)
    icon.alpha_composite(bear, (21, 30))
    os.makedirs(os.path.dirname(dst_png), exist_ok=True)
    icon.save(dst_png)
    return icon


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--legacy", required=True, help="مسیر کلون پروژه‌ی قدیمی goshyar_game")
    args = ap.parse_args()

    legacy_main = os.path.join(args.legacy, "app", "src", "main")
    drawable = os.path.join(legacy_main, "res", "drawable")
    levels_path = os.path.join(ROOT, "assets", "content", "levels.json")
    if not os.path.isdir(drawable):
        sys.exit("پوشه‌ی drawable پیدا نشد: " + drawable)

    with open(levels_path, encoding="utf-8") as f:
        content = json.load(f)

    canva = os.path.join(ROOT, "art", "source", "canva")
    missing = []
    for s in content["sounds"]:
        # تصویر تازه‌ی Canva (sound_<id>.jpg) اگر باشد، بر تصویر قدیمی اولویت دارد.
        src = os.path.join(canva, "sound_%s.jpg" % s["id"])
        if not os.path.exists(src):
            src = os.path.join(drawable, "img_%s.png" % s["id"])
        if os.path.exists(src):
            card_image(src, os.path.join(ASSETS, "images", "sounds", s["id"] + ".webp"))
        else:
            missing.append("image:" + s["id"])
        sfx = os.path.join(legacy_main, "assets", "sfx", os.path.basename(s["audio"]))
        if os.path.exists(sfx):
            dst = os.path.join(ASSETS, "audio", "sfx", os.path.basename(s["audio"]))
            os.makedirs(os.path.dirname(dst), exist_ok=True)
            shutil.copyfile(sfx, dst)
        else:
            missing.append("audio:" + s["id"])

    for p in content["places"]:
        src = os.path.join(drawable, "img_place_%s.png" % p["id"])
        if os.path.exists(src):
            card_image(src, os.path.join(ASSETS, "images", "places", p["id"] + ".webp"))
        else:
            missing.append("place:" + p["id"])

    for name in SCENES:
        scene_image(os.path.join(drawable, name + ".png"),
                    os.path.join(ASSETS, "images", "scenes", name.replace("bg_", "") + ".webp"))

    ui_dir = os.path.join(ASSETS, "audio", "ui")
    os.makedirs(ui_dir, exist_ok=True)
    for ui in ("success", "fail", "tap"):
        shutil.copyfile(os.path.join(legacy_main, "assets", "sfx", "ui_%s.mp3" % ui),
                        os.path.join(ui_dir, ui + ".mp3"))

    for name in MASCOTS:
        mascot_image(os.path.join(canva, name + ".jpg"),
                     os.path.join(ASSETS, "images", "mascot", name + ".webp"))
    launcher_icon(os.path.join(canva, "bear_wave.jpg"), os.path.join(ROOT, "art", "app_icon.png"))

    print("✅ دارایی‌ها ساخته شدند.")
    if missing:
        print("⚠️  نبودند:", ", ".join(missing))


if __name__ == "__main__":
    main()
