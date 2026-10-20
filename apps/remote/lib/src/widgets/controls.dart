import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../theme/theme.dart';
import '../theme/tokens.dart';
import 'common.dart';
import 'pressable.dart';

/// Circular D-pad: four arrows around an accent OK button. Arrows auto-repeat
/// when held; holding OK sends a long press (start/end).
class DPad extends StatelessWidget {
  const DPad({
    super.key,
    required this.onUp,
    required this.onDown,
    required this.onLeft,
    required this.onRight,
    required this.onOk,
    this.onOkLongStart,
    this.onOkLongEnd,
    this.size = 264,
  });

  final VoidCallback onUp;
  final VoidCallback onDown;
  final VoidCallback onLeft;
  final VoidCallback onRight;
  final VoidCallback onOk;
  final VoidCallback? onOkLongStart;
  final VoidCallback? onOkLongEnd;
  final double size;

  @override
  Widget build(BuildContext context) {
    final a = AccentScope.of(context);
    final arrow = size * 0.29;
    final ok = size * 0.42;
    Widget arrowButton(IconData icon, String label, VoidCallback cb, Alignment align) => Align(
          alignment: align,
          child: Padding(
            padding: EdgeInsets.all(size * 0.02),
            child: Pressable(
              onRepeat: cb,
              semanticLabel: label,
              child: SizedBox(
                width: arrow,
                height: arrow,
                child: Center(child: Sym(icon, size: 34)),
              ),
            ),
          ),
        );
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Tokens.card,
        shape: BoxShape.circle,
        border: Border.all(color: Tokens.edge),
        gradient: const RadialGradient(colors: [Tokens.card2, Tokens.card], stops: [0.35, 1]),
      ),
      child: Stack(
        children: [
          arrowButton(Symbols.keyboard_arrow_up, 'Arriba', onUp, Alignment.topCenter),
          arrowButton(Symbols.keyboard_arrow_down, 'Abajo', onDown, Alignment.bottomCenter),
          arrowButton(Symbols.keyboard_arrow_left, 'Izquierda', onLeft, Alignment.centerLeft),
          arrowButton(Symbols.keyboard_arrow_right, 'Derecha', onRight, Alignment.centerRight),
          Center(
            child: Pressable(
              onTap: onOk,
              onLongPress: onOkLongStart,
              onPressEnd: onOkLongEnd,
              haptic: Haptic.light,
              semanticLabel: 'OK',
              child: Container(
                width: ok,
                height: ok,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: a.gradient,
                  boxShadow: [BoxShadow(color: a.glow, blurRadius: 28, offset: const Offset(0, 10))],
                ),
                foregroundDecoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border(top: BorderSide(color: Color(0x2EFFFFFF))),
                ),
                child: Center(child: Text('OK', style: Txt.button.copyWith(fontSize: 18, color: a.onFill, letterSpacing: 0.5))),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Touch volume slider: drag anywhere to set the level; the fill follows the
/// finger. [value] 0..max.
class VolumeSlider extends StatefulWidget {
  const VolumeSlider({
    super.key,
    required this.value,
    required this.max,
    required this.muted,
    required this.onChanged,
    this.height = 60,
  });

  final int value;
  final int max;
  final bool muted;
  final ValueChanged<int> onChanged;
  final double height;

  @override
  State<VolumeSlider> createState() => _VolumeSliderState();
}

class _VolumeSliderState extends State<VolumeSlider> {
  bool _dragging = false;
  int? _local;
  int _lastHapticStep = -1;

  void _set(Offset local, double width) {
    final f = (local.dx / width).clamp(0.0, 1.0);
    final v = (f * widget.max).round();
    if (v != _local) {
      setState(() => _local = v);
      final step = v ~/ 5;
      if (step != _lastHapticStep) {
        _lastHapticStep = step;
        playHaptic(Haptic.selection);
      }
      widget.onChanged(v);
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = AccentScope.of(context);
    final value = _dragging ? (_local ?? widget.value) : widget.value;
    final shown = widget.muted ? 0 : value;
    final fraction = widget.max <= 0 ? 0.0 : (shown / widget.max).clamp(0.0, 1.0);
    final icon = shown == 0 ? Symbols.volume_mute : (fraction < 0.4 ? Symbols.volume_down : Symbols.volume_up);
    return Semantics(
      slider: true,
      label: 'Volumen',
      value: '$shown',
      increasedValue: '${(value + 1).clamp(0, widget.max)}',
      decreasedValue: '${(value - 1).clamp(0, widget.max)}',
      onIncrease: () => widget.onChanged((value + 1).clamp(0, widget.max)),
      onDecrease: () => widget.onChanged((value - 1).clamp(0, widget.max)),
      child: LayoutBuilder(
        builder: (context, box) => GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: (d) {
            setState(() => _dragging = true);
            _set(d.localPosition, box.maxWidth);
          },
          onHorizontalDragUpdate: (d) => _set(d.localPosition, box.maxWidth),
          onHorizontalDragEnd: (_) => setState(() => _dragging = false),
          onTapUp: (d) => _set(d.localPosition, box.maxWidth),
          child: Container(
            height: widget.height,
            decoration: BoxDecoration(color: Tokens.card2, borderRadius: BorderRadius.circular(widget.height / 2)),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                AnimatedContainer(
                  duration: _dragging ? Duration.zero : const Duration(milliseconds: 260),
                  curve: Motion.standard,
                  width: (box.maxWidth * fraction).clamp(widget.height, box.maxWidth),
                  decoration: BoxDecoration(
                    gradient: a.gradient,
                    borderRadius: BorderRadius.circular(widget.height / 2),
                  ),
                  foregroundDecoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(widget.height / 2),
                    border: const Border(top: BorderSide(color: Color(0x2EFFFFFF))),
                  ),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 12),
                  child: Container(width: 4, height: widget.height * 0.4, decoration: BoxDecoration(color: a.onFill.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(2))),
                ),
                Positioned(left: 20, top: 0, bottom: 0, child: Center(child: Sym(icon, color: a.onFill))),
                Positioned(
                  right: 22,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Text(widget.muted ? 'Silencio' : '$value', style: Txt.figure),
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

/// Segmented control with a sliding thumb (340 ms spring).
class Segmented extends StatelessWidget {
  const Segmented({super.key, required this.labels, required this.index, required this.onChanged});
  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: Tokens.card, borderRadius: BorderRadius.circular(24), border: Border.all(color: Tokens.edge)),
      child: LayoutBuilder(
        builder: (context, box) {
          final w = box.maxWidth / labels.length;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: Motion.durSegment,
                curve: Motion.spring,
                left: w * index,
                top: 0,
                bottom: 0,
                width: w,
                child: Container(decoration: BoxDecoration(color: Tokens.card3, borderRadius: BorderRadius.circular(20))),
              ),
              Row(
                children: [
                  for (var i = 0; i < labels.length; i++)
                    Expanded(
                      child: Pressable(
                        size: PressSize.pill,
                        onTap: () => onChanged(i),
                        semanticLabel: labels[i],
                        dimOnPress: false,
                        child: Center(
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: Txt.label.copyWith(fontWeight: FontWeight.w800, color: i == index ? Tokens.ink : Tokens.ink2),
                            child: Text(labels[i]),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Six boxes for a pairing code with a blinking caret and a pop on each char.
class CodeInput extends StatefulWidget {
  const CodeInput({super.key, required this.onChanged, this.length = 6, this.hex = true, this.autofocus = true});
  final ValueChanged<String> onChanged;
  final int length;

  /// Hex codes (Android TV) or digits only (launcher).
  final bool hex;
  final bool autofocus;

  @override
  State<CodeInput> createState() => CodeInputState();
}

class CodeInputState extends State<CodeInput> with SingleTickerProviderStateMixin {
  final controller = TextEditingController();
  final focus = FocusNode();
  late final AnimationController _caret = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat();

  void clear() {
    controller.clear();
    widget.onChanged('');
    setState(() {});
  }

  @override
  void dispose() {
    controller.dispose();
    focus.dispose();
    _caret.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = AccentScope.of(context);
    final text = controller.text;
    return GestureDetector(
      onTap: focus.requestFocus,
      child: Stack(
        children: [
          Row(
            children: [
              for (var i = 0; i < widget.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    height: 68,
                    decoration: BoxDecoration(
                      color: Tokens.card2,
                      borderRadius: BorderRadius.circular(Radii.field),
                      border: Border.all(
                        color: i == text.length ? a.light : (i < text.length ? Tokens.line : Colors.transparent),
                        width: i == text.length ? 2 : 1,
                      ),
                      boxShadow: i == text.length ? [BoxShadow(color: a.tint, spreadRadius: 4)] : const [],
                    ),
                    alignment: Alignment.center,
                    child: i < text.length
                        ? TweenAnimationBuilder<double>(
                            key: ValueKey('c$i${text[i]}'),
                            tween: Tween(begin: 1.12, end: 1),
                            duration: Motion.durPop,
                            curve: Motion.spring,
                            builder: (context, s, c) => Transform.scale(scale: s, child: c),
                            child: Text(text[i], style: Txt.figureL),
                          )
                        : (i == text.length
                            ? FadeTransition(
                                opacity: _caret.drive(TweenSequence([
                                  TweenSequenceItem(tween: ConstantTween(1.0), weight: 1),
                                  TweenSequenceItem(tween: ConstantTween(0.0), weight: 1),
                                ])),
                                child: Container(width: 2, height: 30, color: a.light),
                              )
                            : null),
                  ),
                ),
              ],
            ],
          ),
          Positioned.fill(
            child: Opacity(
              opacity: 0.01,
              child: TextField(
                controller: controller,
                focusNode: focus,
                autofocus: widget.autofocus,
                showCursor: false,
                enableInteractiveSelection: false,
                autocorrect: false,
                enableSuggestions: false,
                keyboardType: widget.hex ? TextInputType.visiblePassword : TextInputType.number,
                textCapitalization: TextCapitalization.characters,
                autofillHints: const [AutofillHints.oneTimeCode],
                maxLength: widget.length,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(widget.hex ? RegExp('[0-9a-fA-F]') : RegExp('[0-9]')),
                  TextInputFormatter.withFunction((o, n) => n.copyWith(text: n.text.toUpperCase())),
                ],
                decoration: const InputDecoration(counterText: '', border: InputBorder.none),
                onChanged: (v) {
                  setState(() {});
                  playHaptic(Haptic.selection);
                  widget.onChanged(v);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
