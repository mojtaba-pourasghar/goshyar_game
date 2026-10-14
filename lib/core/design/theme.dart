import 'package:flutter/material.dart';

import 'tokens.dart';

/// سبک‌های متن؛ اندازه‌ها برای کودک کمی درشت‌تر از معمول‌اند و هیچ متنی زیر ۱۴ نیست.
abstract final class GText {
  static const family = 'Vazirmatn';

  static const display = TextStyle(
    fontFamily: family,
    fontSize: 34,
    fontWeight: FontWeight.w900,
    color: GColors.purple,
    height: 1.25,
  );
  static const title = TextStyle(
    fontFamily: family,
    fontSize: 24,
    fontWeight: FontWeight.w800,
    color: GColors.ink,
    height: 1.35,
  );
  static const heading = TextStyle(
    fontFamily: family,
    fontSize: 19,
    fontWeight: FontWeight.w800,
    color: GColors.ink,
    height: 1.4,
  );
  static const body = TextStyle(
    fontFamily: family,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: GColors.ink,
    height: 1.6,
  );
  static const bodyStrong = TextStyle(
    fontFamily: family,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: GColors.ink,
    height: 1.5,
  );
  static const caption = TextStyle(
    fontFamily: family,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: GColors.inkSoft,
    height: 1.5,
  );
  static const button = TextStyle(
    fontFamily: family,
    fontSize: 20,
    fontWeight: FontWeight.w800,
    color: Colors.white,
    height: 1.2,
  );
  static const label = TextStyle(
    fontFamily: family,
    fontSize: 17,
    fontWeight: FontWeight.w800,
    color: Colors.white,
    height: 1.3,
  );
}

ThemeData buildGoshyarTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: GColors.purple,
    primary: GColors.purple,
    secondary: GColors.orange,
    surface: GColors.sky,
    error: GColors.red,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: GText.family,
    scaffoldBackgroundColor: GColors.sky,
    textTheme: const TextTheme(
      displaySmall: GText.display,
      titleLarge: GText.title,
      titleMedium: GText.heading,
      bodyLarge: GText.body,
      bodyMedium: GText.body,
      labelLarge: GText.bodyStrong,
      bodySmall: GText.caption,
    ),
    splashFactory: InkSparkle.splashFactory,
    sliderTheme: const SliderThemeData(
      trackHeight: 10,
      thumbShape: RoundSliderThumbShape(enabledThumbRadius: 14),
      overlayShape: RoundSliderOverlayShape(overlayRadius: 26),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.all(Colors.white),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? GColors.green : GColors.line,
      ),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {TargetPlatform.android: FadeForwardsPageTransitionsBuilder()},
    ),
  );
}
