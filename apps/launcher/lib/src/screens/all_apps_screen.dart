import 'package:flutter/material.dart';

import '../home_controller.dart';
import '../theme.dart';
import '../widgets/app_tile.dart';
import '../widgets/hints.dart';
import 'app_options.dart';

/// Every installed app (except hidden ones), alphabetically.
class AllAppsScreen extends StatelessWidget {
  const AllAppsScreen({super.key, required this.controller});
  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: backgroundGlow,
        child: ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            final apps = controller.visibleApps;
            return Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 48),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('INICIO  ›', style: Txt.eyebrow),
                                const SizedBox(height: 4),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    const Text('Todas las apps', style: Txt.title),
                                    const SizedBox(width: 10),
                                    Text('${apps.length}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Palette.ink3)),
                                  ],
                                ),
                              ],
                            ),
                            const Spacer(),
                            const KeyHints([KeyHint('OK', 'Opciones', before: 'Mantén'), KeyHint('Atrás', 'Inicio')]),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Expanded(
                        child: LayoutBuilder(builder: (context, box) {
                          const cols = 6, gap = 16.0;
                          final w = (box.maxWidth - 96 - gap * (cols - 1)) / cols;
                          return GridView.builder(
                            padding: const EdgeInsets.fromLTRB(48, 14, 48, 60),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: cols,
                              crossAxisSpacing: gap,
                              mainAxisSpacing: 4,
                              // Card (16:9) + 12 gap + 18 label.
                              mainAxisExtent: w * 9 / 16 + 30,
                            ),
                            itemCount: apps.length,
                            itemBuilder: (context, i) => AppTile(
                              key: ValueKey(apps[i].package),
                              app: apps[i],
                              autofocus: i == 0,
                              pinned: controller.isPinned(apps[i].package),
                              loadIcon: controller.icon,
                              onSelect: () => controller.launch(apps[i]),
                              onLongPress: () => showAppOptions(context, controller, apps[i]),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
                const Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 80,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0x000A0B10), Palette.bg],
                          stops: [0, 0.85],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
