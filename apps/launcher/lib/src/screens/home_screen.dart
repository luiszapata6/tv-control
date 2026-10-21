import 'dart:async';

import 'package:companion_protocol/companion_protocol.dart';
import 'package:flutter/material.dart';

import '../format.dart';
import '../home_controller.dart';
import '../theme.dart';
import '../widgets/app_tile.dart';
import '../widgets/focus_tile.dart';
import '../widgets/hints.dart';
import 'all_apps_screen.dart';
import 'app_options.dart';
import 'pairing_overlay.dart';
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

  /// The focused app's colour for the ambient glow (null: quiet indigo).
  Color? _glow;
  String? _glowOwner;

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

  Future<void> _onAppFocus(String package, bool focused) async {
    if (!focused) {
      if (_glowOwner == package) setState(() => _glow = _glowOwner = null);
      return;
    }
    _glowOwner = package;
    final tint = await c.tint(package);
    if (mounted && _glowOwner == package) setState(() => _glow = tint ?? Palette.indigo);
  }

  Future<void> _openAllApps() =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => AllAppsScreen(controller: c)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palette.homeBg,
      body: ListenableBuilder(
        listenable: c,
        builder: (context, _) {
          final multiRow = c.pinned.length > c.layout.columns;
          return Stack(
            children: [
              Positioned.fill(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  curve: Motion.standard,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0.56, -1.36),
                      radius: 1.45,
                      colors: [(_glow ?? Palette.indigo).withValues(alpha: _glow == null ? 0.08 : 0.2), const Color(0x0008090D)],
                      stops: const [0, 0.7],
                    ),
                  ),
                ),
              ),
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(-1, -1.4),
                      radius: 1.35,
                      colors: [Color(0x1A6C6CF2), Color(0x006C6CF2)],
                      stops: [0, 0.65],
                    ),
                  ),
                ),
              ),
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x0008090D), Color(0xB3040508)],
                      stops: [0.55, 1],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 30, 0, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 48),
                      child: _Header(now: _now, controller: c, compact: multiRow, onSettings: () => showSettingsPanel(context, c)),
                    ),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, box) => SingleChildScrollView(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(minHeight: box.maxHeight),
                            child: Padding(
                              // Room for the focused card's scale and halo.
                              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 14),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _SectionTitle('Tus apps', trailing: '${c.pinned.length} de 12'),
                                  const SizedBox(height: 13),
                                  _PinnedGrid(controller: c, onAppFocus: _onAppFocus),
                                  SizedBox(height: multiRow ? 14 : 22),
                                  const _SectionTitle('Entradas'),
                                  const SizedBox(height: 13),
                                  _InputsRow(controller: c, onAllApps: _openAllApps),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(padding: const EdgeInsets.symmetric(horizontal: 48), child: _Footer(controller: c)),
                  ],
                ),
              ),
              if (c.pairingCode != null) PairingOverlay(code: c.pairingCode!, client: c.pairingClient),
            ],
          );
        },
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text, {this.trailing});
  final String text;
  final String? trailing;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(text, style: Txt.section),
          if (trailing != null) ...[
            const SizedBox(width: 7),
            Text(trailing!, style: Txt.hint.copyWith(color: Palette.ink4)),
          ],
        ],
      );
}

class _Header extends StatelessWidget {
  const _Header({required this.now, required this.controller, required this.compact, required this.onSettings});
  final DateTime now;
  final HomeController controller;

