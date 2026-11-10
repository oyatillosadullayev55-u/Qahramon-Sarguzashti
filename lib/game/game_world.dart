import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../core/audio.dart';
import '../core/constants.dart';
import '../core/progress.dart';
import 'input.dart';
import 'level_builder.dart';
import 'models.dart';

enum GamePhase { playing, paused, won, lost }

class Particle {
  Particle(this.x, this.y, this.vx, this.vy, this.life, this.size, this.color,
      {this.gravity = 500})
      : maxLife = life;

  double x, y, vx, vy, life, size;
  final double gravity;
  final double maxLife;
  final Color color;
}

/// O'yin holati va fizikasi. UI'dan mustaqil: faqat update(dt) chaqiriladi.
class GameWorld extends ChangeNotifier {
  GameWorld(this.levelIndex) : level = LevelBuilder.build(levelIndex);

  final int levelIndex;
  final LevelData level;
  final Hero hero = Hero();
  final Input input = Input();
  final ValueNotifier<GamePhase> phase = ValueNotifier<GamePhase>(GamePhase.playing);
  final ValueNotifier<int> hudTick = ValueNotifier<int>(0);
  final List<Particle> particles = [];
  final math.Random _rnd = math.Random();

  int lives = G.startLives;
  int score = 0;
  int gems = 0;
  int hits = 0;
  int starsEarned = 0;
  bool hasKey = false;
  bool shield = false;
  bool chestOpened = false;
  double chestT = 0;

  // Holatlar
  bool dying = false;
  double dyingT = 0;
  bool winning = false;
  double winT = 0;
  bool _walletSaved = false;

  String toast = '';
  double toastT = 0;

  double time = 0;
  double camX = 0;
  double camBias = 0.35;
  double viewW = 640;
  double magnetT = 0;
  double boltT = 0;
  double potionT = 0;
  double shake = 0;
  double _fxT = 0;
  int _hk = -1;

  bool get locked => dying || winning;

  // ---------------------------------------------------------------- control
  void pause() {
    if (phase.value != GamePhase.playing) return;
    input.clear();
    phase.value = GamePhase.paused;
  }

  void resume() {
    if (phase.value == GamePhase.paused) phase.value = GamePhase.playing;
  }

  void _say(String text) {
    toast = text;
    toastT = 1.6;
    hudTick.value++;
  }

  // ----------------------------------------------------------------- update
  void update(double dt) {
    if (phase.value != GamePhase.playing) return;
    if (!dt.isFinite || dt <= 0) return;
    time += dt;

    _updateHero(dt);

    if (dying) {
      dyingT -= dt;
      if (dyingT <= 0) _finishLose();
    } else if (winning) {
      winT -= dt;
      if (winT <= 0) {
        _saveWallet();
        phase.value = GamePhase.won;
      }
    } else if (phase.value == GamePhase.playing) {
      _updateAttack();
      _updateEnemies(dt);
      _updateHazards();
      _updatePickups(dt);
      _updateChest(dt);
      _checkGoal();
    }

    if (toastT > 0) {
      toastT -= dt;
      if (toastT <= 0) hudTick.value++;
    }
    _updateBlocks(dt);
    _updateEffects(dt);
    _updateCamera(dt);
    _syncHud();
    notifyListeners();
  }

  String get heroFrame {
    final h = hero;
    if (dying) return 'hero_die';
    if (winning) return 'hero_celebrate';
    if (h.hurtT > 0) return 'hero_hurt';
    if (h.attackT > 0) return 'hero_attack';
    if (h.slideT > 0) return 'hero_slide';
    if (!h.onGround) return 'hero_jump';
    if (h.skid) return 'hero_idle';
    if (h.vx.abs() > 12) return 'hero_run';
    return 'hero_idle';
  }

  void _dust(double x, double y, double dirX, int n, {double power = 1}) {
    for (int i = 0; i < n; i++) {
      particles.add(Particle(
        x + _rnd.nextDouble() * 6 - 3,
        y,
        dirX * (15 + _rnd.nextDouble() * 35) * power,
        -(10 + _rnd.nextDouble() * 28),
        0.35 + _rnd.nextDouble() * 0.15,
        3 + _rnd.nextDouble() * 3,
        const Color(0xCCEFE6D2),
        gravity: -25,
      ));
    }
  }

