import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'asset_resolver.dart';

class PackFile {
  const PackFile({required this.path, required this.size, required this.sha256});

  final String path;
  final int size;
  final String sha256;

  factory PackFile.fromJson(Map<String, dynamic> j) =>
      PackFile(path: j['path'] as String, size: (j['size'] ?? 0) as int, sha256: (j['sha256'] ?? '') as String);
}

class AssetPack {
  const AssetPack({required this.id, required this.title, required this.description, required this.files});

  final String id;
  final String title;
  final String description;
  final List<PackFile> files;

  int get totalBytes => files.fold(0, (a, f) => a + f.size);

  factory AssetPack.fromJson(Map<String, dynamic> j) => AssetPack(
    id: j['id'] as String,
    title: (j['title'] ?? j['id']) as String,
    description: (j['description'] ?? '') as String,
    files: [for (final f in (j['files'] ?? const []) as List) PackFile.fromJson(f as Map<String, dynamic>)],
  );
}

enum PackStatus { notDownloaded, partial, downloading, ready }

/// دانلود بسته‌های دارایی از CDN (Cloudflare R2) به حافظه‌ی برنامه.
///
/// - فهرست بسته‌ها (packs.json) پس از هر دریافت موفق روی دیسک نگه داشته می‌شود
///   تا بدون اینترنت هم وضعیت بسته‌های دانلودشده دیده شود.
/// - هر فایل اول در «.part» نوشته و پس از بررسی sha256 جابه‌جا می‌شود؛
///   فایل نیمه‌کاره هرگز پخش نمی‌شود.
/// - فایل‌هایی که قبلاً سالم دانلود شده‌اند دوباره دانلود نمی‌شوند.
class DownloadManager extends ChangeNotifier {
  DownloadManager(this.resolver, {http.Client? client}) : _client = client ?? http.Client();

  final AssetResolver resolver;
  final http.Client _client;

  List<AssetPack> _packs = const [];
  final Map<String, double> _progress = {};
  String? _error;
  bool _loading = false;

  List<AssetPack> get packs => _packs;
  String? get error => _error;
  bool get loading => _loading;
  bool get available => resolver.config.remoteEnabled && !kIsWeb && resolver.cacheDir != null;

  File? get _indexFile => resolver.cacheDir == null
      ? null
      : File('${resolver.cacheDir!.parent.path}/packs-${resolver.config.version}.json');

  PackStatus status(AssetPack p) {
    if (_progress.containsKey(p.id)) return PackStatus.downloading;
    final have = p.files.where((f) => resolver.isDownloaded(f.path)).length;
    if (have == 0) return PackStatus.notDownloaded;
    return have == p.files.length ? PackStatus.ready : PackStatus.partial;
  }

  double progress(AssetPack p) => _progress[p.id] ?? 0;

  int get usedBytes {
    var n = 0;
    for (final p in _packs) {
      for (final f in p.files) {
        if (resolver.isDownloaded(f.path)) n += f.size;
      }
    }
    return n;
  }

  Future<void> refresh() async {
    if (!available) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await _client.get(resolver.config.packIndex).timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) throw HttpException('HTTP ${res.statusCode}');
      final body = utf8.decode(res.bodyBytes);
      _packs = _parse(body);
      final f = _indexFile;
      if (f != null) {
        await f.parent.create(recursive: true);
        await f.writeAsString(body);
      }
    } catch (e) {
      _error = 'اتصال به سرور دارایی‌ها برقرار نشد. فایل‌های ذخیره‌شده همچنان کار می‌کنند.';
      debugPrint('packs.json دریافت نشد: $e');
      final f = _indexFile;
      if (f != null && await f.exists()) _packs = _parse(await f.readAsString());
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  List<AssetPack> _parse(String body) {
    final j = jsonDecode(body) as Map<String, dynamic>;
    return [for (final p in (j['packs'] ?? const []) as List) AssetPack.fromJson(p as Map<String, dynamic>)];
  }

  Future<void> download(AssetPack pack) async {
    if (_progress.containsKey(pack.id)) return;
    _progress[pack.id] = 0;
    _error = null;
    notifyListeners();
    final total = pack.totalBytes == 0 ? pack.files.length : pack.totalBytes;
    var done = 0;
    try {
      for (final f in pack.files) {
        if (!resolver.isDownloaded(f.path)) await _downloadFile(f);
        done += pack.totalBytes == 0 ? 1 : f.size;
        _progress[pack.id] = done / total;
        notifyListeners();
      }
    } catch (e) {
      _error = 'دانلود «${pack.title}» کامل نشد. دوباره امتحان کنید.';
      debugPrint('دانلود بسته شکست خورد: $e');
    } finally {
      _progress.remove(pack.id);
      await resolver.rescan();
      notifyListeners();
    }
  }

  Future<void> _downloadFile(PackFile f) async {
    final target = resolver.localFileFor(f.path)!;
    final part = File('${target.path}.part');
    await part.parent.create(recursive: true);
    final res = await _client.get(resolver.config.file(f.path)).timeout(const Duration(seconds: 60));
    if (res.statusCode != 200) throw HttpException('HTTP ${res.statusCode} برای ${f.path}');
    if (f.sha256.isNotEmpty && sha256.convert(res.bodyBytes).toString() != f.sha256) {
      throw const FormatException('sha256 فایل دانلودشده با فهرست نمی‌خواند');
    }
    try {
      await part.writeAsBytes(res.bodyBytes, flush: true);
      await part.rename(target.path);
    } catch (_) {
      if (await part.exists()) await part.delete();
      rethrow;
    }
  }

  Future<void> remove(AssetPack pack) async {
    for (final f in pack.files) {
      final file = resolver.localFileFor(f.path);
      if (file != null && await file.exists()) await file.delete();
    }
    await resolver.rescan();
    notifyListeners();
  }
}
