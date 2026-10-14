import 'dart:math';

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

/// دروازه‌ی والدین: یک ضرب ساده که کودک خردسال معمولاً نمی‌تواند حل کند.
class ParentGateScreen extends StatefulWidget {
  const ParentGateScreen({super.key});

  @override
  State<ParentGateScreen> createState() => _ParentGateScreenState();
}

class _ParentGateScreenState extends State<ParentGateScreen> {
  final _random = Random();
  late int _a;
  late int _b;
  String _entry = '';
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _newQuestion();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<Narrator>().say('app.parent.gate'));
  }

  void _newQuestion() {
    _a = 3 + _random.nextInt(7);
    _b = 3 + _random.nextInt(7);
    _entry = '';
  }

  void _press(String d) {
    setState(() {
      _error = false;
      if (d == '<') {
        if (_entry.isNotEmpty) _entry = _entry.substring(0, _entry.length - 1);
      } else if (_entry.length < 3) {
        _entry += d;
      }
    });
    if (_entry.length >= (_a * _b).toString().length) _check();
  }

  void _check() {
    if (int.tryParse(_entry) == _a * _b) {
      Navigator.of(context).pushReplacementNamed(Routes.parent);
    } else {
      setState(() {
        _error = true;
        _newQuestion();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const GTopBar(title: 'بخش والدین'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(GSpace.gutter),
                child: Column(
                  children: [
                    const Icon(Icons.lock_rounded, color: GColors.purple, size: 48),
                    const SizedBox(height: GSpace.xs),
                    const Text('این بخش مخصوص بزرگ‌ترهاست.', style: GText.heading, textAlign: TextAlign.center),
                    const SizedBox(height: GSpace.xs),
                    Text('حاصل ضرب را وارد کنید:', style: GText.body),
                    const SizedBox(height: GSpace.sm),
                    // معادله و صفحه‌کلید عددی حتی در رابط فارسی چپ‌به‌راست خوانده می‌شوند.
                    Text(
                      '${faDigits(_a)} × ${faDigits(_b)} = ?',
                      textDirection: TextDirection.ltr,
                      style: GText.display.copyWith(fontSize: 36),
                    ),
                    const SizedBox(height: GSpace.sm),
                    Container(
                      width: 160,
                      height: 60,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(GRadius.md),
                        border: Border.all(color: _error ? GColors.red : GColors.line, width: 3),
                      ),
                      child: Text(faDigits(_entry), style: GText.title),
                    ),
                    if (_error)
                      Padding(
                        padding: const EdgeInsets.only(top: GSpace.xs),
                        child: Text('درست نبود؛ یک پرسش تازه آمد.', style: GText.caption.copyWith(color: GColors.red)),
                      ),
                    const SizedBox(height: GSpace.md),
                    _Keypad(onPress: _press),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Keypad extends StatelessWidget {
  const _Keypad({required this.onPress});

  final ValueChanged<String> onPress;

  @override
  Widget build(BuildContext context) {
    const keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '', '0', '<'];
    return Directionality(
      textDirection: TextDirection.ltr,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: GSpace.sm,
          crossAxisSpacing: GSpace.sm,
          childAspectRatio: 1.5,
          children: [
            for (final k in keys)
              if (k.isEmpty)
                const SizedBox.shrink()
              else
                Pressable(
                  onTap: () => onPress(k),
                  color: k == '<' ? GColors.orange : GColors.blue,
                  radius: GRadius.md,
                  depth: 5,
                  semanticLabel: k == '<' ? 'پاک کردن' : faDigits(k),
                  child: Center(
                    child: k == '<'
                        ? const Icon(Icons.backspace_rounded, color: Colors.white)
                        : Text(faDigits(k), style: GText.title.copyWith(color: Colors.white)),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

/// گزارش والدین: پیشرفت هر مهارت، امتیاز، مدال‌ها، و پاک کردن پیشرفت.
class ParentDashboardScreen extends StatelessWidget {
  const ParentDashboardScreen({super.key});

  static const _skills = {
    'who_made_sound': 'تشخیص صدا',
    'find_source': 'تمرکز و یافتن منبع صدا',
    'sequence': 'حافظه‌ی شنیداری',
    'audio_mission': 'تفکیک صداهای همزمان',
  };

  @override
  Widget build(BuildContext context) {
    final content = context.read<ContentRepository>();
    final p = context.watch<ProgressStore>();
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const GTopBar(title: 'گزارش والدین'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(GSpace.gutter, GSpace.xs, GSpace.gutter, GSpace.xl),
                children: [
                  ClayCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('خلاصه', style: GText.heading.copyWith(color: GColors.purple)),
                        const SizedBox(height: GSpace.xs),
                        _row('امتیاز کل', faDigits(p.points)),
                        _row('مراحل کامل‌شده', '${faDigits(p.completedCount)} از ${faDigits(content.totalLevels)}'),
                        _row('ستاره‌ها', faDigits(p.totalStars)),
                        _row('مدال‌ها', '${faDigits(p.badges.length)} از ${faDigits(content.achievements.length)}'),
                        _row('بهترین زنجیره‌ی پاسخ درست', faDigits(p.bestStreak)),
                      ],
                    ),
                  ),
                  const SizedBox(height: GSpace.md),
                  ClayCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('مهارت‌ها', style: GText.heading.copyWith(color: GColors.purple)),
                        for (final m in content.modes) ...[
                          const SizedBox(height: GSpace.sm),
                          Row(
                            children: [
                              Icon(iconFor(m.icon), color: GColors.fromHex(m.color)),
                              const SizedBox(width: GSpace.xs),
                              Expanded(child: Text(_skills[m.id] ?? m.title, style: GText.bodyStrong)),
                              Text(
                                '${faDigits(p.completedInMode(m.id))}/${faDigits(m.levels.length)}',
                                style: GText.caption,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(GRadius.pill),
                            child: LinearProgressIndicator(
                              value: p.completedInMode(m.id) / m.levels.length,
                              minHeight: 10,
                              color: GColors.fromHex(m.color),
                              backgroundColor: GColors.line,
                            ),
                          ),
                        ],
                        const SizedBox(height: GSpace.sm),
                        Text('بازی دسته‌ها', style: GText.bodyStrong),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: GSpace.xs,
                          runSpacing: GSpace.xs,
                          children: [
                            for (final c in content.categories)
                              Chip(
                                label: Text(
                                  '${c.title}: ${faDigits(p.categorySessions(c.id))} دور',
                                  style: GText.caption.copyWith(color: GColors.ink),
                                ),
                                backgroundColor: GColors.tint(GColors.fromHex(c.color), .36),
                                side: BorderSide.none,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: GSpace.md),
                  ClayCard(
                    child: Text(
                      'گوش‌یار برای کودکان ۳ تا ۸ سال است. جلسه‌های کوتاه ۱۰ تا ۱۵ دقیقه‌ای و بازی همراه با بزرگ‌ترها بهترین نتیجه را دارد. '
                      'همه‌ی صداها و تصویرهای اصلی داخل برنامه‌اند و بدون اینترنت کار می‌کنند.',
                      style: GText.body,
                    ),
                  ),
                  const SizedBox(height: GSpace.lg),
                  ClayButton(
                    label: 'تنظیمات صدا',
                    icon: Icons.tune_rounded,
                    color: GColors.blue,
                    onTap: () => Navigator.of(context).pushNamed(Routes.settings),
                  ),
                  const SizedBox(height: GSpace.sm),
                  ClayButton(
                    label: 'پاک کردن همه‌ی پیشرفت',
                    icon: Icons.delete_forever_rounded,
                    color: GColors.red,
                    onTap: () async {
                      final ok = await confirmSheet(
                        context,
                        title: 'همه‌ی پیشرفت پاک شود؟',
                        message: 'امتیازها، ستاره‌ها، مراحل و مدال‌ها پاک می‌شوند و برنمی‌گردند.',
                        confirm: 'بله، پاک کن',
                      );
                      if (ok) await p.reset();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String k, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        Expanded(child: Text(k, style: GText.body)),
        Text(v, style: GText.bodyStrong),
      ],
    ),
  );
}