  void _updateHero(double dt) {
    final h = hero;
    final maxSpeed = boltT > 0 ? G.boltSpeed : G.runSpeed;
    final isLocked = locked;

    // Jang taymerlari
    if (h.attackT > 0) h.attackT = math.max(0.0, h.attackT - dt);
    if (h.attackCd > 0) h.attackCd -= dt;
    if (h.slideT > 0) h.slideT = math.max(0.0, h.slideT - dt);
    if (h.slideCd > 0) h.slideCd -= dt;
    if (h.hurtT > 0) h.hurtT = math.max(0.0, h.hurtT - dt);

    final wantAttack = input.consumeAttack();
    final wantSlide = input.consumeSlide();
    if (!isLocked) {
      if (wantAttack && h.attackCd <= 0 && h.slideT <= 0) {
        h.attackT = 0.28;
        h.attackCd = 0.42;
        Sfx.play('slash');
      }
      if (wantSlide && h.slideCd <= 0 && h.onGround && h.attackT <= 0) {
        h.slideT = 0.55;
        h.slideCd = 0.95;
        h.vx = h.facing * math.max(maxSpeed * 1.2, h.vx.abs());
        Sfx.play('jump');
      }
    }
    if (h.slideT > 0 && !h.onGround) h.slideT = 0;
    final sliding = h.slideT > 0;

    double dir = 0;
    if (!isLocked && !sliding) {
      dir = (input.right ? 1.0 : 0.0) - (input.left ? 1.0 : 0.0);
    }
    final target = dir * maxSpeed;
    final onG = h.onGround;
    final ice = onG && h.onIce;
    final reversing = dir != 0 && h.vx != 0 && h.vx * dir < 0;
    h.skid = onG && reversing && h.vx.abs() > 80 && !ice;
    double acc;
    if (sliding) {
      acc = 430.0;
    } else if (dir == 0) {
      acc = onG ? (ice ? 220.0 : 1700.0) : 450.0;
    } else if (reversing) {
      acc = onG ? (ice ? 500.0 : 2600.0) : 1500.0;
    } else {
      acc = onG ? (ice ? 520.0 : 1150.0) : 950.0;
    }
    if (h.vx < target) {
      h.vx = math.min(target, h.vx + acc * dt);
    } else if (h.vx > target) {
      h.vx = math.max(target, h.vx - acc * dt);
    }
    if (dir != 0 && !h.skid) h.facing = dir;

    // Sakrash (coyote time + buffer)
    h.coyote = h.onGround ? 0.1 : h.coyote - dt;
    final jumpPressed = input.consumeJump();
    if (!isLocked && jumpPressed) {
      h.jumpBuf = 0.12;
    } else {
      h.jumpBuf -= dt;
    }
    if (h.jumpBuf > 0 && h.coyote > 0 && !isLocked) {
      h.vy = potionT > 0 ? -G.superJumpV : -G.jumpV;
      h.jumpBuf = 0;
      h.coyote = 0;
      h.onGround = false;
      h.jumpCut = false;
      h.slideT = 0;
      Sfx.play('jump');
    }
    if (!input.jumpHeld && !h.jumpCut && h.vy < 0) {
      h.vy *= 0.45;
      h.jumpCut = true;
    }

    h.vy = math.min(h.vy + G.gravity * dt, 900.0);

    // --- X harakati
    h.x += h.vx * dt;
    if (h.x < 0) {
      h.x = 0;
      h.vx = 0;
    }
    final maxX = level.length - G.heroW;
    if (h.x > maxX) {
      h.x = maxX;
      h.vx = 0;
    }
    Rect r = h.rect;
    for (final s in level.solids) {
      if (s.oneWay) continue;
      final sr = s.rect;
      if (sr.right < h.x - 60 || sr.left > h.x + 80) continue;
      if (!r.overlaps(sr)) continue;
      if (r.bottom <= sr.top + 0.5 || r.top >= sr.bottom - 0.5) continue;
      if (h.vx > 0) {
        h.x = sr.left - G.heroW;
      } else if (h.vx < 0) {
        h.x = sr.right;
      } else {
        h.x = h.cx < sr.center.dx ? sr.left - G.heroW : sr.right;
      }
      h.vx = 0;
      r = h.rect;
    }

    // --- Y harakati
    h.prevBottom = h.y + G.heroH;
    final prevBottom = h.prevBottom;
    final wasGround = h.onGround;
    final vyBefore = h.vy;
    h.y += h.vy * dt;
    h.onGround = false;
    h.onIce = false;
    r = h.rect;
    for (final s in level.solids) {
      final sr = s.rect;
      if (sr.right < h.x - 60 || sr.left > h.x + 80) continue;
      if (!r.overlaps(sr)) continue;
      if (r.right <= sr.left + 0.5 || r.left >= sr.right - 0.5) continue;
      if (s.oneWay) {
        if (h.vy >= 0 && prevBottom <= sr.top + 1) {
          h.y = sr.top - G.heroH;
          h.vy = 0;
          h.onGround = true;
          r = h.rect;
        }
        continue;
      }
      if (h.vy >= 0) {
        h.y = sr.top - G.heroH;
        h.vy = 0;
        h.onGround = true;
        h.onIce = s.kind == SolidKind.ice;
        if (s.kind == SolidKind.ground && sr.width > 150) {
          h.respawnX = math.min(math.max(h.x, sr.left + 40), sr.right - 60);
          if (h.respawnX < sr.left + 40) h.respawnX = sr.left + 40;
        }
      } else {
        h.y = sr.bottom;
        h.vy = 0;
        if (s.kind == SolidKind.qblock) _hitBlock(s);
      }
      r = h.rect;
    }

    _animateHero(dt, wasGround, vyBefore);

    // Yiqilib ketdi
    if (h.y > G.viewH + 80) {
      if (!dying && !winning) _fall();
      return;
    }

    if (h.invul > 0) h.invul -= dt;
    if (magnetT > 0) magnetT = math.max(0.0, magnetT - dt);
    if (boltT > 0) boltT = math.max(0.0, boltT - dt);
    if (potionT > 0) potionT = math.max(0.0, potionT - dt);

    // Quvvat effektlari
    _fxT -= dt;
    if (_fxT <= 0 && (boltT > 0 || potionT > 0)) {
      _fxT = 0.05;
      final c = boltT > 0 ? const Color(0xFFFFD83A) : const Color(0xFF55C8FF);
      particles.add(Particle(
        h.cx - h.facing * 8 + _rnd.nextDouble() * 6 - 3,
        h.y + 10 + _rnd.nextDouble() * 36,
        -h.facing * 30,
        -10 - _rnd.nextDouble() * 20,
        0.4,
        3 + _rnd.nextDouble() * 2,
        c,
      ));
    }
  }

