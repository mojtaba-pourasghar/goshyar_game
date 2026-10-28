import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/design/theme.dart';
import '../../core/design/tokens.dart';
import '../../data/notices_store.dart';
import '../routes.dart';
import 'clay.dart';
import 'paywall.dart';

/// چه کاری با خبر شد؛ هر کدام یعنی «دیده شد» (مثل NoticeDialog در هوهو ریاضی).
enum NoticeAction { go, close }

/// متن دکمه‌ی اصلی، یا خالی وقتی خبر فقط چند کلمه است.
String noticeGoLabel(Notice n) {
  if (n.destination.isNotEmpty) return 'بریم ببینیم';
  if (n.hasLink) return 'باز کردن پیوند';
  return '';
}

/// خبر را دنبال می‌کند: صفحه‌ای در برنامه بر پیوند بیرونی مقدم است، چون کودک را جای غیرمنتظره‌ای
/// نمی‌برد. پیوند فقط بعد از دروازه‌ی والدین باز می‌شود.
Future<void> followNotice(NavigatorState nav, NoticesStore store, Notice n) async {
  if (await openNoticeScreen(nav, n.destination)) return;
  if (!n.hasLink || !nav.mounted) return;
  if (await verifyParent(nav.context)) await store.bridge.openUrl(n.link);
}

/// یکی از صفحه‌هایی که استودیو می‌شناسد (NoticeHost.screens). false یعنی این نسخه آن را نمی‌شناسد.
Future<bool> openNoticeScreen(NavigatorState nav, String screen) async {
  const tabs = {'HOME': 0, 'GAMES': 1, 'LIBRARY': 2, 'PROFILE': 3};
  final tab = tabs[screen];
  if (tab != null) {
    nav.pushNamedAndRemoveUntil(Routes.home, (_) => false, arguments: tab);
    return true;
  }
  switch (screen) {
    case 'DOWNLOADS':
      nav.pushNamed(Routes.downloads);
      return true;
    case 'PAYWALL':
      await showPaywall(nav.context);
      return true;
  }
  return false;
}

/// کارت خبر وسط صفحه: عنوان، عکس اگر هست، متن، و حداکثر دو کار — رفتن به جایی که خبر نشان می‌دهد،
/// یا کنار گذاشتن. لمس بیرون یا «بازگشت» هم یعنی «باشه».
Future<NoticeAction> showNoticeCard(BuildContext context, NoticesStore store, Notice n) async {
  final picked = await showDialog<NoticeAction>(
    context: context,
    builder: (_) => NoticeCard(notice: n, store: store),
  );
  return picked ?? NoticeAction.close;
}

class NoticeCard extends StatelessWidget {
  const NoticeCard({super.key, required this.notice, required this.store});

  final Notice notice;
  final NoticesStore store;

  @override
  Widget build(BuildContext context) {
    final go = noticeGoLabel(notice);
    void pick(NoticeAction a) => Navigator.of(context).pop(a);
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: GSpace.lg, vertical: GSpace.xl),
      child: ClayCard(
        border: GColors.orange,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '📣 ${notice.title}',
                textAlign: TextAlign.center,
                style: GText.heading.copyWith(color: GColors.orangeDark),
              ),
              if (notice.hasImage)
                NoticePicture(
                  store: store,
                  notice: notice,
                  // عکس بزرگ‌ترین چیز کارت است و اولین چیزی که کودک لمس می‌کند.
                  onTap: go.isEmpty ? null : () => pick(NoticeAction.go),
                ),
              if (notice.body.isNotEmpty) ...[
                const SizedBox(height: GSpace.sm),
                Text(notice.body, textAlign: TextAlign.center, style: GText.body),
              ],
              const SizedBox(height: GSpace.md),
              if (go.isNotEmpty) ...[
                ClayButton(label: go, color: GColors.green, onTap: () => pick(NoticeAction.go)),
                const SizedBox(height: GSpace.xs),
              ],
              TextButton(
                onPressed: () => pick(NoticeAction.close),
                child: Text(go.isEmpty ? 'باشه' : 'بعداً', style: GText.bodyStrong.copyWith(color: GColors.purple)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// عکس خبر، فقط اگر همان باشد که امضا شده. تا برسد جایش خالی است؛ کارت بعداً بزرگ می‌شود.
class NoticePicture extends StatelessWidget {
  const NoticePicture({super.key, required this.store, required this.notice, this.onTap});

  final NoticesStore store;
  final Notice notice;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: store.image(notice),
      builder: (context, snap) {
        final bytes = snap.data;
        if (bytes == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: GSpace.sm),
          child: GestureDetector(
            onTap: onTap,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(GRadius.sm),
              child: ConstrainedBox(
                // پوستر بلند نباید دکمه‌ها را از صفحه بیرون کند.
                constraints: const BoxConstraints(maxHeight: 280),
                child: Image.memory(bytes, fit: BoxFit.contain, gaplessPlayback: true),
              ),
            ),
          ),
        );
      },
    );
  }
}
