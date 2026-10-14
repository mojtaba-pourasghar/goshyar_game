import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'progress_store.dart';
import 'settings_store.dart';

/// انتقال یک‌باره‌ی داده‌های نسخه‌ی Java به نسخه‌ی Flutter.
///
/// نسخه‌ی قدیمی مراحل کامل‌شده را به‌صورت StringSet ذخیره می‌کرد که افزونه‌ی
/// shared_preferences نمی‌تواند بخواند؛ برای همین MainActivity.kt یک کانال کوچک
/// برای خواندن فایل‌های «goshyar_progress» و «goshyar_audio» دارد.
class LegacyMigration {
  static const _channel = MethodChannel('ir.brandimo.goshyar/legacy');
  static const _doneKey = 'goshyar.legacy_migrated';

  static Future<void> run(SharedPreferences prefs, ProgressStore progress, SettingsStore settings) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    if (prefs.getBool(_doneKey) ?? false) return;
    try {
      final data = await _channel.invokeMapMethod<String, dynamic>('readLegacy');
      if (data != null && data.isNotEmpty) {
        await progress.importLegacy(
          childName: data['child_name'] as String?,
          points: data['total_points'] as int?,
          bestStreak: data['best_streak'] as int?,
          completedLevels: List<String>.from((data['completed_levels'] ?? const []) as List),
          badges: List<String>.from((data['unlocked_badges'] ?? const []) as List),
        );
        const map = {
          'voice_enabled': AudioChannel.voice,
          'sfx_enabled': AudioChannel.effects,
          'music_enabled': AudioChannel.music,
        };
        for (final e in map.entries) {
          final v = data[e.key];
          if (v is bool) await settings.setOn(e.value, v);
        }
      }
      await prefs.setBool(_doneKey, true);
    } on MissingPluginException {
      await prefs.setBool(_doneKey, true);
    } catch (e) {
      // دفعه‌ی بعد دوباره امتحان می‌شود؛ بازی نباید به خاطر این متوقف شود.
      debugPrint('انتقال داده‌ی نسخه‌ی قدیمی انجام نشد: $e');
    }
  }
}
