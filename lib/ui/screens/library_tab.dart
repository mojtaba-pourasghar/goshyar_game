import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/design/theme.dart';
import '../../core/design/tokens.dart';
import '../../core/fa.dart';
import '../../data/content_repository.dart';
import '../routes.dart';
import '../widgets/clay.dart';
import '../widgets/common.dart';
import '../widgets/icons.dart';

/// دسته‌بندی صداها (کتابخانه): کودک آزادانه صداها را می‌شنود و نامشان را یاد می‌گیرد.
class LibraryTab extends StatelessWidget {
  const LibraryTab({super.key});

  @override
  Widget build(BuildContext context) {
    final content = context.read<ContentRepository>();
    final cols = MediaQuery.sizeOf(context).width >= 600 ? 3 : 2;
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(GSpace.gutter, GSpace.md, GSpace.gutter, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('خانه‌ی صداها', style: GText.title.copyWith(color: GColors.purple)),
                  const SizedBox(height: 4),
                  Text('روی هر دسته بزن و صداهایش را بشنو.', style: GText.body),
                  const SizedBox(height: GSpace.sm),
                  const SectionPill('دسته‌بندی صداها'),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(GSpace.gutter),
            sliver: SliverGrid.count(
              crossAxisCount: cols,
              mainAxisSpacing: GSpace.md,
              crossAxisSpacing: GSpace.md,
              childAspectRatio: 1.0,
              children: [
                for (final c in content.categories)
                  CategoryTile(
                    title: c.title,
                    subtitle: '${faDigits(content.soundsIn(c.id).length)} صدا',
                    icon: iconFor(c.icon),
                    color: GColors.fromHex(c.color),
                    onTap: () => Navigator.of(context).pushNamed(Routes.library, arguments: c.id),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
