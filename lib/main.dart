import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/assets/asset_resolver.dart';
import 'core/assets/download_manager.dart';
import 'core/audio/just_audio_service.dart';
import 'core/billing/billing.dart';
import 'data/access_store.dart';
import 'data/content_repository.dart';
import 'data/legacy_migration.dart';
import 'data/notices_store.dart';
import 'data/progress_store.dart';
import 'data/settings_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  final prefs = await SharedPreferences.getInstance();
  final content = await ContentRepository.load(rootBundle);
  final assets = AssetResolver();
  await assets.init(rootBundle);
  final settings = SettingsStore(prefs);
  final progress = ProgressStore(prefs, content);
  await LegacyMigration.run(prefs, progress, settings);
  final access = AccessStore(prefs, const BazaarBilling());
  // خرید قبلی و قیمت را از بازار می‌گیرد؛ منتظرش نمی‌مانیم تا شروع برنامه کند نشود.
  access.sync();
  // خبرهای امضاشده: کار پس‌زمینه‌ی اندروید هماهنگ می‌شود و فایل خبرها خوانده می‌شود، هر دو بی‌انتظار.
  final notices = NoticesStore(prefs, seal: await NoticesStore.loadSeal(rootBundle));
  notices.schedule();
  notices.refresh();

  runApp(
    GoshyarApp(
      content: content,
      assets: assets,
      downloads: DownloadManager(assets),
      settings: settings,
      progress: progress,
      access: access,
      notices: notices,
      audio: JustAudioService(assets, settings),
    ),
  );
}
