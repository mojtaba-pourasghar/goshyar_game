import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/assets/asset_resolver.dart';
import '../../core/design/theme.dart';
import '../../core/design/tokens.dart';
import '../../core/narrator.dart';
import '../../data/content_repository.dart';
import '../../data/models.dart';
import '../../data/progress_store.dart';
import '../routes.dart';
import '../widgets/clay.dart';
import '../widgets/game_widgets.dart';
import '../widgets/icons.dart';
import '../widgets/mascot.dart';
import 'game_screen.dart';

class ResultArgs {
  const ResultArgs({
    required this.game,
    required this.stars,
    required this.points,
    this.badges = const [],
    this.image,
    this.answerTitle,
  });

  final GameArgs game;
  final int stars;
  final int points;
  final List<Achievement> badges;
  final String? image;
  final String? answerTitle;
}

/// نتیجه: روبان «آفرین!»، ستاره‌ها، امتیاز، مدال‌های تازه و دکمه‌ی مرحله‌ی بعد.
class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key, required this.args});

  final ResultArgs args;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  int _token = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _celebrate());
  }

  @override
  void dispose() {
    _token++;
    super.dispose();
  }

  GameMode? get _mode =>
      widget.args.game.modeId == null ? null : context.read<ContentRepository>().mode(widget.args.game.modeId!);

  int? get _nextIndex {
    final m = _mode;
    if (m == null) return null;
    final i = widget.args.game.levelIndex + 1;
    return i < m.levels.length ? i : null;
  }

  Future<void> _celebrate() async {
    final t = ++_token;
    final n = context.read<Narrator>();
    final progress = context.read<ProgressStore>();
    final content = context.read<ContentRepository>();
    bool alive() => mounted && t == _token;

    await n.sayOneOf('level.complete');
    if (!alive()) return;
    await n.say('result.stars.${widget.args.stars.clamp(1, 3)}');
    for (final b in widget.args.badges) {
      if (!alive()) return;
      await n.say('badge.${b.id}');
    }
    if (!alive()) return;
    if (widget.args.game.isCategory) {
      await n.say('cat.complete');
    } else if (progress.completedCount >= content.totalLevels) {
      await n.say('all.done');
    } else if (_nextIndex == null) {
      await n.say('mode.done');
    } else {
      await n.sayOneOf('level.next');
    }
  }

  void _next() {
    final nav = Navigator.of(context);
    final next = _nextIndex;
    if (next != null) {
      nav.pushReplacementNamed(Routes.game, arguments: GameArgs.level(widget.args.game.modeId!, next));
    } else {
      nav.pop();
    }
  }

  void _again() => Navigator.of(context).pushReplacementNamed(Routes.game, arguments: widget.args.game);

  @override
  Widget build(BuildContext context) {
    final a = widget.args;
    final img = a.image == null ? null : context.read<AssetResolver>().image(a.image!);
    final h = MediaQuery.sizeOf(context).height;
    final hasNext = _nextIndex != null;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFDFF3FF), Color(0xFFFFF6DA), Color(0xFFFFE7B3)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: GSpace.gutter, vertical: GSpace.md),
                  child: Column(
                    children: [
                      const _Ribbon(text: 'آفرین!'),
                      const SizedBox(height: GSpace.sm),
                      SizedBox(
                        height: (h * .27).clamp(150.0, 240.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Mascot(pose: MascotPose.celebrate, size: (h * .25).clamp(140.0, 220.0)),
                            if (img != null)
                              Container(
                                width: (h * .14).clamp(90.0, 130.0),
                                height: (h * .14).clamp(90.0, 130.0),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 5),
                                  boxShadow: GShadow.soft(),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Image(image: img, fit: BoxFit.cover),
                              ),
                          ],
                        ),
                      ),
                      Text(
                        switch (a.stars) {
                          3 => 'خیلی خوب جواب دادی!',
                          2 => 'خیلی خوب بود!',
                          _ => 'تمامش کردی! باز هم تمرین کنیم.',
                        },
                        style: GText.title,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: GSpace.sm),
                      StarRow(stars: a.stars, size: 58),
                      const SizedBox(height: GSpace.sm),
                      ScoreChip(points: a.points, prefix: '+'),
                      const SizedBox(height: GSpace.sm),
                      const SpeechBubble(),
                      for (final b in a.badges) ...[const SizedBox(height: GSpace.sm), _BadgeCard(badge: b)],
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(GSpace.gutter, 0, GSpace.gutter, GSpace.md),
                child: Column(
                  children: [
                    ClayButton(
                      label: hasNext ? 'مرحله بعد' : (a.game.isCategory ? 'بازی دوباره' : 'برگشت به مراحل'),
                      icon: hasNext ? Icons.arrow_back_rounded : Icons.replay_rounded,
                      big: true,
                      onTap: hasNext || !a.game.isCategory ? _next : _again,
                    ),
                    const SizedBox(height: GSpace.sm),
                    Row(
                      children: [
                        Expanded(
                          // وقتی دکمه‌ی اصلی خودش «بازی دوباره» است، این دکمه به صفحه‌ی قبل برمی‌گردد.
                          child: (hasNext || !a.game.isCategory)
                              ? ClayButton(
                                  label: 'دوباره',
                                  icon: Icons.replay_rounded,
                                  color: GColors.orange,
                                  onTap: _again,
                                )
                              : ClayButton(
                                  label: 'برگشت',
                                  icon: Icons.arrow_back_rounded,
                                  color: GColors.orange,
                                  onTap: () => Navigator.of(context).pop(),
                                ),
                        ),
                        const SizedBox(width: GSpace.sm),
                        Expanded(
                          child: ClayButton(
                            label: 'خانه',
                            icon: Icons.home_rounded,
                            color: GColors.blue,
                            onTap: () => Navigator.of(context).pushNamedAndRemoveUntil(Routes.home, (_) => false),
                          ),
                        ),
                      ],
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

class _Ribbon extends StatelessWidget {
  const _Ribbon({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: GSpace.xl, vertical: GSpace.xs),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [GColors.greenDark, GColors.green, GColors.greenDark]),
          borderRadius: BorderRadius.circular(GRadius.md),
          boxShadow: GShadow.soft(GColors.greenDark),
        ),
        child: Text(text, style: GText.display.copyWith(color: Colors.white, fontSize: 34)),
      ),
    );
  }
}

class _BadgeCard extends StatelessWidget {
  const _BadgeCard({required this.badge});

  final Achievement badge;

  @override
  Widget build(BuildContext context) {
    return ClayCard(
      border: GColors.yellow,
      padding: const EdgeInsets.all(GSpace.sm),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [GColors.yellow, GColors.orange]),
            ),
            child: Icon(iconFor(badge.icon), color: Colors.white, size: 32),
          ),
          const SizedBox(width: GSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('مدال تازه: ${badge.title}', style: GText.bodyStrong),
                Text(badge.desc, style: GText.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
