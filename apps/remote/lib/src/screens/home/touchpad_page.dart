import 'package:atv_remote/atv_remote.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../services/tv_session.dart';
import '../../theme/theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/common.dart';
import '../../widgets/controls.dart';
import '../../widgets/pressable.dart';

/// Swipe to move (one step every [stepDistance] pt, repeated while dragging),
/// tap for OK, hold for a long OK, two fingers up/down for volume.
class TouchpadPage extends StatefulWidget {
  const TouchpadPage({super.key, required this.session});
  final TvSession session;

  static const stepDistance = 44.0;

  @override
  State<TouchpadPage> createState() => _TouchpadPageState();
}

class _TouchpadPageState extends State<TouchpadPage> {
  Offset? _anchor;
  Offset? _touch;
  String? _gesture;
  IconData _gestureIcon = Symbols.touch_app;
  int _gestureId = 0;
  bool _longActive = false;
  double _twoFingerAnchor = 0;

  TvSession get s => widget.session;

  void _show(String label, IconData icon) {
    setState(() {
      _gesture = label;
      _gestureIcon = icon;
      _gestureId++;
    });
    final id = _gestureId;
    Future<void>.delayed(const Duration(milliseconds: 900), () {
      if (mounted && id == _gestureId) setState(() => _gesture = null);
    });
  }

  void _step(AtvKey key, String label, IconData icon) {
    s.press(key);
    playHaptic(Haptic.selection);
    _show(label, icon);
  }

  void _onScaleStart(ScaleStartDetails d) {
    _anchor = d.localFocalPoint;
    _twoFingerAnchor = d.localFocalPoint.dy;
    setState(() => _touch = d.localFocalPoint);
  }

  void _onScaleUpdate(ScaleUpdateDetails d) {
    final anchor = _anchor;
    if (anchor == null) return;
    if (d.pointerCount >= 2) {
      final dy = d.localFocalPoint.dy - _twoFingerAnchor;
      if (dy.abs() >= 24) {
        _twoFingerAnchor = d.localFocalPoint.dy;
        _step(dy < 0 ? AtvKey.volumeUp : AtvKey.volumeDown, dy < 0 ? 'Volumen +' : 'Volumen −',
            dy < 0 ? Symbols.volume_up : Symbols.volume_down);
      }
      return;
    }
    final delta = d.localFocalPoint - anchor;
    if (delta.distance < TouchpadPage.stepDistance) return;
    _anchor = d.localFocalPoint;
    if (delta.dx.abs() > delta.dy.abs()) {
      delta.dx > 0
          ? _step(AtvKey.right, 'Derecha', Symbols.arrow_forward)
          : _step(AtvKey.left, 'Izquierda', Symbols.arrow_back);
    } else {
      delta.dy > 0
          ? _step(AtvKey.down, 'Abajo', Symbols.arrow_downward)
          : _step(AtvKey.up, 'Arriba', Symbols.arrow_upward);
    }
  }

  void _onScaleEnd(ScaleEndDetails d) {
    _anchor = null;
    setState(() => _touch = null);
  }

  @override
  Widget build(BuildContext context) {
    final a = AccentScope.of(context);
    final playing = s.nowPlaying?.state.name == 'playing';
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.gutter, 8, Space.gutter, 108),
      child: Column(
        children: [
          Expanded(
            child: RiseIn(
              index: 0,
              child: Semantics(
                label: 'Área táctil: desliza para moverte, toca para OK, mantén para menú',
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onScaleStart: _onScaleStart,
                  onScaleUpdate: _onScaleUpdate,
                  onScaleEnd: _onScaleEnd,
                  onTap: () => _step(AtvKey.center, 'OK', Symbols.radio_button_checked),
                  onLongPressStart: (_) {
                    _longActive = s.pressLong(AtvKey.center, start: true);
                    playHaptic(Haptic.medium);
                    _show('OK largo', Symbols.touch_app);
                  },
                  onLongPressEnd: (_) {
                    if (_longActive) s.pressLong(AtvKey.center, start: false);
                    _longActive = false;
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Tokens.card,
                      borderRadius: BorderRadius.circular(Radii.hero),
                      border: Border.all(color: Tokens.edge),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        const Positioned.fill(child: CustomPaint(painter: _DotGrid())),
                        if (_touch != null)
                          Positioned(
                            left: _touch!.dx - 42,
                            top: _touch!.dy - 42,
                            child: Container(
                              width: 84,
                              height: 84,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: a.tint,
                                border: Border.all(color: a.light, width: 2),
                              ),
                            ),
                          ),
                        Positioned(
                          top: 18,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 260),
                              switchInCurve: Motion.spring,
                              transitionBuilder: (c, an) => ScaleTransition(scale: Tween(begin: 0.9, end: 1.0).animate(an), child: FadeTransition(opacity: an, child: c)),
                              child: _gesture == null
                                  ? const SizedBox.shrink()
                                  : Container(
                                      key: ValueKey(_gestureId),
                                      height: 36,
                                      padding: const EdgeInsets.symmetric(horizontal: 14),
                                      decoration: BoxDecoration(color: a.tint, borderRadius: BorderRadius.circular(18)),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Sym(_gestureIcon, size: 18, color: a.ink, filled: true),
                                          const SizedBox(width: 6),
                                          Text(_gesture!, style: Txt.label.copyWith(color: a.ink, fontWeight: FontWeight.w800)),
                                        ],
                                      ),
                                    ),
                            ),
                          ),
                        ),
                        const Positioned(
                          left: 0,
                          right: 0,
                          bottom: 22,
                          child: Column(
                            children: [
                              Eyebrow('Desliza · Toca · Mantén'),
                              SizedBox(height: 4),
                              Text('Dos dedos arriba o abajo para el volumen', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Tokens.ink3)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          RiseIn(
            index: 1,
            child: Row(
              children: [
                _Quick(icon: Symbols.arrow_back, label: 'Atrás', onTap: () => s.press(AtvKey.back)),
                const SizedBox(width: Space.stack),
                _Quick(icon: Symbols.home, label: 'Inicio', onTap: () => s.press(AtvKey.home)),
                const SizedBox(width: Space.stack),
                _Quick(
                  icon: playing ? Symbols.pause : Symbols.play_arrow,
                  label: playing ? 'Pausa' : 'Play',
                  onTap: () => s.press(AtvKey.playPause),
                ),
              ],
            ),
          ),
          const SizedBox(height: Space.stack),
          RiseIn(
            index: 2,
            child: VolumeSlider(
              value: s.displayVolume,
              max: s.volumeMax,
              muted: s.volume?.muted ?? false,
              onChanged: s.setVolume,
            ),
          ),
        ],
      ),
    );
  }
}

class _Quick extends StatelessWidget {
  const _Quick({required this.icon, required this.label, required this.onTap});
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
              height: 56,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [Sym(icon, filled: true), const SizedBox(width: 8), Text(label, style: Txt.label)],
              ),
            ),
          ),
        ),
      );
}

class _DotGrid extends CustomPainter {
  const _DotGrid();

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = const Color(0x12FFFFFF);
    for (var y = 11.0; y < size.height; y += 22) {
      for (var x = 11.0; x < size.width; x += 22) {
        canvas.drawCircle(Offset(x, y), 1, p);
      }
    }
  }

  @override
  bool shouldRepaint(_DotGrid oldDelegate) => false;
}
