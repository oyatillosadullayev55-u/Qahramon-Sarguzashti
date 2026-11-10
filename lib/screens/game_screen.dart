import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../core/audio.dart';
import '../core/constants.dart';
import '../core/progress.dart';
import '../core/sprites.dart';
import '../game/game_painter.dart';
import '../game/game_world.dart';
import '../widgets/common.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.level});

  final int level;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final GameWorld world;
  late final Ticker _ticker;
  final FocusNode _focus = FocusNode();
  Duration _last = Duration.zero;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    world = GameWorld(widget.level);
    _ticker = createTicker(_tick)..start();
    world.phase.addListener(_onPhase);
    Sfx.startMusic();
  }

  void _onPhase() {
    final p = world.phase.value;
    if (p == GamePhase.won || p == GamePhase.lost) Sfx.pauseMusic();
  }

  void _tick(Duration elapsed) {
    var dt = (elapsed - _last).inMicroseconds / 1000000.0;
    _last = elapsed;
    if (dt > 1 / 30) dt = 1 / 30;
    if (dt < 0) dt = 0;
    world.update(dt);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      world.pause();
      Sfx.pauseMusic();
    } else {
      Sfx.resumeMusic();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    world.phase.removeListener(_onPhase);
    Sfx.stopMusic();
    _ticker.dispose();
    _focus.dispose();
    world.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------- keyboard
  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    final key = event.logicalKey;
    final down = event is KeyDownEvent;
    final up = event is KeyUpEvent;
    if (!down && !up) return KeyEventResult.ignored;

    if (key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.keyA) {
      world.input.kLeft = down;
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowRight || key == LogicalKeyboardKey.keyD) {
      world.input.kRight = down;
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.space ||
        key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.keyW) {
      if (down) {
        world.input.pressJump(touch: false);
      } else {
        world.input.releaseJump(touch: false);
      }
      return KeyEventResult.handled;
    }
    if (down && (key == LogicalKeyboardKey.keyJ || key == LogicalKeyboardKey.keyX)) {
      world.input.pressAttack();
      return KeyEventResult.handled;
    }
    if (down && (key == LogicalKeyboardKey.keyS || key == LogicalKeyboardKey.arrowDown)) {
      world.input.pressSlide();
      return KeyEventResult.handled;
    }
    if (down && (key == LogicalKeyboardKey.escape || key == LogicalKeyboardKey.keyP)) {
      if (world.phase.value == GamePhase.playing) {
        world.pause();
      } else {
        world.resume();
      }
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  // ----------------------------------------------------------- navigation
  void _restart() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => GameScreen(level: widget.level)),
    );
  }

  void _next() {
    if (widget.level + 1 < G.levelCount) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => GameScreen(level: widget.level + 1)),
      );
    } else {
      _home();
    }
  }

  void _home() => Navigator.of(context).popUntil((r) => r.isFirst);

  // ---------------------------------------------------------------- build
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Focus(
        focusNode: _focus,
        autofocus: true,
        onKeyEvent: _onKey,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: RepaintBoundary(
                child: CustomPaint(painter: GamePainter(world)),
              ),
            ),
            Positioned.fill(
              child: SafeArea(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Positioned(left: 0, right: 0, top: 0, child: _hud()),
                    _controls(),
                  ],
                ),
              ),
            ),
            ValueListenableBuilder<GamePhase>(
              valueListenable: world.phase,
              builder: (context, p, _) {
                if (p == GamePhase.paused) return _pauseOverlay();
                if (p == GamePhase.won) return _winOverlay();
                if (p == GamePhase.lost) return _loseOverlay();
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------------ HUD
  Widget _hud() {
    return ValueListenableBuilder<int>(
      valueListenable: world.hudTick,
      builder: (context, _, __) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(10, 6, 10, 0),
          child: Stack(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const HeroAvatar(size: 46),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (int i = 0; i < world.lives; i++)
                            Padding(
                              padding: const EdgeInsets.only(right: 3),
                              child: Image.asset(Sprites.path('heart'), width: 24),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          StatPill(asset: 'coin', value: '${world.score}', iconSize: 20),
                          const SizedBox(width: 6),
                          StatPill(asset: 'gem', value: '${world.gems}', iconSize: 20),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(width: 10),
                  if (world.hasKey) _badge('key'),
                  if (world.shield) _badge('shield'),
                  if (world.magnetT > 0) _power('magnet', world.magnetT),
                  if (world.boltT > 0) _power('bolt', world.boltT),
                  if (world.potionT > 0) _power('potion', world.potionT),
                  const Spacer(),
                  ImgButton(asset: 'btn_pause', size: 42, onTap: world.pause),
                ],
              ),
              if (world.toastT > 0)
                Positioned(
                  top: 4,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xCC0A1633),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFFFD25A), width: 1.5),
                      ),
                      child: Text(
                        world.toast,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _badge(String name) {
    return Padding(
      padding: const EdgeInsets.only(right: 8, top: 4),
      child: Image.asset(Sprites.path(name), height: 30),
    );
  }

  Widget _power(String name, double t) {
    return Padding(
      padding: const EdgeInsets.only(right: 10, top: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(Sprites.path(name), height: 28),
          const SizedBox(width: 2),
          OutlinedText('${t.ceil()}', size: 14),
        ],
      ),
    );
  }

  // ------------------------------------------------------------- controls
  Widget _controls() {
    return ValueListenableBuilder<GamePhase>(
      valueListenable: world.phase,
      builder: (context, p, _) {
        if (p != GamePhase.playing) return const SizedBox.shrink();
        return Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              left: 18,
              bottom: 14,
              child: Row(
                children: [
                  HoldButton(
                    size: 66,
                    icon: Icons.arrow_back_ios_new_rounded,
                    color: const Color(0xFF4A6FD8),
                    onDown: () => world.input.tLeft = true,
                    onUp: () => world.input.tLeft = false,
                  ),
                  const SizedBox(width: 14),
                  HoldButton(
                    size: 66,
                    icon: Icons.arrow_forward_ios_rounded,
                    color: const Color(0xFF4A6FD8),
                    onDown: () => world.input.tRight = true,
                    onUp: () => world.input.tRight = false,
                  ),
                ],
              ),
            ),
            Positioned(
              right: 20,
              bottom: 14,
              child: HoldButton(
                size: 82,
                color: const Color(0xFFFF9A1F),
                icon: Icons.keyboard_arrow_up_rounded,
                onDown: () => world.input.pressJump(touch: true),
                onUp: () => world.input.releaseJump(touch: true),
              ),
            ),
            Positioned(
              right: 116,
              bottom: 16,
              child: HoldButton(
                size: 64,
                color: const Color(0xFFE53935),
                icon: Icons.flash_on_rounded,
                onDown: world.input.pressAttack,
                onUp: () {},
              ),
            ),
            Positioned(
              right: 30,
              bottom: 106,
              child: HoldButton(
                size: 54,
                color: const Color(0xFF7B4DFF),
                icon: Icons.keyboard_double_arrow_down_rounded,
                onDown: world.input.pressSlide,
                onUp: () {},
              ),
            ),
          ],
        );
      },
    );
  }

  // -------------------------------------------------------------- overlays
  Widget _overlay(Widget child) {
    return SizedBox.expand(
      child: Container(
        color: Colors.black54,
        alignment: Alignment.center,
        child: FittedBox(fit: BoxFit.scaleDown, child: child),
      ),
    );
  }

  Widget _miniToggle(IconData on, IconData off, bool Function() get, void Function(bool) set) {
    return StatefulBuilder(
      builder: (context, setState) {
        final v = get();
        return GestureDetector(
          onTap: () {
            setState(() => set(!v));
            Progress.saveSettings();
          },
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF1A2A5E),
              border: Border.all(
                  color: v ? const Color(0xFF58D63A) : const Color(0xFF5C6A99), width: 2.5),
            ),
            child: Icon(v ? on : off, color: Colors.white, size: 26),
          ),
        );
      },
    );
  }

  Widget _pauseOverlay() {
    return _overlay(
      Container(
        width: 300,
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFF3A5DB8), width: 2.5),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF14224F), Color(0xFF0A1230)],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const OutlinedText('PAUZA', size: 34),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _miniToggle(Icons.music_note_rounded, Icons.music_off_rounded,
                    () => Sfx.musicEnabled, Sfx.setMusic),
                const SizedBox(width: 16),
                _miniToggle(Icons.volume_up_rounded, Icons.volume_off_rounded,
                    () => Sfx.enabled, Sfx.setSounds),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GlossButton(icon: Icons.home_rounded, onTap: _home),
                const SizedBox(width: 12),
                GlossButton.green(icon: Icons.play_arrow_rounded, width: 84, onTap: world.resume),
                const SizedBox(width: 12),
                GlossButton(icon: Icons.refresh_rounded, onTap: _restart),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _star(int i) {
    final big = i == 1;
    return Padding(
      padding: EdgeInsets.only(top: big ? 0 : 20, left: 2, right: 2),
      child: GrayOut(
        gray: i >= world.starsEarned,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: 1),
          duration: Duration(milliseconds: 500 + i * 250),
          curve: Curves.elasticOut,
          builder: (context, v, child) =>
              Transform.scale(scale: v.clamp(0.0, 1.3).toDouble(), child: child),
          child: Image.asset(Sprites.path('star'), width: big ? 70 : 54),
        ),
      ),
    );
  }

  Widget _winOverlay() {
    final last = widget.level + 1 >= G.levelCount;
    return _overlay(
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 320,
            height: 176,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                Positioned(
                  top: 0,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [for (int i = 0; i < 3; i++) _star(i)],
                  ),
                ),
                Positioned(
                  top: 64,
                  child: Image.asset(Sprites.path('ribbon'), width: 310),
                ),
              ],
            ),
          ),
          const Text(
            'Sizning hisobingiz',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              decoration: TextDecoration.none,
            ),
          ),
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: world.score),
            duration: const Duration(milliseconds: 900),
            builder: (context, v, _) => OutlinedText('$v', size: 38),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GlossButton(icon: Icons.home_rounded, onTap: _home),
              const SizedBox(width: 12),
              GlossButton(icon: Icons.refresh_rounded, onTap: _restart),
              if (!last) ...[
                const SizedBox(width: 12),
                GlossButton.green(label: 'Keyingisi', width: 132, onTap: _next),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _loseOverlay() {
    const w = 270.0;
    const h = w * 430 / 420;
    return _overlay(
      SizedBox(
        width: w,
        height: h,
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Image.asset(
                  Sprites.path('panel_gameover'),
                  fit: BoxFit.fill,
                  filterQuality: FilterQuality.medium,
                ),
              ),
            ),
            // "Try Again" tugmasi ustidagi ko'rinmas hudud
            Positioned(
              left: w * 0.2,
              top: h * 0.56,
              width: w * 0.6,
              height: h * 0.17,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _restart,
              ),
            ),
            // "Main Menu" tugmasi ustidagi ko'rinmas hudud
            Positioned(
              left: w * 0.2,
              top: h * 0.77,
              width: w * 0.6,
              height: h * 0.16,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _home,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
