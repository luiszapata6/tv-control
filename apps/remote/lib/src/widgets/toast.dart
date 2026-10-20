import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../theme/theme.dart';
import '../theme/tokens.dart';
import 'common.dart';

enum ToastKind { success, error, info }

/// Toasts above the dock: success is green with a white 18 % disc, error is a
/// card with the icon on its tint (never reads as good news).
class ToastHost extends StatefulWidget {
  const ToastHost({super.key, required this.child});
  final Widget child;

  static ToastHostState of(BuildContext context) => context.findAncestorStateOfType<ToastHostState>()!;

  static ToastHostState? maybeOf(BuildContext context) => context.findAncestorStateOfType<ToastHostState>();

  @override
  State<ToastHost> createState() => ToastHostState();
}

class _ToastData {
  _ToastData(this.message, this.kind, this.key);
  final String message;
  final ToastKind kind;
  final Key key;
}

class ToastHostState extends State<ToastHost> {
  _ToastData? _current;
  Timer? _timer;
  int _n = 0;

  /// Bottom offset: 12 pt above the dock.
  double bottom = 104;

  void show(String message, {ToastKind kind = ToastKind.success, Duration duration = const Duration(milliseconds: 1800)}) {
    _timer?.cancel();
    setState(() => _current = _ToastData(message, kind, ValueKey(_n++)));
    _timer = Timer(duration, () {
      if (mounted) setState(() => _current = null);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = _current;
    return Stack(
      children: [
        widget.child,
        Positioned(
          left: Space.gutter,
          right: Space.gutter,
          bottom: bottom + MediaQuery.paddingOf(context).bottom,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 420),
            switchInCurve: Motion.spring,
            switchOutCurve: Motion.standard,
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween(begin: const Offset(0, 0.4), end: Offset.zero).animate(anim),
                child: child,
              ),
            ),
            child: t == null ? const SizedBox.shrink() : _Toast(key: t.key, data: t),
          ),
        ),
      ],
    );
  }
}

class _Toast extends StatelessWidget {
  const _Toast({super.key, required this.data});
  final _ToastData data;

  @override
  Widget build(BuildContext context) {
    final success = data.kind == ToastKind.success;
    final error = data.kind == ToastKind.error;
    final bg = success ? Tokens.successFill : Tokens.card2;
    final icon = success ? Symbols.check : (error ? Symbols.error : Symbols.info);
    return Semantics(
      liveRegion: true,
      child: Container(
        height: 56,
        padding: const EdgeInsets.only(left: 10, right: 16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(Radii.tile),
          boxShadow: const [BoxShadow(color: Color(0x80000000), blurRadius: 32, offset: Offset(0, 12))],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: success ? const Color(0x2EFFFFFF) : (error ? Tokens.danger.withValues(alpha: 0.16) : Tokens.card3),
              ),
              child: Center(child: Sym(icon, size: 20, color: success ? Colors.white : (error ? Tokens.danger : Tokens.ink))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(data.message, style: Txt.titleRow.copyWith(color: Colors.white), maxLines: 2, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }
}