  /// Yurish animatsiyasi: qadam fazasi, burilish, og'ish, chang va yerga tushish.
  void _animateHero(double dt, bool wasGround, double vyBefore) {
    final h = hero;
    final feetY = h.y + G.heroH;

    if (h.onGround) {
      h.stride += h.vx.abs() * dt / 15.0;
      final idx = h.stride.floor();
      if (idx != h.stepIdx) {
        h.stepIdx = idx;
        if (h.vx.abs() > 70 && idx.isEven && h.slideT <= 0) {
          _dust(h.cx - h.facing * 9, feetY - 2, -h.facing, 1, power: 0.6);
        }
      }
    } else {
      h.stride = h.stride.floorToDouble();
    }

    h.visFacing += (h.facing - h.visFacing) * math.min(1.0, dt * 18);
    if ((h.facing - h.visFacing).abs() < 0.02) h.visFacing = h.facing;

    final speedK = (h.vx / G.boltSpeed).clamp(-1.0, 1.0).toDouble();
    double targetLean = speedK * 0.12;
    if (h.skid) targetLean = -h.facing * 0.2;
    if (h.slideT > 0 || h.attackT > 0 || dying || winning) targetLean = 0;
    if (!h.onGround) {
      targetLean = speedK * 0.07 + (h.vy / 4000).clamp(-0.06, 0.06).toDouble() * h.facing;
    }
    h.lean += (targetLean - h.lean) * math.min(1.0, dt * 12);

    if (h.skid || h.slideT > 0) {
      h.dustT -= dt;
      if (h.dustT <= 0) {
        h.dustT = 0.035;
        _dust(h.cx - h.facing * (h.slideT > 0 ? 14 : 0), feetY - 2, -h.facing, 2,
            power: 1.2);
      }
    }

    if (h.landT > 0) h.landT = math.max(0.0, h.landT - dt);
    if (h.onGround && !wasGround && vyBefore > 260) {
      h.landT = 0.14;
      _dust(h.cx - 8, feetY - 2, -1, 3);
      _dust(h.cx + 8, feetY - 2, 1, 3);
    }
  }

