import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/design/theme.dart';
import '../../core/design/tokens.dart';
import '../../data/notices_store.dart';
import '../widgets/clay.dart';
import '../widgets/common.dart';
import '../widgets/notice_card.dart';

/// همه‌ی خبرهای فعلی، از زنگوله‌ی صفحه‌ی خانه. با باز شدن این صفحه همه «دیده شد» می‌شوند.
class NoticesScreen extends StatefulWidget {
  const NoticesScreen({super.key});

  @override
  State<NoticesScreen> createState() => _NoticesScreenState();
}

class _NoticesScreenState extends State<NoticesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<NoticesStore>().markAllSeen();
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<NoticesStore>();
    final list = store.notices;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const GTopBar(title: 'خبرها'),
            Expanded(
              child: list.isEmpty
                  ? Center(child: Text('فعلاً خبری نیست.', style: GText.body))
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(GSpace.gutter, GSpace.xs, GSpace.gutter, GSpace.xl),
                      itemCount: list.length,
                      separatorBuilder: (_, _) => const SizedBox(height: GSpace.sm),
                      itemBuilder: (context, i) => _Item(store: store, notice: list[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({required this.store, required this.notice});

  final NoticesStore store;
  final Notice notice;

  @override
  Widget build(BuildContext context) {
    final go = noticeGoLabel(notice);
    void follow() => followNotice(Navigator.of(context), store, notice);
    return ClayCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('📣 ${notice.title}', style: GText.heading.copyWith(color: GColors.orangeDark)),
          if (notice.hasImage) NoticePicture(store: store, notice: notice, onTap: go.isEmpty ? null : follow),
          if (notice.body.isNotEmpty) ...[
            const SizedBox(height: GSpace.xs),
            Text(notice.body, style: GText.body),
          ],
          if (go.isNotEmpty) ...[
            const SizedBox(height: GSpace.sm),
            ClayButton(label: go, color: GColors.green, onTap: follow),
          ],
        ],
      ),
    );
  }
}
