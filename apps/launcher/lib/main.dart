import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'src/home_controller.dart';
import 'src/platform.dart';
import 'src/screens/home_screen.dart';
import 'src/theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = HomeController(MethodChannelLauncherPlatform(), weatherRefresh: const Duration(minutes: 20));
  unawaited(controller.start());
  runApp(TvLauncher(controller: controller));
}

/// The UI is designed for a 960x540 canvas and scaled to the TV, so it looks
/// the same on any resolution or density.
class TvLauncher extends StatelessWidget {
  const TvLauncher({super.key, required this.controller, this.now});
  final HomeController controller;
  final DateTime Function()? now;

  static const designSize = Size(960, 540);

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: <ShortcutActivator, Intent>{
        // The TV remote's select key activates buttons.
        const SingleActivator(LogicalKeyboardKey.select): const ActivateIntent(),
      },
      child: MaterialApp(
        title: 'TV Control',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        builder: (context, child) => ColoredBox(
          color: Palette.bg,
          child: FittedBox(
            fit: BoxFit.contain,
            child: SizedBox.fromSize(size: designSize, child: child),
          ),
        ),
        home: PopScope(
          // Back on the home screen does nothing: a launcher never exits.
          canPop: false,
          child: HomeScreen(controller: controller, now: now),
        ),
      ),
    );
  }
}
