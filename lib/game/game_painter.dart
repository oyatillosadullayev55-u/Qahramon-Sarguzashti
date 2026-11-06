import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../core/sprites.dart';
import 'game_world.dart';
import 'models.dart';

/// Butun dunyoni bitta CustomPainter bilan chizadi (parallax fon, yer, obyektlar, qahramon).
class GamePainter extends CustomPainter {
  GamePainter(this.w) : super(repaint: w);

  final GameWorld w;

  final Paint _paint = Paint()
    ..filterQuality = FilterQuality.medium
    ..isAntiAlias = true;

  final Paint _gray = Paint()
    ..filterQuality = FilterQuality.medium
    ..isAntiAlias = true
    ..colorFilter = const ColorFilter.matrix(<double>[
      0.26, 0.26, 0.26, 0, 0, //
      0.26, 0.26, 0.26, 0, 0,
      0.26, 0.26, 0.26, 0, 0,
      0, 0, 0, 1, 0,
    ]);

  static const Map<PickupType, double> _pickupH = {
    PickupType.coin: 26,
    PickupType.star: 28,
    PickupType.gem: 26,
    PickupType.heart: 26,
    PickupType.magnet: 28,
    PickupType.bolt: 32,
    PickupType.potion: 32,
  };

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final s = size.height / G.viewH;
    final vw = size.width / s;
    if (!vw.isFinite || vw <= 0) return;
    w.viewW = vw;
    if (!w.camX.isFinite) w.camX = 0;

    canvas.save();
    canvas.scale(s);
    canvas.clipRect(Rect.fromLTWH(0, 0, vw, G.viewH));

    _background(canvas, vw);

