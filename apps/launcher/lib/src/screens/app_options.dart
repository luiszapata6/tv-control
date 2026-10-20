import 'package:flutter/material.dart';

import '../home_controller.dart';
import '../platform.dart';
import '../theme.dart';
import '../widgets/focus_tile.dart';

/// Options for an app (hold OK on it): pin, move, hide, app info.
Future<void> showAppOptions(BuildContext context, HomeController c, LauncherApp app) {
  final pinned = c.isPinned(app.package);
  final options = <(IconData, String, Future<void> Function())>[
    if (!pinned) (Icons.push_pin_outlined, 'Fijar en inicio', () => c.pin(app)),
    if (pinned) (Icons.chevron_left, 'Mover a la izquierda', () => c.shift(app, -1)),
    if (pinned) (Icons.chevron_right, 'Mover a la derecha', () => c.shift(app, 1)),
    if (pinned) (Icons.remove_circle_outline, 'Quitar de inicio', () => c.unpin(app)),
    (Icons.visibility_off_outlined, 'Ocultar', () => c.hide(app)),
    (Icons.info_outline, 'Información de la app', () => c.platform.openAppInfo(app.package)),
  ];
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Cerrar',
    barrierColor: const Color(0xB305070C),
    transitionDuration: Motion.focus,
    transitionBuilder: (context, anim, _, child) => FadeTransition(
      opacity: anim,
      child: ScaleTransition(scale: Tween(begin: 0.94, end: 1.0).animate(CurvedAnimation(parent: anim, curve: Motion.spring)), child: child),
    ),
    pageBuilder: (context, _, __) => Center(
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          width: 360,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Palette.card, borderRadius: BorderRadius.circular(26), border: Border.all(color: Palette.line)),
          child: FocusTraversalGroup(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(app.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 14),
                for (final (i, (icon, label, action)) in options.indexed) ...[
                  SizedBox(
                    height: 46,
                    child: FocusTile(
                      autofocus: i == 0,
                      borderRadius: 14,
                      focusedScale: 1.03,
                      semanticLabel: label,
                      onSelect: () async {
                        Navigator.of(context).pop();
                        await action();
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Row(children: [
                          Icon(icon, size: 20, color: Palette.ink),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                          ),
                        ]),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
