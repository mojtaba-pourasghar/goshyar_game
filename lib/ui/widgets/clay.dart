import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/audio/game_audio.dart';
import '../../core/design/theme.dart';
import '../../core/design/tokens.dart';

/// لمس‌پذیر سه‌بعدی: با فشار، کمی پایین می‌رود و لبه‌ی تیره‌ی زیرش کوتاه می‌شود.
/// صدای لمس و لرزش کوتاه دارد. تمام دکمه‌ها و کارت‌های رنگی از همین ساخته می‌شوند.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    required this.onTap,
    this.color = GColors.purple,
    this.radius = GRadius.pill,
    this.depth = 6,
    this.semanticLabel,
    this.sound = true,
    this.padding = EdgeInsets.zero,
    this.gradient = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final Color color;
  final double radius;
  final double depth;
  final String? semanticLabel;
  final bool sound;
  final EdgeInsets padding;
  final bool gradient;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final base = enabled ? widget.color : Color.lerp(widget.color, const Color(0xFFBDBACB), .7)!;
    final edge = GColors.shade(base, .16);
    final depth = _down ? widget.depth * .3 : widget.depth;
    final r = BorderRadius.circular(widget.radius);
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => _set(true) : null,
        onTapCancel: () => _set(false),
        onTapUp: enabled ? (_) => _set(false) : null,
        onTap: enabled
            ? () {
                HapticFeedback.lightImpact();
                if (widget.sound) context.read<GameAudio>().uiTap();
                widget.onTap!();
              }
            : null,
        child: AnimatedContainer(
          duration: GMotion.tap,
          curve: Curves.easeOut,
          margin: EdgeInsets.only(top: widget.depth - depth),
          decoration: BoxDecoration(color: edge, borderRadius: r, boxShadow: _down ? null : GShadow.soft(edge)),
          padding: EdgeInsets.only(bottom: depth),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: r,
              color: base,
              gradient: widget.gradient
                  ? LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [GColors.tint(base, .08), base],
                    )
                  : null,
            ),
            padding: widget.padding,
            // برچسب معنایی جای متن داخل را می‌گیرد تا صفحه‌خوان آن را دو بار نخواند.
            child: widget.semanticLabel == null ? widget.child : ExcludeSemantics(child: widget.child),
          ),
        ),
      ),
    );
  }
}

/// دکمه‌ی اصلی گرد و بزرگ (مثل «شروع بازی» و «مرحله بعد» در تصویر مرجع).
class ClayButton extends StatelessWidget {
  const ClayButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.color = GColors.purple,
    this.big = false,
    this.expand = true,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final Color color;
  final bool big;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final h = big ? GTouch.bigButton : GTouch.button;
    final content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[Icon(icon, color: Colors.white, size: big ? 30 : 26), const SizedBox(width: GSpace.xs)],
        Flexible(
          child: Text(
            label,
            style: big ? GText.button.copyWith(fontSize: 23) : GText.button,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
    return Pressable(
      onTap: onTap,
      color: color,
      semanticLabel: label,
      padding: const EdgeInsets.symmetric(horizontal: GSpace.lg),
      child: SizedBox(height: h - 6, child: content),
    );
  }
}

/// دکمه‌ی گرد آیکونی (بازگشت، تنظیمات، توقف). برچسب معنایی اجباری است.
class ClayIconButton extends StatelessWidget {
  const ClayIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = Colors.white,
    this.iconColor = GColors.purple,
    this.size = GTouch.min,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color color;
  final Color iconColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: Pressable(
        onTap: onTap,
        color: color,
        depth: 4,
        semanticLabel: label,
        gradient: false,
        child: SizedBox(
          width: size,
          height: size - 4,
          child: Icon(icon, color: iconColor, size: size * .5),
        ),
      ),
    );
  }
}

/// کارت سفید با گوشه‌ی گرد و سایه‌ی نرم.
class ClayCard extends StatelessWidget {
  const ClayCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(GSpace.md),
    this.color = GColors.card,
    this.radius = GRadius.lg,
    this.border,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color color;
  final double radius;
  final Color? border;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: border == null ? null : Border.all(color: border!, width: 3),
        boxShadow: GShadow.soft(),
      ),
      child: child,
    );
  }
}

/// برچسب عنوان بنفش (مثل «ویژگی‌های کلیدی» در تصویر مرجع).
class SectionPill extends StatelessWidget {
  const SectionPill(this.text, {super.key, this.color = GColors.purple});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: GSpace.md, vertical: GSpace.xs - 2),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(GRadius.pill)),
      child: Text(text, style: GText.label.copyWith(fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }
}
