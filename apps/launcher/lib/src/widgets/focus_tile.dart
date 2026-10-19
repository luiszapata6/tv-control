import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';

/// A D-pad focusable card: grows and gets an accent ring when focused,
/// presses in on select, and reports long presses (hold OK / menu key).
class FocusTile extends StatefulWidget {
  const FocusTile({
    super.key,
    required this.child,
    required this.onSelect,
    this.onLongPress,
    this.autofocus = false,
    this.focusNode,
    this.borderRadius = 24,
    this.focusedScale = 1.08,
    this.onFocusChange,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback onSelect;
  final VoidCallback? onLongPress;
  final bool autofocus;
  final FocusNode? focusNode;
  final double borderRadius;
  final double focusedScale;
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
    if (!isSelect) return KeyEventResult.ignored;
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
    final scale = _pressed ? 0.97 : (_focused ? widget.focusedScale : 1.0);
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
            duration: _pressed ? const Duration(milliseconds: 90) : Motion.focus,
            curve: _pressed ? Curves.easeOut : Motion.spring,
            child: AnimatedContainer(
              duration: Motion.focus,
              curve: Motion.standard,
              decoration: BoxDecoration(
                color: _focused ? Palette.card2 : Palette.card,
                borderRadius: BorderRadius.circular(widget.borderRadius),
                border: Border.all(
                  color: _focused ? Palette.accent : Palette.line,
                  width: _focused ? 2.5 : 1,
                ),
                boxShadow: _focused
                    ? [BoxShadow(color: Palette.accentDeep.withValues(alpha: 0.45), blurRadius: 28, offset: const Offset(0, 12))]
                    : const [],
              ),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
