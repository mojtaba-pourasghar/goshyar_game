#!/usr/bin/env python3
"""
ساخت فایل‌های صوتی گوینده فارسی بازی گوش‌یار با edge-tts.

نصب:   pip install edge-tts
اجرا:  python3 tools/generate_voice.py
       python3 tools/generate_voice.py --voice fa-IR-FaridNeural   (گوینده مرد)
       python3 tools/generate_voice.py --only v_intro_hello,v_correct_1
       python3 tools/generate_voice.py --list-voices

خروجی: app/src/main/assets/voice/<id>.mp3  +  voice_manifest.json
"""
import argparse
import asyncio
import json
import os
import sys

try:
    import edge_tts
except ImportError:
    sys.exit("edge-tts نصب نیست.  →  pip install edge-tts")

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SCRIPT = os.path.join(ROOT, "tools", "voice_script.json")


async def list_voices():
    voices = await edge_tts.list_voices()
    fa = [v for v in voices if v["Locale"].startswith("fa")]
    for v in fa:
        print(f"{v['ShortName']:<28} {v['Gender']:<8} {v['FriendlyName']}")
    if not fa:
        print("هیچ گوینده فارسی پیدا نشد.")


async def synth(text, voice, rate, pitch, out_path):
    comm = edge_tts.Communicate(text, voice, rate=rate, pitch=pitch)
    await comm.save(out_path)


async def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--voice", help="مثلاً fa-IR-DilaraNeural یا fa-IR-FaridNeural")
    ap.add_argument("--rate", help='مثلاً "-8%%" برای آهسته‌تر')
    ap.add_argument("--pitch", help='مثلاً "+8Hz" برای زیرتر')
    ap.add_argument("--out", help="پوشه خروجی")
    ap.add_argument("--only", help="فقط این id ها، با کاما جدا شده")
    ap.add_argument("--force", action="store_true", help="فایل‌های موجود را دوباره بساز")
    ap.add_argument("--list-voices", action="store_true")
    args = ap.parse_args()

    if args.list_voices:
        await list_voices()
        return

    with open(SCRIPT, encoding="utf-8") as f:
        data = json.load(f)

    d = data["defaults"]
    voice = args.voice or d["voice"]
    rate = args.rate or d.get("rate", "+0%")
    pitch = args.pitch or d.get("pitch", "+0Hz")
    out_dir = os.path.join(ROOT, args.out or d["outDir"])
    os.makedirs(out_dir, exist_ok=True)

    only = set(args.only.split(",")) if args.only else None
    lines = [l for l in data["lines"] if not only or l["id"] in only]

    print(f"گوینده: {voice}   سرعت: {rate}   زیروبمی: {pitch}")
    print(f"خروجی:  {out_dir}")
    print(f"تعداد:  {len(lines)} فایل\n")

    manifest, failed = {}, []
    for i, line in enumerate(lines, 1):
        vid, text = line["id"], line["text"]
        out_path = os.path.join(out_dir, vid + ".mp3")
        if os.path.exists(out_path) and os.path.getsize(out_path) > 0 and not args.force:
            print(f"[{i}/{len(lines)}] ⏭  {vid} (از قبل هست)")
            manifest[vid] = {"file": f"voice/{vid}.mp3", "text": text}
            continue
        try:
            await synth(text, line.get("voice", voice), line.get("rate", rate),
                        line.get("pitch", pitch), out_path)
            size = os.path.getsize(out_path)
            if size == 0:
                raise RuntimeError("فایل خروجی خالی است")
            print(f"[{i}/{len(lines)}] ✅ {vid}  ({size//1024} KB)")
            manifest[vid] = {"file": f"voice/{vid}.mp3", "text": text}
        except Exception as e:
            print(f"[{i}/{len(lines)}] ❌ {vid}: {e}")
            failed.append(vid)
            if os.path.exists(out_path) and os.path.getsize(out_path) == 0:
                os.remove(out_path)

    mf = os.path.join(out_dir, "voice_manifest.json")
    with open(mf, "w", encoding="utf-8") as f:
        json.dump({"voice": voice, "lines": manifest}, f, ensure_ascii=False, indent=2)

    print(f"\nساخته شد: {len(manifest)} فایل   |   ناموفق: {len(failed)}")
    if failed:
        print("ناموفق‌ها: " + ", ".join(failed))
        sys.exit(1)


if __name__ == "__main__":
    asyncio.run(main())
