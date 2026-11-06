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
          Image.asset(Sprites.path('bg_night'), fit: BoxFit.cover),
          Container(color: Colors.black38),
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
    return GestureDetector(
      onTap: locked ? null : () => _open(i),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 92,
            height: 76,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: Opacity(
                    opacity: locked ? 0.5 : 1,
                    child: Image.asset(Sprites.path('plank'), fit: BoxFit.fill),
                  ),
                ),
                locked
                    ? const Icon(Icons.lock_rounded, color: Colors.white, size: 34)
                    : OutlinedText('${i + 1}', size: 34),
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
