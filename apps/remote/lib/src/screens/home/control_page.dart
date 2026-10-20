import 'package:atv_remote/atv_remote.dart';
import 'package:companion_protocol/companion_protocol.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../services/tv_session.dart';
import '../../theme/theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/common.dart';
import '../../widgets/controls.dart';
import '../../widgets/pressable.dart';
import '../../widgets/toast.dart';
import '../onboarding/pair_screen.dart';

/// Main remote: what is playing, favourite apps, D-pad, back/home/menu and volume.
class ControlPage extends StatelessWidget {
  const ControlPage({super.key, required this.session});
  final TvSession session;

  void _press(BuildContext context, AtvKey key) {
    if (!session.press(key)) _notConnected(context);
  }

  static void _notConnected(BuildContext context) =>
      ToastHost.maybeOf(context)?.show('La TV no está conectada', kind: ToastKind.error);

  @override
  Widget build(BuildContext context) {
    final vol = session.volume;
    return LayoutBuilder(
      builder: (context, box) {
        final dpad = (box.maxWidth - 2 * Space.gutter).clamp(220.0, 280.0);
        return ListView(
          padding: const EdgeInsets.fromLTRB(Space.gutter, 8, Space.gutter, 120),
          children: [
            if (session.needsPairing) ...[
              _RepairBanner(session: session),
              const SizedBox(height: 16),
            ],
            RiseIn(index: 0, child: _NowPlayingCard(session: session)),
            const SizedBox(height: 16),
            RiseIn(index: 1, child: _Favourites(session: session)),
            const SizedBox(height: 22),
            RiseIn(
              index: 2,
              child: Center(
                child: DPad(
                  size: dpad,
                  onUp: () => _press(context, AtvKey.up),
                  onDown: () => _press(context, AtvKey.down),
                  onLeft: () => _press(context, AtvKey.left),
                  onRight: () => _press(context, AtvKey.right),
                  onOk: () => _press(context, AtvKey.center),
                  onOkLongStart: () => session.pressLong(AtvKey.center, start: true),
                  onOkLongEnd: () => session.pressLong(AtvKey.center, start: false),
                ),
              ),
            ),
            const SizedBox(height: 20),
            RiseIn(
              index: 3,
              child: Row(
                children: [
                  _NavButton(icon: Symbols.arrow_back, label: 'Atrás', onTap: () => _press(context, AtvKey.back)),
                  const SizedBox(width: Space.stack),
                  _NavButton(icon: Symbols.home, label: 'Inicio', onTap: () => _press(context, AtvKey.home)),
                  const SizedBox(width: Space.stack),
                  _NavButton(icon: Symbols.menu, label: 'Menú', onTap: () => _press(context, AtvKey.menu)),
                ],
              ),
            ),
            const SizedBox(height: 22),
            RiseIn(
              index: 4,
              child: Row(
                children: [
                  Expanded(
                    child: VolumeSlider(
                      value: session.displayVolume,
                      max: session.volumeMax,
                      muted: vol?.muted ?? false,
                      onChanged: session.setVolume,
                    ),
                  ),
                  const SizedBox(width: 10),
                  _MuteButton(session: session),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _RepairBanner extends StatelessWidget {
  const _RepairBanner({required this.session});
  final TvSession session;

  @override
  Widget build(BuildContext context) => Surface(
        padding: const EdgeInsets.all(Space.inset),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Sym(Symbols.link_off, color: Tokens.danger),
                SizedBox(width: 10),
                Expanded(child: Text('La TV ya no reconoce este iPhone', style: Txt.titleBar)),
              ],
            ),
            const SizedBox(height: 6),
            const Text('Pasa si se borraron los datos del control remoto en la TV. Empareja de nuevo.', style: Txt.bodyS),
            const SizedBox(height: 14),
            PrimaryButton(
              label: 'Emparejar de nuevo',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => PairScreen(host: session.tv.host, name: session.tv.name)),
              ),
            ),
          ],
        ),
      );
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Pressable(
          onTap: onTap,
          size: PressSize.pill,
          semanticLabel: label,
          child: Surface(
            radius: Radii.tile,
            child: SizedBox(
              height: 60,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [Sym(icon), const SizedBox(width: 8), Text(label, style: Txt.label)],
              ),
            ),
          ),
        ),
      );
}

class _MuteButton extends StatelessWidget {
  const _MuteButton({required this.session});
  final TvSession session;

