import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../services/tv_session.dart';
import '../../theme/theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/common.dart';
import '../../widgets/controls.dart';
import '../../widgets/pressable.dart';
import '../../widgets/toast.dart';
import 'companion_pairing.dart';

/// The TV's apps with their real icons (through the launcher) to open, pin
/// and reorder the launcher home.
class AppsPage extends StatefulWidget {
  const AppsPage({super.key, required this.session});
  final TvSession session;

  @override
  State<AppsPage> createState() => _AppsPageState();
}

class _AppsPageState extends State<AppsPage> {
  int _mode = 0; // 0 open, 1 arrange
  String _query = '';
  String? _fresh;

  TvSession get s => widget.session;
  bool get _companion => s.companionStatus == CompanionStatus.connected;

  Future<void> _open(RemoteApp app) async {
    final toast = ToastHost.maybeOf(context);
    final ok = await s.launch(app);
    toast?.show(ok ? 'Abriendo ${app.label} en la TV' : 'La TV no está conectada', kind: ok ? ToastKind.success : ToastKind.error);
  }

  Future<void> _pin(RemoteApp app) async {
    setState(() => _fresh = app.package);
    await s.pin(app.package);
    if (!mounted) return;
    ToastHost.maybeOf(context)?.show('${app.label} fijada en el inicio de la TV');
  }

