import 'dart:async';

import 'package:companion_protocol/companion_protocol.dart';
import 'package:flutter/material.dart';

import '../format.dart';
import '../home_controller.dart';
import '../theme.dart';
import '../widgets/app_tile.dart';
import '../widgets/focus_tile.dart';
import 'all_apps_screen.dart';
import 'app_options.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.controller, this.now});
  final HomeController controller;

  /// Clock override for tests.
  final DateTime Function()? now;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late DateTime _now = (widget.now ?? DateTime.now)();
  Timer? _clock;

  HomeController get c => widget.controller;

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(seconds: 10), (_) {
      final next = (widget.now ?? DateTime.now)();
      if (next.minute != _now.minute) setState(() => _now = next);
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  Future<void> _openAllApps() =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => AllAppsScreen(controller: c)));

  Future<void> _openSettings() =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => SettingsScreen(controller: c)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListenableBuilder(
        listenable: c,
        builder: (context, _) => Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(60, 44, 60, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Header(now: _now, controller: c, onSettings: _openSettings),
                  const SizedBox(height: 40),
                  const _SectionLabel('TUS APPS'),
                  const SizedBox(height: 16),
                  _PinnedGrid(controller: c),
                  const SizedBox(height: 32),
                  const _SectionLabel('ENTRADAS'),
                  const SizedBox(height: 14),
                  _InputsRow(controller: c, onAllApps: _openAllApps),
                  const Spacer(),
                  _Footer(controller: c),
                ],
              ),
            ),
            if (c.pairingCode != null) _PairingOverlay(code: c.pairingCode!, client: c.pairingClient),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.6, color: Palette.ink2),
      );
}

class _Header extends StatelessWidget {
  const _Header({required this.now, required this.controller, required this.onSettings});
  final DateTime now;
  final HomeController controller;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final w = controller.weather;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(greetingFor(now),
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.6, color: Palette.ink2)),
            const SizedBox(height: 4),
            Text(formatTime(now),
                style: const TextStyle(fontSize: 64, height: 1, fontWeight: FontWeight.w300, letterSpacing: -3)),
            const SizedBox(height: 6),
            Text(formatDate(now), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Palette.ink2)),
          ],
        ),
        const SizedBox(width: 24),
        const Spacer(),
        if (w != null)
          Flexible(
            child: Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(color: Palette.card, borderRadius: BorderRadius.circular(26), border: Border.all(color: Palette.line)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(w.icon, color: Palette.warn, size: 26),
                  const SizedBox(width: 10),
                  Text(w.temperatureLabel, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text('${controller.place.name} · ${w.label}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Palette.ink2)),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(width: 12),
        SizedBox(
          width: 52,
          height: 52,
          child: FocusTile(
            borderRadius: 26,
            onSelect: onSettings,
            semanticLabel: 'Ajustes',
            child: const Center(child: Icon(Icons.settings_outlined, size: 22, color: Palette.ink)),
          ),
        ),
      ],
    );
  }
}

class _PinnedGrid extends StatelessWidget {
  const _PinnedGrid({required this.controller});
  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    final apps = controller.pinned;
    final columns = controller.layout.columns;
    if (controller.loading) return const SizedBox(height: 120);
    if (apps.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Text('Fija apps desde "Todas las apps" o desde el iPhone.', style: TextStyle(color: Palette.ink2)),
      );
    }
    return FocusTraversalGroup(
      child: LayoutBuilder(
        builder: (context, box) {
          const gap = 18.0;
          final width = (box.maxWidth - gap * (columns - 1)) / columns;
          return Wrap(
            spacing: gap,
            runSpacing: 16,
            children: [
              for (final (i, app) in apps.indexed)
                SizedBox(
                  width: width,
                  child: AppTile(
                    key: ValueKey(app.package),
                    app: app,
                    autofocus: i == 0,
                    loadIcon: controller.icon,
                    onSelect: () => controller.launch(app),
                    onLongPress: () => showAppOptions(context, controller, app),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _InputsRow extends StatelessWidget {
  const _InputsRow({required this.controller, required this.onAllApps});
  final HomeController controller;
  final VoidCallback onAllApps;

  @override
  Widget build(BuildContext context) {
    return FocusTraversalGroup(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        child: Row(
        children: [
          for (final input in controller.inputs.where((i) => i.kind == InputKind.hdmi).take(4)) ...[
            _PillButton(icon: Icons.settings_input_hdmi, label: input.label, onSelect: () => controller.openInput(input)),
            const SizedBox(width: 12),
          ],
          _PillButton(icon: Icons.apps_rounded, label: 'Todas las apps', onSelect: onAllApps, dashed: true),
        ],
        ),
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({required this.icon, required this.label, required this.onSelect, this.dashed = false});
  final IconData icon;
  final String label;
  final VoidCallback onSelect;
  final bool dashed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: FocusTile(
        borderRadius: 23,
        focusedScale: 1.06,
        onSelect: onSelect,
        semanticLabel: label,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: dashed ? Palette.ink2 : Palette.ink),
              const SizedBox(width: 8),
              Flexible(
                child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.controller});
  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    final clients = controller.companionClients;
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: clients.isEmpty ? Palette.ink3 : Palette.success),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            clients.isEmpty ? 'Sin iPhone conectado' : '${clients.join(', ')} conectado',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Palette.ink2),
          ),
        ),
        const Flexible(
          child: Text('Mantén OK sobre una app para más opciones',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Palette.ink3)),
        ),
      ],
    );
  }
}

class _PairingOverlay extends StatelessWidget {
  const _PairingOverlay({required this.code, required this.client});
  final String code;
  final String? client;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: const Color(0xCC05070C),
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.92, end: 1),
            duration: Motion.entry,
            curve: Motion.spring,
            builder: (context, s, child) => Transform.scale(scale: s, child: child),
            child: Container(
              width: 440,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Palette.card,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Palette.line),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.phone_iphone, color: Palette.accent, size: 36),
                  const SizedBox(height: 14),
                  Text('${client ?? 'Un iPhone'} quiere conectarse',
                      textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  const Text('Escribe este código en la app', style: TextStyle(fontSize: 13, color: Palette.ink2)),
                  const SizedBox(height: 22),
                  Text(code,
                      style: const TextStyle(fontSize: 52, fontWeight: FontWeight.w800, letterSpacing: 10, fontFeatures: [FontFeature.tabularFigures()])),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
