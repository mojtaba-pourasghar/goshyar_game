import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'content_repository.dart';
import 'models.dart';

/// پیشرفت کودک: امتیاز، مراحل کامل‌شده، ستاره‌های هر مرحله، زنجیره‌ی پاسخ درست و مدال‌ها.
/// همه در یک کلید JSON ذخیره می‌شود تا نوشتن اتمی و ساده باشد.
class ProgressStore extends ChangeNotifier {
  ProgressStore(this._prefs, this._content) {
    _load();
  }

  static const _key = 'goshyar.progress.v2';

  final SharedPreferences _prefs;
  final ContentRepository _content;

  String _childName = '';
  int _points = 0;
  int _bestStreak = 0;
  int _streak = 0;
  bool _introSeen = false;
  final Map<String, int> _levelStars = {};
  final Set<String> _badges = {};
  final Map<String, int> _categorySessions = {};
  final Map<String, int> _categoryStars = {};

  String get childName => _childName;
  int get points => _points;
  int get bestStreak => _bestStreak;
  int get streak => _streak;
  bool get introSeen => _introSeen;
  Set<String> get badges => Set.unmodifiable(_badges);
  int get completedCount => _levelStars.length;
  int get totalStars => _levelStars.values.fold(0, (a, b) => a + b) + _categoryStars.values.fold(0, (a, b) => a + b);
  int get rank => 1 + _points ~/ (_content.scoring.pointsPerRank <= 0 ? 1 : _content.scoring.pointsPerRank);

  /// پیشرفت به سمت رتبه‌ی بعد، بین ۰ و ۱.
  double get rankProgress {
    final per = _content.scoring.pointsPerRank <= 0 ? 1 : _content.scoring.pointsPerRank;
    return (_points % per) / per;
  }

  static String levelKey(String modeId, int n) => '$modeId:$n';

  bool isLevelDone(String modeId, int n) => _levelStars.containsKey(levelKey(modeId, n));
  int starsFor(String modeId, int n) => _levelStars[levelKey(modeId, n)] ?? 0;
  int completedInMode(String modeId) => _levelStars.keys.where((k) => k.startsWith('$modeId:')).length;
  int categorySessions(String categoryId) => _categorySessions[categoryId] ?? 0;
  int categoryBestStars(String categoryId) => _categoryStars[categoryId] ?? 0;

  /// مرحله‌ی اول همیشه باز است؛ هر مرحله‌ی بعد با تمام شدن قبلی باز می‌شود.
  bool isLevelUnlocked(GameMode mode, int index) => index == 0 || isLevelDone(mode.id, mode.levels[index - 1].number);

  /// اولین مرحله‌ی تمام‌نشده؛ اگر همه تمام شده‌اند، آخرین مرحله.
  int nextLevelIndex(GameMode mode) {
    for (var i = 0; i < mode.levels.length; i++) {
      if (!isLevelDone(mode.id, mode.levels[i].number)) return i;
    }
    return mode.levels.length - 1;
  }

  Future<void> setChildName(String name) async {
    _childName = name.trim();
    await _save();
  }

  Future<void> markIntroSeen() async {
    if (_introSeen) return;
    _introSeen = true;
    await _save();
  }

  /// هر پاسخ درست زنجیره را یکی بالا می‌برد؛ هر پاسخ اشتباه صفرش می‌کند.
  void registerAnswer(bool correct) {
    if (correct) {
      _streak++;
      if (_streak > _bestStreak) _bestStreak = _streak;
    } else {
      _streak = 0;
    }
  }

  /// ثبت پایان یک مرحله از بازی‌های اصلی. بهترین ستاره‌ی مرحله نگه داشته می‌شود.
  /// خروجی: مدال‌هایی که همین حالا باز شدند.
  Future<List<Achievement>> recordLevel(
    GameMode mode,
    GameLevel level, {
    required int stars,
    required int points,
  }) async {
    final key = levelKey(mode.id, level.number);
    final prev = _levelStars[key] ?? 0;
    if (stars > prev) _levelStars[key] = stars;
    _points += points;
    final fresh = _refreshBadges();
    await _save();
    return fresh;
  }

