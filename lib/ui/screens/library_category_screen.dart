import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/design/theme.dart';
import '../../core/design/tokens.dart';
import '../../core/narrator.dart';
import '../../data/content_repository.dart';
import '../../data/models.dart';
import '../widgets/common.dart';
import '../widgets/game_widgets.dart';
import '../widgets/mascot.dart';

/// صداهای یک دسته: لمس هر کارت، صدایش را پخش و بعد نامش را می‌گوید.
class LibraryCategoryScreen extends StatefulWidget {
  const LibraryCategoryScreen({super.key, required this.categoryId});

  final String categoryId;

  @override
  State<LibraryCategoryScreen> createState() => _LibraryCategoryScreenState();
}

class _LibraryCategoryScreenState extends State<LibraryCategoryScreen> {
  String? _playing;

  Future<void> _play(SoundItem s) async {
    final n = context.read<Narrator>();
    n.audio.stopAll();
    setState(() => _playing = s.id);
    await n.audio.playSound(s.audio);
    if (!mounted || _playing != s.id) return;
    await n.say('snd.${s.id}');
    if (mounted && _playing == s.id) setState(() => _playing = null);
  }

  @override
  Widget build(BuildContext context) {
    final content = context.read<ContentRepository>();
    final cat = content.category(widget.categoryId);
    final sounds = content.soundsIn(cat.id);
    final color = GColors.fromHex(cat.color);
    final cols = MediaQuery.sizeOf(context).width >= 600 ? 4 : 3;
    return Scaffold(
      backgroundColor: GColors.tint(color, .36),
      body: SafeArea(
        child: Column(
          children: [
            GTopBar(title: cat.title),
            Text(cat.blurb, style: GText.body, textAlign: TextAlign.center),
            const SizedBox(height: GSpace.xs),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: GSpace.gutter),
              child: SpeechBubble(),
            ),
            Expanded(
              child: GridView.count(
                padding: const EdgeInsets.all(GSpace.gutter),
                crossAxisCount: cols,
                mainAxisSpacing: GSpace.md,
                crossAxisSpacing: GSpace.md,
                childAspectRatio: .82,
                children: [
                  for (final s in sounds)
                    OptionCard(
                      image: s.image,
                      title: s.title,
                      state: _playing == s.id ? OptionState.active : OptionState.idle,
                      onTap: () => _play(s),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
