import '../data/content_repository.dart';
import 'audio/game_audio.dart';

/// پل بین شناسه‌ی جمله‌ها (voice_lines.json) و پخش‌کننده.
/// صفحه‌ها فقط شناسه یا نام گروه می‌دهند؛ متن و فایل از محتوا می‌آید.
class Narrator {
  Narrator(this.content, this.audio);

  final ContentRepository content;
  final GameAudio audio;

  Future<void> say(String? id) => id == null ? Future.value() : audio.say(content.voice(id));

  /// یک جمله‌ی تصادفی از گروه، بدون تکرار پشت سر هم.
  Future<void> sayOneOf(String group) => audio.say(content.pick(group));
}
