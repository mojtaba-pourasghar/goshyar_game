import 'package:flutter/material.dart';

import '../../core/design/theme.dart';
import '../../core/design/tokens.dart';
import 'clay.dart';

/// نوار بالای صفحه: دکمه‌ی بازگشت گرد، عنوان، و یک جزء دلخواه در انتها.
class GTopBar extends StatelessWidget {
  const GTopBar({super.key, this.title, this.onBack, this.trailing, this.light = false, this.backIcon});

  final String? title;
  final VoidCallback? onBack;
  final Widget? trailing;
  final bool light;
  final IconData? backIcon;

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    final back = onBack ?? (canPop ? () => Navigator.of(context).maybePop() : null);
    return Padding(
      padding: const EdgeInsets.fromLTRB(GSpace.gutter - 4, GSpace.xs, GSpace.gutter - 4, GSpace.xs),
      child: Row(
        children: [
          if (back != null)
            ClayIconButton(
              icon: backIcon ?? Icons.arrow_back_rounded,
              label: backIcon == null ? 'بازگشت' : 'توقف',
              onTap: back,
            )
          else
            const SizedBox(width: GTouch.min),
          const SizedBox(width: GSpace.sm),
          Expanded(
            child: title == null
                ? const SizedBox.shrink()
                : Text(
                    title!,
                    style: GText.title.copyWith(color: light ? Colors.white : GColors.purple, fontSize: 22),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
          ),
          const SizedBox(width: GSpace.sm),
          SizedBox(width: trailing == null ? GTouch.min : null, child: trailing),
        ],
      ),
    );
  }
}

/// کاشی رنگی دسته‌ها با آیکون سفید (مثل منوی اصلی در تصویر مرجع).
class CategoryTile extends StatelessWidget {
  const CategoryTile({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      color: color,
      radius: GRadius.lg,
      depth: 7,
      semanticLabel: title,
      child: Stack(
        children: [
          PositionedDirectional(
            end: -18,
            bottom: -18,
            child: Icon(icon, size: 96, color: Colors.white.withValues(alpha: .16)),
          ),
          Padding(
            padding: const EdgeInsets.all(GSpace.sm),
            // در کاشی‌های کوچک (گوشی ۳۲۰ نقطه‌ای) محتوا کوچک می‌شود، نه بریده.
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: .25), shape: BoxShape.circle),
                      child: Icon(icon, color: Colors.white, size: 36),
                    ),
                    const SizedBox(height: GSpace.xs),
                    Text(title, style: GText.label, maxLines: 1, overflow: TextOverflow.ellipsis),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: GText.caption.copyWith(color: Colors.white.withValues(alpha: .9), fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ?trailing,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// لوگوی «گوش‌یار»: نوشته‌ی بنفش با دورگیر سفید و موج صدای زرد.
class GoshyarLogo extends StatelessWidget {
  const GoshyarLogo({super.key, this.size = 56});

  final double size;

  @override
  Widget build(BuildContext context) {
    final style = GText.display.copyWith(fontSize: size, height: 1.1);
    return Semantics(
      label: 'گوش‌یار',
      header: true,
      child: ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SoundBars(height: size * .5),
            Stack(
              children: [
                Text(
                  'گوش‌یار',
                  style: style.copyWith(
                    foreground: Paint()
                      ..style = PaintingStyle.stroke
                      ..strokeWidth = size * .16
                      ..strokeJoin = StrokeJoin.round
                      ..color = Colors.white,
                  ),
                ),
                Text('گوش‌یار', style: style.copyWith(color: GColors.purple)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SoundBars extends StatelessWidget {
  const _SoundBars({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    const hs = [.35, .7, 1.0, .6, .85, .45, .3];
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final h in hs)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 2.5),
            width: height * .16,
            height: height * h,
            decoration: BoxDecoration(
              color: GColors.yellow,
              borderRadius: BorderRadius.circular(height),
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
      ],
    );
  }
}

/// برگه‌ی تأیید ساده با دو دکمه‌ی بزرگ.
Future<bool> confirmSheet(
  BuildContext context, {
  required String title,
  required String message,
  required String confirm,
  Color confirmColor = GColors.red,
}) async {
  final ok = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(GSpace.md),
        child: ClayCard(
          padding: const EdgeInsets.all(GSpace.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: GText.title, textAlign: TextAlign.center),
              const SizedBox(height: GSpace.xs),
              Text(message, style: GText.body, textAlign: TextAlign.center),
              const SizedBox(height: GSpace.lg),
              ClayButton(label: confirm, color: confirmColor, onTap: () => Navigator.pop(context, true)),
              const SizedBox(height: GSpace.sm),
              ClayButton(label: 'نه، برگرد', color: GColors.blue, onTap: () => Navigator.pop(context, false)),
            ],
          ),
        ),
      ),
    ),
  );
  return ok ?? false;
}
