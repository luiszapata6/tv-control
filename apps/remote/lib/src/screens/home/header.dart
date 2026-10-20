import 'dart:ui' show ImageFilter;

import 'package:atv_remote/atv_remote.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../services/tv_session.dart';
import '../../theme/theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/common.dart';
import '../../widgets/pressable.dart';
import '../../widgets/toast.dart';

/// TV name, connection status and the power button.
class SessionHeader extends StatelessWidget {
  const SessionHeader({super.key, required this.session, required this.title, required this.onOpenSettings});
  final TvSession session;
  final String title;
  final VoidCallback onOpenSettings;

  String _statusText() {
    return switch (session.status) {
      AtvConnectionStatus.connected => session.currentAppLabel.isEmpty
          ? session.tv.name
          : '${session.tv.name} · ${session.currentAppLabel}',
      AtvConnectionStatus.connecting || AtvConnectionStatus.idle => 'Conectando…',
      AtvConnectionStatus.unreachable => session.tv.mac == null ? 'TV no disponible' : 'TV apagada o fuera de la red',
      AtvConnectionStatus.needsPairing => 'Hay que emparejar de nuevo',
    };
  }

  Color _dot() => switch (session.status) {
        AtvConnectionStatus.connected => Tokens.success,
        AtvConnectionStatus.needsPairing => Tokens.danger,
        AtvConnectionStatus.unreachable => Tokens.warn,
        _ => Tokens.ink3,
      };

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Row(
        children: [
          Expanded(
            child: Pressable(
              onTap: onOpenSettings,
              size: PressSize.pill,
              semanticLabel: 'Televisores y ajustes',
              dimOnPress: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Flexible(child: Text(title, style: Txt.titleScreen, overflow: TextOverflow.ellipsis)),
                      const SizedBox(width: 4),
                      const Sym(Symbols.expand_more, size: 22, color: Tokens.ink2),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      StatusDot(color: _dot(), pulse: session.isConnected),
                      const SizedBox(width: 7),
                      Flexible(
                        child: Text(_statusText(), style: Txt.bodyS, maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          IconCircle(
            icon: Symbols.power_settings_new,
            label: session.isConnected ? 'Apagar o encender' : 'Encender la TV',
            iconColor: Tokens.danger,
            haptic: Haptic.medium,
            onTap: () async {
              final toast = ToastHost.maybeOf(context);
              final ok = await session.power();
              if (!ok) {
                toast?.show('No hay MAC para encenderla por red', kind: ToastKind.error);
              } else if (!session.isConnected) {
                toast?.show('Encendiendo la TV…', kind: ToastKind.info);
              }
            },
          ),
        ],
      ),
    );
  }
}

/// Floating dock: four tabs, blurred card at 86 %, selected tab tinted.
class Dock extends StatelessWidget {
  const Dock({super.key, required this.index, required this.onChanged});
  final int index;
  final ValueChanged<int> onChanged;

  static const items = [
    (Symbols.settings_remote, 'Control'),
    (Symbols.touch_app, 'Touchpad'),
    (Symbols.apps, 'Apps'),
    (Symbols.keyboard, 'Teclado'),
  ];

  @override
  Widget build(BuildContext context) {
    final a = AccentScope.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(34),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 68,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Tokens.card.withValues(alpha: 0.86),
            borderRadius: BorderRadius.circular(34),
            border: Border.all(color: Tokens.line),
          ),
          child: Row(
            children: [
              for (final (i, (icon, label)) in items.indexed)
                Expanded(
                  child: Pressable(
                    onTap: () => onChanged(i),
                    size: PressSize.pill,
                    haptic: Haptic.selection,
                    semanticLabel: label,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 260),
                      curve: Motion.standard,
                      decoration: BoxDecoration(
                        color: i == index ? a.tint : Colors.transparent,
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Sym(icon, filled: i == index, color: i == index ? a.ink : Tokens.ink2),
                          const SizedBox(height: 2),
                          Text(
                            label,
                            style: Txt.caption.copyWith(
                              color: i == index ? a.ink : Tokens.ink2,
                              fontWeight: i == index ? FontWeight.w800 : FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
