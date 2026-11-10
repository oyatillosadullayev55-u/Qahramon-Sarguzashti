import 'package:flutter/material.dart';

import '../core/sprites.dart';

/// Qalin kontur bilan yozilgan matn (o'yin uslubi).
class OutlinedText extends StatelessWidget {
  const OutlinedText(
    this.text, {
    super.key,
    this.size = 28,
    this.color = Colors.white,
    this.stroke = const Color(0xFF1B2A5A),
  });

  final String text;
  final double size;
  final Color color;
  final Color stroke;

  @override
  Widget build(BuildContext context) {
    final base = TextStyle(fontSize: size, fontWeight: FontWeight.w900, letterSpacing: 1);
    return Stack(
      children: [
        Text(
          text,
          style: base.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = size * 0.22
              ..strokeJoin = StrokeJoin.round
              ..color = stroke,
          ),
        ),
        Text(text, style: base.copyWith(color: color)),
      ],
    );
  }
}

/// Bosilganda biroz kichrayadigan rasmli tugma.
class ImgButton extends StatefulWidget {
  const ImgButton({super.key, required this.asset, required this.size, required this.onTap});

  final String asset; // masalan: 'btn_playbig'
  final double size;
  final VoidCallback onTap;

  @override
  State<ImgButton> createState() => _ImgButtonState();
}

class _ImgButtonState extends State<ImgButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) {
        setState(() => _down = false);
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _down ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: Image.asset(
          Sprites.path(widget.asset),
          width: widget.size,
          filterQuality: FilterQuality.medium,
        ),
      ),
    );
  }
}

/// Yaltiroq gradient tugma (Home / Restart / Next uslubida).
class GlossButton extends StatefulWidget {
  const GlossButton({
    super.key,
    required this.onTap,
    this.icon,
    this.label,
    this.top = const Color(0xFF58B2FF),
    this.bottom = const Color(0xFF1D5FE6),
    this.width = 64,
    this.height = 56,
  });

  final VoidCallback onTap;
  final IconData? icon;
  final String? label;
  final Color top;
  final Color bottom;
  final double width;
  final double height;

  const GlossButton.green({
    super.key,
    required this.onTap,
    this.icon,
    this.label,
    this.width = 110,
    this.height = 56,
  })  : top = const Color(0xFF8BE04A),
        bottom = const Color(0xFF2E9E1E);

  const GlossButton.orange({
    super.key,
    required this.onTap,
    this.icon,
    this.label,
    this.width = 110,
    this.height = 56,
  })  : top = const Color(0xFFFFC24A),
        bottom = const Color(0xFFE67A12);

  @override
  State<GlossButton> createState() => _GlossButtonState();
}

class _GlossButtonState extends State<GlossButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final border = Color.lerp(widget.bottom, Colors.black, 0.55)!;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) {
        setState(() => _down = false);
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _down ? 0.93 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border, width: 3),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [widget.top, widget.bottom],
            ),
            boxShadow: const [
              BoxShadow(color: Color(0x66000000), blurRadius: 8, offset: Offset(0, 4)),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                left: 6,
                right: 6,
                top: 3,
                height: widget.height * 0.34,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(60),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.icon != null)
                      Icon(widget.icon, color: Colors.white, size: widget.height * 0.55),
                    if (widget.icon != null && widget.label != null) const SizedBox(width: 6),
                    if (widget.label != null)
                      OutlinedText(widget.label!, size: widget.height * 0.34, stroke: border),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bir vaqtda bir nechta barmoq bilan ishlaydigan "ushlab turish" tugmasi.
class HoldButton extends StatefulWidget {
  const HoldButton({
    super.key,
    required this.size,
    required this.icon,
    required this.onDown,
    required this.onUp,
    this.color = Colors.white,
  });

  final double size;
  final IconData icon;
  final VoidCallback onDown;
  final VoidCallback onUp;
  final Color color;

  @override
  State<HoldButton> createState() => _HoldButtonState();
}

class _HoldButtonState extends State<HoldButton> {
  bool _down = false;

  void _set(bool v) {
    if (_down == v) return;
    setState(() => _down = v);
    if (v) {
      widget.onDown();
    } else {
      widget.onUp();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 70),
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color.withAlpha(_down ? 170 : 80),
          border: Border.all(color: Colors.white.withAlpha(200), width: 2.5),
        ),
        child: Icon(widget.icon, color: Colors.white, size: widget.size * 0.58),
      ),
    );
  }
}

/// Qora-oq (rangsiz) filtr — olinmagan yulduzlar uchun.
class GrayOut extends StatelessWidget {
  const GrayOut({super.key, required this.child, this.gray = true});

  final Widget child;
  final bool gray;

  @override
  Widget build(BuildContext context) {
    if (!gray) return child;
    return Opacity(
      opacity: 0.55,
      child: ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          0.2126, 0.7152, 0.0722, 0, 0, //
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0, 0, 0, 1, 0,
        ]),
        child: child,
      ),
    );
  }
}

/// Tanga / olmos kabi hisoblagich "tabletkasi".
class StatPill extends StatelessWidget {
  const StatPill({super.key, required this.asset, required this.value, this.iconSize = 22});

  final String asset;
  final String value;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 3, 12, 3),
      decoration: BoxDecoration(
        color: const Color(0xAA0A1633),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(50), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(Sprites.path(asset), height: iconSize),
          const SizedBox(width: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

/// Qahramonning yuzi (dumaloq avatar).
class HeroAvatar extends StatelessWidget {
  const HeroAvatar({super.key, this.size = 46});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFFFD25A), width: 3),
        color: const Color(0xFF14224A),
      ),
      child: ClipOval(
        child: Image.asset(
          Sprites.path('hero_idle'),
          width: size,
          height: size,
          fit: BoxFit.cover,
          alignment: const Alignment(0, -0.9),
        ),
      ),
    );
  }
}
