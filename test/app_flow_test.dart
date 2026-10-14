import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goshyar/app.dart';
import 'package:goshyar/core/assets/asset_resolver.dart';
import 'package:goshyar/core/assets/download_manager.dart';
import 'package:goshyar/core/audio/game_audio.dart';
import 'package:goshyar/data/content_repository.dart';
import 'package:goshyar/data/progress_store.dart';
import 'package:goshyar/data/settings_store.dart';
import 'package:goshyar/ui/routes.dart';
import 'package:goshyar/ui/screens/game_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

class Harness {
  Harness(this.audio, this.progress, this.settings, this.content);

  final SilentAudio audio;
  final ProgressStore progress;
  final SettingsStore settings;
  final ContentRepository content;

  /// عنوان صدایی که آخرین بار در بازی پخش شد (پاسخ درست «این صدا مال کیه؟»).
  String lastSoundTitle() {
    final entry = audio.log.lastWhere((e) => e.startsWith('sound:'));
    final path = entry.substring('sound:'.length);
    return content.sounds.values.firstWhere((s) => s.audio == path).title;
  }
}

Future<Harness> pumpApp(WidgetTester tester, {Size size = const Size(412, 915), bool introSeen = false}) async {
  tester.view.physicalSize = size * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);

  SharedPreferences.setMockInitialValues(
    introSeen ? {'goshyar.progress.v2': '{"introSeen":true}'} : <String, Object>{},
  );
  final prefs = await SharedPreferences.getInstance();
  final content = loadContent();
  final assets = AssetResolver();
  await tester.runAsync(() => assets.init(rootBundle));
  final settings = SettingsStore(prefs);
  final progress = ProgressStore(prefs, content);
  final audio = SilentAudio();
  await tester.pumpWidget(
    GoshyarApp(
      content: content,
      assets: assets,
      downloads: DownloadManager(assets),
      settings: settings,
      progress: progress,
      audio: audio,
    ),
  );
  await tester.pump(const Duration(milliseconds: 500));
  return Harness(audio, progress, settings, content);
}

