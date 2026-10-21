import 'package:flutter/material.dart';

import '../home_controller.dart';
import '../platform.dart';
import '../theme.dart';
import '../widgets/app_tile.dart';
import '../widgets/focus_tile.dart';
import '../widgets/hints.dart';

/// Options for an app (hold OK on it): pin, move, hide, app info.
Future<void> showAppOptions(BuildContext context, HomeController c, LauncherApp app) {
  final pinned = c.isPinned(app.package);
  final position = c.pinned.indexWhere((a) => a.package == app.package);
  final options = <(IconData, String, Future<void> Function())>[
    if (!pinned) (Icons.add_circle_outline_rounded, 'Fijar en Tus apps', () => c.pin(app)),
    if (pinned) (Icons.remove_circle_outline_rounded, 'Quitar de Tus apps', () => c.unpin(app)),
    if (pinned) (Icons.arrow_back_rounded, 'Mover a la izquierda', () => c.shift(app, -1)),
    if (pinned) (Icons.arrow_forward_rounded, 'Mover a la derecha', () => c.shift(app, 1)),
    (Icons.visibility_off_outlined, 'Ocultar', () => c.hide(app)),
    (Icons.info_outline_rounded, 'Información de la app', () => c.platform.openAppInfo(app.package)),
  ];
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Cerrar',
    barrierColor: Palette.scrim,
    transitionDuration: Motion.overlayIn,
    transitionBuilder: (context, anim, _, child) {
      final t = CurvedAnimation(parent: anim, curve: Motion.standard);
      return FadeTransition(
        opacity: t,
        child: SlideTransition(position: Tween(begin: const Offset(0, 0.03), end: Offset.zero).animate(t), child: child),
      );
    },
    pageBuilder: (context, _, __) => Center(
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          width: 590,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Palette.surface2,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0x12FFFFFF)),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 220,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: AppArt(app: app, icon: c.icon(app.package), tint: c.tint(app.package)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(app.label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.2)),
                    const SizedBox(height: 3),
                    Text(position >= 0 ? 'Fijada · posición ${position + 1} de ${c.pinned.length}' : 'No fijada',
                        style: Txt.hint),
                  ],
                ),
              ),
              const SizedBox(width: 32),
              Expanded(
                child: FocusTraversalGroup(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final (i, (icon, label, action)) in options.indexed) ...[
                        if (i > 0) const SizedBox(height: 7),
                        SizedBox(
                          height: 40,
                          child: FocusTile(
                            autofocus: i == 0,
                            radius: 9,
                            semanticLabel: label,
                            onSelect: () async {
                              Navigator.of(context).pop();
                              await action();
                            },
                            builder: (context, f) => Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 15),
                              child: Row(children: [
                                Icon(icon, size: 17, color: f ? Palette.bg : Palette.ink),
                                const SizedBox(width: 11),
                                Expanded(
                                  child: Text(label,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Txt.row.copyWith(color: f ? Palette.bg : Palette.ink)),
                                ),
                              ]),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      const Align(alignment: Alignment.centerLeft, child: KeyHint('Atrás', 'Cerrar')),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
