import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:goshyar/data/models.dart';
import 'package:goshyar/game/game_session.dart';
import 'package:goshyar/game/rounds.dart';

import 'helpers.dart';

void main() {
  final content = loadContent();
  final factory = RoundFactory(content, random: Random(42));

  group('GameSession', () {
    GameSession session(int n) => GameSession(
      rounds: factory.forCategory('animals', rounds: n),
      scoring: const Scoring(correctPoints: 20, firstTryBonus: 5),
    );

    test('پاسخ درست در بار اول: امتیاز با پاداش و پایان نوبت', () {
      final s = session(1);
      final o = s.submit(true);
      expect(o.correct, isTrue);
      expect(o.firstTry, isTrue);
      expect(o.points, 25);
      expect(o.sessionFinished, isTrue);
      expect(s.points, 25);
      expect(s.stars, 3);
      expect(() => s.submit(true), throwsStateError);
    });

    test('پاسخ اشتباه امتیاز نمی‌دهد و پاسخ درست بعدی پاداش بار اول ندارد', () {
      final s = session(2);
      final w1 = s.submit(false);
      final w2 = s.submit(false);
      expect(w1.correct, isFalse);
      expect(w1.points, 0);
      expect(w2.wrongStreak, 2);
      final ok = s.submit(true);
      expect(ok.firstTry, isFalse);
      expect(ok.points, 20);
      expect(ok.sessionFinished, isFalse);
      s.advance();
      expect(s.index, 1);
      expect(s.submit(false).wrongStreak, 1, reason: 'زنجیره‌ی اشتباه با پرسش تازه صفر می‌شود');
      expect(s.submit(true).sessionFinished, isTrue);
      expect(s.mistakes, 3);
      expect(s.points, 40);
    });

    test('ستاره‌ها', () {
      expect(GameSession.starsFor(mistakes: 0, rounds: 1), 3);
      expect(GameSession.starsFor(mistakes: 1, rounds: 1), 2);
      expect(GameSession.starsFor(mistakes: 2, rounds: 1), 1);
      expect(GameSession.starsFor(mistakes: 2, rounds: 5), 2);
      expect(GameSession.starsFor(mistakes: 3, rounds: 5), 1);
    });
  });

  group('RoundFactory', () {
    test('همه‌ی مرحله‌های چهار بازی پرسش معتبر می‌سازند', () {
      for (final mode in content.modes) {
        for (final level in mode.levels) {
          final r = factory.forLevel(mode, level);
          switch (r) {
            case ChoiceRound():
              expect(r.options.map((o) => o.id), contains(r.answerId), reason: '${mode.id} ${level.number}');
              expect(r.options.map((o) => o.id).toSet().length, r.options.length);
              expect(r.check(r.answerId), isTrue);
              expect(r.check(r.options.firstWhere((o) => o.id != r.answerId).id), isFalse);
            case SequenceRound():
              expect(r.check(r.sequence.map((o) => o.id).toList()), isTrue);
              expect(r.check(r.sequence.reversed.map((o) => o.id).toList()), isFalse);
              expect(r.check(r.sequence.take(r.sequence.length - 1).map((o) => o.id).toList()), isFalse);
              expect(
                r.choices.map((o) => o.id).toList(),
                isNot(r.sequence.map((o) => o.id).toList()),
                reason: 'گزینه‌ها نباید به ترتیب پاسخ چیده شوند',
              );
            case CountRound():
              expect(r.options, contains(r.answer));
              expect(r.layers.length, r.answer, reason: 'تعداد لایه‌ها باید با پاسخ برابر باشد');
          }
        }
      }
    });

    test('بازی دسته‌ها: پنج پرسش بدون تکرار، سه گزینه از همان دسته', () {
      for (final c in content.categories) {
        final rounds = factory.forCategory(c.id);
        expect(rounds.length, min(5, content.soundsIn(c.id).length));
        expect(rounds.map((r) => r.answerId).toSet().length, rounds.length);
        for (final r in rounds) {
          expect(r.options.length, 3);
          expect(r.options.map((o) => o.id), contains(r.answerId));
          for (final o in r.options) {
            expect(content.sounds[o.id]!.category, c.id);
          }
        }
      }
    });
  });
}
