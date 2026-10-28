# قاعده‌های نگه‌داری برای وقتی R8 روشن شود (در build.gradle.kts پیش‌فرض خاموش است).
# این‌ها جلو همان خطاهایی را می‌گیرند که فقط در نسخه‌ی release و فقط روی گوشی پیدا می‌شوند.

# کافه‌بازار (Poolakey): سرویس خرید با AIDL و بازتاب صدا زده می‌شود.
-keep class ir.cafebazaar.** { *; }
-keep interface ir.cafebazaar.** { *; }
-keep class com.android.vending.billing.** { *; }
-dontwarn ir.cafebazaar.**

# WorkManager کلاس Worker را با نامش از رشته می‌سازد.
-keep class * extends androidx.work.Worker { *; }
-keep class * extends androidx.work.ListenableWorker { *; }
-keep class androidx.work.impl.** { *; }

# کلاس‌های خود برنامه که اندروید از Manifest با نام می‌سازد.
-keep class com.goshyar.app.GoshyarApplication { *; }
-keep class com.goshyar.app.MainActivity { *; }
-keep class com.goshyar.app.PurchaseActivity { *; }
-keep class com.goshyar.app.NoticeAlarm { *; }
-keep class com.goshyar.app.BootReceiver { *; }
-keep class com.goshyar.app.NoticeWork { *; }

# just_audio روی ExoPlayer/Media3 سوار است.
-dontwarn com.google.android.exoplayer2.**
-dontwarn androidx.media3.**
