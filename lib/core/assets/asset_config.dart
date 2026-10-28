/// نشانی دارایی‌های راه دور (Cloudflare R2 پشت CDN) در یک جا.
///
/// هیچ کلید یا توکنی اینجا نیست و نباید باشد: برنامه فقط فایل‌های عمومی و
/// نسخه‌دار را با GET می‌خواند. مقدارها هنگام ساخت داده می‌شوند:
///
///     flutter build apk --dart-define=GOSHYAR_CDN_BASE=https://assets.example.com \
///                       --dart-define=GOSHYAR_ASSET_VERSION=v1
///
/// اگر GOSHYAR_CDN_BASE خالی باشد، برنامه فقط با دارایی‌های داخل APK کار می‌کند.
class AssetConfig {
  const AssetConfig({this.cdnBase = _cdnBase, this.version = _version, this.noticesBase = _noticesBase});

  static const _cdnBase = String.fromEnvironment('GOSHYAR_CDN_BASE');
  static const _version = String.fromEnvironment('GOSHYAR_ASSET_VERSION', defaultValue: 'v1');

  /// خبرها، مثل هوهو ریاضی، از هاست خود سازنده می‌آیند (استودیو با FTP در public_html/goshyar می‌گذارد)،
  /// نه از CDN؛ پس بی هیچ --dart-define هم کار می‌کنند. با GOSHYAR_NOTICES_BASE عوض می‌شود.
  static const _noticesBase = String.fromEnvironment('GOSHYAR_NOTICES_BASE', defaultValue: 'https://mp-apdl.ir');

  final String cdnBase;
  final String version;
  final String noticesBase;

  bool get remoteEnabled => cdnBase.trim().isNotEmpty;

  /// خبرها فقط روی https؛ خالی یعنی «این ساخت خبر نمی‌گیرد».
  bool get noticesEnabled => noticesBase.trim().startsWith('https://');

  static String _trim(String s) => s.trim().endsWith('/') ? s.trim().substring(0, s.trim().length - 1) : s.trim();

  String get _base => _trim(cdnBase);

  String get _root => '$_base/goshyar/$version';

  /// فهرست بسته‌های قابل دانلود.
  Uri get packIndex => Uri.parse('$_root/packs.json');

  /// خبرهای امضاشده: `noticesBase/goshyar/notices.json`
  Uri get notices => Uri.parse('${_trim(noticesBase)}/goshyar/notices.json');

  /// تصویر یک خبر با مسیر نسبی به goshyar/، مثل notices/3f2a….webp
  Uri noticeFile(String relativePath) => Uri.parse('${_trim(noticesBase)}/goshyar/$relativePath');

  /// نشانی یک فایل با مسیر منطقی، مثل audio/voice/who_01_q.mp3
  Uri file(String logicalPath) => Uri.parse('$_root/$logicalPath');
}
