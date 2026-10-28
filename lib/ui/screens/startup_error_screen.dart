import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// آخرین تور ایمنی: اگر محتوای بازی یا تنظیمات ذخیره‌شده اصلاً خوانده نشوند، همین صفحه
/// اجرا می‌شود.
///
/// عمداً هیچ‌چیز از سیستم طراحی، فونت، دارایی یا Provider برنامه را لازم ندارد — چیزی که
/// جای نمایش خطا را بگیرد نباید خودش بتواند خطا بدهد. جای «برنامه مدام بسته می‌شود»ِ
/// اندروید، کودک یک صفحه و والد یک جمله‌ی روشن می‌بیند.
class StartupErrorApp extends StatelessWidget {
  const StartupErrorApp({super.key, this.detail = ''});

  /// متن فنی خطا؛ فقط در debug نشان داده می‌شود.
  final String detail;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: const Color(0xFF7CC8FF),
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.volume_off_rounded, size: 72, color: Colors.white),
                    const SizedBox(height: 16),
                    const Text(
                      'گوش‌یار این بار باز نشد',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'برنامه را یک بار ببندید و دوباره باز کنید.\n'
                      'اگر باز هم نشد، گوشی را خاموش و روشن کنید؛ پیشرفت کودک جای خودش می‌ماند.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15, height: 1.7, color: Colors.white),
                    ),
                    if (kDebugMode && detail.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text(
                        detail,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
