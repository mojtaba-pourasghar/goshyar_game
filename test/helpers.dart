import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:goshyar/data/content_repository.dart';

/// فونت واقعی برنامه را در تست بارگذاری می‌کند تا اندازه‌ی متن‌ها و آزمون سرریز واقعی باشد
/// (فونت پیش‌فرض تست هر حرف را یک مربع کامل می‌کشد).
Future<void> loadAppFonts() async {
  final loader = FontLoader('Vazirmatn');
  for (final w in ['Regular', 'Medium', 'Bold', 'ExtraBold', 'Black']) {
    final bytes = File('assets/fonts/Vazirmatn-$w.ttf').readAsBytesSync();
    loader.addFont(Future.value(ByteData.view(bytes.buffer)));
  }
  await loader.load();
}

/// محتوای واقعی بازی را مستقیم از فایل‌ها می‌خواند (بدون AssetBundle).
ContentRepository loadContent() {
  final levels = jsonDecode(File('assets/content/levels.json').readAsStringSync()) as Map<String, dynamic>;
  final voice = jsonDecode(File('assets/content/voice_lines.json').readAsStringSync()) as Map<String, dynamic>;
  return ContentRepository.fromJson(levels, voice);
}
