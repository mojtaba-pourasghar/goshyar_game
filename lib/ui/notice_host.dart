import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/design/theme.dart';
import '../core/platform/native_bridge.dart';
import '../data/notices_store.dart';
import 'routes.dart';
import 'widgets/notice_card.dart';
import 'widgets/paywall.dart' show verifyParent;

/// خبرها وقتی برنامه باز است — همان کاری که MainActivity در هوهو ریاضی می‌کند.
///
/// هیچ سرویس پوشی نیست، پس برنامه خودش نگاه می‌کند: یک بار همین که باز شد و بعد هر [every]. وقتی
/// برنامه بسته است، NoticeWork.kt و NoticeAlarm.kt همین کار را حدود هر ربع ساعت می‌کنند.
///
/// هر چه برسد، یکی به نوار اعلان می‌رود و یکی به شکل کارت روی صفحه می‌آید، و بعدی نه زودتر از
/// [NoticesStore.gap]. خبر معمولی منتظر صفحه‌ی خانه می‌ماند — وسط بازی مزاحم کودک نمی‌شود. خبری که
/// «هر جای برنامه» (ANYWHERE) علامت خورده هر جا باشد می‌آید، جز چند صفحه که پشتشان چیزی نیست یا کسی
/// در حال حل کردن دروازه‌ی والدین است.
class NoticeHost extends StatefulWidget {
  const NoticeHost({super.key, required this.builder});

  /// MaterialApp را با کلید ناوبر و ناظر مسیرهای همین‌جا می‌سازد.
  final Widget Function(GlobalKey<NavigatorState> navigatorKey, NavigatorObserver observer) builder;

  /// به اندازه‌ای زیاد که خبر تازه تقریباً همان لحظه برسد، به اندازه‌ای کم که بی‌هزینه باشد (فایل
  /// خبرها یک کیلوبایت است). خبری که «از ساعت فلان» گذاشته شده منتظر این نمی‌ماند: [_planNext].
  static const every = Duration(minutes: 1);

  /// خبرهایی که این‌جا می‌روند (مقدار `screen` در استودیو).
  static const screens = {'HOME', 'GAMES', 'LIBRARY', 'PROFILE', 'DOWNLOADS', 'PAYWALL'};

  @override
  State<NoticeHost> createState() => _NoticeHostState();
}

class _NoticeHostState extends State<NoticeHost> with WidgetsBindingObserver {
  final _navigatorKey = GlobalKey<NavigatorState>();
  late final _routes = _RouteWatcher(_onRoute);

  /// جایی که هیچ خبری رویش نمی‌آید: پشت آغازگر چیزی نیست، معرفی اولین دیدار است، دروازه یعنی والدی
  /// در حال پاسخ دادن.
  static const _never = {Routes.splash, Routes.intro, Routes.parentGate};

  Timer? _beat;
  Timer? _soon;
  Timer? _next;
  bool _showing = false;
  bool _askedPermission = false;
  String? _requested;
  String _version = '';
  NoticesStore? _store;

  NoticesStore get store => _store!;
  NativeBridge get bridge => store.bridge;

