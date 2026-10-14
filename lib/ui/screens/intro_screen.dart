import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/design/theme.dart';
import '../../core/design/tokens.dart';
import '../../core/narrator.dart';
import '../../data/progress_store.dart';
import '../routes.dart';
import '../widgets/clay.dart';
import '../widgets/game_widgets.dart';
import '../widgets/mascot.dart';

class _Page {
  const _Page(this.pose, this.title, this.body, this.voice);

  final MascotPose pose;
  final String title;
  final String body;
  final String voice;
}

const _pages = [
  _Page(MascotPose.wave, 'سلام دوست عزیز!', 'من گوش‌یار هستم.\nبیا با هم دنیای صداها را کشف کنیم.', 'app.intro.1'),
  _Page(MascotPose.listening, 'گوش‌هایت را تیز کن', 'صدای حیوان‌ها، طبیعت، خانه و\nسازها را می‌شنوی.', 'app.intro.2'),
  _Page(MascotPose.cheer, 'گوش کن و پیدا کن', 'اول خوب گوش بده،\nبعد عکس درست را لمس کن.', 'app.intro.3'),
];

/// معرفی برنامه در سه صفحه‌ی کوتاه؛ فقط بار اول نمایش داده می‌شود.
class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final _controller = PageController();
  int _page = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _speak());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _speak() {
    final n = context.read<Narrator>();
    n.audio.stopAll();
    n.say(_pages[_page].voice);
  }

  Future<void> _finish() async {
    await context.read<ProgressStore>().markIntroSeen();
    if (mounted) Navigator.of(context).pushReplacementNamed(Routes.home);
  }

  void _next() {
    if (_page == _pages.length - 1) {
      _finish();
    } else {
      _controller.nextPage(duration: GMotion.medium, curve: GMotion.enter);
    }
  }

  @override
  Widget build(BuildContext context) {
    final last = _page == _pages.length - 1;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF4D9), Color(0xFFFFE3B8), Color(0xFFFFD39A)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Padding(
                  padding: const EdgeInsets.all(GSpace.sm),
                  child: TextButton(
                    onPressed: _finish,
                    style: TextButton.styleFrom(minimumSize: const Size(GTouch.min, GTouch.min)),
                    child: Text('رد شدن', style: GText.bodyStrong.copyWith(color: GColors.purple)),
                  ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _pages.length,
                  onPageChanged: (i) {
                    setState(() => _page = i);
                    _speak();
                  },
                  itemBuilder: (context, i) {
                    final p = _pages[i];
                    return LayoutBuilder(
                      builder: (context, c) => SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: GSpace.gutter),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minHeight: c.maxHeight),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(p.title, style: GText.display.copyWith(fontSize: 30), textAlign: TextAlign.center),
                              const SizedBox(height: GSpace.sm),
                              Text(p.body, style: GText.body.copyWith(fontSize: 18), textAlign: TextAlign.center),
                              const SizedBox(height: GSpace.lg),
                              Mascot(pose: p.pose, size: (c.maxHeight * .5).clamp(160.0, 300.0)),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              StepDots(index: _page, total: _pages.length),
              Padding(
                padding: const EdgeInsets.fromLTRB(GSpace.gutter, GSpace.md, GSpace.gutter, GSpace.lg),
                child: ClayButton(
                  label: last ? 'بزن بریم!' : 'بعدی',
                  icon: last ? Icons.rocket_launch_rounded : Icons.arrow_forward_rounded,
                  color: last ? GColors.orange : GColors.purple,
                  big: true,
                  onTap: _next,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
