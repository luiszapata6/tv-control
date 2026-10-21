import 'package:companion_protocol/companion_protocol.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../home_controller.dart';
import '../theme.dart';
import '../widgets/focus_tile.dart';
import '../widgets/hints.dart';

/// Settings slide in from the right over the home screen.
Future<void> showSettingsPanel(BuildContext context, HomeController c) => showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Cerrar',
      barrierColor: const Color(0xA806070B),
      transitionDuration: Motion.panelIn,
      transitionBuilder: (context, anim, _, child) => SlideTransition(
        position: Tween(begin: const Offset(1, 0), end: Offset.zero).animate(CurvedAnimation(parent: anim, curve: Motion.standard)),
        child: child,
      ),
      pageBuilder: (context, _, __) => Align(
        alignment: Alignment.centerRight,
        child: Material(type: MaterialType.transparency, child: SettingsPanel(controller: c)),
      ),
    );

class SettingsPanel extends StatefulWidget {
  const SettingsPanel({super.key, required this.controller});
  final HomeController controller;

  @override
  State<SettingsPanel> createState() => _SettingsPanelState();
}

class _SettingsPanelState extends State<SettingsPanel> {
  String _address = '';

  /// Revoking needs two presses so a stray OK does not unpair the iPhone.
  bool _confirmRevoke = false;
  bool _revoked = false;

  HomeController get c => widget.controller;

  Future<void> _onRevoke() async {
    if (!_confirmRevoke) {
      setState(() {
        _confirmRevoke = true;
        _revoked = false;
      });
      return;
    }
    setState(() => _confirmRevoke = false);
    try {
      await c.revokeDevices();
      if (mounted) setState(() => _revoked = true);
    } catch (_) {
      // Native side unavailable: nothing was revoked, the row keeps its prompt.
    }
  }

  String get _revokeLabel {
    if (_confirmRevoke) return 'OK otra vez para desvincular todos';
    if (_revoked) return 'Listo · el iPhone debe vincularse de nuevo';
    return 'Desvincular todos';
  }

  void _columns(int delta) {
    final n = c.layout.columns + delta;
    // OK (delta 0 → +1 with wrap) cycles; ◀ ▶ stop at the ends.
    if (delta == 0) {
      c.setColumns(c.layout.columns >= LauncherLayout.maxColumns ? LauncherLayout.minColumns : c.layout.columns + 1);
    } else if (n >= LauncherLayout.minColumns && n <= LauncherLayout.maxColumns) {
      c.setColumns(n);
    }
  }

  @override
  void initState() {
    super.initState();
    c.platform.companionAddress().then((a) {
      if (mounted) setState(() => _address = a);
    }).ignore();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 400,
      height: double.infinity,
      padding: const EdgeInsets.fromLTRB(32, 32, 32, 20),
      decoration: const BoxDecoration(
        color: Palette.surface1,
        border: Border(left: BorderSide(color: Color(0x0FFFFFFF))),
      ),
      child: ListenableBuilder(
        listenable: c,
        builder: (context, _) {
          final clients = c.companionClients;
          return FocusTraversalGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Ajustes', style: TextStyle(fontSize: 28, height: 1, fontWeight: FontWeight.w700, letterSpacing: -0.56)),
                const SizedBox(height: 18),
                const Text('PANTALLA', style: Txt.eyebrow),
                const SizedBox(height: 8),
                _Row(
                  title: 'Columnas de la grilla',
                  sub: 'Apps por fila en Tus apps',
                  autofocus: true,
                  onSelect: () => _columns(0),
                  onKey: (k) {
                    if (k == LogicalKeyboardKey.arrowLeft) _columns(-1);
                    if (k == LogicalKeyboardKey.arrowRight) _columns(1);
                    return k == LogicalKeyboardKey.arrowLeft || k == LogicalKeyboardKey.arrowRight;
                  },
                  trailing: (f) => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.chevron_left_rounded, size: 18, color: f ? Palette.inkOnFill : Palette.ink3),
                      SizedBox(
                        width: 26,
                        child: Text('${c.layout.columns}',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: f ? Palette.bg : Palette.ink, fontFeatures: const [FontFeature.tabularFigures()])),
                      ),
                      Icon(Icons.chevron_right_rounded, size: 18, color: f ? Palette.bg : Palette.ink3),
                    ],
                  ),
                ),
                _Row(
                  title: 'Apps ocultas',
                  sub: c.hiddenApps.isEmpty ? 'Ninguna' : '${c.hiddenApps.length} · OK muestra la primera',
                  onSelect: () {
                    if (c.hiddenApps.isNotEmpty) c.unhide(c.hiddenApps.first);
                  },
                ),
                const SizedBox(height: 12),
                const Text('IPHONE', style: Txt.eyebrow),
                const SizedBox(height: 8),
                _Row(
                  icon: Icons.phone_iphone_rounded,
                  title: clients.isEmpty ? 'App del iPhone' : clients.join(', '),
                  sub: clients.isEmpty ? (_address.isEmpty ? 'Esperando conexión' : 'Esperando conexión · $_address') : 'Conectado ahora',
                  subColor: clients.isEmpty ? null : Palette.green,
                  onSelect: () {},
                ),
                _Row(icon: Icons.link_off_rounded, title: 'Dispositivos vinculados', sub: _revokeLabel, onSelect: _onRevoke),
                const SizedBox(height: 12),
                const Text('SISTEMA', style: Txt.eyebrow),
                const SizedBox(height: 8),
                _Row(
                  icon: Icons.settings_outlined,
                  title: 'Ajustes del sistema',
                  sub: 'Red, pantalla, sonido, protector',
                  onSelect: c.platform.openSystemSettings,
                ),
                const Spacer(),
                const KeyHints([KeyHint('‹  ›', 'Cambiar'), KeyHint('Atrás', 'Cerrar')]),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.title,
    required this.sub,
    required this.onSelect,
    this.icon,
    this.subColor,
    this.trailing,
    this.onKey,
    this.autofocus = false,
  });
  final IconData? icon;
  final String title;
  final String sub;
  final Color? subColor;
  final VoidCallback onSelect;
  final Widget Function(bool focused)? trailing;
  final bool Function(LogicalKeyboardKey key)? onKey;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: SizedBox(
        height: 50,
        child: FocusTile(
          autofocus: autofocus,
          radius: 10,
          focusedScale: 1.02,
          restColor: const Color(0x0AFFFFFF),
          onSelect: onSelect,
          onKey: onKey,
          semanticLabel: title,
          builder: (context, f) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, color: f ? Palette.bg : Palette.ink2),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: Txt.row.copyWith(color: f ? Palette.bg : Palette.ink)),
                      Text(sub,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Txt.hint.copyWith(color: f ? Palette.inkOnFill : (subColor ?? Palette.ink3))),
                    ],
                  ),
                ),
                if (trailing != null) trailing!(f),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
