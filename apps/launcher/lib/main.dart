import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import 'src/home_controller.dart';
import 'src/platform.dart';
import 'src/screens/home_screen.dart';
import 'src/theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = HomeController(MethodChannelLauncherPlatform(), weatherRefresh: const Duration(minutes: 20));
  unawaited(controller.start());
  if (const bool.fromEnvironment('PERF_LOG')) _logFrameTimes();
  runApp(TvLauncher(controller: controller));
}

/// Build with --dart-define=PERF_LOG=true: every 30 frames logs p50/p90 build
/// and raster times (ms) to logcat, to measure focus smoothness on the TV.
void _logFrameTimes() {
  final build = <double>[], raster = <double>[];
  double pct(List<double> v, double p) => (v..sort())[((v.length - 1) * p).round()];
  SchedulerBinding.instance.addTimingsCallback((timings) {
    for (final t in timings) {
      build.add(t.buildDuration.inMicroseconds / 1000);
      raster.add(t.rasterDuration.inMicroseconds / 1000);
    }
    if (build.length >= 30) {
      debugPrint('PERF frames=${build.length} build p50=${pct(build, .5).toStringAsFixed(1)} p90=${pct(build, .9).toStringAsFixed(1)} '
          'raster p50=${pct(raster, .5).toStringAsFixed(1)} p90=${pct(raster, .9).toStringAsFixed(1)} max=${raster.last.toStringAsFixed(1)}');
      build.clear();
      raster.clear();
    }
  });
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
