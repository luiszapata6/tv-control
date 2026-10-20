import 'package:atv_remote/atv_remote.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../services/devices.dart';
import '../../services/services.dart';
import '../../theme/theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/common.dart';
import '../../widgets/controls.dart';
import '../../widgets/pressable.dart';

enum _Step { preparing, code, sending, done, failed }

/// Step 2: the TV shows a 6 character code; type it here.
class PairScreen extends StatefulWidget {
  const PairScreen({super.key, required this.host, this.name});
  final String host;
  final String? name;

  @override
  State<PairScreen> createState() => _PairScreenState();
}

class _PairScreenState extends State<PairScreen> {
  _Step _step = _Step.preparing;
  String _status = 'Preparando un certificado seguro…';
  String? _error;
  String _code = '';
  PairingSession? _session;
  String? _name;
  String? _mac;
  final _codeKey = GlobalKey<CodeInputState>();
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _begin();
    }
  }

  @override
  void dispose() {
    if (_step != _Step.done) _session?.cancel();
    super.dispose();
  }

  Future<void> _begin() async {
    final s = Services.of(context);
    setState(() {
      _step = _Step.preparing;
      _error = null;
    });
    try {
      final identity = await s.devices.identity();
      if (!mounted) return;
      setState(() => _status = 'Conectando con la TV…');
      final info = await s.readTvInfo(widget.host, identity).catchError((_) => (name: null, mac: null));
      _name = info.name ?? widget.name;
      _mac = info.mac;
      if (await s.isPaired(widget.host, identity)) {
        await _save();
        return;
      }
      _session = await s.startPairing(widget.host, identity);
      _name ??= _session!.serverName ?? _session!.subject?.name;
      _mac ??= _session!.subject?.mac;
      if (!mounted) return;
      setState(() => _step = _Step.code);
    } on AtvException catch (e) {
      _fail(e is AtvConnectionException ? 'No pude conectar con la TV. ¿Está encendida y en la misma red?' : e.message);
    } catch (e) {
      _fail('Algo salió mal: $e');
    }
  }

  void _fail(String message) {
    if (!mounted) return;
    playHaptic(Haptic.medium);
    setState(() {
      _step = _Step.failed;
      _error = message;
    });
  }

  void _onCode(String v) {
    setState(() => _code = v);
    if (v.length == 6) _submit();
  }

  Future<void> _submit() async {
    final session = _session;
    if (session == null || _code.length != 6) return;
    setState(() {
      _step = _Step.sending;
      _error = null;
    });
    try {
      await session.finish(_code);
      await _save();
    } on AtvPairingException catch (e) {
      final typo = e.message.contains('does not match') || e.message.contains('6 characters');
      if (typo) {
        playHaptic(Haptic.medium);
        _codeKey.currentState?.clear();
        setState(() {
          _step = _Step.code;
          _code = '';
          _error = 'Ese código no coincide. Revísalo en la TV.';
        });
      } else {
        _fail('La TV rechazó el código. Inténtalo de nuevo.');
      }
    } on AtvException catch (e) {
      _fail(e.message);
    }
  }

  Future<void> _save() async {
    final devices = Services.of(context).devices;
    await devices.save(SavedTv(
      id: _mac ?? widget.host,
      name: _name ?? 'Android TV',
      host: widget.host,
      mac: _mac,
      pairedAt: DateTime.now(),
    ));
    if (!mounted) return;
    playHaptic(Haptic.light);
    setState(() => _step = _Step.done);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Space.gutter, 12, Space.gutter, 20),
          child: AnimatedSwitcher(
            duration: Motion.durEntry,
            switchInCurve: Motion.standard,
            child: switch (_step) {
              _Step.done => _Done(key: const ValueKey('done'), name: _name ?? 'tu TV'),
              _ => _Pairing(
                  key: const ValueKey('pairing'),
                  state: this,
                ),
            },
          ),
        ),
      ),
    );
  }
}

class _Pairing extends StatelessWidget {
  const _Pairing({super.key, required this.state});
  final _PairScreenState state;

  @override
  Widget build(BuildContext context) {
    final a = AccentScope.of(context);
    final step = state._step;
    final busy = step == _Step.preparing || step == _Step.sending;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: IconCircle(icon: Symbols.arrow_back, label: 'Atrás', size: 44, onTap: () => Navigator.of(context).pop()),
        ),
        const SizedBox(height: 16),
        const Eyebrow('Paso 2 de 2'),
        const SizedBox(height: 8),
        Text('Escribe el código que aparece en tu TV', style: Txt.titleScreen.copyWith(fontSize: 28, height: 34 / 28)),
        const SizedBox(height: 24),
        Surface(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: a.tint, borderRadius: BorderRadius.circular(Radii.item)),
                child: Center(child: Sym(Symbols.tv, color: a.ink)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(state._name ?? state.widget.name ?? 'Android TV', style: Txt.titleRow),
                    Text(state.widget.host, style: Txt.bodyS),
                  ],
                ),
              ),
              if (step == _Step.code) Sym(Symbols.check_circle, filled: true, color: a.ink),
            ],
          ),
        ),
        const SizedBox(height: 28),
        if (step == _Step.failed) ...[
          Surface(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Sym(Symbols.error, color: Tokens.danger),
                const SizedBox(width: 12),
                Expanded(child: Text(state._error ?? '', style: Txt.body.copyWith(color: Tokens.ink))),
              ],
            ),
          ),
        ] else if (step == _Step.preparing) ...[
          Row(
            children: [
              SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2, color: a.light)),
              const SizedBox(width: 12),
              Text(state._status, style: Txt.bodyS),
            ],
          ),
        ] else ...[
          const Text('Código de 6 caracteres', style: Txt.bodyS),
          const SizedBox(height: 12),
          CodeInput(
            key: state._codeKey,
            onChanged: state._onCode,
          ),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: state._error == null
                ? const Text('Solo se hace una vez. El iPhone guarda un certificado seguro y se reconecta solo.', style: Txt.bodyS)
                : Text(state._error!, key: ValueKey(state._error), style: Txt.bodyS.copyWith(color: Tokens.danger)),
          ),
        ],
        const Spacer(),
        if (step == _Step.failed)
          PrimaryButton(label: 'Intentar de nuevo', icon: Symbols.refresh, onTap: state._begin)
        else
          PrimaryButton(
            label: 'Emparejar',
            busy: busy,
            onTap: state._code.length == 6 && step == _Step.code ? state._submit : null,
          ),
      ],
    );
  }
}

class _Done extends StatelessWidget {
  const _Done({super.key, required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.6, end: 1),
                duration: Motion.durEntry,
                curve: Motion.spring,
                builder: (context, s, c) => Transform.scale(scale: s, child: c),
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: const BoxDecoration(
                    color: Tokens.successFill,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Color(0x731B873F), blurRadius: 32, offset: Offset(0, 12))],
                  ),
                  child: const Center(child: Sym(Symbols.check, size: 48, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 20),
              const RiseIn(index: 1, child: Text('Listo, ya controlas tu TV', style: Txt.titleScreen)),
              const SizedBox(height: 6),
              RiseIn(index: 2, child: Text(name, style: Txt.body)),
            ],
          ),
        ),
        PrimaryButton(
          label: 'Ir al control',
          onTap: () => Navigator.of(context).popUntil((r) => r.isFirst),
        ),
      ],
    );
  }
}
