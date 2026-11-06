import 'dart:ui';

import '../core/constants.dart';

enum SolidKind { ground, platform, crate, stone, barrel, qblock }

enum PickupType { coin, star, gem, heart, magnet, bolt, potion }

enum EnemyType { slime, turtle, ghost, bomb }

/// Qattiq to'siq: yer, platforma, quti, tosh, bochka, "?" blok.
class Solid {
  Solid(this.rect, this.kind, {this.oneWay = false, this.reward});

  final Rect rect;
  final SolidKind kind;
  final bool oneWay; // faqat tepadan turish mumkin (suzuvchi platformalar)
  final PickupType? reward; // "?" blok ichidagi sovg'a
  bool used = false;
  double bump = 0;
}

class Pickup {
  Pickup(this.type, this.cx, this.cy, {this.vx = 0, this.vy = 0, this.moving = false})
      : phase = (cx * 0.017) % 6.28;

  final PickupType type;
  double cx;
  double cy;
  double vx;
  double vy;
  bool moving; // "?" blokdan otilib chiqqanda true
  bool collected = false;
  final double phase;
  double age = 0;
}

class Enemy {
  Enemy(
    this.type, {
    required this.x,
    required this.y,
    required this.w,
    required this.h,
    required this.minX,
    required this.maxX,
    required this.speed,
    this.hp = 1,
    this.boss = false,
  })  : baseY = y,
        maxHp = hp;

  final EnemyType type;
  double x;
  double y;
  final double w;
  final double h;
  final double minX;
  final double maxX;
  final double speed;
  final double baseY;
  int hp;
  final int maxHp;
  final bool boss;
  double hitCd = 0;
  double dir = -1;
  bool dead = false;
  double deadT = 0;
  double phase = 0;

  double get cx => x + w / 2;
  Rect get rect => Rect.fromLTWH(x + 4, y + 4, w - 8, h - 6);
  bool get stompable => type == EnemyType.slime || type == EnemyType.turtle;
}

class Hero {
  double x = 60;
  double y = G.groundY - G.heroH;
  double vx = 0;
  double vy = 0;
  bool onGround = false;
  double facing = 1;
  double coyote = 0;
  double jumpBuf = 0;
  bool jumpCut = false;
  double invul = 0;
  double animT = 0;
  double respawnX = 60;
  double prevBottom = G.groundY;

  // Animatsiya holati
  double visFacing = 1; // burilish animatsiyasi uchun (-1..1)
  double stride = 0; // bosilgan masofaga bog'liq qadam fazasi
  double lean = 0; // tana og'ishi (radian)
  double landT = 0; // yerga tushgandagi "ezilish"
  bool skid = false; // tormozlanib sirpanish
  int stepIdx = 0;
  double dustT = 0;

  Rect get rect => Rect.fromLTWH(x, y, G.heroW, G.heroH);
  double get cx => x + G.heroW / 2;
  double get cy => y + G.heroH / 2;
}

class LevelData {
  LevelData({
    required this.length,
    required this.solids,
    required this.pickups,
    required this.enemies,
    required this.goalX,
    required this.scoreTotal,
    required this.bg,
    this.hasBoss = false,
  });

  final double length;
  final List<Solid> solids;
  final List<Pickup> pickups;
  final List<Enemy> enemies;
  final double goalX;
  final int scoreTotal;
  final String bg;
  final bool hasBoss;
}
