import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:just_audio/just_audio.dart';

import '../../data/models.dart';
import '../../data/settings_store.dart';
import '../assets/asset_resolver.dart';
import 'game_audio.dart';

/// پخش واقعی صدا با just_audio، با کانال‌های جدا:
///   گوینده ← voice      صدای بازی و صداهای رابط ← effects      موسیقی ← music
///
/// هم‌پوشانی ناخواسته با «نسل» (generation) کنترل می‌شود: هر stopAll شماره‌ی نسل را
/// بالا می‌برد و هر زنجیره‌ی پخشی که بعد از یک await ببیند نسلش عوض شده، ادامه نمی‌دهد.
class JustAudioService with WidgetsBindingObserver implements GameAudio {
  JustAudioService(this._assets, this._settings) {
    _settings.addListener(_applySettings);
    WidgetsBinding.instance.addObserver(this);
  }

  final AssetResolver _assets;
  final SettingsStore _settings;

  final _voice = AudioPlayer();
  final _effect = AudioPlayer();
  final _ui = AudioPlayer();
  final _music = AudioPlayer();
  final List<AudioPlayer> _layers = [];

  final _caption = ValueNotifier<VoiceLine?>(null);
  int _gen = 0;
  String? _musicTrack;
  bool _ducked = false;

  @override
  ValueListenable<VoiceLine?> get caption => _caption;

  double _vol(AudioChannel c) => _settings.effectiveVolume(c);

  Future<bool> _load(AudioPlayer p, String logicalPath) async {
    final r = _assets.resolve(logicalPath);
    if (r == null) return false;
    try {
      if (r.source == AssetSource.bundled) {
        await p.setAsset(r.key);
      } else {
        await p.setFilePath(r.key);
      }
      return true;
    } catch (e) {
      debugPrint('بارگذاری صدا شکست خورد ($logicalPath): $e');
      return false;
    }
  }

  /// play() در just_audio وقتی صدا تمام یا متوقف شود کامل می‌شود.
  Future<void> _playToEnd(AudioPlayer p, String logicalPath, double volume, int gen) async {
    if (volume <= 0 || gen != _gen) return;
    if (!await _load(p, logicalPath) || gen != _gen) return;
    try {
      await p.setVolume(volume);
      await p.play();
    } catch (e) {
      debugPrint('پخش صدا شکست خورد ($logicalPath): $e');
    }
  }

  @override
  Future<void> say(VoiceLine? line) async {
    if (line == null) return;
    final gen = _gen;
    await _voice.stop();
    if (line.delayMs > 0) {
      await Future<void>.delayed(Duration(milliseconds: line.delayMs));
      if (gen != _gen) return;
    }
    _caption.value = line;
    final path = 'audio/${line.file}';
    final canPlay = _vol(AudioChannel.voice) > 0 && _assets.exists(path);
    if (canPlay) {
      _duck(true);
      await _playToEnd(_voice, path, _vol(AudioChannel.voice), gen);
      _duck(false);
    } else {
      // هنوز صدای ضبط‌شده نیست (یا گوینده خاموش است): زمانی شبیه به خواندن جمله صبر می‌کنیم
      // تا ریتم بازی طبیعی بماند و کودک زیرنویس را ببیند.
      final ms = min(2600, max(1300, line.text.length * 55));
      await Future<void>.delayed(Duration(milliseconds: ms));
    }
    if (gen == _gen && identical(_caption.value, line)) _caption.value = null;
  }

  @override
  Future<void> playSound(String logicalPath) async {
    final gen = _gen;
    await _effect.stop();
    await _playToEnd(_effect, logicalPath, _vol(AudioChannel.effects), gen);
  }

  @override
  Future<void> playSequence(List<String> logicalPaths, {Duration gap = const Duration(milliseconds: 450)}) async {
    final gen = _gen;
    for (var i = 0; i < logicalPaths.length; i++) {
      if (gen != _gen) return;
      await _effect.stop();
      await _playToEnd(_effect, logicalPaths[i], _vol(AudioChannel.effects), gen);
      if (i < logicalPaths.length - 1) await Future<void>.delayed(gap);
    }
  }

  @override
  Future<void> playLayered(List<String> logicalPaths, {Duration stagger = const Duration(milliseconds: 700)}) async {
    final gen = _gen;
    while (_layers.length < logicalPaths.length) {
      _layers.add(AudioPlayer());
    }
    final runs = <Future<void>>[];
    for (var i = 0; i < logicalPaths.length; i++) {
      if (gen != _gen) break;
      runs.add(_playToEnd(_layers[i], logicalPaths[i], _vol(AudioChannel.effects) * .85, gen));
      await Future<void>.delayed(stagger);
    }
    await Future.wait(runs);
  }

  void _playUi(String name) {
    final v = _vol(AudioChannel.effects);
    if (v <= 0) return;
    () async {
      try {
        await _ui.stop();
        if (await _load(_ui, 'audio/ui/$name.mp3')) {
          await _ui.setVolume(v * .8);
          await _ui.play();
        }
      } catch (_) {}
    }();
  }

  @override
  void uiTap() => _playUi('tap');
  @override
  void uiSuccess() => _playUi('success');
  @override
  void uiFail() => _playUi('fail');

  @override
  void startMusic(String logicalPath) {
    if (_musicTrack == logicalPath && _music.playing) return;
    _musicTrack = logicalPath;
    _restartMusic();
  }

  Future<void> _restartMusic() async {
    final track = _musicTrack;
    await _music.stop();
    if (track == null || _vol(AudioChannel.music) <= 0) return;
    if (!await _load(_music, track)) return;
    await _music.setLoopMode(LoopMode.one);
    await _music.setVolume(_musicVolume);
    unawaited(_music.play());
  }

  double get _musicVolume => _vol(AudioChannel.music) * (_ducked ? .35 : 1);

  void _duck(bool on) {
    _ducked = on;
    if (_music.playing) _music.setVolume(_musicVolume);
  }

  @override
  void stopMusic() {
    _musicTrack = null;
    _music.stop();
  }

  @override
  void stopAll() {
    _gen++;
    _caption.value = null;
    _voice.stop();
    _effect.stop();
    for (final p in _layers) {
      p.stop();
    }
    _duck(false);
  }

  void _applySettings() {
    if (_vol(AudioChannel.voice) <= 0) _voice.stop();
    if (_vol(AudioChannel.effects) <= 0) {
      _effect.stop();
      for (final p in _layers) {
        p.stop();
      }
    }
    if (_vol(AudioChannel.music) <= 0) {
      _music.stop();
    } else if (_musicTrack != null && !_music.playing) {
      _restartMusic();
    } else {
      _music.setVolume(_musicVolume);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        stopAll();
        _music.pause();
      case AppLifecycleState.resumed:
        if (_musicTrack != null && _vol(AudioChannel.music) > 0) _music.play();
      case AppLifecycleState.inactive:
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _settings.removeListener(_applySettings);
    for (final p in [_voice, _effect, _ui, _music, ..._layers]) {
      p.dispose();
    }
    _caption.dispose();
  }
}