  void _hitBlock(Solid s) {
    if (s.used) return;
    s.used = true;
    s.bump = 0.2;
    Sfx.play('block');
    final cx = s.rect.center.dx;
    final cy = s.rect.top - 8;
    final reward = s.reward ?? PickupType.coin;
    if (reward == PickupType.coin) {
      level.pickups.add(Pickup(PickupType.coin, cx, cy, vx: -70, vy: -260, moving: true));
      level.pickups.add(Pickup(PickupType.coin, cx, cy, vx: 0, vy: -320, moving: true));
      level.pickups.add(Pickup(PickupType.coin, cx, cy, vx: 70, vy: -260, moving: true));
    } else {
      level.pickups.add(Pickup(reward, cx, cy, vx: 55, vy: -280, moving: true));
    }
    _burst(cx, s.rect.top, const Color(0xFFFFC83D), 8);
  }

  // ------------------------------------------------------------ hurt / death
  void _haptic() {
    if (Progress.vibration) HapticFeedback.mediumImpact();
  }

  void _fall() {
    lives--;
    hits++;
    Sfx.play('hurt');
    _haptic();
    shake = 0.3;
    if (lives <= 0) {
      _finishLose();
      return;
    }
    hero.x = hero.respawnX;
    hero.y = G.groundY - G.heroH - 2;
    hero.vx = 0;
    hero.vy = 0;
    hero.invul = 1.5;
    hero.jumpCut = true;
  }

  void _hurtAt(double sourceCx) {
    if (hero.invul > 0 || locked) return;
    if (shield) {
      shield = false;
      hero.invul = 1.0;
      hero.vy = -240;
      hero.vx = (hero.cx < sourceCx ? -1 : 1) * 160.0;
      hero.onGround = false;
      Sfx.play('block');
      _burst(hero.cx, hero.cy, const Color(0xFF55C8FF), 14);
      return;
    }
    lives--;
    hits++;
    Sfx.play('hurt');
    _haptic();
    shake = 0.3;
    _burst(hero.cx, hero.cy, const Color(0xFFFF4A4A), 10);
    hero.slideT = 0;
    hero.attackT = 0;
    if (lives <= 0) {
      _startDying(sourceCx);
      return;
    }
    hero.invul = 1.6;
    hero.hurtT = 0.4;
    hero.vy = -320;
    hero.vx = (hero.cx < sourceCx ? -1 : 1) * 220.0;
    hero.jumpCut = true;
    hero.onGround = false;
  }

  void _startDying(double sourceCx) {
    dying = true;
    dyingT = 1.1;
    input.clear();
    hero.vy = -260;
    hero.vx = (hero.cx < sourceCx ? -1 : 1) * 120.0;
    hero.onGround = false;
    Sfx.play('lose');
  }

  void _finishLose() {
    if (phase.value == GamePhase.lost) return;
    _saveWallet();
    input.clear();
    phase.value = GamePhase.lost;
  }

  void _saveWallet() {
    if (_walletSaved) return;
    _walletSaved = true;
    Progress.addWallet(score, gems);
  }

  void _checkGoal() {
    if (level.hasBoss && level.enemies.any((e) => e.boss && !e.dead)) return;
    if (hero.x + G.heroW >= level.goalX + 20) {
      final ratio = level.scoreTotal == 0 ? 1.0 : score / level.scoreTotal;
      var s = 1;
      if (ratio >= 0.5) s = 2;
      if (ratio >= 0.8 && hits <= 1) s = 3;
      starsEarned = s;
      Progress.complete(levelIndex, s, score);
      Sfx.play('win');
      input.clear();
      winning = true;
      winT = 1.0;
      hero.invul = 0;
    }
  }