  /// ثبت پایان یک دور بازی دسته‌ها.
  Future<List<Achievement>> recordCategorySession(String categoryId, {required int stars, required int points}) async {
    _categorySessions[categoryId] = categorySessions(categoryId) + 1;
    if (stars > categoryBestStars(categoryId)) _categoryStars[categoryId] = stars;
    _points += points;
    final fresh = _refreshBadges();
    await _save();
    return fresh;
  }

  /// فقط برای ثبت زنجیره در مدال‌ها، بدون تمام شدن مرحله.
  Future<List<Achievement>> checkBadges() async {
    final fresh = _refreshBadges();
    if (fresh.isNotEmpty) await _save();
    return fresh;
  }

  int _completedInCategory(String categoryId) {
    var n = 0;
    for (final m in _content.modes) {
      for (final l in m.levels) {
        if (isLevelDone(m.id, l.number) && _content.levelCategory(l) == categoryId) n++;
      }
    }
    return n + categorySessions(categoryId);
  }

  bool ruleSatisfied(String rule) {
    final at = rule.indexOf('>=');
    if (at < 0) return false;
    final left = rule.substring(0, at).trim();
    final right = rule.substring(at + 2).trim();
    final need = right == 'all' ? _content.totalLevels : int.tryParse(right);
    if (need == null) return false;
    if (left == 'levels') return completedCount >= need;
    if (left == 'streak') return _bestStreak >= need;
    if (left.startsWith('cat:')) return _completedInCategory(left.substring(4)) >= need;
    if (left.startsWith('mode:')) return completedInMode(left.substring(5)) >= need;
    return false;
  }

  List<Achievement> _refreshBadges() {
    final fresh = <Achievement>[];
    for (final a in _content.achievements) {
      if (!_badges.contains(a.id) && ruleSatisfied(a.rule)) {
        _badges.add(a.id);
        fresh.add(a);
      }
    }
    return fresh;
  }

  Future<void> reset() async {
    _points = 0;
    _bestStreak = 0;
    _streak = 0;
    _levelStars.clear();
    _badges.clear();
    _categorySessions.clear();
    _categoryStars.clear();
    await _save();
  }

  /// داده‌ی نسخه‌ی قدیمی اندروید (SharedPreferences «goshyar_progress») را یک بار وارد می‌کند.
  /// مراحل قدیمی ستاره نداشتند؛ هر مرحله‌ی کامل‌شده ۳ ستاره حساب می‌شود.
  Future<void> importLegacy({
    String? childName,
    int? points,
    int? bestStreak,
    Iterable<String> completedLevels = const [],
    Iterable<String> badges = const [],
  }) async {
    if (childName != null && childName.isNotEmpty && _childName.isEmpty) _childName = childName;
    if (points != null && points > _points) _points = points;
    if (bestStreak != null && bestStreak > _bestStreak) _bestStreak = bestStreak;
    for (final k in completedLevels) {
      if (k.contains(':')) _levelStars.putIfAbsent(k, () => 3);
    }
    _badges.addAll(badges.where((b) => _content.achievements.any((a) => a.id == b)));
    _refreshBadges();
    await _save();
  }

  void _load() {
    final raw = _prefs.getString(_key);
    if (raw == null) return;
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      _childName = (j['name'] ?? '') as String;
      _points = (j['points'] ?? 0) as int;
      _bestStreak = (j['bestStreak'] ?? 0) as int;
      _introSeen = (j['introSeen'] ?? false) as bool;
      _levelStars.addAll(Map<String, int>.from((j['levels'] ?? const {}) as Map));
      _badges.addAll(List<String>.from((j['badges'] ?? const []) as List));
      _categorySessions.addAll(Map<String, int>.from((j['catSessions'] ?? const {}) as Map));
      _categoryStars.addAll(Map<String, int>.from((j['catStars'] ?? const {}) as Map));
    } catch (e) {
      debugPrint('پیشرفت ذخیره‌شده خوانده نشد: $e');
    }
  }

  Future<void> _save() async {
    notifyListeners();
    await _prefs.setString(
      _key,
      jsonEncode({
        'name': _childName,
        'points': _points,
        'bestStreak': _bestStreak,
        'introSeen': _introSeen,
        'levels': _levelStars,
        'badges': _badges.toList(),
        'catSessions': _categorySessions,
        'catStars': _categoryStars,
      }),
    );
  }
}
