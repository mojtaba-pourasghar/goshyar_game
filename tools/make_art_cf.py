#!/usr/bin/env python3
"""
تصویرهای مانده را با Cloudflare Workers AI (مدل Flux) می‌سازد.

صف را از tools/art_queue.json می‌خواند، هر تصویر را با همان موتور اسکیل
level-3-image-generator می‌سازد، به res/drawable می‌برد و از صف حذف می‌کند.

    python3 tools/make_art_cf.py           همه‌ی صف
    python3 tools/make_art_cf.py img_piano img_guitar
    python3 tools/make_art_cf.py --steps 6
"""
import base64
import json
import os
import subprocess
import sys

import requests
from dotenv import load_dotenv, find_dotenv

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
load_dotenv(find_dotenv(usecwd=True) or os.path.join(ROOT, ".env"))

MODEL = "@cf/black-forest-labs/flux-1-schnell"
QUEUE = os.path.join(ROOT, "tools", "art_queue.json")
RAW = os.path.join(ROOT, "art", "generated")
OUT = os.path.join(ROOT, "app", "src", "main", "res", "drawable")

STEPS = 4
for i, a in enumerate(sys.argv):
    if a == "--steps":
        STEPS = int(sys.argv[i + 1])
ONLY = {a for a in sys.argv[1:] if not a.startswith("--") and not a.isdigit()}


def generate(prompt):
    account = os.environ["CF_ACCOUNT_ID"]
    token = os.environ["CF_API_TOKEN"]
    url = f"https://api.cloudflare.com/client/v4/accounts/{account}/ai/run/{MODEL}"
    r = requests.post(url, headers={"Authorization": f"Bearer {token}"},
                      json={"prompt": prompt, "steps": STEPS}, timeout=120)
    data = r.json()
    img = data.get("result", {}).get("image")
    if not img:
        raise RuntimeError(f"HTTP {r.status_code}: {data.get('errors') or data}")
    return base64.b64decode(img)


def main():
    with open(QUEUE, encoding="utf-8") as fh:
        queue = json.load(fh)

    items = [i for i in queue["remaining"] if not ONLY or i["name"] in ONLY]
    if not items:
        print("صف خالی است.")
        return

    os.makedirs(RAW, exist_ok=True)
    os.makedirs(OUT, exist_ok=True)
    done, failed = [], []

    for n, item in enumerate(items, 1):
        name = item["name"]
        try:
            raw = generate(item["prompt"])
        except Exception as e:
            print(f"[{n}/{len(items)}] ❌ {name}: {e}")
            failed.append(name)
            continue

        raw_path = os.path.join(RAW, name + ".jpg")
        with open(raw_path, "wb") as fh:
            fh.write(raw)

        # پس‌زمینه‌ها عمودی می‌مانند، بقیه مربع ۵۱۲
        size = "1024x1536" if name.startswith("bg_") else "512x512"
        png = os.path.join(OUT, name + ".png")
        subprocess.run(["convert", raw_path, "-filter", "Lanczos",
                        "-resize", size, png], check=True)
        print(f"[{n}/{len(items)}] ✅ {name}  {os.path.getsize(png) // 1024} KB")
        done.append(name)

    queue["remaining"] = [i for i in queue["remaining"] if i["name"] not in done]
    with open(QUEUE, "w", encoding="utf-8") as fh:
        json.dump(queue, fh, ensure_ascii=False, indent=2)

    print(f"\nساخته شد: {len(done)}   |   ناموفق: {len(failed)}   |   مانده در صف: {len(queue['remaining'])}")
    if failed:
        print("ناموفق‌ها: " + ", ".join(failed))


if __name__ == "__main__":
    main()
