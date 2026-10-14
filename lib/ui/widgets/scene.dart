import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/assets/asset_resolver.dart';

/// پس‌زمینه‌ی متناسب با هر بازی. صحنه‌های طبیعت (چمنزار، جنگل روز، جنگل شب) برداری
/// نقاشی می‌شوند تا در هر اندازه‌ی صفحه تیز بمانند؛ مزرعه، خانه و شهر تصویرند.
class SceneBackground extends StatelessWidget {
  const SceneBackground({super.key, required this.scene, this.child, this.dim = 0});

  /// meadow ، forest_day ، forest_night ، farm ، home ، city
  final String scene;
  final Widget? child;

  /// تیرگی روی تصویر تا متن و دکمه‌ها خوانا بمانند (۰ تا ۱).
  final double dim;

  static bool isDark(String scene) => scene == 'forest_night';

  @override
  Widget build(BuildContext context) {
    final img = switch (scene) {
      'farm' || 'home' || 'city' => context.read<AssetResolver>().image('images/scenes/$scene.webp'),
      _ => null,
    };
    return Stack(
      fit: StackFit.expand,
      children: [
        if (img != null)
          Image(image: img, fit: BoxFit.cover, filterQuality: FilterQuality.medium)
        else
          RepaintBoundary(child: CustomPaint(painter: _NaturePainter(scene))),
        if (dim > 0) ColoredBox(color: Colors.black.withValues(alpha: dim)),
        ?child,
      ],
    );
  }
}

class _NaturePainter extends CustomPainter {
  _NaturePainter(this.scene);

  final String scene;

  bool get night => scene == 'forest_night';
  bool get forest => scene != 'meadow';

  @override
  void paint(Canvas canvas, Size s) {
    final sky = night
        ? const [Color(0xFF1B2470), Color(0xFF3549B8), Color(0xFF4F6BD8)]
        : const [Color(0xFF7CC8FF), Color(0xFFB9E3FF), Color(0xFFE8F6FF)];
    canvas.drawRect(
      Offset.zero & s,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: sky,
        ).createShader(Offset.zero & s),
    );

    final rnd = Random(7);
    if (night) {
      final star = Paint()..color = Colors.white.withValues(alpha: .85);
      for (var i = 0; i < 40; i++) {
        canvas.drawCircle(
          Offset(rnd.nextDouble() * s.width, rnd.nextDouble() * s.height * .5),
          rnd.nextDouble() * 1.8 + .6,
          star,
        );
      }
      final moonC = Offset(s.width * .2, s.height * .12);
      final r = s.shortestSide * .085;
      canvas.drawCircle(moonC, r * 1.8, Paint()..color = const Color(0x33FFF3B0));
      canvas.drawCircle(moonC, r, Paint()..color = const Color(0xFFFFE27A));
      canvas.drawCircle(moonC + Offset(r * .45, -r * .2), r * .85, Paint()..color = const Color(0xFF26318A));
    } else {
      final sunC = Offset(s.width * .13, s.height * .25);
      final r = s.shortestSide * .08;
      canvas.drawCircle(sunC, r * 1.9, Paint()..color = const Color(0x40FFE27A));
      canvas.drawCircle(sunC, r, Paint()..color = const Color(0xFFFFD54A));
      _cloud(canvas, Offset(s.width * .42, s.height * .08), s.width * .13);
      _cloud(canvas, Offset(s.width * .88, s.height * .16), s.width * .09);
      _cloud(canvas, Offset(s.width * .35, s.height * .24), s.width * .07);
    }

    final hillFar = night ? const Color(0xFF223C8C) : const Color(0xFF9EDB7A);
    final hillNear = night ? const Color(0xFF1C2F6E) : const Color(0xFF6CC75A);
    final ground = night ? const Color(0xFF172760) : const Color(0xFF55B84A);
    _hill(canvas, s, s.height * .62, s.height * .08, hillFar, 0.0);
    if (forest) {
      for (var i = 0; i < 7; i++) {
        final x = s.width * (i / 6) + (rnd.nextDouble() - .5) * 30;
        _tree(canvas, Offset(x, s.height * .66), s.shortestSide * (.16 + rnd.nextDouble() * .06), night, far: true);
      }
    }
    _hill(canvas, s, s.height * .72, s.height * .06, hillNear, 1.7);
    canvas.drawRect(Rect.fromLTWH(0, s.height * .8, s.width, s.height * .2), Paint()..color = ground);
    if (forest) {
      _tree(canvas, Offset(s.width * .06, s.height * .86), s.shortestSide * .32, night);
      _tree(canvas, Offset(s.width * .95, s.height * .84), s.shortestSide * .36, night);
    }
    final bush = night ? const Color(0xFF1F3A7A) : const Color(0xFF43A83B);
    for (var i = 0; i < 6; i++) {
      final x = rnd.nextDouble() * s.width;
      final y = s.height * (.84 + rnd.nextDouble() * .12);
      final w = s.shortestSide * (.05 + rnd.nextDouble() * .04);
      canvas.drawOval(Rect.fromCenter(center: Offset(x, y), width: w * 2.2, height: w * 1.3), Paint()..color = bush);
    }
    if (!night) {
      final flower = [const Color(0xFFFF7BAC), const Color(0xFFFFD54A), Colors.white];
      for (var i = 0; i < 18; i++) {
        canvas.drawCircle(
          Offset(rnd.nextDouble() * s.width, s.height * (.83 + rnd.nextDouble() * .16)),
          3,
          Paint()..color = flower[i % 3],
        );
      }
    }
  }

  void _cloud(Canvas c, Offset o, double w) {
    final p = Paint()..color = Colors.white.withValues(alpha: .92);
    c.drawCircle(o, w * .32, p);
    c.drawCircle(o + Offset(w * .32, w * .08), w * .26, p);
    c.drawCircle(o - Offset(w * .32, -w * .1), w * .22, p);
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: o + Offset(0, w * .18), width: w * 1.25, height: w * .32),
        Radius.circular(w),
      ),
      p,
    );
  }

  void _hill(Canvas c, Size s, double y, double amp, Color color, double phase) {
    final path = Path()..moveTo(0, s.height);
    for (var x = 0.0; x <= s.width; x += 8) {
      path.lineTo(x, y + sin(x / s.width * pi * 2 + phase) * amp);
    }
    path
      ..lineTo(s.width, s.height)
      ..close();
    c.drawPath(path, Paint()..color = color);
  }

  void _tree(Canvas c, Offset base, double h, bool night, {bool far = false}) {
    final trunk = night ? const Color(0xFF3B2A5E) : const Color(0xFF8A5A33);
    final leaf = night
        ? (far ? const Color(0xFF2A4A9A) : const Color(0xFF233F86))
        : (far ? const Color(0xFF5DBB55) : const Color(0xFF3FA347));
    final leafLight = night ? const Color(0xFF34589F) : const Color(0xFF6FD064);
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(base.dx - h * .06, base.dy - h * .55, h * .12, h * .55),
        Radius.circular(h * .04),
      ),
      Paint()..color = trunk,
    );
    final top = base - Offset(0, h * .7);
    final p = Paint()..color = leaf;
    c.drawCircle(top, h * .3, p);
    c.drawCircle(top + Offset(-h * .22, h * .12), h * .22, p);
    c.drawCircle(top + Offset(h * .22, h * .12), h * .22, p);
    c.drawCircle(top + Offset(-h * .08, -h * .1), h * .12, Paint()..color = leafLight);
  }

  @override
  bool shouldRepaint(_NaturePainter old) => old.scene != scene;
}
