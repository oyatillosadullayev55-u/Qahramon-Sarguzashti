import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../core/audio.dart';
import '../core/constants.dart';
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
    if (p == GamePhase.won || p == GamePhase.lost) {
      Sfx.pauseMusic();
    }
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

  Widget _hud() {
    return ValueListenableBuilder<int>(
      valueListenable: world.hudTick,
      builder: (context, _, __) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(10, 6, 10, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < world.lives; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 3),
                  child: Image.asset(Sprites.path('heart'), width: 26),
                ),
              const SizedBox(width: 14),
              Image.asset(Sprites.path('coin'), width: 26),
              const SizedBox(width: 4),
              OutlinedText('${world.score}', size: 22),
              const SizedBox(width: 14),
              if (world.magnetT > 0) _power('magnet', world.magnetT),
              if (world.boltT > 0) _power('bolt', world.boltT),
              if (world.potionT > 0) _power('potion', world.potionT),
              const Spacer(),
              ImgButton(asset: 'btn_pause', size: 40, onTap: world.pause),
            ],
          ),
        );
      },
    );
  }

  Widget _power(String name, double t) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(Sprites.path(name), height: 26),
          const SizedBox(width: 2),
          OutlinedText('${t.ceil()}', size: 14),
        ],
      ),
    );
  }

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
                    onDown: () => world.input.tLeft = true,
                    onUp: () => world.input.tLeft = false,
                  ),
                  const SizedBox(width: 14),
                  HoldButton(
                    size: 66,
                    icon: Icons.arrow_forward_ios_rounded,
                    onDown: () => world.input.tRight = true,
                    onUp: () => world.input.tRight = false,
                  ),
                ],
              ),
            ),
            Positioned(
              right: 22,
              bottom: 14,
              child: HoldButton(
                size: 82,
                color: const Color(0xFFFF9A1F),
                icon: Icons.keyboard_arrow_up_rounded,
                onDown: () => world.input.pressJump(touch: true),
                onUp: () => world.input.releaseJump(touch: true),
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

  Widget _pauseOverlay() {
    return _overlay(
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 260,
            height: 100,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(child: Image.asset(Sprites.path('plank'), fit: BoxFit.fill)),
                const OutlinedText('PAUZA', size: 38),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ImgButton(asset: 'btn_home', size: 64, onTap: _home),
              const SizedBox(width: 16),
              ImgButton(asset: 'btn_play', size: 84, onTap: world.resume),
              const SizedBox(width: 16),
              ImgButton(asset: 'btn_restart', size: 64, onTap: _restart),
              const SizedBox(width: 16),
              const SoundToggle(size: 52),
            ],
          ),
        ],
      ),
    );
  }

  Widget _winOverlay() {
    final last = widget.level + 1 >= G.levelCount;
    return _overlay(
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(Sprites.path('level_complete'), width: 300),
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int i = 0; i < 3; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: GrayOut(
                    gray: i >= world.starsEarned,
                    child: Image.asset(Sprites.path('star'), width: 56),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(Sprites.path('coin'), width: 26),
              const SizedBox(width: 6),
              OutlinedText('${world.score} / ${world.level.scoreTotal}', size: 22),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ImgButton(asset: 'btn_home', size: 60, onTap: _home),
              const SizedBox(width: 16),
              ImgButton(asset: 'btn_restart', size: 60, onTap: _restart),
              if (!last) ...[
                const SizedBox(width: 16),
                ImgButton(asset: 'btn_play', size: 76, onTap: _next),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _loseOverlay() {
    return _overlay(
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(Sprites.path('game_over'), width: 380),
          const SizedBox(height: 16),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ImgButton(asset: 'btn_home', size: 64, onTap: _home),
              const SizedBox(width: 18),
              ImgButton(asset: 'btn_restart', size: 80, onTap: _restart),
            ],
          ),
        ],
      ),
    );
  }
}