  @override
  Widget build(BuildContext context) {
    final pinned = s.pinnedApps;
    final pinnedSet = pinned.map((a) => a.package).toSet();
    final others = s.apps
        .where((a) => !pinnedSet.contains(a.package))
        .where((a) => _query.isEmpty || a.label.toLowerCase().contains(_query.toLowerCase()))
        .toList()
      ..sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));

    return ListView(
      padding: const EdgeInsets.fromLTRB(Space.gutter, 8, Space.gutter, 120),
      children: [
        if (!_companion) ...[
          RiseIn(index: 0, child: CompanionBanner(session: s)),
          const SizedBox(height: 16),
        ],
        if (_companion) ...[
          RiseIn(
            index: 0,
            child: Segmented(
              labels: const ['Abrir', 'Ordenar launcher'],
              index: _mode,
              onChanged: (i) => setState(() => _mode = i),
            ),
          ),
          const SizedBox(height: 22),
        ],
        RiseIn(
          index: 1,
          child: Row(
            children: [
              const Expanded(child: Eyebrow('En el launcher')),
              Text(_mode == 1 ? 'Arrastra para reordenar' : '${pinned.length} apps', style: Txt.bodyS),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (_mode == 1 && _companion)
          RiseIn(index: 2, child: _ReorderList(session: s))
        else
          RiseIn(
            index: 2,
            child: GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.0,
              children: [
                for (final app in pinned)
                  _AppTile(
                    key: ValueKey(app.package),
                    session: s,
                    app: app,
                    fresh: app.package == _fresh,
                    onTap: () => _open(app),
                    onLongPress: _companion ? () => _options(app, pinned: true) : null,
                  ),
              ],
            ),
          ),
        const SizedBox(height: 24),
        RiseIn(index: 3, child: Eyebrow(_companion ? 'Otras apps instaladas' : 'Apps populares')),
        const SizedBox(height: 12),
        RiseIn(
          index: 4,
          child: TextField(
            onChanged: (v) => setState(() => _query = v),
            style: Txt.titleRow,
            decoration: InputDecoration(
              hintText: 'Buscar app',
              hintStyle: Txt.body.copyWith(color: Tokens.ink3),
              prefixIcon: const Padding(padding: EdgeInsets.only(left: 14, right: 8), child: Sym(Symbols.search, color: Tokens.ink2)),
              prefixIconConstraints: const BoxConstraints(minWidth: 44),
              filled: true,
              fillColor: Tokens.card,
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(26), borderSide: BorderSide.none),
            ),
          ),
        ),
        const SizedBox(height: 12),
        RiseIn(
          index: 5,
          child: Surface(
            child: Column(
              children: [
                for (final (i, app) in others.indexed) ...[
                  if (i > 0) const Divider(height: 1, color: Tokens.line, indent: 64),
                  _AppRow(
                    session: s,
                    app: app,
                    onTap: () => _open(app),
                    onPin: _companion ? () => _pin(app) : null,
                  ),
                ],
                if (others.isEmpty)
                  const Padding(padding: EdgeInsets.all(20), child: Text('No hay más apps.', style: Txt.bodyS)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _options(RemoteApp app, {required bool pinned}) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Tokens.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: Tokens.line, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              Text(app.label, style: Txt.titleSheet),
              const SizedBox(height: 12),
              _SheetRow(icon: Symbols.play_arrow, label: 'Abrir en la TV', onTap: () => Navigator.pop(context, 'open')),
              if (pinned)
                _SheetRow(icon: Symbols.keep_off, label: 'Quitar del inicio', onTap: () => Navigator.pop(context, 'unpin'))
              else
                _SheetRow(icon: Symbols.keep, label: 'Fijar en el inicio', onTap: () => Navigator.pop(context, 'pin')),
            ],
          ),
        ),
      ),
    );
    switch (action) {
      case 'open':
        await _open(app);
      case 'unpin':
        await s.unpin(app.package);
      case 'pin':
        await _pin(app);
    }
  }
}

class _SheetRow extends StatelessWidget {
  const _SheetRow({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Pressable(
        onTap: onTap,
        size: PressSize.row,
        semanticLabel: label,
        child: SizedBox(
          height: 56,
          child: Row(children: [Sym(icon), const SizedBox(width: 14), Text(label, style: Txt.titleRow)]),
        ),
      );
}

class _AppTile extends StatelessWidget {
  const _AppTile({super.key, required this.session, required this.app, required this.onTap, this.onLongPress, this.fresh = false});
  final TvSession session;
  final RemoteApp app;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool fresh;

  @override
  Widget build(BuildContext context) {
    final tile = Pressable(
      onTap: onTap,
      onLongPress: onLongPress,
      size: PressSize.big,
      haptic: Haptic.light,
      semanticLabel: 'Abrir ${app.label}',
      child: Surface(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FutureBuilder(
              future: session.icon(app.package),
              initialData: session.cachedIcon(app.package),
              builder: (context, snap) => AppIcon(label: app.label, png: snap.data, size: 48),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(app.label, style: Txt.label.copyWith(fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
    if (!fresh) return tile;
    // Just pinned: rise in with a green wash (truME "just logged").
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1600),
      curve: Motion.standard,
      builder: (context, t, c) => Transform.translate(
        offset: Offset(0, 10 * (1 - (t * 4).clamp(0.0, 1.0))),
        child: DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            color: Tokens.success.withValues(alpha: 0.28 * (1 - t)),
            borderRadius: BorderRadius.circular(Radii.card),
          ),
          child: c,
        ),
      ),
      child: tile,
    );
  }
}

class _AppRow extends StatelessWidget {
  const _AppRow({required this.session, required this.app, required this.onTap, this.onPin});
  final TvSession session;
  final RemoteApp app;
  final VoidCallback onTap;
  final VoidCallback? onPin;

  @override
  Widget build(BuildContext context) {
    final a = AccentScope.of(context);
    return Pressable(
      onTap: onTap,
      size: PressSize.row,
      semanticLabel: 'Abrir ${app.label}',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
        child: Row(
          children: [
            FutureBuilder(
              future: session.icon(app.package),
              initialData: session.cachedIcon(app.package),
              builder: (context, snap) => AppIcon(label: app.label, png: snap.data, size: 38, radius: 12),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(app.label, style: Txt.titleRow, maxLines: 1, overflow: TextOverflow.ellipsis)),
            if (onPin != null)
              IconCircle(icon: Symbols.add, label: 'Fijar ${app.label}', size: 44, color: a.tint, iconColor: a.ink, onTap: onPin),
          ],
        ),
      ),
    );
  }
}

class _ReorderList extends StatelessWidget {
  const _ReorderList({required this.session});
  final TvSession session;

  @override
  Widget build(BuildContext context) {
    final pinned = session.pinnedApps;
    return Surface(
      child: ReorderableListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        buildDefaultDragHandles: false,
        itemCount: pinned.length,
        onReorderStart: (_) => playHaptic(Haptic.medium),
        onReorderItem: (from, to) {
          playHaptic(Haptic.selection);
          session.reorder(from, to);
        },
        proxyDecorator: (child, i, anim) => Material(
          color: Colors.transparent,
          child: ScaleTransition(scale: Tween(begin: 1.0, end: 1.03).animate(anim), child: child),
        ),
        itemBuilder: (context, i) {
          final app = pinned[i];
          return ReorderableDelayedDragStartListener(
            key: ValueKey(app.package),
            index: i,
            child: Container(
              color: Tokens.card,
              padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
              child: Row(
                children: [
                  Text('${i + 1}', style: Txt.figure.copyWith(color: Tokens.ink3)),
                  const SizedBox(width: 12),
                  FutureBuilder(
                    future: session.icon(app.package),
                    initialData: session.cachedIcon(app.package),
                    builder: (context, snap) => AppIcon(label: app.label, png: snap.data, size: 38, radius: 12),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(app.label, style: Txt.titleRow)),
                  IconCircle(
                    icon: Symbols.remove,
                    label: 'Quitar ${app.label} del inicio',
                    size: 44,
                    color: Colors.transparent,
                    iconColor: Tokens.ink2,
                    onTap: () => session.unpin(app.package),
                  ),
                  ReorderableDragStartListener(
                    index: i,
                    child: const SizedBox(width: 44, height: 44, child: Center(child: Sym(Symbols.drag_indicator, color: Tokens.ink3))),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

