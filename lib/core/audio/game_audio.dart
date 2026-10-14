import 'package:flutter/foundation.dart';

import '../../data/models.dart';

/// رابط پخش صدا. صفحه‌ها فقط با همین رابط کار می‌کنند تا پیاده‌سازی واقعی
/// (just_audio) در تست‌ها با نسخه‌ی بی‌صدا جایگزین شود.
abstract class GameAudio {
  /// جمله‌ای که گوش‌یار همین حالا می‌گوید؛ برای حباب زیرنویس.
  ValueListenable<VoiceLine?> get caption;

  /// پخش یک جمله‌ی گوینده. وقتی تمام شد (یا فایلش نبود و زمان خواندن زیرنویس گذشت) کامل می‌شود.
  Future<void> say(VoiceLine? line);

  /// پخش یک صدای بازی (حیوان، وسیله...). هر صدای بازی قبلی را قطع می‌کند.
  Future<void> playSound(String logicalPath);

  /// چند صدا پشت سر هم با فاصله، برای «ترتیب صداها».
  Future<void> playSequence(List<String> logicalPaths, {Duration gap = const Duration(milliseconds: 450)});

  /// چند صدا روی هم، با شروع پلکانی، برای «مأموریت شنیداری».
  Future<void> playLayered(List<String> logicalPaths, {Duration stagger = const Duration(milliseconds: 700)});

  void uiTap();
  void uiSuccess();
  void uiFail();

  /// موسیقی پس‌زمینه‌ی حلقه‌ای؛ اگر فایلش نباشد کاری نمی‌کند.
  void startMusic(String logicalPath);
  void stopMusic();

  /// گوینده و صداهای بازی را فوراً قطع می‌کند و زنجیره‌های در جریان را باطل می‌کند.
  /// موسیقی را قطع نمی‌کند.
  void stopAll();

  void dispose();
}

/// پیاده‌سازی بی‌صدا برای تست‌ها: هیچ صدایی پخش نمی‌کند ولی زیرنویس را به‌روز می‌کند.
class SilentAudio implements GameAudio {
  final _caption = ValueNotifier<VoiceLine?>(null);
  final List<String> log = [];

  @override
  ValueListenable<VoiceLine?> get caption => _caption;

  @override
  Future<void> say(VoiceLine? line) async {
    if (line == null) return;
    log.add('say:${line.id}');
    _caption.value = line;
  }

  @override
  Future<void> playSound(String logicalPath) async => log.add('sound:$logicalPath');

  @override
  Future<void> playSequence(List<String> logicalPaths, {Duration gap = Duration.zero}) async =>
      log.add('sequence:${logicalPaths.length}');

  @override
  Future<void> playLayered(List<String> logicalPaths, {Duration stagger = Duration.zero}) async =>
      log.add('layered:${logicalPaths.length}');

  @override
  void uiTap() => log.add('ui:tap');
  @override
  void uiSuccess() => log.add('ui:success');
  @override
  void uiFail() => log.add('ui:fail');
  @override
  void startMusic(String logicalPath) => log.add('music:$logicalPath');
  @override
  void stopMusic() => log.add('music:stop');
  @override
  void stopAll() {
    log.add('stopAll');
    _caption.value = null;
  }

  @override
  void dispose() => _caption.dispose();
}
