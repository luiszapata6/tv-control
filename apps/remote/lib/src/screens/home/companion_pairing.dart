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

/// Explains what the launcher adds and starts its pairing.
class CompanionBanner extends StatelessWidget {
  const CompanionBanner({super.key, required this.session});
  final TvSession session;

  @override
  Widget build(BuildContext context) {
    final a = AccentScope.of(context);
    final needsPairing = session.companionStatus == CompanionStatus.needsPairing ||
        session.companionStatus == CompanionStatus.pairing;
    return Surface(
      padding: const EdgeInsets.all(Space.inset),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(color: a.tint, borderRadius: BorderRadius.circular(12)),
                child: Center(child: Sym(needsPairing ? Symbols.link : Symbols.widgets, color: a.ink)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  needsPairing ? 'Conecta con el launcher' : 'Instala el launcher TV Control',
                  style: Txt.titleBar,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            needsPairing
                ? 'Verás las apps reales de tu TV con sus íconos, podrás abrir cualquiera y ordenar el inicio.'
                : 'Con el launcher verás las apps reales de la TV con sus íconos. Mientras tanto puedes abrir las más populares.',
            style: Txt.bodyS,
          ),
          if (needsPairing) ...[
            const SizedBox(height: 14),
            PrimaryButton(label: 'Conectar', icon: Symbols.link, onTap: () => showCompanionPairing(context, session)),
          ],
        ],
      ),
    );
  }
}

/// Asks the launcher for a code and lets the user type it.
Future<void> showCompanionPairing(BuildContext context, TvSession session) async {
  final toast = ToastHost.maybeOf(context);
  try {
    await session.requestCompanionPairing();
  } on CompanionException catch (e) {
    toast?.show('No pude pedir el código: ${e.message}', kind: ToastKind.error);
    return;
  }
  if (!context.mounted) return;
  final ok = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Tokens.card,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (_) => _CompanionCodeSheet(session: session),
  );
  if (ok == true) toast?.show('Launcher conectado');
}

class _CompanionCodeSheet extends StatefulWidget {
  const _CompanionCodeSheet({required this.session});
  final TvSession session;

  @override
  State<_CompanionCodeSheet> createState() => _CompanionCodeSheetState();
}

class _CompanionCodeSheetState extends State<_CompanionCodeSheet> {
  final _key = GlobalKey<CodeInputState>();
  String? _error;
  bool _busy = false;

  Future<void> _submit(String code) async {
    if (code.length != 6) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.session.confirmCompanionPairing(code);
      if (mounted) Navigator.of(context).pop(true);
    } on CompanionException catch (e) {
      playHaptic(Haptic.medium);
      _key.currentState?.clear();
      setState(() {
        _busy = false;
        _error = switch (e.code) {
          'bad_code' => 'Código incorrecto. Revísalo en la TV.',
          'locked' => 'Demasiados intentos. Espera un minuto.',
          _ => e.message,
        };
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: Tokens.line, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 18),
          const Text('Escribe el código del launcher', style: Txt.titleSheet),
          const SizedBox(height: 6),
          const Text('La TV muestra 6 números en pantalla.', style: Txt.bodyS),
          const SizedBox(height: 18),
          CodeInput(key: _key, hex: false, onChanged: _submit),
          const SizedBox(height: 12),
          if (_busy) const LinearProgressIndicator(minHeight: 2),
          if (_error != null) Text(_error!, style: Txt.bodyS.copyWith(color: Tokens.danger)),
        ],
      ),
    );
  }
}
