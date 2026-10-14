import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/assets/asset_resolver.dart';
import '../../core/design/theme.dart';
import '../../core/design/tokens.dart';
import '../../core/narrator.dart';
import '../../data/content_repository.dart';
import '../../data/progress_store.dart';
import '../routes.dart';
import '../widgets/clay.dart';
import '../widgets/common.dart';
import '../widgets/game_widgets.dart';
import '../widgets/mascot.dart';
import 'game_screen.dart';

/// صفحه‌ی انتخاب بازی یک دسته (مثل «بازی حیوانات» در تصویر مرجع).
class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key, required this.categoryId});

  final String categoryId;

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<Narrator>().say('cat.${widget.categoryId}.intro');
      final c = context.read<ContentRepository>();
      context.read<AssetResolver>().precache(context, c.soundsIn(widget.categoryId).map((s) => s.image));
    });
  }

  @override
  Widget build(BuildContext context) {
    final content = context.read<ContentRepository>();
    final cat = content.category(widget.categoryId);
    final sounds = content.soundsIn(cat.id);
    final color = GColors.fromHex(cat.color);
    final best = context.watch<ProgressStore>().categoryBestStars(cat.id);
    final hero = context.read<AssetResolver>().image(sounds.first.image);
    final w = MediaQuery.sizeOf(context).width;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [GColors.tint(color, .34), const Color(0xFFF4F0FF)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const GTopBar(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: GSpace.gutter),
                  child: Column(
                    children: [
                      Text(
                        'بازی ${cat.title}',
                        style: GText.display.copyWith(fontSize: 32),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: GSpace.md),
                      Container(
                        width: (w * .62).clamp(180.0, 320.0),
                        height: (w * .62).clamp(180.0, 320.0),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(color: Colors.white, width: 8),
                          boxShadow: GShadow.glow(color),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: hero == null ? null : Image(image: hero, fit: BoxFit.cover),
                      ),
                      const SizedBox(height: GSpace.md),
                      Text(
                        'صدای ${cat.title} را گوش کن\nو تصویر درست را پیدا کن.',
                        style: GText.body.copyWith(fontSize: 18),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: GSpace.sm),
                      const SpeechBubble(),
                      if (best > 0) ...[
                        const SizedBox(height: GSpace.sm),
                        Text('بهترین نتیجه‌ی تو', style: GText.caption),
                        StarRow(stars: best, size: 34, animate: false),
                      ],
                      const SizedBox(height: GSpace.lg),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(GSpace.gutter, 0, GSpace.gutter, GSpace.md),
                child: Column(
                  children: [
                    ClayButton(
                      label: 'شروع بازی',
                      icon: Icons.play_arrow_rounded,
                      big: true,
                      onTap: () => Navigator.of(context).pushNamed(Routes.game, arguments: GameArgs.category(cat.id)),
                    ),
                    const SizedBox(height: GSpace.sm),
                    ClayButton(
                      label: 'اول صداها را بشنو',
                      icon: Icons.headphones_rounded,
                      color: color,
                      onTap: () => Navigator.of(context).pushNamed(Routes.library, arguments: cat.id),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
