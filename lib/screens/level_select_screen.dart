import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../core/progress.dart';
import '../core/sprites.dart';
import '../widgets/common.dart';
import 'game_screen.dart';

class LevelSelectScreen extends StatefulWidget {
  const LevelSelectScreen({super.key});

  @override
  State<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends State<LevelSelectScreen> {
  Future<void> _open(int i) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => GameScreen(level: i)),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(Sprites.path('bg_env'), fit: BoxFit.cover),
          Container(color: const Color(0x88050B22)),
          SafeArea(
            child: Stack(
              children: [
                Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const OutlinedText('DARAJANI TANLANG', size: 34),
                        const SizedBox(height: 22),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (int i = 0; i < G.levelCount; i++)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: _tile(i),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 8,
                  top: 6,
                  child: ImgButton(
                    asset: 'btn_home',
                    size: 44,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ),
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

  Widget _tile(int i) {
    final locked = i >= Progress.unlocked;
    final stars = Progress.stars[i];
    final boss = i == G.levelCount - 1;
    return GestureDetector(
      onTap: locked ? null : () => _open(i),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: locked ? const Color(0xFF39466E) : const Color(0xFFFFE08A),
                width: 3,
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: locked
                    ? const [Color(0xFF26335C), Color(0xFF141C3A)]
                    : const [Color(0xFFFFC24A), Color(0xFFE67A12)],
              ),
              boxShadow: const [
                BoxShadow(color: Color(0x66000000), blurRadius: 8, offset: Offset(0, 4)),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                locked
                    ? const Icon(Icons.lock_rounded, color: Colors.white70, size: 34)
                    : OutlinedText('${i + 1}', size: 38, stroke: const Color(0xFF8A3E08)),
                if (boss && !locked)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Image.asset(Sprites.path('crown'), width: 24),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int s = 0; s < 3; s++)
                GrayOut(
                  gray: s >= stars,
                  child: Image.asset(Sprites.path('star'), width: 22),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