  @override
  Widget build(BuildContext context) {
    final a = AccentScope.of(context);
    final muted = session.volume?.muted ?? false;
    return Pressable(
      onTap: () {
        if (!session.toggleMute()) ControlPage._notConnected(context);
      },
      semanticLabel: muted ? 'Quitar silencio' : 'Silenciar',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 60,
        height: 60,
        decoration: BoxDecoration(color: muted ? a.tint : Tokens.card2, shape: BoxShape.circle),
        child: Center(child: Sym(Symbols.volume_off, color: muted ? a.ink : Tokens.ink, filled: muted)),
      ),
    );
  }
}

class _NowPlayingCard extends StatelessWidget {
  const _NowPlayingCard({required this.session});
  final TvSession session;

  @override
  Widget build(BuildContext context) {
    final np = session.nowPlaying;
    final appLabel = session.currentAppLabel;
    final title = np?.title ?? (appLabel.isEmpty ? 'Nada en reproducción' : appLabel);
    final pkg = np?.package ?? session.state.currentApp;
    final playing = np?.state == PlaybackState.playing;
    return Surface(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          FutureBuilder(
            future: pkg == null ? Future.value(null) : session.icon(pkg),
            initialData: pkg == null ? null : session.cachedIcon(pkg),
            builder: (context, snap) => AppIcon(label: appLabel.isEmpty ? 'TV' : appLabel, png: snap.data, size: 44),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Eyebrow(np == null ? 'En la TV' : (playing ? 'Reproduciendo' : 'En pausa')),
                const SizedBox(height: 2),
                Text(title, style: Txt.titleRow.copyWith(fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                if (np?.subtitle != null) Text(np!.subtitle!, style: Txt.bodyS, maxLines: 1, overflow: TextOverflow.ellipsis),
                if (np?.progress != null) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: np!.progress,
                      minHeight: 3,
                      backgroundColor: Tokens.line,
                      color: AccentScope.of(context).light,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconCircle(
            icon: playing ? Symbols.pause : Symbols.play_arrow,
            label: playing ? 'Pausar' : 'Reproducir',
            filled: true,
            size: 44,
            onTap: () {
              if (!session.press(AtvKey.playPause)) ControlPage._notConnected(context);
            },
          ),
        ],
      ),
    );
  }
}

class _Favourites extends StatelessWidget {
  const _Favourites({required this.session});
  final TvSession session;

  @override
  Widget build(BuildContext context) {
    final apps = session.pinnedApps;
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: apps.length,
        separatorBuilder: (_, __) => const SizedBox(width: Space.inline),
        itemBuilder: (context, i) {
          final app = apps[i];
          return Pressable(
            size: PressSize.pill,
            haptic: Haptic.light,
            semanticLabel: 'Abrir ${app.label}',
            onTap: () async {
              final toast = ToastHost.maybeOf(context);
              final ok = await session.launch(app);
              toast?.show(ok ? 'Abriendo ${app.label} en la TV' : 'La TV no está conectada',
                  kind: ok ? ToastKind.success : ToastKind.error);
            },
            child: Container(
              padding: const EdgeInsets.only(left: 8, right: 16),
              decoration: BoxDecoration(
                color: Tokens.card,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Tokens.edge),
              ),
              child: Row(
                children: [
                  FutureBuilder(
                    future: session.icon(app.package),
                    initialData: session.cachedIcon(app.package),
                    builder: (context, snap) => AppIcon(label: app.label, png: snap.data, size: 32, radius: 10),
                  ),
                  const SizedBox(width: 10),
                  Text(app.label, style: Txt.label),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