  // ----------------------------------------------------------------- combat
  void _damageEnemy(Enemy e, {bool bounce = false}) {
    if (e.hp > 1) {
      e.hp--;
      e.hitCd = 0.9;
      shake = 0.25;
      Sfx.play('boss');
      _burst(e.cx, e.y + 10, const Color(0xFFFFD83A), 14);
    } else {
      e.dead = true;
      if (e.boss) {
        shake = 0.5;
        score += 10;
        _burst(e.cx, e.y + e.h * 0.5, const Color(0xFFFFD83A), 30);
      } else {
        score += 1;
      }
      Sfx.play('stomp');
      _burst(e.cx, e.y + e.h * 0.5, const Color(0xFFFFFFFF), 8);
    }
    if (bounce) {
      hero.vy = input.jumpHeld ? -540 : -420;
      hero.jumpCut = false;
      hero.onGround = false;
    }
  }

  void _updateAttack() {
    if (hero.attackT <= 0) return;
    final ar = hero.attackRect;
    for (final e in level.enemies) {
      if (e.dead || (e.boss && e.hitCd > 0)) continue;
      if (ar.overlaps(e.rect)) _damageEnemy(e);
    }
  }

  void _updateEnemies(double dt) {
    final h = hero;
    for (final e in level.enemies) {
      if (e.dead) {
        e.deadT += dt;
        continue;
      }
      if (e.hitCd > 0) e.hitCd -= dt;
      final sp = e.boss ? e.speed * (1 + 0.35 * (e.maxHp - e.hp)) : e.speed;
      switch (e.type) {
        case EnemyType.slime:
        case EnemyType.turtle:
        case EnemyType.ghost:
          e.x += e.dir * sp * dt;
          if (e.x < e.minX) {
            e.x = e.minX;
            e.dir = 1;
          }
          if (e.x + e.w > e.maxX) {
            e.x = e.maxX - e.w;
            e.dir = -1;
          }
          if (e.type == EnemyType.ghost) {
            e.y = e.baseY + math.sin(time * 2 + e.phase) * 22;
          }
          break;
        case EnemyType.bomb:
          break;
      }

      final er = e.rect;
      if (e.boss && e.hitCd > 0) continue;
      if (!h.hurtRect.overlaps(er)) continue;
      final cameFromAbove = h.vy > 0 && h.prevBottom <= er.top + (e.boss ? 24 : 12);
      if (e.stompable && cameFromAbove) {
        _damageEnemy(e, bounce: true);
      } else if (h.slideT > 0 && e.stompable && !e.boss) {
        _damageEnemy(e); // sirpanib urib yuborish
      } else {
        _hurtAt(e.cx);
        if (dying) return;
      }
    }
    level.enemies.removeWhere((e) => e.dead && e.deadT > 0.4);
  }

  void _updateHazards() {
    final hr = hero.hurtRect.deflate(3);
    for (final z in level.hazards) {
      if (z.right < hero.x - 40 || z.left > hero.x + 60) continue;
      if (hr.overlaps(z.deflate(4))) {
        _hurtAt(z.center.dx);
        return;
      }
    }
  }

  // ---------------------------------------------------------------- pickups
  void _updatePickups(double dt) {
    final h = hero;
    final hr = h.rect.inflate(4);
    for (final p in level.pickups) {
      if (p.collected) continue;
      p.age += dt;

      if (p.moving) {
        p.vy += 900 * dt;
        p.cx += p.vx * dt;
        p.cy += p.vy * dt;
        if (p.vy > 0 && p.cy >= G.groundY - 16) {
          p.cy = G.groundY - 16;
          p.moving = false;
        }
      } else if (magnetT > 0 &&
          (p.type == PickupType.coin || p.type == PickupType.star || p.type == PickupType.gem)) {
        final dx = h.cx - p.cx;
        final dy = h.cy - p.cy;
        final d = math.sqrt(dx * dx + dy * dy);
        if (d < 180 && d > 1) {
          final sp = 420 * dt;
          p.cx += dx / d * math.min(sp, d);
          p.cy += dy / d * math.min(sp, d);
        }
      }

      if (p.moving && p.age < 0.25) continue;
      final pr = Rect.fromCenter(center: Offset(p.cx, p.cy), width: 28, height: 28);
      if (hr.overlaps(pr)) _collect(p);
    }
    level.pickups.removeWhere((p) => p.collected);
  }

