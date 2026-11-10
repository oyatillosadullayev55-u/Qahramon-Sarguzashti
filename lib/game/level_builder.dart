import 'dart:math';
import 'dart:ui';

import '../core/constants.dart';
import 'models.dart';

/// Har bir daraja uchun deterministik (har safar bir xil) level yaratadi.
class LevelBuilder {
  LevelBuilder._();

  static const List<String> backgrounds = [
    'bg_day',
    'bg_forest',
    'bg_env',
    'bg_night',
    'bg_env',
  ];

  static LevelData build(int index) {
    final rnd = Random(7001 + index * 173);
    final solids = <Solid>[];
    final pickups = <Pickup>[];
    final enemies = <Enemy>[];
    final hazards = <Rect>[];
    var scoreTotal = 0;
    const gy = G.groundY;

    void coin(double x, double y) {
      pickups.add(Pickup(PickupType.coin, x, y));
      scoreTotal += 1;
    }

    void arc(double cx, double baseY, int n) {
      for (int i = 0; i < n; i++) {
        final t = n == 1 ? 0.5 : i / (n - 1);
        final px = cx + (t - 0.5) * (n - 1) * 30;
        final py = baseY - sin(t * pi) * 30;
        coin(px, py);
      }
    }

    PickupType rollReward() {
      final r = rnd.nextDouble();
      if (r < 0.42) return PickupType.coin;
      if (r < 0.54) return PickupType.heart;
      if (r < 0.68) return PickupType.shield;
      if (r < 0.78) return PickupType.magnet;
      if (r < 0.90) return PickupType.bolt;
      return PickupType.potion;
    }

    final target = 2800.0 + index * 700;
    final enemyProb = 0.18 + index * 0.05;
    double x = 0;
    bool first = true;

    while (true) {
      if (!first) x += 64 + rnd.nextInt(28 + index * 10);
      if (!first && x >= target) break;

      final segW = first ? 720.0 : 300.0 + rnd.nextInt(380);
      solids.add(Solid(Rect.fromLTWH(x, gy, segW, 200), SolidKind.ground));
      if (first) arc(x + 260, gy - 30, 5);

      double sx = x + (first ? 460 : 70);
      final limit = x + segW - 50;

      while (true) {
        int kind;
        double fw;
        double pw = 0;

        if (!first && rnd.nextDouble() < enemyProb) {
          final r = rnd.nextDouble();
          if (r < 0.4) {
            kind = 10;
            fw = 150;
          } else if (r < 0.7) {
            kind = 11;
            fw = 160;
          } else if (r < 0.85) {
            kind = 13;
            fw = 110;
          } else {
            kind = 12;
            fw = 190;
          }
        } else {
          final r = rnd.nextDouble();
          if (r < 0.20) {
            kind = 0;
            fw = 130;
          } else if (r < 0.34) {
            kind = 1;
            fw = 120;
          } else if (r < 0.42) {
            kind = 3;
            fw = 120;
          } else if (r < 0.52) {
            kind = 7;
            fw = 200;
          } else if (r < 0.62) {
            kind = first ? 0 : 6;
            fw = first ? 130 : 130;
          } else if (r < 0.84) {
            kind = 4;
            pw = 110.0 + rnd.nextInt(50);
            fw = pw + 30;
          } else {
            kind = 5;
            fw = 90;
          }
        }

        if (sx + fw > limit) break;
        final cx = sx + fw / 2;

        switch (kind) {
          case 0:
            arc(cx, gy - 28, 5);
            break;
          case 1:
            final h = 1 + rnd.nextInt(2);
            for (int i = 0; i < h; i++) {
              solids.add(Solid(
                Rect.fromLTWH(cx - 19, gy - 38.0 * (i + 1), 38, 38),
                SolidKind.crate,
              ));
            }
            arc(cx, gy - 38.0 * h - 30, 3);
            break;
          case 3:
            solids.add(Solid(Rect.fromLTWH(cx - 44, gy - 33, 44, 33), SolidKind.stone));
            solids.add(Solid(Rect.fromLTWH(cx, gy - 33, 44, 33), SolidKind.stone));
            arc(cx, gy - 62, 3);
            break;
          case 4:
            final py = gy - 72 - rnd.nextInt(14).toDouble();
            solids.add(Solid(
              Rect.fromLTWH(cx - pw / 2, py, pw, 16),
              SolidKind.platform,
              oneWay: true,
            ));
            final roll = rnd.nextDouble();
            if (roll < 0.55) {
              for (int i = 0; i < 4; i++) {
                coin(cx - 45 + i * 30.0, py - 24);
              }
            } else if (roll < 0.75) {
              pickups.add(Pickup(PickupType.gem, cx, py - 28));
              scoreTotal += 5;
            } else if (roll < 0.9) {
              pickups.add(Pickup(PickupType.star, cx, py - 28));
              scoreTotal += 3;
            } else {
              pickups.add(Pickup(PickupType.heart, cx, py - 28));
            }
            break;
          case 5:
            final reward = rollReward();
            if (reward == PickupType.coin) scoreTotal += 3;
            solids.add(Solid(
              Rect.fromLTWH(cx - 20, gy - 110, 40, 36),
              SolidKind.qblock,
              reward: reward,
            ));
            break;
          case 6:
            // Tikanlar: ustidan sakrab o'tish kerak
            hazards.add(Rect.fromLTWH(cx - 24, gy - 30, 48, 30));
            arc(cx, gy - 62, 3);
            break;
          case 7:
            // Muz zinapoyasi: ustida sirpanchiq
            for (int i = 0; i < 3; i++) {
              solids.add(Solid(
                Rect.fromLTWH(cx - 60 + i * 40.0, gy - 34, 40, 34),
                SolidKind.ice,
              ));
            }
            for (int i = 0; i < 3; i++) {
              coin(cx - 40 + i * 40.0, gy - 62);
            }
            break;
          case 10:
            enemies.add(Enemy(EnemyType.slime,
                x: cx - 22, y: gy - 36, w: 44, h: 36, minX: cx - 70, maxX: cx + 70, speed: 38));
            break;
          case 11:
            enemies.add(Enemy(EnemyType.turtle,
                x: cx - 27, y: gy - 38, w: 54, h: 38, minX: cx - 75, maxX: cx + 75, speed: 62));
            break;
          case 12:
            enemies.add(Enemy(EnemyType.ghost,
                x: cx - 22, y: gy - 95, w: 44, h: 41, minX: cx - 90, maxX: cx + 90, speed: 55)
              ..phase = rnd.nextDouble() * 6);
            break;
          case 13:
            enemies.add(Enemy(EnemyType.bomb,
                x: cx - 18, y: gy - 38, w: 36, h: 38, minX: cx - 18, maxX: cx + 18, speed: 0));
            arc(cx, gy - 58, 3);
            break;
        }

        sx += fw + 40 + rnd.nextInt(50);
      }

      first = false;
      x += segW;
    }

    // Kalit: darajaning o'rtasidagi suzuvchi platformaga qo'yiladi
    final platforms = solids.where((s) => s.kind == SolidKind.platform).toList();
    final mid = (x + 0) * 0.55;
    if (platforms.isNotEmpty) {
      platforms.sort((a, b) =>
          (a.rect.center.dx - mid).abs().compareTo((b.rect.center.dx - mid).abs()));
      final p = platforms.first.rect;
      pickups.add(Pickup(PickupType.key, p.center.dx, p.top - 38));
    } else {
      solids.add(Solid(Rect.fromLTWH(mid - 55, gy - 88, 110, 16), SolidKind.platform, oneWay: true));
      pickups.add(Pickup(PickupType.key, mid, gy - 126));
    }

    // Finish maydoni
    final hasBoss = index == G.levelCount - 1;
    final endW = hasBoss ? 760.0 : 600.0;
    solids.add(Solid(Rect.fromLTWH(x, gy, endW, 200), SolidKind.ground));
    arc(x + 120, gy - 30, 5);
    if (hasBoss) {
      enemies.add(Enemy(EnemyType.turtle,
          x: x + 420,
          y: gy - 90,
          w: 130,
          h: 90,
          minX: x + 60,
          maxX: x + 620,
          speed: 85,
          hp: 5,
          boss: true));
    }
    scoreTotal += 15; // sandiq mukofoti
    final chestX = x + endW - 330;

    return LevelData(
      length: x + endW,
      solids: solids,
      pickups: pickups,
      enemies: enemies,
      hazards: hazards,
      chest: Rect.fromLTWH(chestX, gy - 38, 52, 38),
      hasBoss: hasBoss,
      goalX: x + endW - 200,
      scoreTotal: scoreTotal,
      bg: backgrounds[index % backgrounds.length],
    );
  }
}
