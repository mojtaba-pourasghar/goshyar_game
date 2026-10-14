import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// محتوا بدون تغییر کد ویرایش می‌شود؛ این تست‌ها جلوی ارجاع شکسته را می‌گیرند.
void main() {
  final content = loadContent();

  test('هر صدا تصویر و فایل صوتی دارد', () {
    for (final s in content.sounds.values) {
      expect(File('assets/${s.image}').existsSync(), isTrue, reason: s.image);
      expect(File('assets/${s.audio}').existsSync(), isTrue, reason: s.audio);
    }
    for (final p in content.places.values) {
      expect(File('assets/${p.image}').existsSync(), isTrue, reason: p.image);
    }
  });

  test('همه‌ی شناسه‌های مرحله‌ها در levels.json تعریف شده‌اند', () {
    for (final m in content.modes) {
      for (final l in m.levels) {
        for (final id in [...l.options.where((_) => m.id != 'find_source'), ...l.sequence, ...l.layers]) {
          expect(content.sounds, contains(id), reason: '${m.id}:${l.number} $id');
        }
        if (l.sound != null) expect(content.sounds, contains(l.sound));
        if (m.id == 'find_source') {
          for (final id in l.options) {
            expect(content.places, contains(id), reason: '${m.id}:${l.number} $id');
          }
        }
      }
    }
  });

  test('هر مرحله پرسش، راهنمایی و تشویق ویژه دارد', () {
    for (final m in content.modes) {
      for (final l in m.levels) {
        for (final part in ['q', 'hint', 'ok']) {
          expect(content.voice(m.voiceId(l, part)), isNotNull, reason: m.voiceId(l, part));
        }
      }
    }
  });

  test('جمله‌ها و گروه‌هایی که کد صدا می‌زند وجود دارند', () {
    const ids = [
      'app.splash.welcome',
      'app.intro.1',
      'app.intro.2',
      'app.intro.3',
      'app.games.hub',
      'app.library.hint',
      'app.progress.shown',
      'app.settings.shown',
      'app.parent.gate',
      'app.downloads.shown',
      'cat.mission',
      'cat.complete',
      'seq.your_turn',
      'mode.done',
      'all.done',
      'result.stars.1',
      'result.stars.2',
      'result.stars.3',
      'session.pause',
      'session.resume',
    ];
    for (final id in ids) {
      expect(content.voice(id), isNotNull, reason: id);
    }
    for (final g in [
      'home.greet',
      'listen.invite',
      'question.who',
      'feedback.correct',
      'feedback.wrong',
      'replay.tip',
      'idle.nudge',
      'level.complete',
      'level.next',
    ]) {
      expect(content.pick(g), isNotNull, reason: g);
    }
    for (final m in content.modes) {
      expect(content.voice('${m.voicePrefix}.welcome'), isNotNull);
      expect(content.voice('${m.voicePrefix}.mission'), isNotNull);
    }
    for (final c in content.categories) {
      expect(content.voice('cat.${c.id}.intro'), isNotNull);
    }
    for (final s in content.sounds.values) {
      expect(content.voice('snd.${s.id}'), isNotNull);
    }
    for (final a in content.achievements) {
      expect(content.voice('badge.${a.id}'), isNotNull);
    }
  });

  // نام باید به‌صورت واژه‌ی کامل آمده باشد؛ «در» داخل «درآورد» حساب نمی‌شود.
  bool mentions(String text, String word) =>
      RegExp('(^|[\\s،.!؟?«»])${RegExp.escape(word)}(\$|[\\s،.!؟?«»])').hasMatch(text);

  test('پرسش‌ها پاسخ درست را پیش از انتخاب لو نمی‌دهند', () {
    for (final m in content.modes.where((m) => m.id == 'who_made_sound' || m.id == 'find_source')) {
      for (final l in m.levels) {
        final q = content.voice(m.voiceId(l, 'q'))!.text;
        final title = m.id == 'find_source' ? content.places[l.answer]!.title : content.sounds[l.answer]!.title;
        expect(mentions(q, title), isFalse, reason: '${m.voiceId(l, 'q')}: «$q» شامل «$title» است');
      }
    }
    for (final g in ['listen.invite', 'question.who', 'feedback.wrong', 'idle.nudge', 'replay.tip']) {
      for (final l in content.allVoiceLines.where((l) => l.group == g)) {
        for (final s in content.sounds.values) {
          expect(mentions(l.text, s.title), isFalse, reason: '${l.id} نام «${s.title}» را دارد');
        }
      }
    }
  });

  test('هر جمله شناسه‌ی یکتا، متن کوتاه و نام فایل ثابت دارد', () {
    final files = <String>{};
    for (final l in content.allVoiceLines) {
      expect(l.text.trim(), isNotEmpty);
      expect(l.text.length, lessThan(110), reason: '${l.id} برای کودک بلند است');
      expect(l.file, 'voice/${l.id.replaceAll('.', '_')}.mp3');
      expect(files.add(l.file), isTrue, reason: 'فایل تکراری ${l.file}');
    }
  });
}
