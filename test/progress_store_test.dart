import 'package:flutter_test/flutter_test.dart';
import 'package:goshyar/data/progress_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

void main() {
  final content = loadContent();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('ثبت مرحله: امتیاز، ستاره‌ی بهتر، باز شدن مرحله‌ی بعد و مدال اولین قدم', () async {
    final prefs = await SharedPreferences.getInstance();
    final p = ProgressStore(prefs, content);
    final mode = content.mode('who_made_sound');
    expect(p.isLevelUnlocked(mode, 0), isTrue);
    expect(p.isLevelUnlocked(mode, 1), isFalse);

    final fresh = await p.recordLevel(mode, mode.levels[0], stars: 2, points: 20);
    expect(fresh.map((a) => a.id), contains('first_step'));
    expect(p.points, 20);
    expect(p.starsFor(mode.id, 1), 2);
    expect(p.isLevelUnlocked(mode, 1), isTrue);
    expect(p.nextLevelIndex(mode), 1);

    await p.recordLevel(mode, mode.levels[0], stars: 1, points: 20);
    expect(p.starsFor(mode.id, 1), 2, reason: 'بهترین ستاره نگه داشته می‌شود');
    expect(p.points, 40);

    final again = ProgressStore(prefs, content);
    expect(again.points, 40);
    expect(again.badges, contains('first_step'));
    expect(again.starsFor(mode.id, 1), 2);
  });

  test('زنجیره‌ی پاسخ درست و مدال گوش تیز', () async {
    final prefs = await SharedPreferences.getInstance();
    final p = ProgressStore(prefs, content);
    for (var i = 0; i < 9; i++) {
      p.registerAnswer(true);
    }
    p.registerAnswer(false);
    expect(p.streak, 0);
    expect(p.bestStreak, 9);
    expect(await p.checkBadges(), isEmpty);
    for (var i = 0; i < 10; i++) {
      p.registerAnswer(true);
    }
    expect((await p.checkBadges()).map((a) => a.id), contains('sharp_ear'));
  });

  test('قانون levels>=all با تعداد واقعی مرحله‌ها', () async {
    final prefs = await SharedPreferences.getInstance();
    final p = ProgressStore(prefs, content);
    for (final m in content.modes) {
      for (final l in m.levels) {
        await p.recordLevel(m, l, stars: 3, points: 25);
      }
    }
    expect(p.completedCount, content.totalLevels);
    expect(p.badges, containsAll(content.achievements.where((a) => !a.rule.startsWith('streak')).map((a) => a.id)));
    expect(p.badges, contains('audio_hero'));
  });

  test('انتقال داده‌ی نسخه‌ی قدیمی و پاک کردن پیشرفت', () async {
    final prefs = await SharedPreferences.getInstance();
    final p = ProgressStore(prefs, content);
    await p.importLegacy(
      childName: 'آرین',
      points: 180,
      bestStreak: 4,
      completedLevels: ['sequence:1', 'sequence:2', 'who_made_sound:1'],
      badges: ['first_step', 'unknown_badge'],
    );
    expect(p.childName, 'آرین');
    expect(p.points, 180);
    expect(p.completedInMode('sequence'), 2);
    expect(p.starsFor('sequence', 1), 3);
    expect(p.badges, isNot(contains('unknown_badge')));
    await p.reset();
    expect(p.points, 0);
    expect(p.completedCount, 0);
    expect(p.childName, 'آرین', reason: 'نام کودک با پاک کردن پیشرفت می‌ماند');
  });
}
