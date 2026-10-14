import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// سه کانال صوتی مستقل: گوینده، افکت‌ها (صدای بازی و بازخورد)، موسیقی پس‌زمینه.
enum AudioChannel { voice, effects, music }

class SettingsStore extends ChangeNotifier {
  SettingsStore(this._prefs);

  final SharedPreferences _prefs;

  static String _onKey(AudioChannel c) => 'goshyar.audio.${c.name}.on';
  static String _volKey(AudioChannel c) => 'goshyar.audio.${c.name}.volume';
  static const _subtitlesKey = 'goshyar.subtitles';

  static const _defaultVolume = {AudioChannel.voice: 1.0, AudioChannel.effects: 0.9, AudioChannel.music: 0.35};

  bool isOn(AudioChannel c) => _prefs.getBool(_onKey(c)) ?? true;
  double volume(AudioChannel c) => _prefs.getDouble(_volKey(c)) ?? _defaultVolume[c]!;

  /// بلندی مؤثر: اگر کانال خاموش باشد صفر.
  double effectiveVolume(AudioChannel c) => isOn(c) ? volume(c) : 0;

  /// زیرنویس حرف‌های گوش‌یار در حباب گفت‌وگو؛ تا صدای ضبط‌شده نیامده ضروری است.
  bool get subtitles => _prefs.getBool(_subtitlesKey) ?? true;

  Future<void> setOn(AudioChannel c, bool on) async {
    await _prefs.setBool(_onKey(c), on);
    notifyListeners();
  }

  Future<void> setVolume(AudioChannel c, double v) async {
    await _prefs.setDouble(_volKey(c), v.clamp(0.0, 1.0));
    notifyListeners();
  }

  Future<void> setSubtitles(bool on) async {
    await _prefs.setBool(_subtitlesKey, on);
    notifyListeners();
  }
}
