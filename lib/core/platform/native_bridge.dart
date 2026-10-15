import 'package:flutter/services.dart';

/// کارهای کوچکی که فقط سمت اندروید شدنی است (MainActivity.kt، کانال com.goshyar.app/native).
/// روی وب و در آزمون‌ها کانال نیست؛ هر متد آن‌جا بی‌صدا «نه» برمی‌گرداند.
class NativeBridge {
  const NativeBridge();

  static const _channel = MethodChannel('com.goshyar.app/native');

  /// صفحه‌ی یک برنامه در کافه‌بازار (یا اگر بازار نصب نیست، همان صفحه در مرورگر).
  Future<bool> openStorePage(String packageName) =>
      _call<bool>('openStorePage', {'packageName': packageName}).then((v) => v ?? false);

  /// اجازه‌ی نمایش اعلان (اندروید ۱۳+). پایین‌تر از ۱۳ همیشه true.
  Future<bool> notificationsAllowed() => _call<bool>('notificationsAllowed').then((v) => v ?? false);

  Future<void> requestNotifications() => _call<void>('requestNotifications');

  Future<T?> _call<T>(String method, [Map<String, Object?>? args]) async {
    try {
      return await _channel.invokeMethod<T>(method, args);
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }
}
