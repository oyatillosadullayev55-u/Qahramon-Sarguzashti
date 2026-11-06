import 'package:flutter/material.dart';

import '../core/audio.dart';
import '../core/progress.dart';
import '../core/sprites.dart';

/// Qalin kontur bilan yozilgan matn (o'yin uslubi).
class OutlinedText extends StatelessWidget {
  const OutlinedText(
    this.text, {
    super.key,
    this.size = 28,
    this.color = Colors.white,
    this.stroke = const Color(0xFF4A2511),
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

  final String asset; // masalan: 'btn_play'
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
        scale: _down ? 0.9 : 1.0,
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
          color: widget.color.withAlpha(_down ? 150 : 70),
          border: Border.all(color: Colors.white.withAlpha(190), width: 2.5),
        ),
        child: Icon(widget.icon, color: Colors.white, size: widget.size * 0.6),
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

/// Ovozni yoqish/o'chirish tugmasi (sozlama saqlanadi).
class SoundToggle extends StatefulWidget {
  const SoundToggle({super.key, this.size = 44});

  final double size;

  @override
  State<SoundToggle> createState() => _SoundToggleState();
}

class _SoundToggleState extends State<SoundToggle> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        setState(() => Sfx.setEnabled(!Sfx.enabled));
        Progress.saveSettings();
      },
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withAlpha(110),
          border: Border.all(color: Colors.white.withAlpha(200), width: 2),
        ),
        child: Icon(
          Sfx.enabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
          color: Colors.white,
          size: widget.size * 0.58,
        ),
      ),
    );
  }
}
