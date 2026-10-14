import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';

import 'models.dart';

/// کل محتوای بازی را یک بار از levels.json و voice_lines.json می‌خواند.
class ContentRepository {
  ContentRepository._({
    required this.categories,
    required this.sounds,
    required this.places,
    required this.modes,
    required this.achievements,
    required this.scoring,
    required this.categoryRounds,
    required this.categoryOptions,
    required Map<String, VoiceLine> voice,
  }) : _voice = voice {
    for (final l in voice.values) {
      if (l.group != null) _groups.putIfAbsent(l.group!, () => []).add(l);
    }
  }

  final List<SoundCategory> categories;
  final Map<String, SoundItem> sounds;
  final Map<String, PlaceItem> places;
  final List<GameMode> modes;
  final List<Achievement> achievements;
  final Scoring scoring;
  final int categoryRounds;
  final int categoryOptions;

  final Map<String, VoiceLine> _voice;
  final Map<String, List<VoiceLine>> _groups = {};
  final Map<String, String> _lastPicked = {};
  final Random _random = Random();

  static Future<ContentRepository> load(AssetBundle bundle) async {
    final levels = jsonDecode(await bundle.loadString('assets/content/levels.json')) as Map<String, dynamic>;
    final voice = jsonDecode(await bundle.loadString('assets/content/voice_lines.json')) as Map<String, dynamic>;
    return ContentRepository.fromJson(levels, voice);
  }

  factory ContentRepository.fromJson(Map<String, dynamic> levels, Map<String, dynamic> voice) {
    final play = (levels['categoryPlay'] ?? const {}) as Map<String, dynamic>;
    return ContentRepository._(
      categories: [for (final c in levels['categories'] as List) SoundCategory.fromJson(c as Map<String, dynamic>)],
      sounds: {
        for (final s in levels['sounds'] as List) (s as Map<String, dynamic>)['id'] as String: SoundItem.fromJson(s),
      },
      places: {
        for (final p in levels['places'] as List) (p as Map<String, dynamic>)['id'] as String: PlaceItem.fromJson(p),
      },
      modes: [for (final m in levels['modes'] as List) GameMode.fromJson(m as Map<String, dynamic>)],
      achievements: [
        for (final a in (levels['achievements'] ?? const []) as List) Achievement.fromJson(a as Map<String, dynamic>),
      ],
      scoring: Scoring.fromJson(levels['scoring'] as Map<String, dynamic>?),
      categoryRounds: (play['rounds'] ?? 5) as int,
      categoryOptions: (play['options'] ?? 3) as int,
      voice: {
        for (final l in voice['lines'] as List) (l as Map<String, dynamic>)['id'] as String: VoiceLine.fromJson(l),
      },
    );
  }

  GameMode mode(String id) => modes.firstWhere((m) => m.id == id);
  SoundCategory category(String id) => categories.firstWhere((c) => c.id == id);
  List<SoundItem> soundsIn(String categoryId) => sounds.values.where((s) => s.category == categoryId).toList();

  int get totalLevels => modes.fold(0, (n, m) => n + m.levels.length);

  /// دسته‌ی یک مرحله برای شمارش مدال‌های دسته‌ای (مثل «دوست طبیعت»).
  String levelCategory(GameLevel level) {
    final id =
        level.sound ??
        (level.sequence.isNotEmpty ? level.sequence.first : null) ??
        (level.layers.isNotEmpty ? level.layers.first : null);
    return id == null ? '' : (sounds[id]?.category ?? '');
  }

  VoiceLine? voice(String id) => _voice[id];
  Iterable<VoiceLine> get allVoiceLines => _voice.values;

  /// یک جمله از یک گروه هم‌معنا، بدون تکرار جمله‌ی قبلی همان گروه،
  /// تا کودک پشت سر هم یک جمله را نشنود.
  VoiceLine? pick(String group) {
    final list = _groups[group];
    if (list == null || list.isEmpty) return null;
    if (list.length == 1) return list.first;
    VoiceLine choice;
    do {
      choice = list[_random.nextInt(list.length)];
    } while (choice.id == _lastPicked[group]);
    _lastPicked[group] = choice.id;
    return choice;
  }
}
