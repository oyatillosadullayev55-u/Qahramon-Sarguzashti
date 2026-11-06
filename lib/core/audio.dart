import 'package:audioplayers/audioplayers.dart';

/// Ovoz effektlari va fon musiqasi uchun xavfsiz boshqaruv sinfi.
class Sfx {
  Sfx._();

  static bool enabled = true;

  static final Map<String, List<AudioPlayer>> _players = {};
  static final Map<String, int> _playerIndices = {};
  static AudioPlayer? _musicPlayer;
  static bool _musicWanted = false;

  static const int _poolSize = 3;

  static Future<void> init() async {
    try {
      _musicPlayer ??= AudioPlayer();
    } catch (_) {}
  }

  static void play(String name) {
    if (!enabled) return;
    try {
      _players[name] ??= List.generate(_poolSize, (_) => AudioPlayer());
      _playerIndices[name] ??= 0;

      final list = _players[name]!;
      final idx = _playerIndices[name]! % list.length;
      _playerIndices[name] = idx + 1;

      final player = list[idx];
      player.stop().then((_) {
        player.play(AssetSource('sounds/$name.wav'), volume: 0.85);
      }).catchError((_) {
        player.play(AssetSource('sounds/$name.wav'), volume: 0.85);
      });
    } catch (_) {}
  }

  static void startMusic() {
    _musicWanted = true;
    if (!enabled) return;
    try {
      _musicPlayer ??= AudioPlayer();
      _musicPlayer!.setReleaseMode(ReleaseMode.loop).then((_) {
        _musicPlayer!.play(AssetSource('sounds/music.wav'), volume: 0.35);
      }).catchError((_) {
        _musicPlayer!.play(AssetSource('sounds/music.wav'), volume: 0.35);
      });
    } catch (_) {}
  }

  static void pauseMusic() {
    try {
      _musicPlayer?.pause();
    } catch (_) {}
  }

  static void resumeMusic() {
    if (!enabled || !_musicWanted) return;
    try {
      if (_musicPlayer?.state == PlayerState.paused) {
        _musicPlayer?.resume();
      } else {
        startMusic();
      }
    } catch (_) {}
  }

  static void stopMusic() {
    _musicWanted = false;
    try {
      _musicPlayer?.stop();
    } catch (_) {}
  }

  static void setEnabled(bool v) {
    enabled = v;
    if (!v) {
      pauseMusic();
    } else if (_musicWanted) {
      startMusic();
    }
  }
}