  /// Several rows of apps: a smaller clock leaves them room.
  final bool compact;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final w = controller.weather;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(greetingFor(now), style: Txt.eyebrow.copyWith(color: Palette.amber, fontWeight: FontWeight.w700, letterSpacing: 2.6)),
            const SizedBox(height: 5),
            Transform.translate(
              offset: const Offset(-4, 0),
              child: Text(formatTime(now), style: Txt.clock.copyWith(fontSize: compact ? 68 : 78)),
            ),
            const SizedBox(height: 5),
            Text(formatDate(now), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Palette.ink2)),
          ],
        ),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Row(
            children: [
              if (w != null) ...[
                Icon(w.icon, color: Palette.amber, size: 24),
                const SizedBox(width: 11),
                Text(w.temperatureLabel, style: Txt.temp),
                const SizedBox(width: 11),
                Container(
                  padding: const EdgeInsets.only(left: 11),
                  decoration: const BoxDecoration(border: Border(left: BorderSide(color: Color(0x1AFFFFFF)))),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(controller.place.name, style: const TextStyle(fontSize: 13, height: 1.15, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(w.label, style: Txt.sub.copyWith(height: 1.15)),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
              ],
              SizedBox.square(
                dimension: 38,
                child: FocusTile(
                  radius: 19,
                  focusedScale: 1.08,
                  restColor: const Color(0x12FFFFFF),
                  onSelect: onSettings,
                  semanticLabel: 'Ajustes',
                  builder: (context, f) => Center(child: Icon(Icons.tune_rounded, size: 17, color: f ? Palette.bg : Palette.inkSoft)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PinnedGrid extends StatelessWidget {
  const _PinnedGrid({required this.controller, required this.onAppFocus});
  final HomeController controller;
  final void Function(String package, bool focused) onAppFocus;

  @override
  Widget build(BuildContext context) {
    final apps = controller.pinned;
    final columns = controller.layout.columns;
    if (controller.loading) return const SizedBox(height: 120);
    if (apps.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Text('Fija apps desde "Todas las apps" o desde el iPhone.', style: TextStyle(fontSize: 15, color: Palette.ink2)),
      );
    }
    return FocusTraversalGroup(
      child: LayoutBuilder(
        builder: (context, box) {
          const gap = 16.0;
          final width = (box.maxWidth - gap * (columns - 1)) / columns;
          return Wrap(
            spacing: gap,
            runSpacing: 0,
            children: [
              for (final (i, app) in apps.indexed)
                SizedBox(
                  width: width,
                  child: AppTile(
                    key: ValueKey(app.package),
                    app: app,
                    autofocus: i == 0,
                    loadIcon: controller.icon,
                    loadTint: controller.tint,
                    onFocusChange: (f) => onAppFocus(app.package, f),
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
    final hdmi = controller.inputs.where((i) => i.kind == InputKind.hdmi).take(4);
    return FocusTraversalGroup(
      child: Row(
        children: [
          for (final input in hdmi) ...[
            Expanded(child: _InputCard(icon: Icons.settings_input_hdmi_rounded, label: input.label, onSelect: () => controller.openInput(input))),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: _InputCard(
              icon: Icons.apps_rounded,
              iconColor: Palette.indigoLight,
              label: 'Todas las apps',
              sub: '${controller.visibleApps.length} instaladas',
              onSelect: onAllApps,
            ),
          ),
        ],
      ),
    );
  }
}

class _InputCard extends StatelessWidget {
  const _InputCard({required this.icon, required this.label, required this.onSelect, this.sub, this.iconColor = Palette.inkSoft});
  final IconData icon;
  final Color iconColor;
  final String label;
  final String? sub;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: FocusTile(
        radius: 8,
        restColor: Palette.surface1,
        onSelect: onSelect,
        semanticLabel: label,
        builder: (context, f) => DecoratedBox(
          decoration: BoxDecoration(
            gradient: f ? null : const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF171924), Palette.surface1]),
            border: f ? null : const Border(top: BorderSide(color: Color(0x12FFFFFF), width: 0.5)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Icon(icon, size: 18, color: f ? Palette.bg : iconColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: Txt.body.copyWith(height: 1.1, color: f ? Palette.bg : Palette.ink)),
                      if (sub != null)
                        Text(sub!, maxLines: 1, overflow: TextOverflow.ellipsis, style: Txt.sub.copyWith(height: 1.2, color: f ? Palette.inkOnFill : null)),
                    ],
                  ),
                ),
              ],
            ),
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
    final connected = clients.isNotEmpty;
    return SizedBox(
      height: 22,
      child: Row(
        children: [
          Icon(Icons.phone_iphone_rounded, size: 15, color: connected ? Palette.ink2 : Palette.ink4),
          const SizedBox(width: 8),
          Flexible(
            child: Text(connected ? clients.join(', ') : 'Sin iPhone conectado',
                maxLines: 1, overflow: TextOverflow.ellipsis, style: Txt.hint.copyWith(color: connected ? Palette.ink2 : Palette.ink4)),
          ),
          if (connected) ...[
            const SizedBox(width: 8),
            Container(
              height: 20,
              padding: const EdgeInsets.fromLTRB(7, 0, 8, 0),
              decoration: BoxDecoration(color: const Color(0x1F4ADE80), borderRadius: BorderRadius.circular(10)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Palette.green,
                      boxShadow: [BoxShadow(color: Color(0xB34ADE80), blurRadius: 5)],
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text('Conectado', style: Txt.hint.copyWith(fontWeight: FontWeight.w700, color: Palette.green)),
                ],
              ),
            ),
          ],
          const Spacer(),
          const KeyHints([KeyHint('OK', 'Abrir'), KeyHint('OK', 'Opciones', before: 'Mantén')]),
        ],
      ),
    );
  }
}
