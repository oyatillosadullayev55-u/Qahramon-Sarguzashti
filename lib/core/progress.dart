import 'package:shared_preferences/shared_preferences.dart';

import 'audio.dart';
import 'constants.dart';

/// Daraja yutuqlari, hamyon (tanga/olmos) va sozlamalar. Telefon xotirasida saqlanadi.
class Progress {
  Progress._();

  static int unlocked = 1;
  static final List<int> stars = List<int>.filled(G.levelCount, 0);
  static final List<int> best = List<int>.filled(G.levelCount, 0);
  static int coins = 0;
  static int gems = 0;
  static bool vibration = true;
  static String playerName = 'Oyatillo';

  static int get totalStars => stars.fold(0, (a, b) => a + b);
  static int get playerLevel => 1 + totalStars;

  static Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      unlocked = (p.getInt('unlocked') ?? 1).clamp(1, G.levelCount).toInt();
      final s = p.getStringList('stars');
      final b = p.getStringList('best');
      for (int i = 0; i < G.levelCount; i++) {
        if (s != null && i < s.length) stars[i] = int.tryParse(s[i]) ?? 0;
        if (b != null && i < b.length) best[i] = int.tryParse(b[i]) ?? 0;
      }
      coins = p.getInt('coins') ?? 0;
      gems = p.getInt('gems') ?? 0;
      Sfx.enabled = p.getBool('sound') ?? true;
      Sfx.musicEnabled = p.getBool('music') ?? true;
      vibration = p.getBool('vibration') ?? true;
    } catch (_) {}
  }

  static Future<void> _save() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setInt('unlocked', unlocked);
      await p.setStringList('stars', stars.map((e) => '$e').toList());
      await p.setStringList('best', best.map((e) => '$e').toList());
      await p.setInt('coins', coins);
      await p.setInt('gems', gems);
      await p.setBool('sound', Sfx.enabled);
      await p.setBool('music', Sfx.musicEnabled);
      await p.setBool('vibration', vibration);
    } catch (_) {}
  }

  static void complete(int level, int earned, int score) {
    if (earned > stars[level]) stars[level] = earned;
    if (score > best[level]) best[level] = score;
    if (level + 2 > unlocked) unlocked = level + 2;
    if (unlocked > G.levelCount) unlocked = G.levelCount;
    _save();
  }

  static void addWallet(int c, int g) {
    coins += c;
    gems += g;
    _save();
  }

  static void saveSettings() => _save();
}
