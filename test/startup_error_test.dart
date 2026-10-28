import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goshyar/ui/screens/startup_error_screen.dart';

/// تور ایمنی راه‌اندازی (lib/main.dart): اگر محتوا یا تنظیمات خوانده نشوند، این صفحه جای
/// «برنامه مدام بسته می‌شود» را می‌گیرد. پس خودش نباید به هیچ دارایی، فونت یا Provider
/// نیاز داشته باشد و باید روی کوچک‌ترین گوشی هم بی‌سرریز بنشیند.
void main() {
  testWidgets('صفحه‌ی خطای راه‌اندازی بی‌هیچ وابستگی و راست‌چین نشان داده می‌شود', (tester) async {
    await tester.pumpWidget(const StartupErrorApp(detail: 'خطای آزمایشی'));
    await tester.pumpAndSettle();

    expect(find.text('گوش‌یار این بار باز نشد'), findsOneWidget);
    expect(Directionality.of(tester.element(find.byType(Scaffold))), TextDirection.rtl);
    expect(tester.takeException(), isNull);
  });

  testWidgets('در گوشی ۳۲۰×۵۶۸ سرریز نمی‌کند', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const StartupErrorApp());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
