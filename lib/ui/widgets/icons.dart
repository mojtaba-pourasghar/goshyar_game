import 'package:flutter/material.dart';

/// نام آیکون‌ها در levels.json به آیکون‌های Material گرد.
/// آیکون برداری است و در هر اندازه‌ای تیز می‌ماند؛ از ایموجی استفاده نمی‌شود.
IconData iconFor(String name) => switch (name) {
  'pets' => Icons.pets_rounded,
  'house' => Icons.home_rounded,
  'eco' => Icons.eco_rounded,
  'music' => Icons.music_note_rounded,
  'work' => Icons.work_rounded,
  'rocket' => Icons.rocket_launch_rounded,
  'hearing' => Icons.hearing_rounded,
  'travel_explore' => Icons.travel_explore_rounded,
  'queue_music' => Icons.queue_music_rounded,
  'nights_stay' => Icons.nights_stay_rounded,
  'flag' => Icons.flag_rounded,
  'construction' => Icons.construction_rounded,
  'psychology' => Icons.psychology_rounded,
  'emoji_events' => Icons.emoji_events_rounded,
  _ => Icons.star_rounded,
};
