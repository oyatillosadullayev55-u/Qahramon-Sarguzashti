import 'dart:ui' as ui;

import 'package:flutter/services.dart';

/// Barcha rasmlarni oldindan yuklab, CustomPainter uchun tayyor ushlab turadi.
class Sprites {
  Sprites._();

  static const List<String> names = [
    // qahramon pozalari
    'hero_idle', 'hero_run', 'hero_jump', 'hero_attack', 'hero_hurt',
    'hero_die', 'hero_slide', 'hero_celebrate',
    // yig'iladigan narsalar
    'coin', 'star', 'heart', 'gem', 'key', 'shield', 'magnet', 'bolt', 'potion',
    'qblock', 'chest', 'crown',
    // to'siqlar
    'grass_l', 'grass_s', 'stone', 'crate', 'ice', 'spikes', 'signpost',
    // dushmanlar
    'slime', 'turtle', 'ghost', 'bomb',
    // fonlar
    'bg_day', 'bg_night', 'bg_forest', 'bg_env',
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
