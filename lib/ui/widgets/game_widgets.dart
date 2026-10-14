import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/assets/asset_resolver.dart';
import '../../core/design/theme.dart';
import '../../core/design/tokens.dart';
import '../../core/fa.dart';
import 'clay.dart';

/// دکمه‌ی بزرگ پخش صدا با موج‌های تپنده هنگام پخش (مثل دکمه‌ی آبی در تصویر مرجع).
class PlaySoundButton extends StatefulWidget {
  const PlaySoundButton({
    super.key,
    required this.onTap,
    required this.playing,
    this.size = 112,
    this.color = GColors.blue,
    this.label = 'دوباره گوش کن',
  });

  final VoidCallback? onTap;
  final bool playing;
  final double size;
  final Color color;
  final String label;

  @override
  State<PlaySoundButton> createState() => _PlaySoundButtonState();
}

class _PlaySoundButtonState extends State<PlaySoundButton> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));

  @override
  void initState() {
    super.initState();
    if (widget.playing) _c.repeat();
  }

  @override
  void didUpdateWidget(PlaySoundButton old) {
    super.didUpdateWidget(old);
    if (widget.playing && !_c.isAnimating) _c.repeat();
    if (!widget.playing && _c.isAnimating) _c.reset();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    return SizedBox(
      width: s * 1.5,
      height: s * 1.5,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _c,
            builder: (context, _) => CustomPaint(
              size: Size.square(s * 1.5),
              painter: _RipplePainter(widget.playing ? _c.value : -1, widget.color),
            ),
          ),
          Pressable(
            onTap: widget.onTap,
            color: widget.color,
            depth: 7,
            sound: false,
            semanticLabel: widget.label,
            child: Container(
              width: s,
              height: s - 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 5),
              ),
              child: Icon(
                widget.playing ? Icons.graphic_eq_rounded : Icons.volume_up_rounded,
                color: Colors.white,
                size: s * .5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RipplePainter extends CustomPainter {
  _RipplePainter(this.t, this.color);

  final double t;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final base = size.width / 3;
    canvas.drawCircle(c, base * 1.08, Paint()..color = color.withValues(alpha: .14));
    if (t < 0) return;
    for (var i = 0; i < 2; i++) {
      final p = (t + i / 2) % 1;
      canvas.drawCircle(
        c,
        base * (1 + p * .5),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..color = color.withValues(alpha: (1 - p) * .5),
      );
    }
  }

  @override
  bool shouldRepaint(_RipplePainter old) => old.t != t;
}

enum OptionState { idle, active, correct, wrong, dimmed }

/// کارت گزینه با تصویر بزرگ. پاسخ درست: قاب سبز و تیک؛ پاسخ اشتباه: تکان و قاب قرمز.
class OptionCard extends StatefulWidget {
  const OptionCard({
    super.key,
    required this.image,
    required this.title,
    required this.onTap,
    this.state = OptionState.idle,
    this.showTitle = true,
    this.badge,
  });

  final String image;
  final String title;
  final VoidCallback? onTap;
  final OptionState state;
  final bool showTitle;

  /// عدد کوچک گوشه‌ی کارت (برای ترتیب انتخاب در بازی ترتیب صداها).
  final String? badge;

  @override
  State<OptionCard> createState() => _OptionCardState();
}

class _OptionCardState extends State<OptionCard> with SingleTickerProviderStateMixin {
  late final AnimationController _shake = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));

  @override
  void didUpdateWidget(OptionCard old) {
    super.didUpdateWidget(old);
    if (widget.state == OptionState.wrong && old.state != OptionState.wrong) _shake.forward(from: 0);
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final img = context.read<AssetResolver>().image(widget.image);
    final borderColor = switch (widget.state) {
      OptionState.correct => GColors.green,
      OptionState.wrong => GColors.red,
      OptionState.active => GColors.blue,
      _ => Colors.white,
    };
    final card = AnimatedContainer(
      duration: GMotion.quick,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(GRadius.md),
        border: Border.all(color: borderColor, width: 5),
        boxShadow: switch (widget.state) {
          OptionState.correct => GShadow.glow(GColors.green),
          OptionState.active => GShadow.glow(GColors.blue),
          _ => GShadow.soft(),
        },
      ),
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(GRadius.sm),
              // بزرگ‌نمایی جزئی، قاب سفیدی را که روی بعضی تصویرهای قدیمی پخته شده پنهان می‌کند.
              child: Transform.scale(
                scale: 1.06,
                child: img == null
                    ? const ColoredBox(
                        color: GColors.cream,
                        child: Center(child: Icon(Icons.image_rounded, color: GColors.orange, size: 40)),
                      )
                    : Image(image: img, fit: BoxFit.cover, width: double.infinity, filterQuality: FilterQuality.medium),
              ),
            ),
          ),
          if (widget.showTitle)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 4, 6),
              child: Text(
                widget.title,
                style: GText.bodyStrong.copyWith(fontSize: 15),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
    return AnimatedOpacity(
      duration: GMotion.quick,
      opacity: widget.state == OptionState.dimmed ? .45 : 1,
      child: AnimatedBuilder(
        animation: _shake,
        builder: (_, child) =>
            Transform.translate(offset: Offset(sin(_shake.value * pi * 6) * 10 * (1 - _shake.value), 0), child: child),
        child: Semantics(
          button: true,
          label: widget.title,
          child: GestureDetector(
            onTap: widget.onTap,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(child: ExcludeSemantics(child: card)),
                if (widget.state == OptionState.correct)
                  const PositionedDirectional(
                    top: -10,
                    end: -8,
                    child: _Badge(icon: Icons.check_rounded, color: GColors.green),
                  ),
                if (widget.state == OptionState.wrong)
                  const PositionedDirectional(
                    top: -10,
                    end: -8,
                    child: _Badge(icon: Icons.close_rounded, color: GColors.red),
                  ),
                if (widget.badge != null)
                  PositionedDirectional(
                    top: -10,
                    start: -8,
                    child: _Badge(text: widget.badge, color: GColors.purple),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({this.icon, this.text, required this.color});

  final IconData? icon;
  final String? text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: GShadow.soft(color),
      ),
      child: icon != null
          ? Icon(icon, color: Colors.white, size: 22)
          : Text(text!, style: GText.label.copyWith(fontSize: 16)),
    );
  }
}

/// «مرحله ۳ از ۵» با نوار نقطه‌ای.
class StepDots extends StatelessWidget {
  const StepDots({super.key, required this.index, required this.total, this.light = false});

  final int index;
  final int total;
  final bool light;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'مرحله ${faDigits(index + 1)} از ${faDigits(total)}',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < total; i++)
            AnimatedContainer(
              duration: GMotion.medium,
              curve: GMotion.enter,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == index ? 30 : 14,
              height: 14,
              decoration: BoxDecoration(
                color: i < index
                    ? GColors.green
                    : i == index
                    ? GColors.yellow
                    : (light ? Colors.white.withValues(alpha: .5) : GColors.line),
                borderRadius: BorderRadius.circular(GRadius.pill),
              ),
            ),
        ],
      ),
    );
  }
}

