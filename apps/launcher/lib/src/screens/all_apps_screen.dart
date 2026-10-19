import 'package:flutter/material.dart';

import '../home_controller.dart';
import '../theme.dart';
import '../widgets/app_tile.dart';
import 'app_options.dart';

/// Every installed app (except hidden ones), alphabetically.
class AllAppsScreen extends StatelessWidget {
  const AllAppsScreen({super.key, required this.controller});
  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final apps = controller.visibleApps;
          return Padding(
            padding: const EdgeInsets.fromLTRB(60, 40, 60, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('Todas las apps', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.6)),
                    const SizedBox(width: 14),
                    Text('${apps.length}', style: const TextStyle(fontSize: 16, color: Palette.ink2, fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 22),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.only(bottom: 40, top: 8),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 6,
                      mainAxisSpacing: 18,
                      crossAxisSpacing: 18,
                      childAspectRatio: 1.25,
                    ),
                    itemCount: apps.length,
                    itemBuilder: (context, i) => AppTile(
                      key: ValueKey(apps[i].package),
                      app: apps[i],
                      autofocus: i == 0,
                      loadIcon: controller.icon,
                      onSelect: () => controller.launch(apps[i]),
                      onLongPress: () => showAppOptions(context, controller, apps[i]),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
