import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/tokens.dart';

/// How much a control squeezes when pressed (truME v2 "scale by size").
enum PressSize {
  /// Icon buttons, D-pad arrows, dock items: .92
  small(0.92, Motion.durRelease, Motion.spring),

  /// Pills and chips: .96
  pill(0.96, Motion.durRelease, Motion.spring),

  /// Cards and primary buttons: .98
  big(0.98, Motion.durReleaseBig, Motion.releaseBig),

  /// Rows inside a grouped card: tint only, no scale.
  row(1, Duration(milliseconds: 200), Motion.standard);

  const PressSize(this.scale, this.release, this.releaseCurve);
  final double scale;
  final Duration release;
  final Curve releaseCurve;
}

enum Haptic { none, light, selection, medium }

/// Global switch from Settings.
bool hapticsEnabled = true;

void playHaptic(Haptic h) {
  if (!hapticsEnabled) return;
  switch (h) {
    case Haptic.none:
      return;
    case Haptic.light:
      HapticFeedback.lightImpact();
    case Haptic.selection:
      HapticFeedback.selectionClick();
    case Haptic.medium:
      HapticFeedback.mediumImpact();
  }
}

/// The one widget for everything tappable (truME `Pressable`): press starts
/// on pointer-down, lasts at least 120 ms, releases with a spring, cancels if
/// the finger moves more than 10 pt, and plays a haptic.
///
/// [onRepeat] makes it auto-repeat while held (volume): after 400 ms, then
/// every 120 ms, every 60 ms after 1.5 s.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.onRepeat,
    this.onPressStart,
    this.onPressEnd,
    this.size = PressSize.small,
    this.haptic = Haptic.selection,
    this.semanticLabel,
    this.enabled = true,
    this.dimOnPress = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onRepeat;
  final VoidCallback? onPressStart;
  final VoidCallback? onPressEnd;
  final PressSize size;
  final Haptic haptic;
  final String? semanticLabel;
  final bool enabled;
  final bool dimOnPress;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _pressed = false;
  Offset? _down;
  DateTime? _downAt;
  Timer? _longTimer;
  Timer? _repeatTimer;
  Timer? _releaseTimer;
  bool _longFired = false;
  int _repeats = 0;

  bool get _active => widget.enabled && (widget.onTap != null || widget.onLongPress != null || widget.onRepeat != null);

  @override
  void dispose() {
    _cancelTimers();
    _releaseTimer?.cancel();
    super.dispose();
  }

  void _cancelTimers() {
    _longTimer?.cancel();
    _repeatTimer?.cancel();
    _longTimer = null;
    _repeatTimer = null;
  }

  void _onDown(PointerDownEvent e) {
    if (!_active) return;
    _releaseTimer?.cancel();
    _down = e.position;
    _downAt = DateTime.now();
    _longFired = false;
    _repeats = 0;
    setState(() => _pressed = true);
    widget.onPressStart?.call();
    if (widget.onRepeat != null) {
      _longTimer = Timer(const Duration(milliseconds: 400), _repeat);
    } else if (widget.onLongPress != null) {
      _longTimer = Timer(const Duration(milliseconds: 500), () {
        _longFired = true;
        playHaptic(Haptic.medium);
        widget.onLongPress!();
      });
    }
  }

  void _repeat() {
    if (!mounted || !_pressed) return;
    _longFired = true;
    _repeats++;
    playHaptic(Haptic.selection);
    widget.onRepeat!();
    final held = DateTime.now().difference(_downAt!);
    _repeatTimer = Timer(Duration(milliseconds: held > const Duration(milliseconds: 1500) ? 60 : 120), _repeat);
  }

  void _onMove(PointerMoveEvent e) {
    if (_down != null && (e.position - _down!).distance > 10) _cancel();
  }

  void _cancel() {
    _cancelTimers();
    _down = null;
    _release();
  }

  void _onUp(PointerUpEvent e) {
    if (_down == null) return;
    _cancelTimers();
    _down = null;
    if (!_longFired) {
      playHaptic(widget.haptic);
      (widget.onTap ?? widget.onRepeat)?.call();
    }
    _release();
  }

  void _release() {
    widget.onPressEnd?.call();
    // Keep the press visible for at least 120 ms so quick taps still read.
    final shown = _downAt == null ? Motion.durPressMin : DateTime.now().difference(_downAt!);
    final wait = shown >= Motion.durPressMin ? Duration.zero : Motion.durPressMin - shown;
    _releaseTimer = Timer(wait, () {
      if (mounted) setState(() => _pressed = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final scale = _pressed ? widget.size.scale : 1.0;
    Widget child = AnimatedScale(
      scale: scale,
      duration: _pressed ? Motion.durPress : widget.size.release,
      curve: _pressed ? Motion.press : widget.size.releaseCurve,
      child: widget.child,
    );
    if (widget.dimOnPress) {
      child = TweenAnimationBuilder<double>(
        tween: Tween(end: _pressed ? 0.9 : 1.0),
        duration: _pressed ? Motion.durPress : const Duration(milliseconds: 200),
        curve: Motion.standard,
        builder: (context, b, c) => b >= 0.999
            ? c!
            : ColorFiltered(
                colorFilter: ColorFilter.matrix([b, 0, 0, 0, 0, 0, b, 0, 0, 0, 0, 0, b, 0, 0, 0, 0, 0, 1, 0]),
                child: c,
              ),
        child: child,
      );
    }
    return Semantics(
      button: true,
      enabled: widget.enabled,
      label: widget.semanticLabel,
      onTap: _active ? (widget.onTap ?? widget.onRepeat) : null,
      excludeSemantics: widget.semanticLabel != null,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: _onDown,
        onPointerMove: _onMove,
        onPointerUp: _onUp,
        onPointerCancel: (_) => _cancel(),
        child: Opacity(opacity: widget.enabled ? 1 : 0.4, child: child),
      ),
    );
  }

  /// Number of auto-repeats in the current press (for tests).
  int get repeats => _repeats;
}
