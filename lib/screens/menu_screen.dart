import 'package:flutter/material.dart';

import '../core/sprites.dart';
import '../widgets/common.dart';
import 'level_select_screen.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(Sprites.path('bg_day'), fit: BoxFit.cover),
          SafeArea(
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const OutlinedText('SARGUZASHT', size: 54),
                          const SizedBox(height: 2),
                          const OutlinedText("Platformer o'yini", size: 18, stroke: Color(0xFF1F4D7A)),
                          const SizedBox(height: 18),
                          ImgButton(
                            asset: 'btn_play',
                            size: 110,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const LevelSelectScreen()),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: LayoutBuilder(
                    builder: (context, c) {
                      final h = c.maxHeight;
                      return Stack(
                        clipBehavior: Clip.hardEdge,
                        children: [
                          Positioned(
                            bottom: -h * 0.12,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: Image.asset(Sprites.path('grass_l'), width: h * 0.95),
                            ),
                          ),
                          Positioned(
                            bottom: h * 0.28,
                            left: c.maxWidth * 0.12,
                            child: Image.asset(Sprites.path('hero_idle'), height: h * 0.36),
                          ),
                          Positioned(
                            bottom: h * 0.28,
                            right: c.maxWidth * 0.12,
                            child: Image.asset(Sprites.path('slime'), width: h * 0.2),
                          ),
                          Positioned(
                            bottom: h * 0.7,
                            left: c.maxWidth * 0.3,
                            child: Image.asset(Sprites.path('coin'), width: h * 0.1),
                          ),
                          Positioned(
                            bottom: h * 0.62,
                            right: c.maxWidth * 0.3,
                            child: Image.asset(Sprites.path('star'), width: h * 0.11),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const Positioned(
            right: 12,
            top: 8,
            child: SafeArea(child: SoundToggle()),
          ),
        ],
      ),
    );
  }
}
