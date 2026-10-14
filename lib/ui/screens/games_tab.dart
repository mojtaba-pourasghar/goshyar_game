import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/design/theme.dart';
import '../../core/design/tokens.dart';
import '../../core/fa.dart';
import '../../data/content_repository.dart';
import '../../data/models.dart';
import '../../data/progress_store.dart';
import '../routes.dart';
import '../widgets/clay.dart';
import '../widgets/icons.dart';

/// انتخاب بازی و مأموریت: چهار بازی اصلی با پیشرفت هرکدام.
class GamesTab extends StatelessWidget {
  const GamesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final content = context.read<ContentRepository>();
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(GSpace.gutter, GSpace.md, GSpace.gutter, GSpace.xl),
        children: [
          Text('بازی‌ها و مأموریت‌ها', style: GText.title.copyWith(color: GColors.purple)),
          const SizedBox(height: 4),
          Text('یک بازی را انتخاب کن و مرحله‌به‌مرحله جلو برو.', style: GText.body),
          const SizedBox(height: GSpace.md),
          for (var i = 0; i < content.modes.length; i++) ...[
            _ModeCard(mode: content.modes[i], number: i + 1),
            const SizedBox(height: GSpace.md),
          ],
        ],
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({required this.mode, required this.number});

  final GameMode mode;
  final int number;

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressStore>();
    final done = progress.completedInMode(mode.id);
    final total = mode.levels.length;
    final color = GColors.fromHex(mode.color);
    return Pressable(
      onTap: () => Navigator.of(context).pushNamed(Routes.levels, arguments: mode.id),
      color: color,
      radius: GRadius.lg,
      depth: 7,
      semanticLabel: '${mode.title}، ${faDigits(done)} از ${faDigits(total)} مرحله',
      padding: const EdgeInsets.all(GSpace.md),
      child: Row(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .22),
              borderRadius: BorderRadius.circular(GRadius.md),
            ),
            child: Icon(iconFor(mode.icon), color: Colors.white, size: 44),
          ),
          const SizedBox(width: GSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${faDigits(number)}. ${mode.title}',
                  style: GText.label.copyWith(fontSize: 19),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  mode.subtitle,
                  style: GText.caption.copyWith(color: Colors.white.withValues(alpha: .92)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: GSpace.xs),
                ClipRRect(
                  borderRadius: BorderRadius.circular(GRadius.pill),
                  child: LinearProgressIndicator(
                    value: total == 0 ? 0 : done / total,
                    minHeight: 10,
                    color: GColors.yellow,
                    backgroundColor: Colors.white.withValues(alpha: .3),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${faDigits(done)} از ${faDigits(total)} مرحله',
                  style: GText.caption.copyWith(color: Colors.white, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(width: GSpace.xs),
          const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white),
        ],
      ),
    );
  }
}
