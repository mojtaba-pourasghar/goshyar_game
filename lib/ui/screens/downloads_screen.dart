import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/assets/asset_resolver.dart';
import '../../core/assets/download_manager.dart';
import '../../core/design/theme.dart';
import '../../core/design/tokens.dart';
import '../../core/fa.dart';
import '../../core/narrator.dart';
import '../../data/content_repository.dart';
import '../widgets/clay.dart';
import '../widgets/common.dart';

/// صداها و تصویرهای ذخیره‌شده: وضعیت دارایی‌های داخلی (همیشه آفلاین) و
/// بسته‌های قابل دانلود از CDN.
class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<Narrator>().say('app.downloads.shown');
      context.read<DownloadManager>().refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final content = context.read<ContentRepository>();
    final assets = context.watch<AssetResolver>();
    final dm = context.watch<DownloadManager>();

    final sounds = content.sounds.values;
    final audioOk = sounds.where((s) => assets.exists(s.audio)).length;
    final imageOk = sounds.where((s) => assets.exists(s.image)).length;
    final lines = content.allVoiceLines.toList();
    final voiceOk = lines.where((l) => assets.exists('audio/${l.file}')).length;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const GTopBar(title: 'ذخیره‌شده‌ها'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(GSpace.gutter, GSpace.xs, GSpace.gutter, GSpace.xl),
                children: [
                  ClayCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.offline_pin_rounded, color: GColors.green, size: 30),
                            const SizedBox(width: GSpace.xs),
                            Text('بدون اینترنت', style: GText.heading.copyWith(color: GColors.greenDark)),
                          ],
                        ),
                        const SizedBox(height: GSpace.xs),
                        _status('صدای حیوان‌ها و وسایل', audioOk, sounds.length),
                        _status('تصویر کارت‌ها', imageOk, sounds.length),
                        _status('صدای گوینده', voiceOk, lines.length),
                        if (voiceOk < lines.length)
                          Padding(
                            padding: const EdgeInsets.only(top: GSpace.xs),
                            child: Text(
                              'صدای گوینده هنوز ضبط نشده است؛ تا آن زمان حرف‌های گوش‌یار به‌صورت نوشته نمایش داده می‌شود.',
                              style: GText.caption,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: GSpace.md),
                  ClayCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.cloud_download_rounded, color: GColors.blue, size: 30),
                            const SizedBox(width: GSpace.xs),
                            Expanded(
                              child: Text(
                                'بسته‌های قابل دانلود',
                                style: GText.heading.copyWith(color: GColors.blueDark),
                              ),
                            ),
                            if (dm.available)
                              IconButton(
                                tooltip: 'به‌روزرسانی فهرست',
                                onPressed: dm.loading ? null : dm.refresh,
                                icon: const Icon(Icons.refresh_rounded),
                              ),
                          ],
                        ),
                        const SizedBox(height: GSpace.xs),
                        if (!dm.available)
                          Text(
                            'سرور دارایی‌ها برای این نسخه تنظیم نشده است. همه‌ی محتوای اصلی داخل برنامه است.',
                            style: GText.body,
                          )
                        else if (dm.loading && dm.packs.isEmpty)
                          const Center(
                            child: Padding(padding: EdgeInsets.all(GSpace.md), child: CircularProgressIndicator()),
                          )
                        else ...[
                          if (dm.error != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: GSpace.xs),
                              child: Text(dm.error!, style: GText.caption.copyWith(color: GColors.redDark)),
                            ),
                          if (dm.packs.isEmpty && dm.error == null) Text('بسته‌ای موجود نیست.', style: GText.body),
                          for (final p in dm.packs) _PackTile(pack: p, dm: dm),
                          const SizedBox(height: GSpace.xs),
                          Text('فضای استفاده‌شده: ${faBytes(dm.usedBytes)}', style: GText.caption),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _status(String label, int have, int total) {
    final ok = have == total;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(
            ok ? Icons.check_circle_rounded : Icons.pending_rounded,
            color: ok ? GColors.green : GColors.orange,
            size: 22,
          ),
          const SizedBox(width: GSpace.xs),
          Expanded(child: Text(label, style: GText.body)),
          Text('${faDigits(have)} از ${faDigits(total)}', style: GText.bodyStrong),
        ],
      ),
    );
  }
}

class _PackTile extends StatelessWidget {
  const _PackTile({required this.pack, required this.dm});

  final AssetPack pack;
  final DownloadManager dm;

  @override
  Widget build(BuildContext context) {
    final status = dm.status(pack);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: GSpace.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(pack.title, style: GText.bodyStrong),
                    Text('${pack.description} • ${faBytes(pack.totalBytes)}', style: GText.caption),
                  ],
                ),
              ),
              const SizedBox(width: GSpace.xs),
              switch (status) {
                PackStatus.ready => TextButton.icon(
                  onPressed: () => dm.remove(pack),
                  icon: const Icon(Icons.delete_outline_rounded, color: GColors.red),
                  label: Text('حذف', style: GText.bodyStrong.copyWith(color: GColors.red)),
                ),
                PackStatus.downloading => const SizedBox(width: 28, height: 28, child: CircularProgressIndicator()),
                _ => ClayButton(
                  label: status == PackStatus.partial ? 'تکمیل' : 'دانلود',
                  icon: Icons.download_rounded,
                  color: GColors.blue,
                  expand: false,
                  onTap: () => dm.download(pack),
                ),
              },
            ],
          ),
          if (status == PackStatus.downloading) ...[
            const SizedBox(height: 4),
            LinearProgressIndicator(value: dm.progress(pack), minHeight: 8),
          ],
        ],
      ),
    );
  }
}
