package com.goshyar.app

import android.Manifest
import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * کد بومی برنامه، سه کانال:
 * - com.goshyar.app/billing: پرداخت کافه‌بازار (BazaarBilling.kt)
 * - com.goshyar.app/native: باز کردن صفحه‌ی یک برنامه در بازار، اجازه‌ی اعلان (اندروید ۱۳+)
 * - com.goshyar.app/legacy: خواندن پیشرفت نسخه‌ی قدیمی Java (putStringSet که shared_preferences نمی‌خواند)
 * اعلان‌ها را SDK پوشه خودش دریافت و نمایش می‌دهد (Manifest: pushe_token).
 */
class MainActivity : FlutterActivity() {
    private var billing: BazaarBilling? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        billing = BazaarBilling(this).also { MethodChannel(messenger, "com.goshyar.app/billing").setMethodCallHandler(it) }
        MethodChannel(messenger, "com.goshyar.app/native").setMethodCallHandler { call, result ->
            when (call.method) {
                "openStorePage" -> result.success(openStorePage(call.argument<String>("packageName")!!))
                "notificationsAllowed" -> result.success(notificationsAllowed())
                "requestNotifications" -> { requestNotifications(); result.success(null) }
                else -> result.notImplemented()
            }
        }
        MethodChannel(messenger, "com.goshyar.app/legacy")
            .setMethodCallHandler { call, result ->
                if (call.method == "readLegacy") {
                    result.success(readLegacy())
                } else {
                    result.notImplemented()
                }
            }
    }

    override fun onDestroy() {
        billing?.disconnect()
        super.onDestroy()
    }

    /** صفحه‌ی برنامه در کافه‌بازار؛ اگر بازار نصب نبود، همان صفحه در مرورگر. */
    private fun openStorePage(packageName: String): Boolean {
        val bazaar = Intent(Intent.ACTION_VIEW, Uri.parse("bazaar://details?id=$packageName"))
            .setPackage("com.farsitel.bazaar")
        val web = Intent(Intent.ACTION_VIEW, Uri.parse("https://cafebazaar.ir/app/$packageName"))
        for (intent in listOf(bazaar, web)) {
            try {
                startActivity(intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
                return true
            } catch (_: ActivityNotFoundException) {
            }
        }
        return false
    }

    private fun notificationsAllowed(): Boolean =
        Build.VERSION.SDK_INT < 33 ||
            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED

    /** اندروید ۱۳ به بعد برای نمایش اعلان اجازه می‌خواهد؛ پایین‌تر از آن چیزی لازم نیست. */
    private fun requestNotifications() {
        if (Build.VERSION.SDK_INT >= 33 && !notificationsAllowed()) {
            requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), 7)
        }
    }

    private fun readLegacy(): Map<String, Any> {
        val out = HashMap<String, Any>()
        val progress = getSharedPreferences("goshyar_progress", Context.MODE_PRIVATE)
        if (progress.contains("child_name")) out["child_name"] = progress.getString("child_name", "") ?: ""
        if (progress.contains("total_points")) out["total_points"] = progress.getInt("total_points", 0)
        if (progress.contains("best_streak")) out["best_streak"] = progress.getInt("best_streak", 0)
        progress.getStringSet("completed_levels", null)?.let { out["completed_levels"] = ArrayList(it) }
        progress.getStringSet("unlocked_badges", null)?.let { out["unlocked_badges"] = ArrayList(it) }

        val audio = getSharedPreferences("goshyar_audio", Context.MODE_PRIVATE)
        for (key in listOf("music_enabled", "sfx_enabled", "voice_enabled")) {
            if (audio.contains(key)) out[key] = audio.getBoolean(key, true)
        }
        return out
    }
}
