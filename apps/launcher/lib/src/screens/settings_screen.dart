import 'package:companion_protocol/companion_protocol.dart';
import 'package:flutter/material.dart';

import '../home_controller.dart';
import '../theme.dart';
import '../widgets/focus_tile.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.controller});
  final HomeController controller;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _address = '';

  /// Revoking needs two presses so a stray OK does not unpair the iPhone.
  bool _confirmRevoke = false;
  bool _revoked = false;

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
      await widget.controller.revokeDevices();
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

  @override
  void initState() {
    super.initState();
    widget.controller.platform.companionAddress().then((a) {
      if (mounted) setState(() => _address = a);
    }).ignore();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return Scaffold(
      body: ListenableBuilder(
        listenable: c,
        builder: (context, _) => Padding(
          padding: const EdgeInsets.fromLTRB(60, 40, 60, 32),
          child: FocusTraversalGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Ajustes', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.6)),
                const SizedBox(height: 24),
                _Row(
                  icon: Icons.grid_view_rounded,
                  title: 'Columnas en inicio',
                  value: '${c.layout.columns}',
                  autofocus: true,
                  onSelect: () {
                    final next = c.layout.columns >= LauncherLayout.maxColumns ? LauncherLayout.minColumns : c.layout.columns + 1;
                    c.setColumns(next);
                  },
                ),
                _Row(
                  icon: Icons.visibility_outlined,
                  title: 'Apps ocultas',
                  value: c.hiddenApps.isEmpty ? 'Ninguna' : '${c.hiddenApps.length} · OK para mostrar la primera',
                  onSelect: () {
                    if (c.hiddenApps.isNotEmpty) c.unhide(c.hiddenApps.first);
                  },
                ),
                _Row(
                  icon: Icons.phone_iphone,
                  title: 'App del iPhone',
                  value: c.companionClients.isEmpty
                      ? (_address.isEmpty ? 'Esperando conexión' : 'Esperando conexión · $_address')
                      : c.companionClients.join(', '),
                  onSelect: () {},
                ),
                _Row(
                  icon: Icons.link_off,
                  title: 'Dispositivos vinculados',
                  value: _revokeLabel,
                  onSelect: _onRevoke,
                ),
                _Row(
                  icon: Icons.settings_outlined,
                  title: 'Ajustes del sistema',
                  value: 'Red, pantalla, sonido, protector de pantalla',
                  onSelect: c.platform.openSystemSettings,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.title, required this.value, required this.onSelect, this.autofocus = false});
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onSelect;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        height: 62,
        width: 620,
        child: FocusTile(
          autofocus: autofocus,
          borderRadius: 18,
          focusedScale: 1.02,
          onSelect: onSelect,
          semanticLabel: title,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                Icon(icon, size: 22, color: Palette.accent),
                const SizedBox(width: 14),
                Expanded(
                  flex: 3,
                  child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 12),
                Flexible(
                  flex: 4,
                  child: Text(value,
                      maxLines: 1,
                      textAlign: TextAlign.end,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, color: Palette.ink2, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
