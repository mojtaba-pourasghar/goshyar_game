import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/audio/game_audio.dart';
import '../../core/design/theme.dart';
import '../../core/design/tokens.dart';
import '../../core/fa.dart';
import '../../core/narrator.dart';
import '../../data/content_repository.dart';
import '../../data/progress_store.dart';
import '../routes.dart';
import '../widgets/clay.dart';
import '../widgets/common.dart';
import '../widgets/game_widgets.dart';
import '../widgets/icons.dart';
import '../widgets/mascot.dart';
import 'games_tab.dart';
import 'library_tab.dart';
import 'profile_tab.dart';

/// پوسته‌ی اصلی با نوار پایین چهار بخشی: خانه، بازی‌ها، صداها، من.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late int _tab = widget.initialTab;

  static const _tabVoice = ['home.greet', 'app.games.hub', 'app.library.hint', 'app.progress.shown'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _speak());
  }

  void _speak() {
    final n = context.read<Narrator>();
    n.audio.stopAll();
    final id = _tabVoice[_tab];
    if (id.contains('greet')) {
      n.sayOneOf(id);
    } else {
      n.say(id);
    }
  }

  void _select(int i) {
    if (i == _tab) return;
    setState(() => _tab = i);
    _speak();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: [
          HomeTab(onOpenGames: () => _select(1)),
          const GamesTab(),
          const LibraryTab(),
          const ProfileTab(),
        ],
      ),
      bottomNavigationBar: _BottomBar(index: _tab, onSelect: _select),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.index, required this.onSelect});

  final int index;
  final ValueChanged<int> onSelect;

  static const _items = [
    (Icons.home_rounded, 'خانه'),
    (Icons.sports_esports_rounded, 'بازی‌ها'),
    (Icons.library_music_rounded, 'صداها'),
    (Icons.face_rounded, 'من'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(GRadius.lg)),
        boxShadow: GShadow.soft(),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: GSpace.xs, vertical: GSpace.xs),
          child: Row(
            children: [
              for (var i = 0; i < _items.length; i++)
                Expanded(
                  child: Semantics(
                    selected: i == index,
                    button: true,
                    label: _items[i].$2,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(GRadius.md),
                      onTap: () {
                        context.read<GameAudio>().uiTap();
                        onSelect(i);
                      },
                      child: AnimatedContainer(
                        duration: GMotion.quick,
                        height: 64,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: i == index ? GColors.purpleSoft : Colors.transparent,
                          borderRadius: BorderRadius.circular(GRadius.md),
                        ),
                        child: ExcludeSemantics(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(_items[i].$1, size: 30, color: i == index ? GColors.purple : GColors.inkSoft),
                              Text(
                                _items[i].$2,
                                style: GText.caption.copyWith(
                                  fontSize: 13,
                                  color: i == index ? GColors.purple : GColors.inkSoft,
                                  fontWeight: i == index ? FontWeight.w800 : FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// منوی اصلی: سلام به کودک، امتیاز، گوش‌یار و کاشی‌های رنگی دسته‌ها.
class HomeTab extends StatelessWidget {
  const HomeTab({super.key, required this.onOpenGames});

  final VoidCallback onOpenGames;

  @override
  Widget build(BuildContext context) {
    final content = context.read<ContentRepository>();
    final progress = context.watch<ProgressStore>();
    final name = progress.childName.isEmpty ? 'دوست من' : progress.childName;
    final width = MediaQuery.sizeOf(context).width;
    final cols = width >= 600 ? 3 : 2;
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(GSpace.gutter, GSpace.md, GSpace.gutter, 0),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'سلام $name!',
                      style: GText.title.copyWith(color: GColors.purple),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  ScoreChip(points: progress.points),
                  const SizedBox(width: GSpace.xs),
                  ClayIconButton(
                    icon: Icons.settings_rounded,
                    label: 'تنظیمات',
                    size: 52,
                    onTap: () => Navigator.of(context).pushNamed(Routes.settings),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: GSpace.gutter, vertical: GSpace.sm),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  const Mascot(pose: MascotPose.wave, size: 120),
                  const SizedBox(width: GSpace.xs),
                  const Expanded(child: SpeechBubble(fallback: 'امروز با کدام صداها بازی کنیم؟')),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: GSpace.gutter),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  const Flexible(child: SectionPill('دسته‌بندی صداها')),
                  const SizedBox(width: GSpace.xs),
                  Expanded(
                    child: Text(
                      'یکی را انتخاب کن',
                      style: GText.caption,
                      textAlign: TextAlign.end,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(GSpace.gutter, GSpace.md, GSpace.gutter, GSpace.md),
            sliver: SliverGrid.count(
              crossAxisCount: cols,
              mainAxisSpacing: GSpace.md,
              crossAxisSpacing: GSpace.md,
              childAspectRatio: 1.08,
              children: [
                for (final c in content.categories)
                  CategoryTile(
                    title: c.title,
                    icon: iconFor(c.icon),
                    color: GColors.fromHex(c.color),
                    onTap: () => Navigator.of(context).pushNamed(Routes.category, arguments: c.id),
                  ),
              ],
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(GSpace.gutter, 0, GSpace.gutter, GSpace.xl),
            sliver: SliverToBoxAdapter(
              child: Pressable(
                onTap: onOpenGames,
                color: GColors.purple,
                radius: GRadius.lg,
                semanticLabel: 'بازی‌ها و مأموریت‌ها',
                padding: const EdgeInsets.all(GSpace.md),
                child: Row(
                  children: [
                    const Icon(Icons.sports_esports_rounded, color: GColors.yellow, size: 48),
                    const SizedBox(width: GSpace.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('بازی‌ها و مأموریت‌ها', style: GText.label.copyWith(fontSize: 19)),
                          Text(
                            'چهار بازی شنیداری، ${faDigits(content.totalLevels)} مرحله',
                            style: GText.caption.copyWith(color: Colors.white.withValues(alpha: .9)),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
