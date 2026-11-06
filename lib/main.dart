import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/audio.dart';
import 'core/progress.dart';
import 'core/sprites.dart';
import 'screens/menu_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  await Sprites.load();
  await Progress.load();
  await Sfx.init();
  runApp(const OyinApp());
}

class OyinApp extends StatelessWidget {
  const OyinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sarguzasht',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.orange),
      home: const MenuScreen(),
    );
  }
}
