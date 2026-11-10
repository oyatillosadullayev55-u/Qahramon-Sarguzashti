import 'package:audioplayers/audioplayers.dart';

/// Ovoz effektlari va fon musiqasi. Xatolar o'yinni to'xtatmaydi.
class Sfx {
  Sfx._();

  static bool enabled = true; // ovoz effektlari
  static bool musicEnabled = true; // fon musiqasi

  static const _names = [
    'jump', 'coin', 'block', 'stomp', 'hurt', 'power', 'win', 'lose', 'boss',
    'slash', 'key', 'chest',
  ];
  static final Map<String, List<AudioPlayer>> _pool = {};
  static final Map<String, int> _idx = {};
  static AudioPlayer? _music;
  static bool _musicWanted = false;

  static Future<void> init() async {
    try {
      for (final n in _names) {
        final list = <AudioPlayer>[];
        for (int i = 0; i < 3; i++) {
          final p = AudioPlayer();
          await p.setPlayerMode(PlayerMode.lowLatency);
          await p.setReleaseMode(ReleaseMode.stop);
          list.add(p);
        }
        _pool[n] = list;
        _idx[n] = 0;
      }
      _music = AudioPlayer();
      await _music!.setReleaseMode(ReleaseMode.loop);
    } catch (_) {}
  }

  static void play(String name) {
    if (!enabled) return;
    final list = _pool[name];
    if (list == null) return;
    final i = (_idx[name] ?? 0) % list.length;
    _idx[name] = i + 1;
    try {
      list[i].play(AssetSource('sounds/$name.wav'), volume: 0.9);
    } catch (_) {}
  }

  static void startMusic() {
    _musicWanted = true;
    if (!musicEnabled) return;
    try {
      _music?.play(AssetSource('sounds/music.wav'), volume: 0.3);
    } catch (_) {}
  }

  static void pauseMusic() {
    try {
      _music?.pause();
    } catch (_) {}
  }

  static void resumeMusic() {
    if (!musicEnabled || !_musicWanted) return;
    try {
      _music?.resume();
    } catch (_) {}
  }

  static void stopMusic() {
    _musicWanted = false;
    try {
      _music?.stop();
    } catch (_) {}
  }

  static void setMusic(bool v) {
    musicEnabled = v;
    if (!v) {
      pauseMusic();
    } else if (_musicWanted) {
      startMusic();
    }
  }

  static void setSounds(bool v) => enabled = v;
}
