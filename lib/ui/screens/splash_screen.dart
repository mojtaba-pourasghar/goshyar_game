import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/design/theme.dart';
import '../../core/design/tokens.dart';
import '../../core/narrator.dart';
import '../../data/progress_store.dart';
import '../routes.dart';
import '../widgets/clay.dart';
import '../widgets/common.dart';
import '../widgets/mascot.dart';
import '../widgets/scene.dart';

/// صفحه‌ی شروع: لوگو، گوش‌یار با هدفون، شعار و دکمه‌ی بزرگ پخش.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<Narrator>().say('app.splash.welcome'));
  }

  void _start() {
    final seen = context.read<ProgressStore>().introSeen;
    Navigator.of(context).pushReplacementNamed(seen ? Routes.home : Routes.intro);
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height;
    return Scaffold(
      body: SceneBackground(
        scene: 'meadow',
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, c) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: c.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: GSpace.gutter, vertical: GSpace.md),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: ClayIconButton(
                          icon: Icons.settings_rounded,
                          label: 'تنظیمات',
                          onTap: () => Navigator.of(context).pushNamed(Routes.settings),
                        ),
                      ),
                      GoshyarLogo(size: h < 640 ? 46 : 60),
                      Mascot(pose: MascotPose.listening, size: (h * .32).clamp(170.0, 300.0)),
                      const SectionPill('بازی کن، گوش بده، کشف کن!', color: GColors.purple),
                      const SizedBox(height: GSpace.sm),
                      const SpeechBubble(),
                      const SizedBox(height: GSpace.md),
                      Pressable(
                        onTap: _start,
                        color: GColors.orange,
                        depth: 8,
                        semanticLabel: 'شروع',
                        child: Container(
                          width: 104,
                          height: 96,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 6),
                          ),
                          child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 64),
                        ),
                      ),
                      const SizedBox(height: GSpace.xs),
                      Text(
                        'اولین بازی آموزشی شنیداری برای کودکان',
                        style: GText.caption.copyWith(color: GColors.ink),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