    if (w.shake > 0) {
      final a = w.shake * 22;
      canvas.translate(math.sin(w.time * 90) * a * 0.4, math.cos(w.time * 77) * a * 0.4);
    }
    canvas.translate(-w.camX, 0);
    _signs(canvas);
    _solids(canvas, vw);
    _pickups(canvas, vw);
    _enemies(canvas, vw);
    _hero(canvas);
    _particles(canvas);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant GamePainter oldDelegate) => true;

  // ------------------------------------------------------------- primitives
  void _img(Canvas c, ui.Image img, Rect dst,
      {bool flipX = false, double opacity = 1, Paint? paint}) {
    final p = paint ?? _paint;
    p.color = Color.fromRGBO(255, 255, 255, opacity);
    final src = Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble());
    if (flipX) {
      c.save();
      c.translate(dst.center.dx, 0);
      c.scale(-1, 1);
      c.translate(-dst.center.dx, 0);
      c.drawImageRect(img, src, dst, p);
      c.restore();
    } else {
      c.drawImageRect(img, src, dst, p);
    }
  }

  /// 3 bo'lakli cho'zish: chap/o'ng chekkalar o'zgarmaydi, o'rtasi takrorlanadi.
  void _slice3(Canvas c, ui.Image img, Rect dst, double capSrc) {
    final iw = img.width.toDouble();
    final ih = img.height.toDouble();
    final k = dst.height / ih;
    final capDst = capSrc * k;
    c.drawImageRect(img, Rect.fromLTWH(0, 0, capSrc, ih),
        Rect.fromLTWH(dst.left, dst.top, capDst, dst.height), _paint);
    c.drawImageRect(img, Rect.fromLTWH(iw - capSrc, 0, capSrc, ih),
        Rect.fromLTWH(dst.right - capDst, dst.top, capDst, dst.height), _paint);

    final midSrcW = iw - 2 * capSrc;
    final midDstW = midSrcW * k;
    if (midDstW <= 0 || !midDstW.isFinite) return;
    double x = dst.left + capDst;
    final end = dst.right - capDst;
    while (x < end - 0.01) {
      final wd = math.min(midDstW, end - x);
      final srcW = midSrcW * (wd / midDstW);
      c.drawImageRect(img, Rect.fromLTWH(capSrc, 0, srcW, ih),
          Rect.fromLTWH(x, dst.top, wd + 0.6, dst.height), _paint);
      x += wd;
    }
  }

  // ---------------------------------------------------------------- layers
  void _background(Canvas c, double vw) {
    final img = Sprites.get(w.level.bg);
    // Rasm butun daraja bo'ylab bitta bo'lib, sekin siljiydi (takrorlanmaydi).
    final scale = math.max(G.viewH / img.height, vw * 1.35 / img.width);
    final bw = img.width * scale;
    final bh = img.height * scale;
    final maxCam = math.max(1.0, w.level.length - vw);
    final t = (w.camX / maxCam).clamp(0.0, 1.0).toDouble();
    final x = -t * (bw - vw);
    _img(c, img, Rect.fromLTWH(x, G.viewH - bh, bw, bh));
  }

  void _signs(Canvas c) {
    const gy = G.groundY;
    _img(c, Sprites.get('signpost'), const Rect.fromLTWH(20, gy - 68, 68, 69));
    final gx = w.level.goalX;
    final bob = math.sin(w.time * 4) * 2;
    _img(c, Sprites.get('signpost'), Rect.fromLTWH(gx - 4, gy - 84 + bob, 84, 85));
  }

  void _solids(Canvas c, double vw) {
    for (final s in w.level.solids) {
      final r = s.rect;
      if (r.right < w.camX - 60 || r.left > w.camX + vw + 60) continue;
      switch (s.kind) {
        case SolidKind.ground:
          _slice3(c, Sprites.get('grass_l'),
              Rect.fromLTRB(r.left - 6, r.top - 11, r.right + 6, r.top + 67), 46);
          break;
        case SolidKind.platform:
          _slice3(c, Sprites.get('grass_s'),
              Rect.fromLTWH(r.left - 4, r.top - 9, r.width + 8, 46), 34);
          break;
        case SolidKind.crate:
          _img(c, Sprites.get('crate'), r);
          break;
        case SolidKind.stone:
          _img(c, Sprites.get('stone'), r);
          break;
        case SolidKind.barrel:
          _img(c, Sprites.get('barrel'), r);
          break;
        case SolidKind.qblock:
          final off = s.bump > 0 ? -math.sin(s.bump / 0.2 * math.pi) * 9 : 0.0;
          _img(c, Sprites.get('qblock'), r.shift(Offset(0, off)),
              paint: s.used ? _gray : null);
          break;
      }
    }
  }

  void _pickups(Canvas c, double vw) {
    for (final p in w.level.pickups) {
      if (p.cx < w.camX - 40 || p.cx > w.camX + vw + 40) continue;
      final img = Sprites.get(p.type.name);
      final hh = _pickupH[p.type]!;
      double ww = hh * img.width / img.height;
      final bob = p.moving ? 0.0 : math.sin(w.time * 3 + p.phase) * 3;
      if (p.type == PickupType.coin) {
        ww *= 0.55 + 0.45 * math.cos(w.time * 3 + p.phase).abs();
      }
      final pop = p.age < 0.2 ? 0.6 + p.age / 0.2 * 0.4 : 1.0;
      final dst = Rect.fromCenter(
          center: Offset(p.cx, p.cy + bob), width: ww * pop, height: hh * pop);
      _img(c, img, dst);
    }
  }

  void _enemies(Canvas c, double vw) {
    for (final e in w.level.enemies) {
      if (e.x + e.w < w.camX - 60 || e.x > w.camX + vw + 60) continue;
      final img = Sprites.get(e.type.name);
      var dst = Rect.fromLTWH(e.x, e.y, e.w, e.h);
      var opacity = 1.0;
      if (e.dead) {
        final t = (e.deadT / 0.3).clamp(0.0, 1.0).toDouble();
        final nh = e.h * (1 - t * 0.8);
        dst = Rect.fromLTWH(e.x, e.y + e.h - nh, e.w, nh);
        opacity = 1 - t;
      }
      final flip = (e.type == EnemyType.turtle || e.type == EnemyType.ghost) && e.dir < 0;
      if (e.boss && e.hitCd > 0 && (e.hitCd * 14).floor().isEven) opacity = 0.4;
      _img(c, img, dst, flipX: flip, opacity: opacity);
      if (e.boss && !e.dead) {
        final bar = Rect.fromLTWH(e.x + 15, e.y - 14, e.w - 30, 8);
        c.drawRRect(RRect.fromRectAndRadius(bar.inflate(1.5), const Radius.circular(5)),
            Paint()..color = const Color(0xCC000000));
        final f = e.hp / e.maxHp;
        c.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromLTWH(bar.left, bar.top, bar.width * f, bar.height), const Radius.circular(4)),
            Paint()..color = const Color(0xFFE53935));
      }
    }
  }

  void _hero(Canvas c) {
    final h = w.hero;
    final img = Sprites.get(w.heroFrame);
    final ww = img.width * 0.29;
    final hh = img.height * 0.29;
    final cx = h.x + G.heroW / 2;
    final feet = h.y + G.heroH + 1;

    if (w.magnetT > 0) {
      final ring = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0x66FF5A5A);
      c.drawCircle(Offset(cx, h.cy), 60 + math.sin(w.time * 6) * 6, ring);
    }

    // Oyoq ostidagi yumshoq soya
    if (h.onGround) {
      c.drawOval(
        Rect.fromCenter(center: Offset(cx, feet - 1), width: 30, height: 6),
        Paint()..color = const Color(0x2E000000),
      );
    }

    // Squash & stretch + yugurish tebranishi
    double sx = 1, sy = 1, bob = 0;
    final speedK = (h.vx.abs() / G.runSpeed).clamp(0.0, 1.4).toDouble();
    if (h.landT > 0) {
      final k = h.landT / 0.14;
      sx = 1 + 0.17 * k;
      sy = 1 - 0.15 * k;
    } else if (!h.onGround) {
      final st = (-h.vy / 2600).clamp(-0.08, 0.12).toDouble();
      sy = 1 + st;
      sx = 1 - st * 0.6;
    } else if (h.vx.abs() > 12 && !h.skid) {
      bob = math.sin(h.stride * math.pi / 2).abs() * 2.6 * speedK;
    } else {
      sy = 1 + math.sin(w.time * 3) * 0.012; // nafas olish
    }

    final blink = h.invul > 0 && (h.invul * 10).floor().isEven;
    final p = Paint()
      ..filterQuality = FilterQuality.medium
      ..isAntiAlias = true
      ..color = Color.fromRGBO(255, 255, 255, blink ? 0.35 : 1.0);

    c.save();
    c.translate(cx, feet - bob);
    c.rotate(h.lean);
    c.scale(sx * h.visFacing, sy);
    final src = Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble());
    c.drawImageRect(img, src, Rect.fromLTWH(-ww / 2, -hh, ww, hh), p);
    c.restore();
  }

  void _particles(Canvas c) {
    final p = Paint()..style = PaintingStyle.fill;
    for (final pt in w.particles) {
      final a = (pt.life / pt.maxLife).clamp(0.0, 1.0).toDouble();
      p.color = pt.color.withAlpha((a * 255).round());
      c.drawCircle(Offset(pt.x, pt.y), pt.size * (0.5 + a * 0.5), p);
    }
  }
}
