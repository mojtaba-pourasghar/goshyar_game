import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/assets/asset_resolver.dart';
import 'core/assets/download_manager.dart';
import 'core/audio/game_audio.dart';
import 'core/design/theme.dart';
import 'core/narrator.dart';
import 'core/billing/billing.dart';
import 'data/access_store.dart';
import 'data/content_repository.dart';
import 'data/notices_store.dart';
import 'data/progress_store.dart';
import 'data/settings_store.dart';
import 'ui/notice_host.dart';
import 'ui/routes.dart';

class GoshyarApp extends StatelessWidget {
  const GoshyarApp({
    super.key,
    required this.content,
    required this.assets,
    required this.downloads,
    required this.settings,
    required this.progress,
    required this.audio,
    this.access,
    this.notices,
    this.initialRoute = Routes.splash,
  });

  final ContentRepository content;
  final AssetResolver assets;
  final DownloadManager downloads;
  final SettingsStore settings;
  final ProgressStore progress;
  final GameAudio audio;

  /// پیش‌فرض (آزمون‌ها): بدون پرداخت و با قاعده‌ی همان نسخه‌ای که اجرا می‌شود.
  final AccessStore? access;

  /// پیش‌فرض (آزمون‌ها): بی‌کلید، پس هیچ خبری خوانده و نشان داده نمی‌شود.
  final NoticesStore? notices;
  final String initialRoute;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider.value(value: content),
        Provider.value(value: audio),
        Provider(create: (_) => Narrator(content, audio)),
        ChangeNotifierProvider.value(value: assets),
        ChangeNotifierProvider.value(value: downloads),
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider.value(value: progress),
        if (access != null)
          ChangeNotifierProvider.value(value: access!)
        else
          ChangeNotifierProvider(create: (_) => AccessStore(settings.prefs, const NoBilling())),
        if (notices != null)
          ChangeNotifierProvider.value(value: notices!)
        else
          ChangeNotifierProvider(create: (_) => NoticesStore(settings.prefs)),
      ],
      // خبرها وقتی برنامه باز است: نگاه هر دو دقیقه و کارت خبر روی صفحه (همان MainActivity هوهو ریاضی).
      child: NoticeHost(
        builder: (navigatorKey, noticeRoutes) => MaterialApp(
          title: 'گوش‌یار',
          debugShowCheckedModeBanner: false,
          navigatorKey: navigatorKey,
          theme: buildGoshyarTheme(),
          locale: const Locale('fa', 'IR'),
          supportedLocales: const [Locale('fa', 'IR')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          initialRoute: initialRoute,
          onGenerateRoute: Routes.generate,
          navigatorObservers: [AudioRouteObserver(audio), noticeRoutes],
          // متن‌ها با بزرگ‌نمایی سیستم بزرگ می‌شوند ولی نه آن‌قدر که چیدمان بشکند.
          builder: (context, child) {
            final mq = MediaQuery.of(context);
            return MediaQuery(
              data: mq.copyWith(textScaler: mq.textScaler.clamp(maxScaleFactor: 1.3)),
              child: child!,
            );
          },
        ),
      ),
    );
  }
}

/// با هر جابه‌جایی صفحه، گوینده و صداهای بازی صفحه‌ی قبل قطع می‌شوند
/// تا صدای یک صفحه روی صفحه‌ی دیگر نماند.
class AudioRouteObserver extends NavigatorObserver {
  AudioRouteObserver(this.audio);

  final GameAudio audio;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PageRoute) audio.stopAll();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PageRoute) audio.stopAll();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) => audio.stopAll();
}
