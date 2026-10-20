import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../services/dictation.dart';
import '../../services/tv_session.dart';
import '../../theme/theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/common.dart';
import '../../widgets/pressable.dart';
import '../../widgets/toast.dart';

/// Type (or dictate) and the text appears in the focused field on the TV.
class KeyboardPage extends StatefulWidget {
  const KeyboardPage({super.key, required this.session, required this.dictation});
  final TvSession session;
  final Dictation dictation;

  @override
  State<KeyboardPage> createState() => _KeyboardPageState();
}

class _KeyboardPageState extends State<KeyboardPage> {
  final _text = TextEditingController();
  final _focus = FocusNode();
  Timer? _debounce;
  bool _listening = false;
  final List<String> _recent = [];

  @override
  void dispose() {
    _debounce?.cancel();
    _text.dispose();
    _focus.dispose();
    if (_listening) widget.dictation.stop();
    super.dispose();
  }

  void _changed(String v) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 150), () => _send(v));
  }

  void _send(String v) {
    if (!widget.session.setText(v)) {
      ToastHost.maybeOf(context)?.show('La TV no está conectada', kind: ToastKind.error);
    }
  }

  void _clear() {
    _text.clear();
    _send('');
    setState(() {});
  }

  void _backspace() {
    final t = _text.text;
    if (t.isEmpty) return;
    _text.text = t.substring(0, t.length - 1);
    _changed(_text.text);
  }

  void _submit() {
    final t = _text.text.trim();
    if (t.isNotEmpty) {
      _recent.remove(t);
      _recent.insert(0, t);
      if (_recent.length > 6) _recent.removeLast();
    }
    widget.session.submitText();
    playHaptic(Haptic.light);
    setState(() {});
  }

  Future<void> _startDictation() async {
    final ok = await widget.dictation.start((text, isFinal) {
      if (!mounted) return;
      _text.text = text;
      _changed(text);
      if (isFinal) setState(() => _listening = false);
    });
    if (!mounted) return;
    if (!ok) {
      ToastHost.maybeOf(context)?.show('Permite el micrófono y el reconocimiento de voz en Ajustes', kind: ToastKind.error);
      return;
    }
    setState(() => _listening = true);
  }

  Future<void> _stopDictation() async {
    await widget.dictation.stop();
    if (mounted) setState(() => _listening = false);
  }

  void _useRecent(String t) {
    _text.text = t;
    _changed(t);
  }

  @override
  Widget build(BuildContext context) {
    final a = AccentScope.of(context);
    final app = widget.session.currentAppLabel;
    return ListView(
      padding: const EdgeInsets.fromLTRB(Space.gutter, 8, Space.gutter, 120),
      children: [
        RiseIn(
          index: 0,
          child: Surface(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Eyebrow(app.isEmpty ? 'En la pantalla' : 'En la pantalla · $app'),
                const SizedBox(height: 10),
                Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(color: Tokens.bg, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      const Sym(Symbols.search, size: 20, color: Tokens.ink3),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _text.text.isEmpty ? 'Escribe para buscar en la TV' : _text.text,
                          style: Txt.titleRow.copyWith(color: _text.text.isEmpty ? Tokens.ink3 : Tokens.ink),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        RiseIn(
          index: 1,
          child: TextField(
            controller: _text,
            focusNode: _focus,
            onChanged: _changed,
            onSubmitted: (_) => _submit(),
            textInputAction: TextInputAction.search,
            autocorrect: false,
            style: Txt.titleRow.copyWith(fontSize: 17),
            decoration: InputDecoration(
              labelText: 'Escribe aquí y aparece al instante',
              labelStyle: Txt.bodyS,
              filled: true,
              fillColor: Tokens.card2,
              suffixIcon: _text.text.isEmpty
                  ? null
                  : Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: IconCircle(icon: Symbols.close, label: 'Borrar texto', size: 40, color: Tokens.card3, onTap: _clear),
                    ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(Radii.field), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Radii.field),
                borderSide: BorderSide(color: a.light, width: 2),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        RiseIn(
          index: 2,
          child: Row(
            children: [
              SizedBox(
                width: 112,
                child: Pressable(
                  onRepeat: _backspace,
                  size: PressSize.pill,
                  semanticLabel: 'Borrar letra',
                  child: Surface(
                    radius: Radii.tile,
                    child: const SizedBox(
                      height: 56,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [Sym(Symbols.backspace), SizedBox(width: 8), Text('Letra', style: Txt.label)],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: Space.stack),
              Expanded(child: PrimaryButton(label: 'Buscar en la TV', icon: Symbols.search, onTap: _submit)),
            ],
          ),
        ),
        const SizedBox(height: 30),
        RiseIn(index: 3, child: _MicButton(listening: _listening, onStart: _startDictation, onStop: _stopDictation)),
        if (_recent.isNotEmpty) ...[
          const SizedBox(height: 28),
          const Eyebrow('Recientes'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final r in _recent)
                Pressable(
                  onTap: () => _useRecent(r),
                  size: PressSize.pill,
                  semanticLabel: r,
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(color: Tokens.card, borderRadius: BorderRadius.circular(20), border: Border.all(color: Tokens.edge)),
                    child: Center(widthFactor: 1, child: Text(r, style: Txt.label)),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _MicButton extends StatefulWidget {
  const _MicButton({required this.listening, required this.onStart, required this.onStop});
  final bool listening;
  final Future<void> Function() onStart;
  final Future<void> Function() onStop;

  @override
  State<_MicButton> createState() => _MicButtonState();
}

class _MicButtonState extends State<_MicButton> with SingleTickerProviderStateMixin {
  late final AnimationController _halo = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400));

  @override
  void didUpdateWidget(_MicButton old) {
    super.didUpdateWidget(old);
    if (widget.listening && !_halo.isAnimating) _halo.repeat();
    if (!widget.listening) _halo.stop();
  }

  @override
  void dispose() {
    _halo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = AccentScope.of(context);
    final on = widget.listening;
    return Column(
      children: [
        SizedBox(
          width: 116,
          height: 116,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (on)
                AnimatedBuilder(
                  animation: _halo,
                  builder: (context, _) => Transform.scale(
                    scale: 1 + 0.55 * _halo.value,
                    child: Container(
                      decoration: BoxDecoration(shape: BoxShape.circle, color: a.fill.withValues(alpha: 0.55 * (1 - _halo.value))),
                    ),
                  ),
                ),
              Pressable(
                onPressStart: () {
                  if (!on) widget.onStart();
                },
                onPressEnd: () {
                  if (on) widget.onStop();
                },
                onTap: () {},
                haptic: Haptic.light,
                semanticLabel: on ? 'Dejar de dictar' : 'Mantén para dictar',
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 260),
                  width: 116,
                  height: 116,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: on ? a.gradient : null,
                    color: on ? null : Tokens.card,
                    border: Border.all(color: on ? Colors.transparent : a.light, width: 2),
                    boxShadow: on ? [BoxShadow(color: a.glow, blurRadius: 28, offset: const Offset(0, 12))] : const [],
                  ),
                  child: Center(child: Sym(Symbols.mic, size: 44, filled: true, color: on ? a.onFill : a.ink)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: on
              ? Text('TE ESCUCHO', key: const ValueKey('on'), style: Txt.eyebrow.copyWith(color: a.ink))
              : const Column(
                  key: ValueKey('off'),
                  children: [
                    Text('Mantén para dictar', style: Txt.titleRow),
                    SizedBox(height: 2),
                    Text('Suelta y el texto se envía a la TV', style: Txt.bodyS),
                  ],
                ),
        ),
      ],
    );
  }
}
