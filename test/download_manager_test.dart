import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goshyar/core/assets/asset_config.dart';
import 'package:goshyar/core/assets/asset_resolver.dart';
import 'package:goshyar/core/assets/download_manager.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// CDN ساختگی: packs.json و فایل‌ها را از حافظه برمی‌گرداند؛ می‌شود «قطعش» کرد.
class FakeCdn {
  FakeCdn(this.files, {this.corruptPath});

  final Map<String, List<int>> files;
  final String? corruptPath;
  bool online = true;
  final List<String> requests = [];

  Map<String, dynamic> get index => {
    'version': 'v1',
    'packs': [
      {
        'id': 'voice-fa',
        'title': 'صدای گوینده',
        'description': 'آزمایشی',
        'files': [
          for (final e in files.entries)
            {'path': e.key, 'size': e.value.length, 'sha256': sha256.convert(e.value).toString()},
        ],
      },
    ],
  };

  http.Client get client => MockClient((req) async {
    requests.add(req.url.path);
    if (!online) throw const SocketException('offline');
    final p = req.url.path.replaceFirst('/goshyar/v1/', '');
    if (p == 'packs.json') return http.Response.bytes(utf8.encode(jsonEncode(index)), 200);
    final body = files[p];
    if (body == null) return http.Response('missing', 404);
    return http.Response.bytes(p == corruptPath ? [...body, 0] : body, 200);
  });
}

void main() {
  late Directory tmp;
  setUp(() async => tmp = await Directory.systemTemp.createTemp('goshyar_dl'));
  tearDown(() async => tmp.delete(recursive: true));

  Future<(AssetResolver, DownloadManager)> make(FakeCdn cdn) async {
    final r = AssetResolver(
      config: const AssetConfig(cdnBase: 'https://cdn.test', version: 'v1'),
    );
    await r.useCacheDir(Directory('${tmp.path}/goshyar_assets/v1'));
    return (r, DownloadManager(r, client: cdn.client));
  }

  test('دانلود بسته، بررسی sha256، اولویت فایل دانلودی و کار بدون اینترنت', () async {
    final cdn = FakeCdn({
      'audio/voice/app_splash_welcome.mp3': List.filled(300, 7),
      'audio/voice/who_01_q.mp3': List.filled(500, 9),
    });
    final (resolver, dm) = await make(cdn);
    expect(dm.available, isTrue);
    await dm.refresh();
    expect(dm.packs.single.id, 'voice-fa');
    expect(dm.status(dm.packs.single), PackStatus.notDownloaded);

    await dm.download(dm.packs.single);
    expect(dm.error, isNull);
    expect(dm.status(dm.packs.single), PackStatus.ready);
    expect(dm.usedBytes, 800);
    final r = resolver.resolve('audio/voice/who_01_q.mp3')!;
    expect(r.source, AssetSource.downloaded);
    expect(File(r.key).lengthSync(), 500);

    // دوباره دانلود نمی‌شود.
    final before = cdn.requests.length;
    await dm.download(dm.packs.single);
    expect(cdn.requests.length, before);

    // قطع اینترنت: فهرست ذخیره‌شده خوانده می‌شود و فایل‌ها همچنان در دسترس‌اند.
    cdn.online = false;
    final (resolver2, dm2) = await make(cdn);
    await dm2.refresh();
    expect(dm2.error, isNotNull);
    expect(dm2.packs.single.id, 'voice-fa');
    expect(dm2.status(dm2.packs.single), PackStatus.ready);
    expect(resolver2.exists('audio/voice/app_splash_welcome.mp3'), isTrue);

    await dm2.remove(dm2.packs.single);
    expect(resolver2.exists('audio/voice/app_splash_welcome.mp3'), isFalse);
  });

  test('فایل خراب ذخیره نمی‌شود و نیمه‌کاره پخش نمی‌شود', () async {
    final cdn = FakeCdn({
      'audio/voice/a.mp3': List.filled(100, 1),
      'audio/voice/b.mp3': List.filled(100, 2),
    }, corruptPath: 'audio/voice/b.mp3');
    final (resolver, dm) = await make(cdn);
    await dm.refresh();
    await dm.download(dm.packs.single);
    expect(dm.error, isNotNull);
    expect(resolver.isDownloaded('audio/voice/a.mp3'), isTrue);
    expect(resolver.isDownloaded('audio/voice/b.mp3'), isFalse);
    expect(dm.status(dm.packs.single), PackStatus.partial);
    expect(
      Directory(resolver.cacheDir!.path).listSync(recursive: true).where((e) => e.path.endsWith('.part')),
      isEmpty,
      reason: 'فایل .part خراب باید پاک شود',
    );
  });

  test('بدون نشانی CDN، مدیر دانلود غیرفعال است', () async {
    final r = AssetResolver(config: const AssetConfig(cdnBase: ''));
    await r.useCacheDir(Directory('${tmp.path}/x'));
    expect(DownloadManager(r).available, isFalse);
  });
}
