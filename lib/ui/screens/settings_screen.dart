import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/design/theme.dart';
import '../../core/design/tokens.dart';
import '../../core/fa.dart';
import '../../core/narrator.dart';
import '../../data/settings_store.dart';
import '../routes.dart';
import '../widgets/clay.dart';
import '../widgets/common.dart';

/// تنظیمات صدا: سه کانال مستقل (گوینده، صداهای بازی، موسیقی) و زیرنویس.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<Narrator>().say('app.settings.shown'));
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsStore>();
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const GTopBar(title: 'تنظیمات'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(GSpace.gutter, GSpace.xs, GSpace.gutter, GSpace.xl),
                children: [
                  _ChannelCard(
                    channel: AudioChannel.voice,
                    icon: Icons.record_voice_over_rounded,
                    color: GColors.purple,
                    title: 'صدای گوش‌یار',
                    subtitle: 'راهنما و تشویق‌ها',
                    settings: s,
                  ),
                  const SizedBox(height: GSpace.md),
                  _ChannelCard(
                    channel: AudioChannel.effects,
                    icon: Icons.pets_rounded,
                    color: GColors.orange,
                    title: 'صداهای بازی',
                    subtitle: 'صدای حیوان‌ها، وسایل و افکت‌ها',
                    settings: s,
                  ),
                  const SizedBox(height: GSpace.md),
                  _ChannelCard(
                    channel: AudioChannel.music,
                    icon: Icons.music_note_rounded,
                    color: GColors.pink,
                    title: 'موسیقی',
                    subtitle: 'آهنگ آرام پس‌زمینه',
                    settings: s,
                  ),
                  const SizedBox(height: GSpace.md),
                  ClayCard(
                    child: Material(
                      type: MaterialType.transparency,
                      child: SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: s.subtitles,
                        onChanged: s.setSubtitles,
                        secondary: const Icon(Icons.chat_bubble_rounded, color: GColors.blue, size: 32),
                        title: const Text('نمایش حرف‌های گوش‌یار', style: GText.bodyStrong),
                        subtitle: const Text('متن هر جمله در حباب گفت‌وگو', style: GText.caption),
                      ),
                    ),
                  ),
                  const SizedBox(height: GSpace.lg),
                  ClayButton(
                    label: 'صداها و تصویرهای ذخیره‌شده',
                    icon: Icons.download_for_offline_rounded,
                    color: GColors.green,
                    onTap: () => Navigator.of(context).pushNamed(Routes.downloads),
                  ),
                  const SizedBox(height: GSpace.sm),
                  ClayButton(
                    label: 'بخش والدین',
                    icon: Icons.lock_rounded,
                    color: GColors.blue,
                    onTap: () => Navigator.of(context).pushNamed(Routes.parentGate),
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

class _ChannelCard extends StatelessWidget {
  const _ChannelCard({
    required this.channel,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.settings,
  });

  final AudioChannel channel;
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final SettingsStore settings;

  @override
  Widget build(BuildContext context) {
    final on = settings.isOn(channel);
    final vol = settings.volume(channel);
    return ClayCard(
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(color: GColors.tint(color, .36), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 30),
              ),
              const SizedBox(width: GSpace.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: GText.bodyStrong),
                    Text(subtitle, style: GText.caption),
                  ],
                ),
              ),
              Semantics(
                label: '$title ${on ? 'روشن' : 'خاموش'}',
                child: Switch(value: on, onChanged: (v) => settings.setOn(channel, v)),
              ),
            ],
          ),
          Row(
            children: [
              const Icon(Icons.volume_mute_rounded, color: GColors.inkSoft),
              Expanded(
                child: Slider(
                  value: vol,
                  onChanged: on ? (v) => settings.setVolume(channel, v) : null,
                  activeColor: color,
                  inactiveColor: GColors.line,
                  label: faDigits((vol * 100).round()),
                  semanticFormatterCallback: (v) => 'بلندی ${faDigits((v * 100).round())} درصد',
                ),
              ),
              const Icon(Icons.volume_up_rounded, color: GColors.inkSoft),
            ],
          ),
        ],
      ),
    );
  }
}
