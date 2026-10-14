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
import '../widgets/mascot.dart';

/// پیشرفت کودک: نام، رتبه، ستاره‌ها، مراحل، پیشرفت هر بازی و مدال‌ها.
class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  Future<void> _editName(BuildContext context, ProgressStore p) async {
    final ctrl = TextEditingController(text: p.childName);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(GRadius.lg)),
        title: const Text('اسم تو چیست؟', style: GText.title, textAlign: TextAlign.center),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLength: 20,
          textAlign: TextAlign.center,
          style: GText.title,
          decoration: const InputDecoration(hintText: 'مثلاً آرین'),
          onSubmitted: (v) => Navigator.pop(context, v),
        ),
        actions: [ClayButton(label: 'ذخیره', color: GColors.green, onTap: () => Navigator.pop(context, ctrl.text))],
      ),
    );
    if (name != null) await p.setChildName(name);
  }

  @override
  Widget build(BuildContext context) {
    final content = context.read<ContentRepository>();
    final p = context.watch<ProgressStore>();
    final cols = MediaQuery.sizeOf(context).width >= 600 ? 4 : 3;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(GSpace.gutter, GSpace.md, GSpace.gutter, GSpace.xl),
        children: [
          ClayCard(
            child: Row(
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: const BoxDecoration(color: GColors.cream, shape: BoxShape.circle),
                  child: const Mascot(pose: MascotPose.cheer, size: 96, bounce: false),
                ),
                const SizedBox(width: GSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              p.childName.isEmpty ? 'قهرمان کوچولو' : p.childName,
                              style: GText.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            tooltip: 'تغییر نام',
                            constraints: const BoxConstraints(minWidth: GTouch.min, minHeight: GTouch.min),
                            onPressed: () => _editName(context, p),
                            icon: const Icon(Icons.edit_rounded, color: GColors.purple),
                          ),
                        ],
                      ),
                      Text('سطح ${faDigits(p.rank)}', style: GText.bodyStrong.copyWith(color: GColors.purple)),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(GRadius.pill),
                        child: LinearProgressIndicator(
                          value: p.rankProgress,
                          minHeight: 12,
                          color: GColors.orange,
                          backgroundColor: GColors.cream,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: GSpace.md),
          Row(
            children: [
              _Stat(icon: Icons.star_rounded, color: GColors.yellowDark, value: p.points, label: 'امتیاز'),
              const SizedBox(width: GSpace.sm),
              _Stat(icon: Icons.auto_awesome_rounded, color: GColors.orange, value: p.totalStars, label: 'ستاره'),
              const SizedBox(width: GSpace.sm),
              _Stat(
                icon: Icons.flag_rounded,
                color: GColors.green,
                value: p.completedCount,
                label: 'از ${faDigits(content.totalLevels)} مرحله',
              ),
            ],
          ),
          const SizedBox(height: GSpace.lg),
          const SectionPill('پیشرفت بازی‌ها'),
          const SizedBox(height: GSpace.sm),
          ClayCard(
            child: Column(
              children: [for (final m in content.modes) _ModeProgress(mode: m, done: p.completedInMode(m.id))],
            ),
          ),
          const SizedBox(height: GSpace.lg),
          Row(
            children: [
              const SectionPill('مدال‌های من'),
              const Spacer(),
              Text('${faDigits(p.badges.length)} از ${faDigits(content.achievements.length)}', style: GText.caption),
            ],
          ),
          const SizedBox(height: GSpace.sm),
          GridView.count(
            crossAxisCount: cols,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: GSpace.sm,
            crossAxisSpacing: GSpace.sm,
            childAspectRatio: .78,
            children: [for (final a in content.achievements) _BadgeTile(a: a, unlocked: p.badges.contains(a.id))],
          ),
          const SizedBox(height: GSpace.lg),
          ClayButton(
            label: 'بخش والدین',
            icon: Icons.lock_rounded,
            color: GColors.blue,
            onTap: () => Navigator.of(context).pushNamed(Routes.parentGate),
          ),
          const SizedBox(height: GSpace.sm),
          ClayButton(
            label: 'صداها و تصویرهای ذخیره‌شده',
            icon: Icons.download_for_offline_rounded,
            color: GColors.green,
            onTap: () => Navigator.of(context).pushNamed(Routes.downloads),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.color, required this.value, required this.label});

  final IconData icon;
  final Color color;
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ClayCard(
        padding: const EdgeInsets.symmetric(vertical: GSpace.sm, horizontal: GSpace.xs),
        child: Semantics(
          label: '${faDigits(value)} $label',
          child: ExcludeSemantics(
            child: Column(
              children: [
                Icon(icon, color: color, size: 30),
                FittedBox(child: Text(faDigits(value), style: GText.title.copyWith(fontSize: 22))),
                Text(label, style: GText.caption.copyWith(fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeProgress extends StatelessWidget {
  const _ModeProgress({required this.mode, required this.done});

  final GameMode mode;
  final int done;

  @override
  Widget build(BuildContext context) {
    final color = GColors.fromHex(mode.color);
    final total = mode.levels.length;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(iconFor(mode.icon), color: color, size: 28),
          const SizedBox(width: GSpace.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(mode.title, style: GText.bodyStrong.copyWith(fontSize: 15)),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(GRadius.pill),
                  child: LinearProgressIndicator(
                    value: total == 0 ? 0 : done / total,
                    minHeight: 10,
                    color: color,
                    backgroundColor: GColors.line,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: GSpace.xs),
          Text('${faDigits(done)}/${faDigits(total)}', style: GText.caption),
        ],
      ),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  const _BadgeTile({required this.a, required this.unlocked});

  final Achievement a;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${a.title}، ${unlocked ? 'گرفته شده' : 'هنوز گرفته نشده'}. ${a.desc}',
      child: ExcludeSemantics(
        child: Opacity(
          opacity: unlocked ? 1 : .45,
          child: ClayCard(
            padding: const EdgeInsets.all(GSpace.xs),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: unlocked
                          ? const [GColors.yellow, GColors.orange]
                          : const [Color(0xFFDCD8EA), Color(0xFFBDB8D3)],
                    ),
                  ),
                  child: Icon(unlocked ? iconFor(a.icon) : Icons.lock_rounded, color: Colors.white, size: 30),
                ),
                const SizedBox(height: 6),
                Text(
                  a.title,
                  style: GText.bodyStrong.copyWith(fontSize: 13),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  a.desc,
                  style: GText.caption.copyWith(fontSize: 11.5, height: 1.3),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