  @override
  void initState() {
    super.initState();
    _store = context.read<NoticesStore>();
    if (!store.ready) return;
    WidgetsBinding.instance.addObserver(this);
    NativeBridge.listen(onNoticeTapped: _tapped, onPermission: (_) => _soonCheck());
    bridge.appVersion().then((v) => _version = v);
    bridge.takeLaunchNotice().then((tap) {
      if (tap != null) _tapped(tap);
    });
    _start();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _beat?.cancel();
    _soon?.cancel();
    _next?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _start();
    } else if (state == AppLifecycleState.paused) {
      // بسته شدن را NoticeWork.once در MainActivity.onPause پوشش می‌دهد (و آلارم ساعت شروع خبر بعدی
      // را همان‌جا می‌گذارد)؛ این‌جا فقط ساعت‌ها می‌ایستند.
      _beat?.cancel();
      _beat = null;
      _next?.cancel();
      _next = null;
    }
  }

  /// نگاه همین حالا، و بعد هر [NoticeHost.every] تا وقتی برنامه جلوی چشم است.
  void _start() {
    _beat?.cancel();
    _beat = Timer.periodic(NoticeHost.every, (_) => _look());
    // آنچه NoticeCenter.kt وقتی برنامه پشت صحنه بود گرفته، در حافظه‌ی Dart هنوز نیست.
    _look(reload: true);
  }

  Future<void> _look({bool reload = false}) async {
    if (!store.enabled) return;
    if (reload) await store.reloadFromDisk();
    // «چیزی عوض شد؟» این‌جا مهم نیست: main() همان اول یک بار نگاه کرده و تغییر را همان‌جا برداشته،
    // و تکیه بر آن یعنی کارت و اجازه‌ی اعلان هیچ‌وقت نمی‌آمدند تا برنامه دوباره باز شود.
    await store.refresh();
    if (!mounted) return;
    // هر نوبت: نوبت خبر بعدی شاید همین حالا رسیده باشد — هم برای نوار اعلان، هم برای کارت.
    unawaited(bridge.postNotices());
    _showIfDue();
    // اگر کارتی همین حالا آمد، اجازه بعد از بسته شدنش پرسیده می‌شود (_put)، نه روی آن.
    if (!_showing) unawaited(_askIfUseful());
    _planNext();
  }

  /// خبری که «از ساعت فلان» گذاشته شده سر همان دقیقه می‌آید، نه در نگاه بعدی به سرور.
  void _planNext() {
    _next?.cancel();
    _next = null;
    final wait = store.nextStartIn();
    if (wait == null) return;
    _next = Timer(wait + const Duration(milliseconds: 500), () {
      if (!mounted) return;
      unawaited(bridge.postNotices());
      _showIfDue();
      _planNext();
    });
  }

  /// اجازه‌ی اعلان فقط وقتی پرسیده می‌شود که چیزی برای گفتن باشد — اولین اجرای کودک یک بازی است، نه
  /// پنجره‌ی اجازه. بی این اجازه (اندروید ۱۳ به بعد) هیچ خبری به نوار اعلان نمی‌رسد، پس هر اجرا یک بار
  /// پرسیده می‌شود؛ اندروید خودش بعد از دو «نه» دیگر پنجره نشان نمی‌دهد. صفحه‌ی تنظیمات این‌جا خودبه‌خود
  /// باز نمی‌شود — آن فقط از بخش والدین است.
  Future<void> _askIfUseful() async {
    if (_askedPermission || store.current.isEmpty) return;
    _askedPermission = true;
    if (await bridge.notificationsAllowed()) {
      unawaited(bridge.askBackgroundOnce());
      return;
    }
    await bridge.requestNotifications(openSettings: false);
  }

  void _onRoute() => _soonCheck(const Duration(milliseconds: 450));

  void _soonCheck([Duration after = const Duration(milliseconds: 300)]) {
    _soon?.cancel();
    _soon = Timer(after, () {
      if (mounted) _showIfDue();
    });
  }

  /// لمس یک اعلان در نوار: کودک همین خبر را خواسته، پس از همه‌ی نوبت‌ها جلو می‌افتد. اگر خبر جایی را
  /// نشان می‌دهد همان‌جا می‌رود، وگرنه خود خبر با عکس و دکمه‌هایش می‌آید — هر دو وقتی صفحه‌ای پشتش باشد.
  Future<void> _tapped(NoticeTap tap) async {
    // آنچه NoticeCenter.kt در پس‌زمینه گرفته، در حافظه‌ی Dart هنوز نیست.
    await store.reloadFromDisk();
    if (store.find(tap.id) == null) await store.refresh();
    _requested = tap.id;
    _requestedScreen = tap.screen;
    _soonCheck();
  }

  String _requestedScreen = '';

  /// اگر نوبت خبری رسیده و صفحه‌ی مناسبی جلوی چشم است، نشانش بده (MainActivity.showNoticeIfDue).
  Future<void> _showIfDue() async {
    if (!mounted || _showing || !store.ready || !store.enabled) return;
    final nav = _navigatorKey.currentState;
    final route = _routes.current;
    if (nav == null || route == null || _never.contains(route) || _routes.popups > 0) return;

    final asked = _requested;
    if (asked != null) {
      final screen = _requestedScreen;
      _requested = null;
      _requestedScreen = '';
      final n = store.find(asked);
      if (n != null) await store.markSeen(n.id);
      if (screen.isNotEmpty && await openNoticeScreen(nav, screen)) return;
      if (n != null) return _put(nav, n);
    }

    final onHome = route == Routes.home;
    if (onHome && store.updateDue(_version)) return _putUpdate(nav, store.updateWaiting(_version)!);

    final due = store.dueNow(onHome: onHome);
    if (due != null) await _put(nav, due);
  }

  /// یک خبر به شکل کارت. هر طور بسته شود «دیده شد» و فاصله تا بعدی از همین حالا شمرده می‌شود.
  Future<void> _put(NavigatorState nav, Notice n) async {
    _showing = true;
    await store.shown();
    try {
      if (!nav.mounted) return;
      final action = await showNoticeCard(nav.context, store, n);
      await store.markSeen(n.id);
      await store.shown();
      if (action == NoticeAction.go && nav.mounted) await followNotice(nav, store, n);
    } finally {
      _showing = false;
    }
    // حالا که کودک خبر را دید، وقت پرسیدن اجازه برای خبرهای بعدی در نوار اعلان است.
    unawaited(_askIfUseful());
    // نفر بعدی صف، وقتی فاصله‌اش تمام شد — بی‌آنکه منتظر نگاه بعدی بماند.
    _soonCheck(NoticesStore.gap + const Duration(milliseconds: 500));
    _planNext();
  }

  /// «نسخه‌ی تازه آمده»، حداکثر روزی یک بار؛ دانلود فقط پشت دروازه‌ی والدین.
  Future<void> _putUpdate(NavigatorState nav, AppUpdate u) async {
    _showing = true;
    await store.askedAboutUpdate();
    try {
      if (!nav.mounted) return;
      final get = await showDialog<bool>(
        context: nav.context,
        builder: (context) => AlertDialog(
          title: Text('نسخه‌ی تازه‌ی گوش‌یار', style: GText.heading),
          content: Text(u.note.isEmpty ? 'نسخه‌ی ${u.version} آمده است.' : u.note, style: GText.body),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('بعداً')),
            TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('دریافت')),
          ],
        ),
      );
      if (get == true && nav.mounted && await verifyParent(nav.context)) await bridge.openUrl(u.url);
    } finally {
      _showing = false;
    }
  }

  @override
  Widget build(BuildContext context) => widget.builder(_navigatorKey, _routes);
}

/// کدام صفحه جلوی چشم است، و آیا پنجره‌ای (برگه‌ی خرید، دیالوگ) رویش باز است.
class _RouteWatcher extends NavigatorObserver {
  _RouteWatcher(this.onChange);

  final VoidCallback onChange;
  String? current;
  int popups = 0;

  void _enter(Route<dynamic>? route) {
    if (route == null) return;
    if (route is PageRoute) {
      current = route.settings.name;
    } else {
      popups++;
    }
  }

  void _leave(Route<dynamic> route, Route<dynamic>? under) {
    if (route is PageRoute) {
      if (under is PageRoute) current = under.settings.name;
    } else if (popups > 0) {
      popups--;
    }
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _enter(route);
    onChange();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _leave(route, previousRoute);
    onChange();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is! PageRoute && popups > 0) popups--;
    onChange();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (oldRoute != null && oldRoute is! PageRoute && popups > 0) popups--;
    _enter(newRoute);
    onChange();
  }
}
