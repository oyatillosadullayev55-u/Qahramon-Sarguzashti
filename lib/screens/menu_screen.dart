import 'package:flutter/material.dart';

import '../core/progress.dart';
import '../core/sprites.dart';
import '../widgets/common.dart';
import '../widgets/panels.dart';
import 'level_select_screen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  Future<void> _play() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const LevelSelectScreen()),
    );
    if (mounted) setState(() {});
  }

  Widget _profile() {
    final lvl = Progress.playerLevel;
    final frac = (Progress.totalStars % 3) / 3.0;
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 4, 16, 4),
      decoration: BoxDecoration(
        color: const Color(0xAA0A1633),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withAlpha(50), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const HeroAvatar(size: 44),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(Progress.playerName,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Lv. $lvl',
                      style: const TextStyle(color: Color(0xFFBFD0FF), fontSize: 11)),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 44,
                    height: 6,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: frac == 0 ? 0.08 : frac,
                        backgroundColor: const Color(0x55FFFFFF),
                        valueColor: const AlwaysStoppedAnimation(Color(0xFFFFB02E)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(Sprites.path('bg_env'), fit: BoxFit.cover),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x66050B22), Color(0x99050B22)],
              ),
            ),
          ),
          SafeArea(
            child: Stack(
              children: [
                Row(
                  children: [
                    // Chap: qahramon portreti
                    Expanded(
                      flex: 4,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 60, 8, 14),
                        child: Center(
                          child: AspectRatio(
                            aspectRatio: 624 / 736,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFF3A5DB8), width: 2.5),
                                boxShadow: const [
                                  BoxShadow(color: Color(0x884B7BFF), blurRadius: 18),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(17),
                                child: Image.asset(Sprites.path('portrait'), fit: BoxFit.cover),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // O'ng: logo va tugmalar
                    Expanded(
                      flex: 6,
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset(Sprites.path('logo'), width: 340),
                              const SizedBox(height: 14),
                              ImgButton(asset: 'btn_playbig', size: 220, onTap: _play),
                              const SizedBox(height: 14),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ImgButton(
                                      asset: 'btn_settings',
                                      size: 62,
                                      onTap: () => showSettings(context)),
                                  const SizedBox(width: 22),
                                  ImgButton(
                                      asset: 'btn_trophy',
                                      size: 62,
                                      onTap: () => showRecords(context)),
                                  const SizedBox(width: 22),
                                  ImgButton(
                                      asset: 'btn_stats',
                                      size: 62,
                                      onTap: () => showStats(context)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Positioned(left: 12, top: 8, child: _profile()),
                Positioned(
                  right: 12,
                  top: 8,
                  child: Row(
                    children: [
                      StatPill(asset: 'coin', value: '${Progress.coins}'),
                      const SizedBox(width: 8),
                      StatPill(asset: 'gem', value: '${Progress.gems}'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
