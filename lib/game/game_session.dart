import '../data/models.dart';
import 'rounds.dart';

/// نتیجه‌ی یک پاسخ.
class AnswerOutcome {
  const AnswerOutcome({
    required this.correct,
    required this.points,
    required this.firstTry,
    required this.roundFinished,
    required this.sessionFinished,
    required this.wrongStreak,
  });

  final bool correct;
  final int points;
  final bool firstTry;
  final bool roundFinished;
  final bool sessionFinished;

  /// چند پاسخ اشتباه پشت سر هم در همین پرسش؛ از دومی به بعد راهنمای تکرار صدا پخش می‌شود.
  final int wrongStreak;
}

/// وضعیت یک نوبت بازی: چند پرسش پشت سر هم، امتیاز، اشتباه‌ها و ستاره‌ها.
/// منطق خالص Dart است تا بدون رابط کاربری تست شود.
class GameSession {
  GameSession({required this.rounds, required this.scoring}) : assert(rounds.isNotEmpty);

  final List<GameRound> rounds;
  final Scoring scoring;

  int _index = 0;
  int _mistakesThisRound = 0;
  int _totalMistakes = 0;
  int _points = 0;
  int _firstTryCount = 0;
  bool _finished = false;

  int get index => _index;
  int get total => rounds.length;
  GameRound get current => rounds[_index];
  int get points => _points;
  int get mistakes => _totalMistakes;
  int get firstTryCount => _firstTryCount;
  bool get finished => _finished;
  bool get isLastRound => _index == rounds.length - 1;

  int pointsFor({required bool firstTry}) => scoring.correctPoints + (firstTry ? scoring.firstTryBonus : 0);

  AnswerOutcome submit(bool correct) {
    if (_finished) {
      throw StateError('نوبت بازی تمام شده است');
    }
    if (!correct) {
      _mistakesThisRound++;
      _totalMistakes++;
      return AnswerOutcome(
        correct: false,
        points: 0,
        firstTry: false,
        roundFinished: false,
        sessionFinished: false,
        wrongStreak: _mistakesThisRound,
      );
    }
    final firstTry = _mistakesThisRound == 0;
    final pts = pointsFor(firstTry: firstTry);
    _points += pts;
    if (firstTry) _firstTryCount++;
    final last = isLastRound;
    if (last) _finished = true;
    return AnswerOutcome(
      correct: true,
      points: pts,
      firstTry: firstTry,
      roundFinished: true,
      sessionFinished: last,
      wrongStreak: 0,
    );
  }

  /// رفتن به پرسش بعد، پس از پاسخ درست.
  void advance() {
    if (_index < rounds.length - 1) {
      _index++;
      _mistakesThisRound = 0;
    }
  }

  /// ستاره‌ها: بدون اشتباه ۳، تا نصف تعداد پرسش‌ها اشتباه (حداقل یک) ۲، بیشتر ۱.
  int get stars => starsFor(mistakes: _totalMistakes, rounds: rounds.length);

  static int starsFor({required int mistakes, required int rounds}) {
    if (mistakes == 0) return 3;
    final allowance = rounds ~/ 2 < 1 ? 1 : rounds ~/ 2;
    return mistakes <= allowance ? 2 : 1;
  }
}
