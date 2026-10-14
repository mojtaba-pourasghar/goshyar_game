import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/design/theme.dart';
import '../../core/design/tokens.dart';
import '../../core/fa.dart';
import '../../core/narrator.dart';
import '../../data/content_repository.dart';
import '../../data/progress_store.dart';
import '../routes.dart';
import '../widgets/clay.dart';
import '../widgets/common.dart';
import '../widgets/icons.dart';
import '../widgets/scene.dart';
import 'game_screen.dart';

/// نقشه‌ی مراحل یک بازی: هر مرحله با ستاره‌هایش؛ مرحله‌ی بعد با تمام شدن قبلی باز می‌شود.
class LevelMapScreen extends StatefulWidget {
  const LevelMapScreen({super.key, required this.modeId});

  final String modeId;

  @override
  State<LevelMapScreen> createState() => _LevelMapScreenState();
}

class _LevelMapScreenState extends State<LevelMapScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final mode = context.read<ContentRepository>().mode(widget.modeId);
      context.read<Narrator>().say('${mode.voicePrefix}.welcome');
    });
  }

  void _play(int index) =>
      Navigator.of(context).pushNamed(Routes.game, arguments: GameArgs.level(widget.modeId, index));

  @override
  Widget build(BuildContext context) {
    final mode = context.read<ContentRepository>().mode(widget.modeId);
    final p = context.watch<ProgressStore>();
    final color = GColors.fromHex(mode.color);
    final next = p.nextLevelIndex(mode);
    final dark = SceneBackground.isDark(mode.scene);
    final cols = MediaQuery.sizeOf(context).width >= 600 ? 5 : 3;
    return Scaffold(
      body: SceneBackground(
        scene: mode.scene,
        child: SafeArea(
          child: Column(
            children: [
              GTopBar(title: mode.title, light: dark),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: GSpace.gutter),
                child: ClayCard(
                  padding: const EdgeInsets.symmetric(horizontal: GSpace.md, vertical: GSpace.sm),
                  child: Row(
                    children: [
                      Icon(iconFor(mode.icon), color: color, size: 36),
                      const SizedBox(width: GSpace.sm),
                      Expanded(child: Text(mode.subtitle, style: GText.bodyStrong)),
                      Text(
                        '${faDigits(p.completedInMode(mode.id))}/${faDigits(mode.levels.length)}',
                        style: GText.heading.copyWith(color: color),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(GSpace.gutter),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
                    mainAxisSpacing: GSpace.md,
                    crossAxisSpacing: GSpace.md,
                    childAspectRatio: .86,
                  ),
                  itemCount: mode.levels.length,
                  itemBuilder: (context, i) {
                    final level = mode.levels[i];
                    final unlocked = p.isLevelUnlocked(mode, i);
                    final stars = p.starsFor(mode.id, level.number);
                    return _LevelBubble(
                      number: level.number,
                      stars: stars,
                      unlocked: unlocked,
                      current: i == next && stars == 0,
                      color: color,
                      onTap: unlocked ? () => _play(i) : null,
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(GSpace.gutter, 0, GSpace.gutter, GSpace.md),
                child: ClayButton(
                  label: p.completedInMode(mode.id) == 0 ? 'شروع بازی' : 'ادامه بازی',
                  icon: Icons.play_arrow_rounded,
                  color: GColors.orange,
                  big: true,
                  onTap: () => _play(next),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LevelBubble extends StatelessWidget {
  const _LevelBubble({
    required this.number,
    required this.stars,
    required this.unlocked,
    required this.current,
    required this.color,
    required this.onTap,
  });

  final int number;
  final int stars;
  final bool unlocked;
  final bool current;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final label = unlocked
        ? 'مرحله ${faDigits(number)}${stars > 0 ? '، ${faDigits(stars)} ستاره' : ''}'
        : 'مرحله ${faDigits(number)}، قفل';
    return Semantics(
      label: label,
      button: unlocked,
      child: ExcludeSemantics(
        child: Column(
          children: [
            Expanded(
              child: AspectRatio(
                aspectRatio: 1,
                child: Pressable(
                  onTap: onTap,
                  color: unlocked ? (stars > 0 ? GColors.green : color) : const Color(0xFFB9B4CC),
                  depth: 6,
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: current ? GColors.yellow : Colors.white, width: current ? 6 : 4),
                    ),
                    child: unlocked
                        ? Text(faDigits(number), style: GText.display.copyWith(color: Colors.white, fontSize: 30))
                        : const Icon(Icons.lock_rounded, color: Colors.white, size: 30),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < 3; i++)
                  Icon(
                    Icons.star_rounded,
                    size: 20,
                    color: i < stars ? GColors.yellow : Colors.white.withValues(alpha: .75),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
