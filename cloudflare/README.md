# Cloudflare: ذخیره و توزیع دارایی‌های گوش‌یار

Cloudflare فقط مسئول **نگه‌داری و رساندن فایل‌ها** (تصویر، صدای بازی، صدای گوینده) است؛
طراحی و رابط کاربری در خود برنامه‌ی Flutter است.

> **وضعیت:** کد Worker، پیکربندی، اسکریپت‌های ساخت و بارگذاری آماده‌اند و به‌صورت **محلی**
> (wrangler dev / Miniflare) آزمایش شده‌اند. **هیچ حساب Cloudflare به این پروژه وصل نشده و
> چیزی روی Cloudflare واقعی ساخته یا بارگذاری نشده است.** مراحل زیر را صاحب حساب باید انجام دهد.

## معماری

```
برنامه (Flutter)
  │  GET https://<دامنه>/goshyar/v1/packs.json           ← فهرست بسته‌ها (کش ۵ دقیقه)
  │  GET https://<دامنه>/goshyar/v1/audio/voice/….mp3     ← فایل‌ها (کش یک‌ساله، immutable)
  ▼
Cloudflare Worker «goshyar-assets»  (فقط GET/HEAD، CORS، کش لبه، Range، ETag/304)
  ▼
R2 bucket «goshyar-assets»  (خصوصی؛ تنها راه دسترسی همین Worker است)
```

- **نسخه‌بندی:** همه‌ی مسیرها زیر `goshyar/<نسخه>/` هستند. فایل منتشرشده هرگز عوض نمی‌شود؛
  برای تغییر، نسخه‌ی تازه (`v2`) بسازید و برنامه را با `GOSHYAR_ASSET_VERSION=v2` بسازید.
  به همین دلیل کش یک‌ساله امن است.
- **ساختار پوشه‌ها:** دقیقاً همان مسیرهای منطقی برنامه (`audio/voice/…`, `audio/sfx/…`, `images/…`)،
  پس فایل دانلودشده خودبه‌خود جای فایل داخلی را می‌گیرد (`lib/core/assets/asset_resolver.dart`).
- **بدون اینترنت:** همه‌ی صداها و تصویرهای اصلی داخل APK هستند. بسته‌های دانلودی اختیاری‌اند،
  روی دستگاه می‌مانند و بدون اینترنت پخش می‌شوند؛ فهرست بسته‌ها هم روی دستگاه ذخیره می‌شود.
- **امنیت:** برنامه هیچ کلید یا توکنی ندارد. bucket عمومی نمی‌شود. Worker فقط پیشوند `goshyar/`
  را سرو می‌کند و `..` را رد می‌کند. هر فایل در برنامه با sha256 فهرست بررسی می‌شود.

## راه‌اندازی (یک بار)

```bash
cd cloudflare/worker
npx wrangler@4 login                                  # اعتبارنامه فقط روی سیستم شما می‌ماند
npx wrangler@4 r2 bucket create goshyar-assets
npx wrangler@4 r2 bucket cors set goshyar-assets --file ../r2-cors.json
# دامنه را در wrangler.toml (routes) تنظیم کنید، بعد:
npx wrangler@4 deploy
```

## انتشار دارایی‌ها

```bash
cd goshyar_game
python3 cloudflare/scripts/build_packs.py --version v1 --voice-dir /path/to/recorded/voice
cloudflare/scripts/upload.sh v1        # packs.json آخر از همه بارگذاری می‌شود
```

## ساخت برنامه با CDN

```bash
flutter build apk --release \
  --dart-define=GOSHYAR_CDN_BASE=https://assets.example.com \
  --dart-define=GOSHYAR_ASSET_VERSION=v1
```

بدون `GOSHYAR_CDN_BASE`، صفحه‌ی «ذخیره‌شده‌ها» می‌گوید سرور تنظیم نشده و برنامه فقط با
دارایی‌های داخلی کار می‌کند.

## آزمایش محلی (بدون حساب)

```bash
python3 cloudflare/scripts/build_packs.py --version v1
cd cloudflare/dist && npx wrangler@4 r2 object put goshyar-assets/goshyar/v1/packs.json \
   --file goshyar/v1/packs.json --local --config ../worker/wrangler.toml --persist-to ../worker/.wrangler/state
cd ../worker && npx wrangler@4 dev --persist-to .wrangler/state
curl -i http://127.0.0.1:8787/goshyar/v1/packs.json
```

آنچه محلی بررسی شد: پاسخ ۲۰۰ و بایت‌های یکسان، کش لبه (HIT)، کش کوتاه packs.json و یک‌ساله برای فایل‌ها،
Range ← ۲۰۶ با Content-Range، HEAD، ETag ← ۳۰۴، ۴۰۴ بیرون از پیشوند و مسیر `..`، ۴۰۵ برای POST،
پیش‌پرواز CORS، و دانلود واقعی یک فایل با `DownloadManager` برنامه و بررسی sha256.
