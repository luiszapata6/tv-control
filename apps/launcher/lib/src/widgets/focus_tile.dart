import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';

/// How focus shows: [card] for images (scale, white ring, indigo halo,
/// sheen), [fill] for rows and buttons (light inverted fill).
enum FocusLook { card, fill }

/// A D-pad focusable element: focus is the only thing that glows. Presses in
/// on select and reports long presses (hold OK / menu key).
class FocusTile extends StatefulWidget {
  const FocusTile({
    super.key,
    required this.builder,
    required this.onSelect,
    this.look = FocusLook.fill,
    this.onLongPress,
    this.onKey,
    this.autofocus = false,
    this.focusNode,
    this.radius = 10,
    this.focusedScale,
    this.restColor = const Color(0x0DFFFFFF),
    this.restBorder,
    this.onFocusChange,
    this.semanticLabel,
  });

  /// Builds the content; [focused] lets it invert its colours on [FocusLook.fill].
  final Widget Function(BuildContext context, bool focused) builder;
  final VoidCallback onSelect;
  final FocusLook look;
  final VoidCallback? onLongPress;

  /// Extra keys (e.g. left/right to change a value); return true if handled.
  final bool Function(LogicalKeyboardKey key)? onKey;
  final bool autofocus;
  final FocusNode? focusNode;
  final double radius;
  final double? focusedScale;
  final Color restColor;
  final Color? restBorder;
  final ValueChanged<bool>? onFocusChange;
  final String? semanticLabel;

  @override
  State<FocusTile> createState() => _FocusTileState();
}

class _FocusTileState extends State<FocusTile> {
  bool _focused = false;
  bool _pressed = false;
  DateTime? _downAt;

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    final key = event.logicalKey;
    final isSelect = key == LogicalKeyboardKey.select ||
        key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter ||
        key == LogicalKeyboardKey.gameButtonA;
    if (key == LogicalKeyboardKey.contextMenu && event is KeyDownEvent) {
      widget.onLongPress?.call();
      return widget.onLongPress == null ? KeyEventResult.ignored : KeyEventResult.handled;
    }
    if (!isSelect) {
      if (event is! KeyUpEvent && (widget.onKey?.call(key) ?? false)) return KeyEventResult.handled;
      return KeyEventResult.ignored;
    }
    if (event is KeyDownEvent) {
      _downAt = DateTime.now();
      setState(() => _pressed = true);
    } else if (event is KeyRepeatEvent) {
      // Holding OK: treat as a long press once.
      if (_downAt != null && widget.onLongPress != null &&
          DateTime.now().difference(_downAt!) > const Duration(milliseconds: 500)) {
        _downAt = null;
        setState(() => _pressed = false);
        widget.onLongPress!();
      }
    } else if (event is KeyUpEvent) {
      setState(() => _pressed = false);
      if (_downAt != null) {
        _downAt = null;
        widget.onSelect();
      }
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final card = widget.look == FocusLook.card;
    final lit = _focused || _pressed;
    final focusScale = widget.focusedScale ?? (card ? 1.10 : 1.03);
    final scale = _pressed ? (card ? 1.04 : 1.0) : (_focused ? focusScale : 1.0);
    final duration = _pressed ? Motion.pressDown : (_focused ? Motion.focusIn : Motion.focusOut);
    final r = BorderRadius.circular(widget.radius);
    // No blurred shadows: on the Hisense GPU a blurred halo cost ~13 ms per
    // frame. Crisp rings read the same from the sofa.
    final shadows = lit
        ? [
            if (card) const BoxShadow(color: Color(0x596C6CF2), spreadRadius: 7),
            if (card) const BoxShadow(color: Palette.ink, spreadRadius: 3.5),
            if (card) const BoxShadow(color: Palette.bg, spreadRadius: 1.5),
            if (!card) const BoxShadow(color: Color(0x596C6CF2), spreadRadius: 3),
          ]
        : const <BoxShadow>[];
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: Focus(
        focusNode: widget.focusNode,
        autofocus: widget.autofocus,
        onFocusChange: (f) {
          setState(() => _focused = f);
          widget.onFocusChange?.call(f);
        },
        onKeyEvent: _onKey,
        child: GestureDetector(
          onTap: widget.onSelect,
          onLongPress: widget.onLongPress,
          child: AnimatedScale(
            scale: scale,
            duration: duration,
            curve: _pressed ? Curves.easeOut : (_focused ? Motion.standard : Motion.exit),
            child: AnimatedContainer(
              duration: duration,
              curve: Motion.standard,
              decoration: BoxDecoration(
                color: card ? null : (lit ? Palette.ink : widget.restColor),
                borderRadius: r,
                border: !card && !lit && widget.restBorder != null ? Border.all(color: widget.restBorder!, width: 1) : null,
                boxShadow: shadows,
              ),
              child: ClipRRect(
                borderRadius: r,
                child: Stack(
                  fit: StackFit.passthrough,
                  children: [
                    widget.builder(context, lit),
                    if (card)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: AnimatedOpacity(
                            opacity: lit ? 1 : 0,
                            duration: duration,
                            child: const DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment(-0.6, -1),
                                  end: Alignment(0.6, 1),
                                  colors: [Color(0x38FFFFFF), Color(0x00FFFFFF)],
                                  stops: [0, 0.4],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (card && _pressed) const Positioned.fill(child: IgnorePointer(child: ColoredBox(color: Color(0x1F000000)))),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
