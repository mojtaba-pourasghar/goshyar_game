package ir.brandimo.goshyar

import android.content.Context
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * تنها کد بومی برنامه: خواندن تنظیمات و پیشرفت ذخیره‌شده‌ی نسخه‌ی قدیمی (Java)
 * تا کودک بعد از به‌روزرسانی امتیاز و مراحلش را از دست ندهد.
 * نسخه‌ی قدیمی مراحل را با putStringSet نوشته بود که افزونه‌ی shared_preferences
 * نمی‌تواند بخواند؛ بقیه‌ی برنامه کاملاً Flutter است.
 */
class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "ir.brandimo.goshyar/legacy")
            .setMethodCallHandler { call, result ->
                if (call.method == "readLegacy") {
                    result.success(readLegacy())
                } else {
                    result.notImplemented()
                }
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
