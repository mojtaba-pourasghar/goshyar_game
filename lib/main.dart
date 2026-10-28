import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/assets/asset_resolver.dart';
import 'core/assets/download_manager.dart';
import 'core/audio/game_audio.dart';
import 'core/audio/just_audio_service.dart';
import 'core/billing/billing.dart';
import 'data/access_store.dart';
import 'data/content_repository.dart';
import 'data/legacy_migration.dart';
import 'data/notices_store.dart';
import 'data/progress_store.dart';
import 'data/settings_store.dart';
import 'ui/screens/startup_error_screen.dart';

/// راه‌اندازی برنامه.
///
/// قاعده‌ی این فایل: **هیچ گامی اجازه ندارد برنامه را ببندد.** روی گوشی‌ای که یک افزونه،
/// یک دارایی یا یک کار پس‌زمینه ناخواسته خطا بدهد، کودک باید صفحه‌ای ببیند — نه پیغام
/// «برنامه مدام بسته می‌شود» سیستم. پس هر گام جداگانه گرفته می‌شود، و هر چه به اندروید
/// دست می‌زند (کافه‌بازار، WorkManager، AlarmManager) بعد از اولین فریم انجام می‌شود،
/// نه پیش از [runApp].
void main() => runZonedGuarded(_start, _report);

Future<void> _start() async {
  WidgetsFlutterBinding.ensureInitialized();
  _installErrorHandlers();

  await _quiet('چرخش صفحه', () => SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]));

  // تنها دو چیزی که بی آن‌ها بازی‌ای برای نشان دادن نیست.
  final SharedPreferences prefs;
  final ContentRepository content;
  try {
    prefs = await SharedPreferences.getInstance();
    content = await ContentRepository.load(rootBundle);
  } catch (error, stack) {
    _report(error, stack);
    runApp(StartupErrorApp(detail: '$error'));
    return;
  }

  final assets = AssetResolver();
  await _quiet('فهرست دارایی‌ها', () => assets.init(rootBundle));

  final settings = SettingsStore(prefs);
  final progress = ProgressStore(prefs, content);
  await _quiet('انتقال داده‌ی نسخه‌ی قدیمی', () => LegacyMigration.run(prefs, progress, settings));

  final access = AccessStore(prefs, const BazaarBilling());
  final notices = NoticesStore(prefs, seal: await _value('کلید خبرها', () => NoticesStore.loadSeal(rootBundle)));

  // اگر پخش صدا روی این گوشی بالا نیاید، بازی بی‌صدا ادامه می‌دهد؛ بسته نمی‌شود.
  final GameAudio audio = _sync('پخش صدا', () => JustAudioService(assets, settings)) ?? SilentAudio();

  runApp(
    GoshyarApp(
      content: content,
      assets: assets,
      downloads: DownloadManager(assets),
      settings: settings,
      progress: progress,
      access: access,
      notices: notices,
      audio: audio,
    ),
  );

  // کافه‌بازار و کارهای پس‌زمینه‌ی خبرها: بعد از اینکه صفحه‌ی اول روی گوشی آمد. اگر این‌ها
  // روی گوشی‌ای خطا بدهند، بازی از قبل باز است و کودک چیزی نمی‌بیند جز نبود خبر و خرید.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _quiet('هماهنگی با کافه‌بازار', access.sync);
    _quiet('زمان‌بندی خبرها', notices.schedule);
    _quiet('خواندن خبرها', notices.refresh);
  });
}

/// خطای ویجت‌ها و خطای گرفته‌نشده‌ی هر isolate: در release فقط در لاگ می‌نشیند. صفحه‌ی قرمز
/// و بسته شدن برنامه هیچ‌کدام به کودک کمکی نمی‌کنند.
void _installErrorHandlers() {
  final inherited = FlutterError.onError;
  FlutterError.onError = (details) {
    if (kDebugMode) {
      inherited?.call(details);
    } else {
      _report(details.exception, details.stack ?? StackTrace.current);
    }
  };
  ui.PlatformDispatcher.instance.onError = (error, stack) {
    _report(error, stack);
    return true;
  };
}

void _report(Object error, StackTrace stack) => debugPrint('گوش‌یار — خطای گرفته‌نشده: $error\n$stack');

/// یک گام راه‌اندازی که شکستنش برنامه را نمی‌شکند.
Future<void> _quiet(String what, Future<void> Function() step) async {
  try {
    await step();
  } catch (error, stack) {
    debugPrint('گوش‌یار — «$what» انجام نشد: $error');
    _report(error, stack);
  }
}

Future<T?> _value<T>(String what, Future<T?> Function() step) async {
  try {
    return await step();
  } catch (error, stack) {
    debugPrint('گوش‌یار — «$what» انجام نشد: $error');
    _report(error, stack);
    return null;
  }
}

T? _sync<T>(String what, T Function() step) {
  try {
    return step();
  } catch (error, stack) {
    debugPrint('گوش‌یار — «$what» انجام نشد: $error');
    _report(error, stack);
    return null;
  }
}
