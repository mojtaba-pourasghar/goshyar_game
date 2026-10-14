/// اعداد فارسی برای نمایش (۰۱۲۳۴۵۶۷۸۹).
String faDigits(Object value) {
  const fa = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
  final s = value.toString();
  final b = StringBuffer();
  for (final ch in s.split('')) {
    final d = int.tryParse(ch);
    b.write(d == null ? ch : fa[d]);
  }
  return b.toString();
}

/// اندازه‌ی فایل خوانا، مثل «۱٫۲ مگابایت».
String faBytes(int bytes) {
  if (bytes < 1024) return '${faDigits(bytes)} بایت';
  if (bytes < 1024 * 1024) return '${faDigits((bytes / 1024).round())} کیلوبایت';
  final mb = (bytes / (1024 * 1024)).toStringAsFixed(1).replaceAll('.', '٫');
  return '${faDigits(mb)} مگابایت';
}
