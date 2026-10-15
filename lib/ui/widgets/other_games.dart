import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/design/theme.dart';
import '../../core/design/tokens.dart';
import '../../core/platform/native_bridge.dart';
import '../../data/content_repository.dart';
import '../../data/models.dart';
import 'clay.dart';
import 'icons.dart';
import 'paywall.dart';

/// بخش «بازی‌های دیگر ما». باز کردن کافه‌بازار پیوند بیرونی است، پس پشت دروازه‌ی والدین است.
class OtherGamesSection extends StatefulWidget {
  const OtherGamesSection({super.key});

  @override
  State<OtherGamesSection> createState() => _OtherGamesSectionState();
}

class _OtherGamesSectionState extends State<OtherGamesSection> {
  Future<void> _open(OtherGame g) async {
    if (!await verifyParent(context)) return;
    final ok = await const NativeBridge().openStorePage(g.package);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'cafebazaar.ir/app/${g.package}',
            textDirection: TextDirection.ltr,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final games = context.read<ContentRepository>().otherGames;
    if (games.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionPill('بازی‌های دیگر ما'),
        const SizedBox(height: GSpace.sm),
        for (final g in games) ...[
          Pressable(
            onTap: () => _open(g),
            color: GColors.fromHex(g.color),
            radius: GRadius.lg,
            depth: 7,
            semanticLabel: '${g.title}، در کافه‌بازار',
            padding: const EdgeInsets.all(GSpace.md),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(GRadius.md),
                  ),
                  child: Icon(
                    iconFor(g.icon),
                    color: GColors.fromHex(g.color),
                    size: 32,
                  ),
                ),
                const SizedBox(width: GSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        g.title,
                        style: GText.heading.copyWith(color: Colors.white),
                      ),
                      Text(
                        g.subtitle,
                        style: GText.caption.copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.storefront_rounded, color: Colors.white),
              ],
            ),
          ),
          const SizedBox(height: GSpace.sm),
        ],
      ],
    );
  }
}
