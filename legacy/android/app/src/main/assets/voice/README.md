# صدای گوینده فارسی

این فایل‌ها تولیدی هستند و در گیت نگه‌داری نمی‌شوند. برای ساختشان:

```bash
pip install edge-tts
python3 tools/generate_voice.py
```

متن کامل همه جمله‌ها در `tools/voice_script.json` است.
برای گوینده مرد: `python3 tools/generate_voice.py --voice fa-IR-FaridNeural`
فهرست گوینده‌های فارسی: `python3 tools/generate_voice.py --list-voices`

اگر فایلی موجود نباشد، برنامه بی‌سروصدا از آن رد می‌شود و بازی قفل نمی‌شود.
