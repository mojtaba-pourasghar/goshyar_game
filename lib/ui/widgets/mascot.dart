import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/assets/asset_resolver.dart';
import '../../core/audio/game_audio.dart';
import '../../core/design/theme.dart';
import '../../core/design/tokens.dart';
import '../../data/models.dart';
import '../../data/settings_store.dart';

enum MascotPose { listening, wave, celebrate, think, cheer }

/// گوش‌یار: خرس نارنجی با هدفون و هودی آبی. با حرکت آرام بالا و پایین «زنده» است؛
/// اگر کاربر کاهش حرکت را در گوشی روشن کرده باشد، ثابت می‌ماند.
class Mascot extends StatefulWidget {
  const Mascot({super.key, this.pose = MascotPose.wave, this.size = 180, this.bounce = true});

  final MascotPose pose;
  final double size;
  final bool bounce;

  @override
  State<Mascot> createState() => _MascotState();
}

class _MascotState extends State<Mascot> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))
    ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  String get _path =>
      'images/mascot/bear_${switch (widget.pose) {
        MascotPose.listening => 'listening',
        MascotPose.wave => 'wave',
        MascotPose.celebrate => 'celebrate',
        MascotPose.think => 'think',
        MascotPose.cheer => 'cheer',
      }}.webp';

  @override
  Widget build(BuildContext context) {
    final img = context.read<AssetResolver>().image(_path);
    final still = !widget.bounce || MediaQuery.of(context).disableAnimations;
    final picture = AnimatedSwitcher(
      duration: GMotion.quick,
      transitionBuilder: (child, a) => ScaleTransition(scale: Tween(begin: .9, end: 1.0).animate(a), child: child),
      child: img == null
          ? Icon(Icons.pets_rounded, key: ValueKey(widget.pose), size: widget.size * .6, color: GColors.orange)
          : Image(
              key: ValueKey(widget.pose),
              image: img,
              width: widget.size,
              height: widget.size,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
            ),
    );
    return Semantics(
      label: 'گوش‌یار، خرس مهربان',
      image: true,
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: still
            ? picture
            : AnimatedBuilder(
                animation: _c,
                builder: (_, child) {
                  final t = _c.value * 2 * pi;
                  return Transform.translate(
                    offset: Offset(0, sin(t) * widget.size * .025),
                    child: Transform.rotate(angle: sin(t + pi / 3) * .025, child: child),
                  );
                },
                child: picture,
              ),
      ),
    );
  }
}

/// حباب گفت‌وگوی گوش‌یار: همان جمله‌ای که گوینده می‌گوید را نشان می‌دهد.
/// تا وقتی صدای ضبط‌شده نیامده، تنها راه رساندن پیام است؛ برای والدین هم مفید است.
class SpeechBubble extends StatelessWidget {
  const SpeechBubble({super.key, this.fallback, this.maxWidth = 340, this.borderColor = GColors.purpleSoft});

  /// متنی که وقتی گوش‌یار ساکت است نشان داده شود (مثلاً پرسش مرحله).
  final String? fallback;
  final double maxWidth;

  /// رنگ قاب؛ پس از پاسخ اشتباه نارنجی می‌شود.
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final show = context.select<SettingsStore, bool>((s) => s.subtitles);
    return ValueListenableBuilder<VoiceLine?>(
      valueListenable: context.read<GameAudio>().caption,
      builder: (context, line, _) {
        final text = line?.text ?? fallback;
        final visible = show && text != null && text.isNotEmpty;
        return AnimatedSwitcher(
          duration: GMotion.quick,
          transitionBuilder: (c, a) => FadeTransition(
            opacity: a,
            child: ScaleTransition(scale: Tween(begin: .92, end: 1.0).animate(a), child: c),
          ),
          child: !visible
              ? const SizedBox.shrink()
              : Container(
                  key: ValueKey(text),
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  padding: const EdgeInsets.symmetric(horizontal: GSpace.md, vertical: GSpace.sm),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(GRadius.md),
                    border: Border.all(color: borderColor, width: 2.5),
                    boxShadow: GShadow.soft(),
                  ),
                  child: Semantics(
                    liveRegion: true,
                    child: Text(text, style: GText.bodyStrong, textAlign: TextAlign.center),
                  ),
                ),
        );
      },
    );
  }
}