/// امتیاز: ستاره‌ی زرد و عدد فارسی.
class ScoreChip extends StatelessWidget {
  const ScoreChip({super.key, required this.points, this.prefix = ''});

  final int points;
  final String prefix;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${faDigits(points)} امتیاز',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: GSpace.sm, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF4CF),
          borderRadius: BorderRadius.circular(GRadius.pill),
          border: Border.all(color: GColors.yellow, width: 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star_rounded, color: GColors.yellowDark, size: 24),
            const SizedBox(width: 4),
            Text(
              '$prefix${faDigits(points)}',
              style: GText.bodyStrong.copyWith(color: GColors.orangeDark, fontSize: 17),
            ),
          ],
        ),
      ),
    );
  }
}

/// ردیف ستاره‌ها؛ ستاره‌های گرفته‌شده یکی‌یکی با جهش ظاهر می‌شوند.
class StarRow extends StatelessWidget {
  const StarRow({super.key, required this.stars, this.size = 56, this.animate = true});

  final int stars;
  final double size;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final still = !animate || MediaQuery.of(context).disableAnimations;
    return Semantics(
      label: '${faDigits(stars)} ستاره از ۳',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 3; i++)
            Padding(
              padding: EdgeInsets.only(bottom: i == 1 ? size * .25 : 0),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: still ? 1 : 0, end: 1),
                duration: Duration(milliseconds: 500 + i * 250),
                curve: Curves.elasticOut,
                builder: (_, v, child) => Transform.scale(scale: i < stars ? v : 1, child: child),
                child: Icon(
                  Icons.star_rounded,
                  size: i == 1 ? size * 1.2 : size,
                  color: i < stars ? GColors.yellow : const Color(0xFFDCD8EA),
                  shadows: i < stars
                      ? const [Shadow(color: Color(0x66E0A100), blurRadius: 8, offset: Offset(0, 3))]
                      : null,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
