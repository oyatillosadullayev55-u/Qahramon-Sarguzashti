import 'dart:ui' as ui;

import 'package:flutter/services.dart';

/// Barcha rasmlarni oldindan yuklab, CustomPainter uchun tayyor ushlab turadi.
class Sprites {
  Sprites._();

  static const List<String> names = [
    'hero_idle', 'hero_run1', 'hero_run2', 'hero_run3', 'hero_jump',
    'coin', 'star', 'heart', 'gem', 'qblock', 'magnet', 'bolt', 'potion',
    'grass_l', 'grass_m', 'grass_s', 'stone', 'crate', 'barrel', 'signpost',
    'btn_play', 'btn_pause', 'btn_restart', 'btn_home',
    'slime', 'turtle', 'ghost', 'bomb',
    'bg_day', 'bg_night', 'bg_forest',
    'plank', 'level_complete', 'scroll', 'stars_bar', 'game_over',
  ];

  static final Map<String, ui.Image> _images = {};

  static String path(String name) => 'assets/images/$name.png';

  static ui.Image get(String name) => _images[name]!;

  static Future<void> load() async {
    for (final n in names) {
      final data = await rootBundle.load(path(n));
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      _images[n] = frame.image;
    }
  }
}