/// زمان بازی را جلو می‌برد؛ pumpAndSettle به خاطر حرکت دائمی ماسکوت قابل استفاده نیست.
Future<void> wait(WidgetTester tester, [int ms = 3000]) async {
  for (var i = 0; i < ms ~/ 100; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> tapText(WidgetTester tester, String text) async {
  final f = find.text(text);
  await tester.ensureVisible(f.first);
  await tester.pump();
  await tester.tap(f.first);
  await wait(tester, 600);
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets('شروع ← معرفی ← خانه ← دسته‌ی حیوانات ← یک دور کامل بازی ← نتیجه', (tester) async {
    final h = await pumpApp(tester);
    expect(find.text('بازی کن، گوش بده، کشف کن!'), findsOneWidget);
    expect(h.audio.log, contains('say:app.splash.welcome'));

    await tester.tap(find.bySemanticsLabel('شروع'));
    await wait(tester, 1000);
    expect(find.text('سلام دوست عزیز!'), findsOneWidget);
    await tapText(tester, 'بعدی');
    await tapText(tester, 'بعدی');
    await tapText(tester, 'بزن بریم!');
    expect(h.progress.introSeen, isTrue);

    expect(find.text('سلام دوست من!'), findsOneWidget);
    for (final c in h.content.categories) {
      expect(find.text(c.title), findsWidgets);
    }

    await tapText(tester, 'حیوانات');
    expect(find.text('بازی حیوانات'), findsOneWidget);
    await tapText(tester, 'شروع بازی');

    // پرسش اول: یک پاسخ اشتباه، بعد پاسخ درست.
    await wait(tester);
    var answer = h.lastSoundTitle();
    final wrong = h.content
        .soundsIn('animals')
        .map((s) => s.title)
        .firstWhere((t) => t != answer && find.text(t).evaluate().isNotEmpty);
    await tapText(tester, wrong);
    expect(find.text('اشکالی ندارد، دوباره امتحان کن!'), findsOneWidget);
    expect(h.audio.log, contains('ui:fail'));
    await wait(tester, 1500);

    await tapText(tester, answer);
    expect(find.text('آفرین! درست بود!'), findsOneWidget);
    expect(h.audio.log.last, startsWith('say:snd.'));

    for (var round = 2; round <= 5; round++) {
      await tapText(tester, 'صدای بعدی');
      await wait(tester);
      answer = h.lastSoundTitle();
      await tapText(tester, answer);
      expect(find.text('آفرین! درست بود!'), findsOneWidget, reason: 'پرسش $round');
    }
    await tapText(tester, 'دیدن ستاره‌ها');
    await wait(tester, 1500);

    expect(find.text('آفرین!'), findsOneWidget);
    expect(find.bySemanticsLabel('۲ ستاره از ۳'), findsOneWidget, reason: 'یک اشتباه در پنج پرسش = دو ستاره');
    expect(h.progress.categorySessions('animals'), 1);
    expect(h.progress.points, 20 + 4 * 25);
    expect(h.progress.badges, isEmpty, reason: 'بازی دسته‌ها مرحله‌ی بازی‌های اصلی را کامل نمی‌کند');

    await tapText(tester, 'خانه');
    expect(find.text('سلام دوست من!'), findsOneWidget);
    await wait(tester, 13000);
  });

  testWidgets('بازی‌ها ← نقشه‌ی مراحل ← مرحله‌ی ۱ ← نتیجه ← مرحله‌ی بعد', (tester) async {
    final h = await pumpApp(tester, introSeen: true);
    await tester.tap(find.bySemanticsLabel('شروع'));
    await wait(tester, 1000);
    await tapText(tester, 'بازی‌ها');
    final mode = h.content.mode('who_made_sound');
    await tapText(tester, '۱. ${mode.title}');
    expect(find.bySemanticsLabel('مرحله ۲، قفل'), findsOneWidget);

    await tapText(tester, 'شروع بازی');
    await wait(tester);
    expect(find.text('مرحله ۱'), findsOneWidget);
    await tapText(tester, h.lastSoundTitle());
    expect(h.audio.log, contains('say:who.01.ok'));
    await tapText(tester, 'دیدن ستاره‌ها');
    await wait(tester, 1500);
    expect(find.bySemanticsLabel('۳ ستاره از ۳'), findsOneWidget);
    expect(h.progress.starsFor('who_made_sound', 1), 3);
    expect(h.progress.badges, contains('first_step'));
    expect(find.text('مدال تازه: اولین قدم'), findsOneWidget);

    await tapText(tester, 'مرحله بعد');
    await wait(tester);
    expect(find.text('مرحله ۲'), findsOneWidget);

    // توقف ← خروج
    await tester.tap(find.bySemanticsLabel('توقف'));
    await wait(tester, 800);
    expect(find.text('بازی متوقف شد'), findsOneWidget);
    await tapText(tester, 'خروج از بازی');
    await wait(tester, 800);
    expect(find.bySemanticsLabel('مرحله ۱، ۳ ستاره'), findsOneWidget);
    await wait(tester, 13000);
  });

  testWidgets('ترتیب صداها و مأموریت شنیداری', (tester) async {
    final h = await pumpApp(tester, introSeen: true);
    await tester.tap(find.bySemanticsLabel('شروع'));
    await wait(tester, 1000);
    await tapText(tester, 'بازی‌ها');

    final seq = h.content.mode('sequence');
    await tapText(tester, '۳. ${seq.title}');
    await tapText(tester, 'شروع بازی');
    await wait(tester);
    expect(h.audio.log, contains('sequence:3'));
    for (final id in seq.levels.first.sequence) {
      await tapText(tester, h.content.sounds[id]!.title);
    }
    await wait(tester, 1000);
    expect(find.text('آفرین! درست بود!'), findsOneWidget);
    await tapText(tester, 'دیدن ستاره‌ها');
    await wait(tester, 1000);
    expect(find.text('مرحله بعد'), findsOneWidget);
    await tapText(tester, 'خانه');
    await tester.tap(find.bySemanticsLabel('بازی‌ها').first);
    await wait(tester, 800);

    final mission = h.content.mode('audio_mission');
    await tapText(tester, '۴. ${mission.title}');
    await tapText(tester, 'شروع بازی');
    await wait(tester);
    expect(h.audio.log, contains('layered:3'));
    await tester.tap(find.bySemanticsLabel('۲'));
    await wait(tester, 800);
    expect(find.text('اشکالی ندارد، دوباره امتحان کن!'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('۳'));
    await wait(tester, 800);
    expect(find.text('آفرین! درست بود!'), findsOneWidget);
    await wait(tester, 13000);
  });

  testWidgets('تنظیمات صدا ذخیره می‌شود و دروازه‌ی والدین با پاسخ درست باز می‌شود', (tester) async {
    final h = await pumpApp(tester, introSeen: true);
    await tester.tap(find.bySemanticsLabel('تنظیمات'));
    await wait(tester, 800);
    expect(find.text('صدای گوش‌یار'), findsOneWidget);
    await tester.tap(find.byType(Switch).first);
    await wait(tester, 300);
    expect(h.settings.isOn(AudioChannel.voice), isFalse);

    await tapText(tester, 'بخش والدین');
    final q = find.textContaining('×');
    final parts = (tester.widget<Text>(q).data!).replaceAll(RegExp(r'[^۰-۹×]'), '').split('×');
    int fa(String s) => int.parse(s.split('').map((c) => '۰۱۲۳۴۵۶۷۸۹'.indexOf(c)).join());
    final product = (fa(parts[0]) * fa(parts[1])).toString();
    for (final d in product.split('')) {
      await tester.tap(find.bySemanticsLabel('۰۱۲۳۴۵۶۷۸۹'[int.parse(d)]));
      await tester.pump(const Duration(milliseconds: 200));
    }
    await wait(tester, 800);
    expect(find.text('گزارش والدین'), findsOneWidget);
    await wait(tester, 3000);
  });

  for (final size in const [Size(320, 568), Size(360, 640), Size(800, 1280)]) {
    testWidgets('چیدمان بدون سرریز در اندازه‌ی ${size.width.toInt()}×${size.height.toInt()}', (tester) async {
      final h = await pumpApp(tester, size: size, introSeen: true);
      await tester.tap(find.bySemanticsLabel('شروع'));
      await wait(tester, 1000);
      for (final tab in ['بازی‌ها', 'صداها', 'من', 'خانه']) {
        await tester.tap(find.bySemanticsLabel(tab).first);
        await wait(tester, 500);
      }
      await tapText(tester, 'موسیقی');
      await tapText(tester, 'شروع بازی');
      await wait(tester);
      await tapText(tester, h.lastSoundTitle());
      await wait(tester, 1000);
      for (var i = 0; i < 4; i++) {
        await tapText(tester, 'صدای بعدی');
        await wait(tester);
        await tapText(tester, h.lastSoundTitle());
      }
      await tapText(tester, 'دیدن ستاره‌ها');
      await wait(tester, 13000);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('همه‌ی صفحه‌ها در گوشی کوچک ۳۲۰×۵۶۸ بدون سرریز', (tester) async {
    final h = await pumpApp(tester, size: const Size(320, 568), introSeen: true);
    final nav = tester.state<NavigatorState>(find.byType(Navigator));
    Future<void> visit(String route, [Object? args]) async {
      nav.pushNamed(route, arguments: args);
      await wait(tester, 2500);
      final err = tester.takeException();
      if (err is FlutterError) debugPrint(err.toStringDeep());
      expect(err, isNull, reason: '$route $args');
      nav.pop();
      await wait(tester, 600);
    }

    for (final m in h.content.modes) {
      await visit(Routes.levels, m.id);
      await visit(Routes.game, GameArgs.level(m.id, m.levels.length - 1));
    }
    for (final c in h.content.categories) {
      await visit(Routes.category, c.id);
      await visit(Routes.library, c.id);
    }
    await visit(Routes.settings);
    await visit(Routes.downloads);
    await visit(Routes.parentGate);
    await visit(Routes.parent);
    await wait(tester, 13000);
  });
}