  void _collect(Pickup p) {
    p.collected = true;
    Color c = const Color(0xFFFFD83A);
    String snd = 'power';
    switch (p.type) {
      case PickupType.coin:
        score += 1;
        snd = 'coin';
        break;
      case PickupType.star:
        score += 3;
        snd = 'coin';
        break;
      case PickupType.gem:
        score += 5;
        gems += 1;
        c = const Color(0xFF55C8FF);
        snd = 'coin';
        break;
      case PickupType.heart:
        if (lives < G.maxLives) lives++;
        c = const Color(0xFFFF4A6A);
        break;
      case PickupType.magnet:
        magnetT = 8;
        c = const Color(0xFFFF4A4A);
        break;
      case PickupType.bolt:
        boltT = 8;
        break;
      case PickupType.potion:
        potionT = 8;
        c = const Color(0xFF55C8FF);
        break;
      case PickupType.shield:
        shield = true;
        c = const Color(0xFF55C8FF);
        break;
      case PickupType.key:
        hasKey = true;
        snd = 'key';
        _say('Kalit topildi!');
        break;
    }
    Sfx.play(snd);
    _burst(p.cx, p.cy, c, 7);
  }

  void _updateChest(double dt) {
    if (chestOpened) {
      chestT += dt;
      return;
    }
    if (!hero.rect.overlaps(level.chest.inflate(6))) return;
    if (hasKey) {
      chestOpened = true;
      score += 15;
      gems += 3;
      shake = 0.2;
      Sfx.play('chest');
      _burst(level.chest.center.dx, level.chest.top, const Color(0xFFFFD83A), 28);
      _say('Sandiq ochildi! +15 ball, +3 olmos');
    } else if (toastT <= 0) {
      _say('Sandiqni ochish uchun kalit kerak!');
    }
  }

  // ---------------------------------------------------------------- effects
  void _updateBlocks(double dt) {
    for (final s in level.solids) {
      if (s.bump > 0) s.bump = math.max(0.0, s.bump - dt);
    }
  }

  void _burst(double x, double y, Color color, int n) {
    for (int i = 0; i < n; i++) {
      final a = _rnd.nextDouble() * math.pi * 2;
      final sp = 60 + _rnd.nextDouble() * 120;
      particles.add(Particle(x, y, math.cos(a) * sp, math.sin(a) * sp - 60, 0.5,
          2.5 + _rnd.nextDouble() * 2.5, color));
    }
  }

  void _updateEffects(double dt) {
    if (shake > 0) shake = math.max(0.0, shake - dt);
    for (final p in particles) {
      p.life -= dt;
      p.vy += p.gravity * dt;
      p.x += p.vx * dt;
      p.y += p.vy * dt;
    }
    particles.removeWhere((p) => p.life <= 0);
  }

  void _updateCamera(double dt) {
    if (!viewW.isFinite || viewW <= 0) viewW = 640;
    if (!camX.isFinite) camX = 0;
    final maxCam = math.max(0.0, level.length - viewW);
    final wantBias = hero.facing >= 0 ? 0.35 : 0.62;
    camBias += (wantBias - camBias) * math.min(1.0, dt * 2.5);
    final target = (hero.x - viewW * camBias).clamp(0.0, maxCam).toDouble();
    camX += (target - camX) * math.min(1.0, dt * 6);
  }

  void _syncHud() {
    final k = Object.hash(lives, score, gems, hasKey, shield, magnetT.ceil(), boltT.ceil(),
        potionT.ceil());
    if (k != _hk) {
      _hk = k;
      hudTick.value++;
    }
  }

  @override
  void dispose() {
    phase.dispose();
    hudTick.dispose();
    super.dispose();
  }
}
