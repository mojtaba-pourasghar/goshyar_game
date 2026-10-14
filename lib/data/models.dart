/// مدل‌های محتوای بازی؛ همه از assets/content/levels.json خوانده می‌شوند
/// تا محتوای آموزشی بدون تغییر کد قابل ویرایش باشد.
library;

class SoundCategory {
  const SoundCategory({
    required this.id,
    required this.title,
    required this.blurb,
    required this.icon,
    required this.color,
  });

  final String id;
  final String title;
  final String blurb;
  final String icon;
  final String color;

  factory SoundCategory.fromJson(Map<String, dynamic> j) => SoundCategory(
    id: j['id'] as String,
    title: j['title'] as String,
    blurb: (j['blurb'] ?? '') as String,
    icon: (j['icon'] ?? '') as String,
    color: (j['color'] ?? '#FF8A1F') as String,
  );
}

class SoundItem {
  const SoundItem({
    required this.id,
    required this.title,
    required this.category,
    required this.image,
    required this.audio,
  });

  final String id;
  final String title;
  final String category;

  /// مسیر منطقی تصویر، مثل images/sounds/lion.webp
  final String image;

  /// مسیر منطقی صدا، مثل audio/sfx/animals_lion.mp3
  final String audio;

  factory SoundItem.fromJson(Map<String, dynamic> j) => SoundItem(
    id: j['id'] as String,
    title: j['title'] as String,
    category: j['category'] as String,
    image: j['image'] as String,
    audio: j['audio'] as String,
  );
}

class PlaceItem {
  const PlaceItem({required this.id, required this.title, required this.image});

  final String id;
  final String title;
  final String image;

  factory PlaceItem.fromJson(Map<String, dynamic> j) =>
      PlaceItem(id: j['id'] as String, title: j['title'] as String, image: j['image'] as String);
}

enum GameModeKind { whoMadeSound, findSource, sequence, audioMission }

GameModeKind modeKindFromId(String id) => switch (id) {
  'who_made_sound' => GameModeKind.whoMadeSound,
  'find_source' => GameModeKind.findSource,
  'sequence' => GameModeKind.sequence,
  'audio_mission' => GameModeKind.audioMission,
  _ => throw FormatException('حالت بازی ناشناخته: $id'),
};

class GameLevel {
  const GameLevel({
    required this.number,
    this.sound,
    this.answer,
    this.options = const [],
    this.sequence = const [],
    this.layers = const [],
    this.countAnswer,
    this.countOptions = const [],
    this.scene,
    this.sceneTitle,
  });

  final int number;

  /// پیدا کردن منبع و «این صدا مال کیه؟»: صدایی که پخش می‌شود.
  final String? sound;

  /// شناسه‌ی گزینه‌ی درست (مکان یا صدا).
  final String? answer;
  final List<String> options;

  /// ترتیب صداها.
  final List<String> sequence;

  /// مأموریت شنیداری: صداهای همزمان صحنه، پاسخ عددی و گزینه‌های عددی.
  final List<String> layers;
  final int? countAnswer;
  final List<int> countOptions;
  final String? scene;
  final String? sceneTitle;

  factory GameLevel.fromJson(GameModeKind kind, Map<String, dynamic> j) {
    final n = j['n'] as int;
    switch (kind) {
      case GameModeKind.whoMadeSound:
      case GameModeKind.findSource:
        return GameLevel(
          number: n,
          sound: j['sound'] as String,
          answer: (j['answer'] ?? j['sound']) as String,
          options: List<String>.from(j['options'] as List),
        );
      case GameModeKind.sequence:
        return GameLevel(number: n, sequence: List<String>.from(j['sequence'] as List));
      case GameModeKind.audioMission:
        return GameLevel(
          number: n,
          layers: List<String>.from(j['layers'] as List),
          countAnswer: j['answer'] as int,
          countOptions: List<int>.from(j['options'] as List),
          scene: j['scene'] as String?,
          sceneTitle: j['sceneTitle'] as String?,
        );
    }
  }
}

class GameMode {
  const GameMode({
    required this.id,
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.scene,
    required this.voicePrefix,
    required this.levels,
  });

  final String id;
  final GameModeKind kind;
  final String title;
  final String subtitle;
  final String icon;
  final String color;
  final String scene;
  final String voicePrefix;
  final List<GameLevel> levels;

  factory GameMode.fromJson(Map<String, dynamic> j) {
    final kind = modeKindFromId(j['id'] as String);
    return GameMode(
      id: j['id'] as String,
      kind: kind,
      title: j['title'] as String,
      subtitle: (j['subtitle'] ?? '') as String,
      icon: (j['icon'] ?? '') as String,
      color: (j['color'] ?? '#5B2BC4') as String,
      scene: (j['scene'] ?? 'meadow') as String,
      voicePrefix: j['voicePrefix'] as String,
      levels: [for (final l in j['levels'] as List) GameLevel.fromJson(kind, l as Map<String, dynamic>)],
    );
  }

  /// شناسه‌ی جمله‌ی گوینده برای یک مرحله: who.01.q ، who.01.hint ، who.01.ok
  String voiceId(GameLevel level, String part) => '$voicePrefix.${level.number.toString().padLeft(2, '0')}.$part';
}

class Achievement {
  const Achievement({
    required this.id,
    required this.title,
    required this.desc,
    required this.icon,
    required this.rule,
  });

  final String id;
  final String title;
  final String desc;
  final String icon;

  /// قانون باز شدن: levels>=5 ، levels>=all ، streak>=10 ، cat:nature>=3 ، mode:sequence>=4
  final String rule;

  factory Achievement.fromJson(Map<String, dynamic> j) => Achievement(
    id: j['id'] as String,
    title: j['title'] as String,
    desc: (j['desc'] ?? '') as String,
    icon: (j['icon'] ?? '') as String,
    rule: j['rule'] as String,
  );
}

class Scoring {
  const Scoring({this.correctPoints = 20, this.firstTryBonus = 5, this.pointsPerRank = 500});

  final int correctPoints;
  final int firstTryBonus;
  final int pointsPerRank;

  factory Scoring.fromJson(Map<String, dynamic>? j) => j == null
      ? const Scoring()
      : Scoring(
          correctPoints: (j['correctPoints'] ?? 20) as int,
          firstTryBonus: (j['firstTryBonus'] ?? 5) as int,
          pointsPerRank: (j['pointsPerRank'] ?? 500) as int,
        );
}

/// یک جمله‌ی گوینده.
class VoiceLine {
  const VoiceLine({
    required this.id,
    required this.text,
    required this.file,
    this.event = '',
    this.screen = '',
    this.group,
    this.delayMs = 0,
  });

  final String id;
  final String text;
  final String file;
  final String event;
  final String screen;
  final String? group;
  final int delayMs;

  factory VoiceLine.fromJson(Map<String, dynamic> j) => VoiceLine(
    id: j['id'] as String,
    text: j['text'] as String,
    file: (j['file'] ?? 'voice/${(j['id'] as String).replaceAll('.', '_')}.mp3') as String,
    event: (j['event'] ?? '') as String,
    screen: (j['screen'] ?? '') as String,
    group: j['group'] as String?,
    delayMs: (j['delayMs'] ?? 0) as int,
  );
}
