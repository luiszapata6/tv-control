import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../services/devices.dart';
import '../../services/services.dart';
import '../../services/tv_session.dart';
import '../../theme/theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/common.dart';
import '../../widgets/pressable.dart';
import '../onboarding/discover_screen.dart';
import 'companion_pairing.dart';

/// TVs, launcher connection, accent and haptics.
Future<void> showSettingsSheet(BuildContext context, TvSession? session) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Tokens.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => _SettingsSheet(session: session),
    );

class _SettingsSheet extends StatelessWidget {
  const _SettingsSheet({required this.session});
  final TvSession? session;

  @override
  Widget build(BuildContext context) {
    final services = Services.of(context);
    final devices = services.devices;
    final prefs = services.preferences;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.92,
      builder: (context, scroll) => ListenableBuilder(
        listenable: Listenable.merge([devices, prefs, if (session != null) session!]),
        builder: (context, _) => ListView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: Tokens.line, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 18),
            const Text('Televisores', style: Txt.titleSheet),
            const SizedBox(height: 12),
            Surface(
              color: Tokens.card2,
              child: Column(
                children: [
                  for (final (i, tv) in devices.tvs.indexed) ...[
                    if (i > 0) const Divider(height: 1, color: Tokens.line, indent: 62),
                    _TvRow(
                      tv: tv,
                      selected: tv.id == devices.selected?.id,
                      onTap: () {
                        devices.select(tv.id);
                        Navigator.of(context).pop();
                      },
                      onForget: () => _confirmForget(context, devices, tv),
                    ),
                  ],
                  if (devices.tvs.isNotEmpty) const Divider(height: 1, color: Tokens.line),
                  Pressable(
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const DiscoverScreen(canClose: true)));
                    },
                    size: PressSize.row,
                    semanticLabel: 'Agregar otra TV',
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      child: Row(
                        children: [
                          Sym(Symbols.add_circle, color: AccentScope.of(context).ink),
                          const SizedBox(width: 14),
                          Text('Agregar otra TV', style: Txt.titleRow.copyWith(color: AccentScope.of(context).ink)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (session != null) ...[
              const SizedBox(height: 24),
              const Text('Launcher', style: Txt.titleSheet),
              const SizedBox(height: 12),
              Surface(
                color: Tokens.card2,
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Sym(
                      switch (session!.companionStatus) {
                        CompanionStatus.connected => Symbols.check_circle,
                        CompanionStatus.unavailable => Symbols.cloud_off,
                        _ => Symbols.link,
                      },
                      filled: true,
                      color: session!.companionStatus == CompanionStatus.connected ? Tokens.success : Tokens.ink2,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        switch (session!.companionStatus) {
                          CompanionStatus.connected => 'Conectado: apps, íconos y orden del inicio',
                          CompanionStatus.unavailable => 'No encontrado en esta TV',
                          _ => 'Disponible, falta conectar',
                        },
                        style: Txt.bodyS.copyWith(color: Tokens.ink),
                      ),
                    ),
                    if (session!.companionStatus == CompanionStatus.needsPairing ||
                        session!.companionStatus == CompanionStatus.pairing)
                      TextButton(onPressed: () => showCompanionPairing(context, session!), child: const Text('Conectar')),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            const Text('Apariencia', style: Txt.titleSheet),
            const SizedBox(height: 12),
            Row(
              children: [
                for (final a in Accent.all) ...[
                  Expanded(
                    child: Pressable(
                      onTap: () => prefs.setAccent(a.name),
                      size: PressSize.pill,
                      semanticLabel: 'Color ${a.name}',
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        height: 64,
                        decoration: BoxDecoration(
                          color: Tokens.card2,
                          borderRadius: BorderRadius.circular(Radii.tile),
                          border: Border.all(color: prefs.accentName == a.name ? a.light : Colors.transparent, width: 2),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(width: 22, height: 22, decoration: BoxDecoration(shape: BoxShape.circle, gradient: a.gradient)),
                            const SizedBox(width: 8),
                            Text(a.name, style: Txt.label),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (a != Accent.all.last) const SizedBox(width: 10),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Surface(
              color: Tokens.card2,
              child: SwitchListTile(
                value: prefs.haptics,
                onChanged: prefs.setHaptics,
                title: const Text('Vibración al tocar', style: Txt.titleRow),
                subtitle: const Text('Respuesta háptica en botones y gestos', style: Txt.bodyS),
                activeThumbColor: AccentScope.of(context).light,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmForget(BuildContext context, DeviceStore devices, SavedTv tv) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Tokens.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.hero)),
        title: const Text('¿Olvidar esta TV?', style: Txt.titleSheet),
        content: Text('${tv.name} se quitará del iPhone. Para volver a usarla tendrás que emparejar de nuevo.', style: Txt.body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Olvidar', style: TextStyle(color: Tokens.danger)),
          ),
        ],
      ),
    );
    if (ok == true) {
      playHaptic(Haptic.medium);
      await devices.remove(tv.id);
    }
  }
}

class _TvRow extends StatelessWidget {
  const _TvRow({required this.tv, required this.selected, required this.onTap, required this.onForget});
  final SavedTv tv;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onForget;

  @override
  Widget build(BuildContext context) {
    final a = AccentScope.of(context);
    return Pressable(
      onTap: onTap,
      onLongPress: onForget,
      size: PressSize.row,
      semanticLabel: tv.name,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(color: selected ? a.tint : Tokens.card3, borderRadius: BorderRadius.circular(10)),
              child: Center(child: Sym(Symbols.tv, size: 20, color: selected ? a.ink : Tokens.ink2)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tv.name, style: Txt.titleRow),
                  Text(tv.host, style: Txt.bodyS),
                ],
              ),
            ),
            if (selected) Sym(Symbols.check, color: a.ink),
            IconCircle(icon: Symbols.delete, label: 'Olvidar ${tv.name}', size: 44, color: Colors.transparent, iconColor: Tokens.ink3, onTap: onForget),
          ],
        ),
      ),
    );
  }
}
