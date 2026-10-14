import 'package:flutter/material.dart';

/// رنگ‌های گوش‌یار، برگرفته از تصویر مرجع: بنفش عمیق برای عنوان‌ها و دکمه‌های اصلی،
/// نارنجی گرم خرس، آبی هدفون، و رنگ‌های شاد کارت‌ها روی آسمان روشن.
abstract final class GColors {
  static const purple = Color(0xFF5B2BC4);
  static const purpleDark = Color(0xFF41189A);
  static const purpleSoft = Color(0xFFEDE6FF);

  static const orange = Color(0xFFFF8A1F);
  static const orangeDark = Color(0xFFD96A00);
  static const yellow = Color(0xFFFFC83D);
  static const yellowDark = Color(0xFFE0A100);

  static const blue = Color(0xFF3B82F6);
  static const blueDark = Color(0xFF2257C9);
  static const sky = Color(0xFFE8F3FF);
  static const skyDeep = Color(0xFFBFE0FF);

  static const green = Color(0xFF2FBF71);
  static const greenDark = Color(0xFF1E9354);
  static const red = Color(0xFFF0524F);
  static const redDark = Color(0xFFC63633);
  static const pink = Color(0xFFE9478F);

  static const ink = Color(0xFF2A2250);
  static const inkSoft = Color(0xFF5E5A7A);
  static const card = Colors.white;
  static const line = Color(0xFFE6E3F3);
  static const cream = Color(0xFFFFF7E8);

  /// رنگ تیره‌تر برای لبه‌ی سه‌بعدی دکمه‌ها و کارت‌های رنگی.
  static Color shade(Color c, [double amount = .18]) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
  }

  static Color tint(Color c, [double amount = .38]) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0)).toColor();
  }

  static Color fromHex(String hex) {
    final h = hex.replaceFirst('#', '');
    return Color(int.parse(h.length == 6 ? 'FF$h' : h, radix: 16));
  }
}

abstract final class GSpace {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;

  /// فاصله‌ی کناری صفحه‌ها.
  static const gutter = 20.0;
}

abstract final class GRadius {
  static const sm = 14.0;
  static const md = 20.0;
  static const lg = 28.0;
  static const xl = 36.0;
  static const pill = 999.0;
}

/// اندازه‌های لمسی: کودکان ۳ تا ۸ سال دقت انگشت کمتری دارند، پس از حداقل ۴۸ بزرگ‌تر است.
abstract final class GTouch {
  static const min = 56.0;
  static const button = 64.0;
  static const bigButton = 76.0;
}

abstract final class GMotion {
  static const tap = Duration(milliseconds: 120);
  static const quick = Duration(milliseconds: 220);
  static const medium = Duration(milliseconds: 380);
  static const slow = Duration(milliseconds: 650);
  static const bounce = Curves.elasticOut;
  static const enter = Curves.easeOutCubic;
  static const exit = Curves.easeInCubic;
}

abstract final class GShadow {
  /// سایه‌ی نرم کارت‌ها (سبک Claymorphism: سایه‌ی پهن و کم‌رنگ).
  static List<BoxShadow> soft([Color tint = const Color(0xFF4B3C9E)]) => [
    BoxShadow(color: tint.withValues(alpha: .10), blurRadius: 18, offset: const Offset(0, 8)),
    BoxShadow(color: tint.withValues(alpha: .06), blurRadius: 4, offset: const Offset(0, 2)),
  ];

  static List<BoxShadow> glow(Color c) => [BoxShadow(color: c.withValues(alpha: .45), blurRadius: 22, spreadRadius: 2)];
}
