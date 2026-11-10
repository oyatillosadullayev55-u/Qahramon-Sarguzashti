import 'package:flutter/material.dart';

import '../core/audio.dart';
import '../core/constants.dart';
import '../core/progress.dart';
import '../core/sprites.dart';
import 'common.dart';

/// Qorong'i, ko'k hoshiyali oyna (Sozlamalar, Rekordlar, Statistika uchun).
class GamePanel extends StatelessWidget {
  const GamePanel({super.key, required this.title, required this.icon, required this.child});

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340, maxHeight: 340),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Container(
            width: 330,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF3A5DB8), width: 2.5),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF14224F), Color(0xFF0A1230)],
              ),
              boxShadow: const [BoxShadow(color: Color(0x88000000), blurRadius: 20)],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(icon, color: Colors.white, size: 26),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Icon(Icons.close_rounded, color: Color(0xFF58B2FF), size: 30),
                    ),
                  ],
                ),
                const Divider(color: Color(0x443A5DB8), height: 14),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> showSettings(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black54,
    builder: (_) => const Material(
      type: MaterialType.transparency,
      child: _SettingsBody(),
    ),
  );
}

class _SettingsBody extends StatefulWidget {
  const _SettingsBody();

  @override
  State<_SettingsBody> createState() => _SettingsBodyState();
}

class _SettingsBodyState extends State<_SettingsBody> {
  Widget _row(IconData icon, String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
          ),
          Switch(
            value: value,
            onChanged: (v) {
              setState(() => onChanged(v));
              Progress.saveSettings();
            },
            thumbColor: WidgetStateProperty.all(Colors.white),
            trackColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.selected)
                  ? const Color(0xFF58D63A)
                  : const Color(0xFF3B4566),
            ),
          ),
        ],
      ),
    );
  }

  Widget _info(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
          ),
          Text(value, style: const TextStyle(color: Color(0xFFBFD0FF), fontSize: 15)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GamePanel(
      title: 'Sozlamalar',
      icon: Icons.settings_rounded,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _row(Icons.music_note_rounded, 'Musiqa', Sfx.musicEnabled, Sfx.setMusic),
          _row(Icons.volume_up_rounded, 'Ovozlar', Sfx.enabled, Sfx.setSounds),
          _row(Icons.vibration_rounded, 'Tebranish', Progress.vibration,
              (v) => Progress.vibration = v),
          _info(Icons.language_rounded, 'Til', "O'zbekcha"),
        ],
      ),
    );
  }
}

Future<void> showRecords(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black54,
    builder: (_) => Material(
      type: MaterialType.transparency,
      child: GamePanel(
        title: 'Rekordlar',
        icon: Icons.emoji_events_rounded,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < G.levelCount; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Text('${i + 1}-daraja',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    for (int s = 0; s < 3; s++)
                      GrayOut(
                        gray: s >= Progress.stars[i],
                        child: Image.asset(Sprites.path('star'), width: 20),
                      ),
                    SizedBox(
                      width: 64,
                      child: Text(
                        Progress.best[i] > 0 ? '${Progress.best[i]}' : '-',
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                            color: Color(0xFFFFD25A),
                            fontWeight: FontWeight.w800,
                            fontSize: 15),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

Future<void> showStats(BuildContext context) {
  Widget row(String asset, String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Image.asset(Sprites.path(asset), height: 26),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
            ),
            Text(value,
                style: const TextStyle(
                    color: Color(0xFFFFD25A), fontSize: 17, fontWeight: FontWeight.w800)),
          ],
        ),
      );
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black54,
    builder: (_) => Material(
      type: MaterialType.transparency,
      child: GamePanel(
        title: 'Statistika',
        icon: Icons.bar_chart_rounded,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            row('coin', 'Yig\'ilgan tangalar', '${Progress.coins}'),
            row('gem', 'Olmoslar', '${Progress.gems}'),
            row('star', 'Yulduzlar', '${Progress.totalStars} / ${G.levelCount * 3}'),
            row('key', 'Ochilgan darajalar', '${Progress.unlocked} / ${G.levelCount}'),
          ],
        ),
      ),
    ),
  );
}
