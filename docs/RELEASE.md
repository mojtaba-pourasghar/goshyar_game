# ساخت نسخه‌ی release و انتشار در کافه‌بازار

## debug و release چه فرقی دارند

| | debug (دکمه‌ی Run در Android Studio) | release (برای بازار) |
|---|---|---|
| مرحله‌ها | **همه باز**، بی‌ترتیب و بی‌خرید | در هر بازی **فقط مرحله‌ی ۱** رایگان؛ بقیه با «نسخه‌ی کامل» |
| پرداخت | لازم نیست | کافه‌بازار (Poolakey) |
| امضا | کلید debug | کلید release شما |

## ۱. یک بار: ساخت کلید امضا (keystore)

**با Android Studio:**
1. پوشه‌ی `android` پروژه را در Android Studio باز کنید (File ← Open ← `goshyar_game/android`).
2. منوی **Build ← Generate Signed App Bundle / APK** ← **APK** ← Next.
3. زیر Key store path، **Create new…** را بزنید:
   - مسیر: مثلاً `C:\MyData\Keys\goshyar-release.jks` (**بیرون از پروژه**)
   - رمز keystore و رمز کلید را بگذارید. Alias: `goshyar`. Validity: `25`. نام و شهر را پر کنید.
4. OK بزنید. **کلید ساخته شد؛ پنجره را ببندید** (ادامه‌ی ساخت را با Flutter انجام می‌دهیم).

**یا با خط فرمان:**
```powershell
keytool -genkey -v -keystore C:\MyData\Keys\goshyar-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias goshyar
```

⚠️ از فایل `.jks` و رمزهایش **پشتیبان** بگیرید. اگر گم شود، دیگر نمی‌توانید نسخه‌ی تازه روی همین برنامه در بازار منتشر کنید.

## ۲. یک بار: `android/key.properties`
`android/key.properties.example` را کپی کنید به `android/key.properties` و پر کنید:
```properties
storePassword=رمز keystore
keyPassword=رمز کلید
keyAlias=goshyar
storeFile=C:/MyData/Keys/goshyar-release.jks
```
(در مسیر ویندوز از `/` استفاده کنید.) این فایل در گیت نیست.

## ۳. یک بار: پنل کافه‌بازار و `android/services.properties`
1. در [پنل توسعه‌دهندگان کافه‌بازار](https://pishkhan.cafebazaar.ir) برنامه‌ی `com.goshyar.app` را بسازید.
2. **پرداخت درون‌برنامه‌ای** ← محصول تازه:
   - نوع: **مصرف‌نشدنی** (یک بار خرید، برای همیشه)
   - شناسه (SKU): **`goshyar_full`**
   - قیمت: **۱۸۰٬۰۰۰ تومان**
3. از همان بخش **کلید RSA** را کپی کنید.
4. `android/services.properties.example` را کپی کنید به `android/services.properties`:
   ```properties
   bazaar.rsa=کلید RSA از پنل بازار
   pushe.token=توکن SDK از کنسول پوشه (اگر اعلان می‌خواهید)
   ```
قیمتی که در برنامه دیده می‌شود از خود بازار خوانده می‌شود؛ اگر نشد، «۱۸۰٬۰۰۰ تومان» نشان داده می‌شود.

## ۴. هر بار: ساخت فایل release
در ترمینال Android Studio (پایین صفحه، تب **Terminal**) در پوشه‌ی پروژه:
```powershell
flutter build apk --release
```
خروجی: `build\app\outputs\flutter-apk\app-release.apk` ← همین را در پنل بازار بارگذاری کنید.
(برای بسته‌ی کوچک‌تر: `flutter build appbundle --release` ← `build\app\outputs\bundle\release\app-release.aab`)

پیش از هر انتشار، `version` را در `pubspec.yaml` بالا ببرید (مثلاً `2.0.1+3`؛ عدد بعد از `+` باید هر بار بیشتر شود).

**نصب release روی گوشی خودتان برای آزمایش:** `flutter run --release` (گوشی با کابل وصل).
خرید فقط وقتی کار می‌کند که کافه‌بازار روی گوشی نصب و وارد حساب شده باشد. برای خرید آزمایشی، شماره‌ی حساب
بازار خود را در پنل به‌عنوان «آزمایش‌کننده» ثبت کنید.

## اعلان‌ها (پوشه)
- **دریافت در برنامه:** فقط وقتی `pushe.token` در `services.properties` باشد، SDK پوشه در برنامه گذاشته می‌شود.
  والدین در «بخش والدین ← اعلان‌ها» اجازه‌ی اعلان را می‌دهند (اندروید ۱۳ به بعد).
- **ارسال:** استودیو (`tools/voice-studio`) ← تب **ارسال اعلان**: عنوان، متن، عکس (نشانی https) و پیوند.
  توکن **وب‌سرویس** پوشه را همان‌جا ذخیره کنید؛ با توکن SDK فرق دارد.

## چه چیزی آزموده شده و چه چیزی نه (صادقانه)
- کد Dart، قفل مرحله‌ها و برگه‌ی خرید با ۳۳ آزمون خودکار آزموده شده‌اند.
- **کد Kotlin پرداخت و اعلان، و ساخت Gradle، در محیط توسعه ساخته نشده‌اند** (دسترسی به سرورهای گوگل و
  JitPack بسته بود). اولین ساخت روی سیستم شماست؛ اگر خطا داد، متن کامل را بفرستید.
- ارسال اعلان استودیو با یک سرور ساختگی آزموده شده، نه با سرور واقعی پوشه. اولین ارسال را با یک گوشی
  آزمایشی امتحان کنید؛ پاسخ کامل سرور در استودیو نشان داده می‌شود.
