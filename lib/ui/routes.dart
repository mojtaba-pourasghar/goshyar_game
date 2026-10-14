import 'package:flutter/material.dart';

import 'screens/category_screen.dart';
import 'screens/downloads_screen.dart';
import 'screens/game_screen.dart';
import 'screens/home_shell.dart';
import 'screens/intro_screen.dart';
import 'screens/level_map_screen.dart';
import 'screens/library_category_screen.dart';
import 'screens/parent_screens.dart';
import 'screens/result_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/splash_screen.dart';

/// همه‌ی مسیرهای برنامه در یک جا.
abstract final class Routes {
  static const splash = '/';
  static const intro = '/intro';
  static const home = '/home';
  static const category = '/category';
  static const levels = '/levels';
  static const game = '/game';
  static const result = '/result';
  static const library = '/library';
  static const settings = '/settings';
  static const parentGate = '/parent-gate';
  static const parent = '/parent';
  static const downloads = '/downloads';

  static Route<dynamic> generate(RouteSettings s) {
    final Widget page = switch (s.name) {
      splash => const SplashScreen(),
      intro => const IntroScreen(),
      home => HomeShell(initialTab: (s.arguments as int?) ?? 0),
      category => CategoryScreen(categoryId: s.arguments! as String),
      levels => LevelMapScreen(modeId: s.arguments! as String),
      game => GameScreen(args: s.arguments! as GameArgs),
      result => ResultScreen(args: s.arguments! as ResultArgs),
      library => LibraryCategoryScreen(categoryId: s.arguments! as String),
      settings => const SettingsScreen(),
      parentGate => const ParentGateScreen(),
      parent => const ParentDashboardScreen(),
      downloads => const DownloadsScreen(),
      _ => const HomeShell(),
    };
    return MaterialPageRoute(builder: (_) => page, settings: s);
  }
}
