import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/assets/asset_resolver.dart';
import '../../core/audio/game_audio.dart';
import '../../core/design/theme.dart';
import '../../core/design/tokens.dart';
import '../../core/fa.dart';
import '../../core/narrator.dart';
import '../../data/content_repository.dart';
import '../../data/models.dart';
import '../../data/progress_store.dart';
import '../../game/game_session.dart';
import '../../game/rounds.dart';
import '../routes.dart';
import '../widgets/clay.dart';
import '../widgets/game_widgets.dart';
import '../widgets/mascot.dart';
import '../widgets/scene.dart';
import 'result_screen.dart';

/// ورودی صفحه‌ی بازی: یا یک مرحله از یکی از چهار بازی، یا یک دور بازی دسته‌ها.
class GameArgs {
  const GameArgs.level(String this.modeId, this.levelIndex) : categoryId = null;
  const GameArgs.category(String this.categoryId) : modeId = null, levelIndex = 0;

  final String? modeId;
  final int levelIndex;
  final String? categoryId;

  bool get isCategory => categoryId != null;
}

enum _Phase { listening, answering, wrong, correct, finishing }

/// جای خالی پایین صفحه تا نوار بازخورد روی گزینه‌ها نیفتد.
const _bannerReserve = 150.0;

/// صفحه‌ی اجرای بازی شنیداری.
///
/// جریان هر پرسش: دعوت به گوش دادن ← پخش صدا ← پرسش ← انتخاب کودک ←
/// بازخورد (درست: تشویق و امتیاز / اشتباه: دلگرمی و راهنمایی، بدون لو دادن پاسخ).
class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.args});

  final GameArgs args;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final ContentRepository _content = context.read<ContentRepository>();
  late final Narrator _narrator = context.read<Narrator>();
  late final GameAudio _audio = context.read<GameAudio>();
  late final ProgressStore _progress = context.read<ProgressStore>();

  late final GameSession _session;
  GameMode? _mode;
  GameLevel? _level;

  _Phase _phase = _Phase.listening;
  bool _playing = false;
  bool _heardOnce = false;
  int _token = 0;
  Timer? _idle;
  MascotPose _pose = MascotPose.listening;
  final Map<String, OptionState> _optionStates = {};
  final List<String> _picked = [];
  final Set<int> _wrongCounts = {};
  int? _pickedCount;
  String? _bannerText;
  int _lastPoints = 0;

  @override
  void initState() {
    super.initState();
    final factory = RoundFactory(_content);
    final a = widget.args;
    final List<GameRound> rounds;
    if (a.isCategory) {
      rounds = factory.forCategory(a.categoryId!);
    } else {
      _mode = _content.mode(a.modeId!);
      _level = _mode!.levels[a.levelIndex.clamp(0, _mode!.levels.length - 1)];
      rounds = [factory.forLevel(_mode!, _level!)];
    }
    _session = GameSession(rounds: rounds, scoring: _content.scoring);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _precache();
      _startRound(first: true);
    });
  }

  @override
  void dispose() {
    _idle?.cancel();
    _token++;
    super.dispose();
  }

  GameRound get _round => _session.current;

  String get _scene {
    final r = _round;
    if (r is CountRound) return r.scene;
    if (_mode != null) return _mode!.scene;
    return switch (widget.args.categoryId) {
      'animals' => 'farm',
      'home' => 'home',
      'professions' || 'science' => 'city',
      'nature' => 'forest_day',
      _ => 'meadow',
    };
  }

  String get _title {
    if (_mode != null) return 'مرحله ${faDigits(_level!.number)}';
    return _content.category(widget.args.categoryId!).title;
  }

  void _precache() {
    final paths = <String>[];
    for (final r in _session.rounds) {
      if (r is ChoiceRound) paths.addAll(r.options.map((o) => o.image));
      if (r is SequenceRound) paths.addAll(r.choices.map((o) => o.image));
    }
    context.read<AssetResolver>().precache(context, paths);
  }

  // ---------------------------------------------------------------- جریان

  /// اگر نوبت عوض شده باشد (پرسش بعد، خروج، توقف) ادامه نده.
  bool _alive(int t) => mounted && t == _token;

  Future<void> _startRound({bool first = false}) async {
    final t = ++_token;
    _idle?.cancel();
    setState(() {
      _phase = _Phase.listening;
      _heardOnce = false;
      _optionStates.clear();
      _picked.clear();
      _pickedCount = null;
      _bannerText = null;
      _pose = MascotPose.listening;
    });
    _audio.stopAll();
    final r = _round;
    if (first) {
      final missionLine = _mode == null
          ? 'cat.mission'
          : (widget.args.levelIndex == 0 ? '${_mode!.voicePrefix}.mission' : null);
      await _narrator.say(missionLine);
      if (!_alive(t)) return;
    }
    if (r is SequenceRound) {
      await _narrator.say(r.questionVoiceId);
      if (!_alive(t)) return;
      await _playRoundAudio(t);
      if (!_alive(t)) return;
      _beginAnswering(t);
      await _narrator.say('seq.your_turn');
    } else {
      await _narrator.sayOneOf('listen.invite');
      if (!_alive(t)) return;
      await _playRoundAudio(t);
      if (!_alive(t)) return;
      _beginAnswering(t);
      if (r.questionVoiceId != null) {
        await _narrator.say(r.questionVoiceId);
      } else {
        await _narrator.sayOneOf('question.who');
      }
    }
  }

  Future<void> _playRoundAudio(int t) async {
    setState(() => _playing = true);
    final r = _round;
    switch (r) {
      case ChoiceRound():
        await _audio.playSound(r.soundAudio);
      case SequenceRound():
        await _audio.playSequence(r.audioPaths);
      case CountRound():
        await _audio.playLayered(r.audioPaths);
    }
    if (mounted && t == _token) {
      setState(() {
        _playing = false;
        _heardOnce = true;
      });
    }
  }

  void _beginAnswering(int t) {
    if (!_alive(t)) return;
    setState(() {
      _phase = _Phase.answering;
      _pose = MascotPose.think;
    });
    _armIdle();
  }

  void _armIdle() {
    _idle?.cancel();
    _idle = Timer(const Duration(seconds: 12), () {
      if (mounted && _phase == _Phase.answering && !_playing) _narrator.sayOneOf('idle.nudge');
    });
  }

  /// تکرار صدای پرسش با دکمه‌ی آبی؛ گوینده را قطع می‌کند تا صداها روی هم نیفتند.
  Future<void> _replay() async {
    if (_playing || _phase == _Phase.correct || _phase == _Phase.finishing) return;
    final t = ++_token;
    _audio.stopAll();
    setState(() {
      if (_phase == _Phase.wrong) {
        _phase = _Phase.answering;
        _bannerText = null;
      }
      _pose = MascotPose.listening;
    });
    await _playRoundAudio(t);
    if (_alive(t)) {
      setState(() {
        if (_phase == _Phase.listening) _phase = _Phase.answering;
        _pose = MascotPose.think;
      });
      _armIdle();
    }
  }

  // ---------------------------------------------------------------- پاسخ‌ها

  bool get _canAnswer => _heardOnce && (_phase == _Phase.answering || _phase == _Phase.wrong);

  void _onChoice(ChoiceOption o) {
    final r = _round as ChoiceRound;
    if (!_canAnswer) return;
    if (_optionStates[o.id] == OptionState.dimmed || _optionStates[o.id] == OptionState.wrong) return;
    _answer(r.check(o.id), optionId: o.id);
  }

  void _onSequencePick(ChoiceOption o) {
    final r = _round as SequenceRound;
    if (!_canAnswer || _picked.length >= r.sequence.length) return;
    if (_phase == _Phase.wrong) setState(() => _bannerText = null);
    _audio.stopAll();
    _audio.playSound(o.audio!);
    setState(() {
      _phase = _Phase.answering;
      _picked.add(o.id);
    });
    _armIdle();
    if (_picked.length == r.sequence.length) {
      Future<void>.delayed(const Duration(milliseconds: 650), () {
        if (mounted && _picked.length == r.sequence.length && _phase == _Phase.answering) {
          _answer(r.check(_picked));
        }
      });
    }
  }

  void _undoPick() {
    if (_picked.isEmpty || !_canAnswer) return;
    setState(() => _picked.removeLast());
  }

  void _onCount(int value) {
    final r = _round as CountRound;
    if (!_canAnswer || _wrongCounts.contains(value)) return;
    setState(() => _pickedCount = value);
    _answer(r.check(value), count: value);
  }

  Future<void> _answer(bool correct, {String? optionId, int? count}) async {
    final t = ++_token;
    _idle?.cancel();
    _audio.stopAll();
    final outcome = _session.submit(correct);
    _progress.registerAnswer(correct);

    if (!correct) {
      _audio.uiFail();
      setState(() {
        _phase = _Phase.wrong;
        _pose = MascotPose.cheer;
        if (optionId != null) _optionStates[optionId] = OptionState.wrong;
        if (count != null) _wrongCounts.add(count);
        _bannerText = _content.voice(_round.hintVoiceId ?? '')?.text ?? 'یک بار دیگر خوب گوش کن.';
      });
      // کارت اشتباه کمی بعد کم‌رنگ می‌شود تا کودک دوباره آن را انتخاب نکند.
      Future<void>.delayed(const Duration(milliseconds: 700), () {
        if (mounted && optionId != null && _optionStates[optionId] == OptionState.wrong) {
          setState(() => _optionStates[optionId] = OptionState.dimmed);
        }
        if (mounted && _round is SequenceRound) setState(() => _picked.clear());
      });
      await _narrator.sayOneOf('feedback.wrong');
      if (!_alive(t)) return;
      await _narrator.say(_round.hintVoiceId);
      if (!_alive(t)) return;
      if (outcome.wrongStreak >= 2) await _narrator.sayOneOf('replay.tip');
      return;
    }

    _audio.uiSuccess();
    setState(() {
      _phase = _Phase.correct;
      _pose = MascotPose.celebrate;
      _lastPoints = outcome.points;
      _bannerText = null;
      if (optionId != null) {
        for (final o in (_round as ChoiceRound).options) {
          _optionStates[o.id] = o.id == optionId ? OptionState.correct : OptionState.dimmed;
        }
      }
    });
    await _narrator.sayOneOf('feedback.correct');
    if (!_alive(t)) return;
    await _narrator.say(_round.successVoiceId);
  }

  Future<void> _continue() async {
    if (_phase != _Phase.correct) return;
    if (!_session.finished) {
      _session.advance();
      _wrongCounts.clear();
      _startRound();
      return;
    }
    setState(() => _phase = _Phase.finishing);
    _token++;
    _audio.stopAll();
    final stars = _session.stars;
    final List<Achievement> fresh;
    if (_mode != null) {
      fresh = await _progress.recordLevel(_mode!, _level!, stars: stars, points: _session.points);
    } else {
      fresh = await _progress.recordCategorySession(widget.args.categoryId!, stars: stars, points: _session.points);
    }
    if (!mounted) return;
    final r = _session.rounds.last;
    Navigator.of(context).pushReplacementNamed(
      Routes.result,
      arguments: ResultArgs(
        game: widget.args,
        stars: stars,
        points: _session.points,
        badges: fresh,
        image: r is ChoiceRound ? r.answer.image : null,
        answerTitle: r is ChoiceRound ? r.answer.title : null,
      ),
    );
  }

  // ---------------------------------------------------------------- توقف

  Future<void> _pause() async {
    _token++;
    _idle?.cancel();
    _audio.stopAll();
    setState(() => _playing = false);
    _narrator.say('session.pause');
    final choice = await showModalBottomSheet<String>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) => const _PauseSheet(),
    );
    if (!mounted) return;
    _audio.stopAll();
    switch (choice) {
      case 'restart':
        Navigator.of(context).pushReplacementNamed(Routes.game, arguments: widget.args);
      case 'exit':
        Navigator.of(context).pop();
      default:
        _narrator.say('session.resume');
        if (_phase == _Phase.listening) {
          _startRound();
        } else if (_phase == _Phase.answering || _phase == _Phase.wrong) {
          _armIdle();
        }
    }
  }

  // ---------------------------------------------------------------- رابط

  @override
  Widget build(BuildContext context) {
    final dark = SceneBackground.isDark(_scene);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _pause();
      },
      child: Scaffold(
        body: SceneBackground(
          scene: _scene,
          dim: switch (_scene) {
            'farm' || 'home' || 'city' => .12,
            _ => 0,
          },
          child: SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    _TopBar(
                      title: _title,
                      light: dark || _scene == 'city' || _scene == 'home' || _scene == 'farm',
                      points: _session.points,
                      index: _session.index,
                      total: _session.total,
                      onPause: _pause,
                    ),
                    Expanded(child: _body()),
                  ],
                ),
                _Banner(
                  show: _phase == _Phase.correct,
                  points: _lastPoints,
                  last: _session.finished,
                  onContinue: _continue,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header({double mascot = 92}) {
    final q = _content.voice(_round.questionVoiceId ?? '')?.text ?? 'این صدا مال کیه؟';
    final wrong = _phase == _Phase.wrong;
    // پس از اشتباه، دلگرمی و راهنمایی بالای صفحه می‌آید، نه در نواری که روی گزینه‌ها بیفتد.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: GSpace.gutter),
      child: Column(
        children: [
          AnimatedSize(
            duration: GMotion.quick,
            child: wrong
                ? Padding(
                    padding: const EdgeInsets.only(bottom: GSpace.xs),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: GSpace.md, vertical: 6),
                      decoration: BoxDecoration(
                        color: GColors.orange,
                        borderRadius: BorderRadius.circular(GRadius.pill),
                        boxShadow: GShadow.soft(GColors.orangeDark),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.favorite_rounded, color: Colors.white, size: 22),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'اشکالی ندارد، دوباره امتحان کن!',
                              style: GText.label.copyWith(fontSize: 16),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
          Row(
            children: [
              Mascot(pose: _pose, size: mascot),
              const SizedBox(width: GSpace.xs),
              Expanded(
                child: SpeechBubble(
                  fallback: wrong && _bannerText != null ? _bannerText : q,
                  borderColor: wrong ? GColors.orange : GColors.purpleSoft,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _playButton({String label = 'دوباره گوش کن', double size = 96}) => Center(
    child: PlaySoundButton(
      playing: _playing,
      size: size,
      label: label,
      onTap: _phase == _Phase.correct || _phase == _Phase.finishing ? null : _replay,
    ),
  );

  Widget _body() {
    final r = _round;
    return LayoutBuilder(
      builder: (context, c) {
        final compact = c.maxHeight < 560;
        final child = switch (r) {
          ChoiceRound() => _choiceBody(r, c, compact),
          SequenceRound() => _sequenceBody(r, c, compact),
          CountRound() => _countBody(r, c, compact),
        };
        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: _bannerReserve),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: c.maxHeight - _bannerReserve),
            child: child,
          ),
        );
      },
    );
  }

  Widget _choiceBody(ChoiceRound r, BoxConstraints c, bool compact) {
    final n = r.options.length;
    const gap = GSpace.md;
    final mascot = compact ? 76.0 : 96.0;
    final play = compact ? 80.0 : 100.0;
    // ارتفاع باقی‌مانده برای کارت‌ها، پس از سربرگ، دکمه‌ی پخش و جای نوار بازخورد.
    final cardsH = c.maxHeight - _bannerReserve - mascot - play * 1.5 - (compact ? 16 : 40);
    final innerW = c.maxWidth - GSpace.gutter * 2;
    // تعداد ستونی را برمی‌گزیند که بزرگ‌ترین کارت را می‌دهد (مثلاً سه گزینه: یک ردیف سه‌تایی یا ۲+۱).
    var side = 0.0;
    for (final cols in {n, if (n > 2) 2}) {
      final rows = (n / cols).ceil();
      final byW = (innerW - gap * (cols - 1)) / cols;
      final byH = (cardsH - gap * (rows - 1)) / rows * .82;
      final s = byW < byH ? byW : byH;
      if (s > side) side = s;
    }
    side = side.clamp(88.0, 210.0);
    return Column(
      children: [
        _header(mascot: mascot),
        SizedBox(height: compact ? GSpace.xs : GSpace.md),
        _playButton(size: play),
        SizedBox(height: compact ? GSpace.xs : GSpace.md),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: GSpace.gutter),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: gap,
            runSpacing: gap,
            children: [
              for (final o in r.options)
                SizedBox(
                  width: side,
                  height: side / .82,
                  child: OptionCard(
                    image: o.image,
                    title: o.title,
                    state: _optionStates[o.id] ?? OptionState.idle,
                    onTap: () => _onChoice(o),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sequenceBody(SequenceRound r, BoxConstraints c, bool compact) {
    final n = r.sequence.length;
    // فضای داخل کارت: حاشیه‌ی صفحه و حاشیه‌ی داخلی کارت هر دو کم می‌شوند.
    final slot = ((c.maxWidth - GSpace.gutter * 2 - GSpace.sm * 2 - 8 * (n - 1)) / n).clamp(36.0, 84.0);
    final cols = n <= 3 ? n : 3;
    final w = ((c.maxWidth - GSpace.gutter * 2 - GSpace.md * (cols - 1)) / cols).clamp(80.0, 150.0);
    return Column(
      children: [
        _header(mascot: compact ? 72 : 88),
        SizedBox(height: compact ? GSpace.xs : GSpace.sm),
        _playButton(label: 'دوباره پخش کن', size: compact ? 76 : 90),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: GSpace.gutter, vertical: GSpace.xs),
          child: ClayCard(
            padding: const EdgeInsets.all(GSpace.sm),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < n; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      _Slot(
                        size: slot,
                        number: i + 1,
                        image: i < _picked.length ? r.sequence.firstWhere((o) => o.id == _picked[i]).image : null,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: GSpace.xs),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('ترتیب تو', style: GText.caption),
                    const SizedBox(width: GSpace.xs),
                    TextButton.icon(
                      onPressed: _picked.isEmpty ? null : _undoPick,
                      style: TextButton.styleFrom(minimumSize: const Size(GTouch.min, 44)),
                      icon: const Icon(Icons.undo_rounded),
                      label: const Text('برگرداندن', style: GText.bodyStrong),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: GSpace.gutter),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: GSpace.md,
            runSpacing: GSpace.md,
            children: [
              for (final o in r.choices)
                SizedBox(
                  width: w,
                  height: w / .82,
                  child: OptionCard(
                    image: o.image,
                    title: o.title,
                    badge: _picked.contains(o.id) ? faDigits(_picked.indexOf(o.id) + 1) : null,
                    state: _picked.contains(o.id) ? OptionState.active : OptionState.idle,
                    onTap: () => _onSequencePick(o),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _countBody(CountRound r, BoxConstraints c, bool compact) {
    return Column(
      children: [
        const SizedBox(height: GSpace.xs),
        SectionPill(r.sceneTitle, color: GColors.purpleDark),
        SizedBox(height: compact ? GSpace.xs : GSpace.md),
        _header(mascot: compact ? 90 : 120),
        SizedBox(height: compact ? GSpace.xs : GSpace.md),
        _playButton(label: 'دوباره گوش کن', size: compact ? 84 : 104),
        SizedBox(height: compact ? GSpace.sm : GSpace.lg),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: GSpace.gutter),
          child: ClayCard(
            padding: const EdgeInsets.all(GSpace.md),
            child: Column(
              children: [
                Text('چند صدای مختلف شنیدی؟', style: GText.heading, textAlign: TextAlign.center),
                const SizedBox(height: GSpace.md),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: GSpace.md,
                  runSpacing: GSpace.md,
                  children: [
                    for (final v in r.options)
                      _CountButton(
                        value: v,
                        state: _wrongCounts.contains(v)
                            ? OptionState.dimmed
                            : (_phase == _Phase.correct && v == _pickedCount)
                            ? OptionState.correct
                            : OptionState.idle,
                        onTap: () => _onCount(v),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.title,
    required this.light,
    required this.points,
    required this.index,
    required this.total,
    required this.onPause,
  });

  final String title;
  final bool light;
  final int points;
  final int index;
  final int total;
  final VoidCallback onPause;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(GSpace.gutter - 4, GSpace.xs, GSpace.gutter - 4, GSpace.xs),
      child: Row(
        children: [
          ClayIconButton(icon: Icons.pause_rounded, label: 'توقف', onTap: onPause, size: 52),
          const SizedBox(width: GSpace.sm),
          Expanded(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: GSpace.sm, vertical: 2),
                  decoration: BoxDecoration(
                    color: light ? Colors.black.withValues(alpha: .25) : Colors.white.withValues(alpha: .7),
                    borderRadius: BorderRadius.circular(GRadius.pill),
                  ),
                  child: Text(
                    total > 1 ? '$title: پرسش ${faDigits(index + 1)} از ${faDigits(total)}' : title,
                    style: GText.bodyStrong.copyWith(color: light ? Colors.white : GColors.purple),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (total > 1) ...[const SizedBox(height: 4), StepDots(index: index, total: total, light: true)],
              ],
            ),
          ),
          const SizedBox(width: GSpace.sm),
          ScoreChip(points: points),
        ],
      ),
    );
  }
}

class _Slot extends StatelessWidget {
  const _Slot({required this.size, required this.number, this.image});

  final double size;
  final int number;
  final String? image;

  @override
  Widget build(BuildContext context) {
    final img = image == null ? null : context.read<AssetResolver>().image(image!);
    return AnimatedContainer(
      duration: GMotion.quick,
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: img == null ? GColors.purpleSoft : Colors.white,
        borderRadius: BorderRadius.circular(GRadius.sm),
        border: Border.all(color: img == null ? GColors.line : GColors.blue, width: 3),
      ),
      clipBehavior: Clip.antiAlias,
      child: img == null
          ? Center(
              child: Text(faDigits(number), style: GText.title.copyWith(color: GColors.purple.withValues(alpha: .5))),
            )
          : Image(image: img, fit: BoxFit.cover),
    );
  }
}

class _CountButton extends StatelessWidget {
  const _CountButton({required this.value, required this.state, required this.onTap});

  final int value;
  final OptionState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = switch (state) {
      OptionState.correct => GColors.green,
      OptionState.dimmed => const Color(0xFFB9B4CC),
      _ => GColors.purple,
    };
    return Pressable(
      onTap: state == OptionState.dimmed ? null : onTap,
      color: color,
      depth: 6,
      semanticLabel: faDigits(value),
      child: Container(
        width: 72,
        height: 66,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 4),
        ),
        child: Text(faDigits(value), style: GText.display.copyWith(color: Colors.white, fontSize: 32)),
      ),
    );
  }
}

/// نوار پایین صفحه پس از پاسخ درست: تشویق، امتیاز و رفتن به پرسش بعد.
/// (بازخورد اشتباه بالای صفحه نمایش داده می‌شود تا روی گزینه‌ها نیفتد.)
class _Banner extends StatelessWidget {
  const _Banner({required this.show, required this.points, required this.last, required this.onContinue});

  final bool show;
  final int points;
  final bool last;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      // تا وقتی پنهان است، برای صفحه‌خوان هم وجود ندارد.
      child: ExcludeSemantics(
        excluding: !show,
        child: AnimatedSlide(
          offset: show ? Offset.zero : const Offset(0, 1.2),
          duration: GMotion.medium,
          curve: show ? GMotion.enter : GMotion.exit,
          child: Padding(
            padding: const EdgeInsets.all(GSpace.sm),
            child: ClayCard(
              color: const Color(0xFFE8FFF1),
              border: GColors.green,
              padding: const EdgeInsets.all(GSpace.md),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.celebration_rounded, color: GColors.green, size: 34),
                      const SizedBox(width: GSpace.xs),
                      Expanded(
                        child: Text('آفرین! درست بود!', style: GText.heading.copyWith(color: GColors.greenDark)),
                      ),
                      ScoreChip(points: points, prefix: '+'),
                    ],
                  ),
                  const SizedBox(height: GSpace.sm),
                  ClayButton(
                    label: last ? 'دیدن ستاره‌ها' : 'صدای بعدی',
                    icon: last ? Icons.star_rounded : Icons.arrow_forward_rounded,
                    color: GColors.green,
                    onTap: show ? onContinue : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PauseSheet extends StatelessWidget {
  const _PauseSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(GSpace.md),
        child: ClayCard(
          padding: const EdgeInsets.all(GSpace.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Mascot(pose: MascotPose.cheer, size: 110),
              Text('بازی متوقف شد', style: GText.title.copyWith(color: GColors.purple)),
              const SizedBox(height: GSpace.md),
              ClayButton(
                label: 'ادامه بازی',
                icon: Icons.play_arrow_rounded,
                color: GColors.green,
                big: true,
                onTap: () => Navigator.pop(context, 'resume'),
              ),
              const SizedBox(height: GSpace.sm),
              ClayButton(
                label: 'شروع دوباره',
                icon: Icons.replay_rounded,
                color: GColors.orange,
                onTap: () => Navigator.pop(context, 'restart'),
              ),
              const SizedBox(height: GSpace.sm),
              ClayButton(
                label: 'خروج از بازی',
                icon: Icons.logout_rounded,
                color: GColors.red,
                onTap: () => Navigator.pop(context, 'exit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
