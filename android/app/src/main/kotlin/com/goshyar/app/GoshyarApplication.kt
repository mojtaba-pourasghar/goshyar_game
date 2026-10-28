package com.goshyar.app

import android.app.Application
import android.content.pm.ApplicationInfo
import android.util.Log
import androidx.work.Configuration

/**
 * کلاس Application برنامه — فقط برای یک کار: راه‌اندازی WorkManager به‌دست خودمان.
 *
 * WorkManager پیش‌فرض خودش را با یک ContentProvider (androidx.startup.InitializationProvider)
 * انجام می‌دهد که **پیش از هر خط کد ما** و پیش از اولین Activity اجرا می‌شود. هر خطایی در آن
 * لحظه، پیش از آنکه جایی برای گرفتنش باشد، پروسه را می‌کشد و اندروید همان «برنامه مدام بسته
 * می‌شود» را نشان می‌دهد — بی هیچ صفحه‌ای، بلافاصله پس از لمس آیکون. چیزی هم که بعدش در
 * try/catch باشد (NoticeWork.schedule) دیگر به اجرا نمی‌رسد.
 *
 * پس آن provider در Manifest برداشته شده و WorkManager با همین [Configuration.Provider]
 * «در لحظه‌ی نیاز» بالا می‌آید: اولین `WorkManager.getInstance(context)` آن را می‌سازد، و آن
 * فراخوانی‌ها همه داخل try/catch هستند (NoticeWork.kt). نتیجه: صف خبرها همان کار قبلی را
 * می‌کند، ولی شکستنش دیگر برنامه‌ی کودک را نمی‌بندد.
 */
class GoshyarApplication : Application(), Configuration.Provider {

    /** BuildConfig در AGP 8 به بعد پیش‌فرض ساخته نمی‌شود؛ پرچم خود بسته همان را می‌گوید. */
    private val debuggable: Boolean
        get() = applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE != 0

    override val workManagerConfiguration: Configuration
        get() = Configuration.Builder()
            .setMinimumLoggingLevel(if (debuggable) Log.DEBUG else Log.ERROR)
            .build()
}
