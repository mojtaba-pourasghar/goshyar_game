import 'dart:math';

import '../data/content_repository.dart';
import '../data/models.dart';

/// یک گزینه‌ی قابل انتخاب در بازی (حیوان، وسیله یا مکان).
class ChoiceOption {
  const ChoiceOption({required this.id, required this.title, required this.image, this.audio});

  final String id;
  final String title;
  final String image;
  final String? audio;
}

/// یک پرسش بازی. منطق داوری اینجاست و هیچ وابستگی‌ای به رابط کاربری ندارد.
sealed class GameRound {
  const GameRound({required this.questionVoiceId, required this.hintVoiceId, required this.successVoiceId});

  final String? questionVoiceId;
  final String? hintVoiceId;
  final String? successVoiceId;

  /// صداهایی که پیش از پرسش پخش می‌شوند (به ترتیب، یا همزمان در مأموریت).
  List<String> get audioPaths;
}

/// «این صدا مال کیه؟»، «صدای مخفی را پیدا کن» و بازی دسته‌ها.
class ChoiceRound extends GameRound {
  const ChoiceRound({
    required this.soundAudio,
    required this.options,
    required this.answerId,
    this.soundTitle,
    super.questionVoiceId,
    super.hintVoiceId,
    super.successVoiceId,
  });

  final String soundAudio;
  final String? soundTitle;
  final List<ChoiceOption> options;
  final String answerId;

  @override
  List<String> get audioPaths => [soundAudio];

  bool check(String optionId) => optionId == answerId;

  ChoiceOption get answer => options.firstWhere((o) => o.id == answerId);
}

/// «ترتیب صداها»: کودک باید همان ترتیب را بچیند.
class SequenceRound extends GameRound {
  const SequenceRound({
    required this.sequence,
    required this.choices,
    super.questionVoiceId,
    super.hintVoiceId,
    super.successVoiceId,
  });

  /// ترتیب درست.
  final List<ChoiceOption> sequence;

  /// همان گزینه‌ها با ترتیب بُرخورده، تا ترتیب پاسخ از چیدمان لو نرود.
  final List<ChoiceOption> choices;

  @override
  List<String> get audioPaths => [for (final o in sequence) o.audio!];

  bool check(List<String> picked) {
    if (picked.length != sequence.length) return false;
    for (var i = 0; i < picked.length; i++) {
      if (picked[i] != sequence[i].id) return false;
    }
    return true;
  }
}

/// «مأموریت شنیداری»: چند صدای همزمان؛ کودک تعدادشان را می‌شمارد.
class CountRound extends GameRound {
  const CountRound({
    required this.layers,
    required this.options,
    required this.answer,
    required this.scene,
    required this.sceneTitle,
    super.questionVoiceId,
    super.hintVoiceId,
    super.successVoiceId,
  });

  final List<ChoiceOption> layers;
  final List<int> options;
  final int answer;
  final String scene;
  final String sceneTitle;

  @override
  List<String> get audioPaths => [for (final o in layers) o.audio!];

  bool check(int value) => value == answer;
}

/// پرسش‌ها را از محتوای بازی می‌سازد.
class RoundFactory {
  RoundFactory(this.content, {Random? random}) : _random = random ?? Random();

  final ContentRepository content;
  final Random _random;

  ChoiceOption _soundOption(String id) {
    final s = content.sounds[id];
    if (s == null) throw StateError('صدا در levels.json نیست: $id');
    return ChoiceOption(id: s.id, title: s.title, image: s.image, audio: s.audio);
  }

  ChoiceOption _placeOption(String id) {
    final p = content.places[id];
    if (p == null) throw StateError('مکان در levels.json نیست: $id');
    return ChoiceOption(id: p.id, title: p.title, image: p.image);
  }

  /// یک مرحله از یکی از چهار بازی اصلی.
  GameRound forLevel(GameMode mode, GameLevel level) {
    final q = mode.voiceId(level, 'q');
    final hint = mode.voiceId(level, 'hint');
    final ok = mode.voiceId(level, 'ok');
    switch (mode.kind) {
      case GameModeKind.whoMadeSound:
      case GameModeKind.findSource:
        final sound = content.sounds[level.sound]!;
        final opts = [
          for (final id in level.options) mode.kind == GameModeKind.findSource ? _placeOption(id) : _soundOption(id),
        ]..shuffle(_random);
        return ChoiceRound(
          soundAudio: sound.audio,
          soundTitle: sound.title,
          options: opts,
          answerId: level.answer!,
          questionVoiceId: q,
          hintVoiceId: hint,
          successVoiceId: ok,
        );
      case GameModeKind.sequence:
        final seq = [for (final id in level.sequence) _soundOption(id)];
        final shuffled = [...seq];
        // اگر بُر زدن تصادفاً همان ترتیب درست را ساخت، دوباره بُر بزن.
        for (var i = 0; i < 6; i++) {
          shuffled.shuffle(_random);
          if (!_sameOrder(shuffled, seq)) break;
        }
        return SequenceRound(
          sequence: seq,
          choices: shuffled,
          questionVoiceId: q,
          hintVoiceId: hint,
          successVoiceId: ok,
        );
      case GameModeKind.audioMission:
        return CountRound(
          layers: [for (final id in level.layers) _soundOption(id)],
          options: level.countOptions,
          answer: level.countAnswer!,
          scene: level.scene ?? mode.scene,
          sceneTitle: level.sceneTitle ?? '',
          questionVoiceId: q,
          hintVoiceId: hint,
          successVoiceId: ok,
        );
    }
  }

  /// بازی سریع یک دسته: [rounds] پرسش «این صدا مال کیه؟» با [optionCount] گزینه‌ی بزرگ.
  /// هر صدا در یک دور فقط یک بار پرسیده می‌شود.
  List<ChoiceRound> forCategory(String categoryId, {int? rounds, int? optionCount}) {
    final pool = content.soundsIn(categoryId)..shuffle(_random);
    final n = min(rounds ?? content.categoryRounds, pool.length);
    final k = min(optionCount ?? content.categoryOptions, pool.length);
    return [
      for (var i = 0; i < n; i++)
        () {
          final target = pool[i];
          final distractors = pool.where((s) => s.id != target.id).toList()..shuffle(_random);
          final opts = [_soundOption(target.id), for (final d in distractors.take(k - 1)) _soundOption(d.id)]
            ..shuffle(_random);
          return ChoiceRound(
            soundAudio: target.audio,
            soundTitle: target.title,
            options: opts,
            answerId: target.id,
            successVoiceId: 'snd.${target.id}',
          );
        }(),
    ];
  }

  static bool _sameOrder(List<ChoiceOption> a, List<ChoiceOption> b) {
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id) return false;
    }
    return true;
  }
}
