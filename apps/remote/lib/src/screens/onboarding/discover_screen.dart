import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../services/discovery.dart';
import '../../services/services.dart';
import '../../theme/theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/common.dart';
import '../../widgets/pressable.dart';
import 'pair_screen.dart';

/// Step 1: find the TV on the network (or type its IP).
class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key, this.canClose = false});

  /// True when adding a second TV (shows a close button).
  final bool canClose;

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  StreamSubscription<List<DiscoveredTv>>? _sub;
  List<DiscoveredTv> _found = const [];
  Object? _error;
  bool _searching = true;
  Timer? _hint;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sub ??= Services.of(context).discovery.watch().listen(
          (list) => setState(() => _found = list),
          onError: (Object e) => setState(() => _error = e),
        );
    _hint ??= Timer(const Duration(seconds: 8), () {
      if (mounted) setState(() => _searching = false);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _hint?.cancel();
    super.dispose();
  }

  void _open(String host, String? name) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => PairScreen(host: host, name: name)));
  }

  Future<void> _manual() async {
    final host = await showDialog<String>(context: context, builder: (_) => const _ManualIpDialog());
    if (host != null && host.isNotEmpty) _open(host, null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Space.gutter, 24, Space.gutter, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.canClose)
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconCircle(icon: Symbols.close, label: 'Cerrar', size: 44, onTap: () => Navigator.of(context).pop()),
                ),
              RiseIn(index: 0, child: const Eyebrow('Paso 1 de 2')),
              const SizedBox(height: 8),
              RiseIn(
                index: 1,
                child: Text('Elige tu TV', style: Txt.titleScreen.copyWith(fontSize: 28, height: 34 / 28)),
              ),
              const SizedBox(height: 6),
              RiseIn(
                index: 2,
                child: const Text('Tu iPhone y la TV deben estar en la misma red Wi-Fi.', style: Txt.body),
              ),
              const SizedBox(height: 28),
              Expanded(
                child: RiseIn(
                  index: 3,
                  child: _found.isEmpty
                      ? _Searching(searching: _searching, error: _error)
                      : ListView.separated(
                          itemCount: _found.length,
                          separatorBuilder: (_, _) => const SizedBox(height: Space.stack),
                          itemBuilder: (context, i) => _TvRow(tv: _found[i], onTap: () => _open(_found[i].host, _found[i].name)),
                        ),
                ),
              ),
              GhostButton(label: '¿No aparece tu TV? Escribir IP', onTap: _manual),
            ],
          ),
        ),
      ),
    );
  }
}

class _Searching extends StatelessWidget {
  const _Searching({required this.searching, this.error});
  final bool searching;
  final Object? error;

  @override
  Widget build(BuildContext context) {
    final a = AccentScope.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox.square(
          dimension: 64,
          child: searching
              ? CircularProgressIndicator(strokeWidth: 3, color: a.light)
              : Sym(Symbols.wifi_find, size: 56, color: Tokens.ink3),
        ),
        const SizedBox(height: 20),
        Text(searching ? 'Buscando tu TV…' : 'No encontré ninguna TV', style: Txt.titleBar),
        const SizedBox(height: 6),
        Text(
          error != null
              ? 'Permite el acceso a la red local en Ajustes > Privacidad > Red local.'
              : (searching ? 'Asegúrate de que esté encendida.' : 'Revisa que esté encendida o escribe su IP.'),
          style: Txt.bodyS,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _TvRow extends StatelessWidget {
  const _TvRow({required this.tv, required this.onTap});
  final DiscoveredTv tv;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final a = AccentScope.of(context);
    return Pressable(
      onTap: onTap,
      size: PressSize.big,
      semanticLabel: tv.name,
      child: Surface(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                  Text(tv.name, style: Txt.titleRow),
                  const SizedBox(height: 2),
                  Text(tv.host, style: Txt.bodyS),
                ],
              ),
            ),
            const Sym(Symbols.chevron_right, color: Tokens.ink3),
          ],
        ),
      ),
    );
  }
}

class _ManualIpDialog extends StatefulWidget {
  const _ManualIpDialog();

  @override
  State<_ManualIpDialog> createState() => _ManualIpDialogState();
}

class _ManualIpDialogState extends State<_ManualIpDialog> {
  final _c = TextEditingController();

  bool get _valid => RegExp(r'^\d{1,3}(\.\d{1,3}){3}$').hasMatch(_c.text.trim());

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Tokens.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.hero)),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('IP de la TV', style: Txt.titleSheet),
            const SizedBox(height: 6),
            const Text('En la TV: Configuración > Red > Estado de la red.', style: Txt.bodyS),
            const SizedBox(height: 16),
            TextField(
              controller: _c,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: Txt.titleRow.copyWith(fontSize: 18),
              decoration: InputDecoration(
                hintText: '192.168.1.50',
                filled: true,
                fillColor: Tokens.card2,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(Radii.field), borderSide: BorderSide.none),
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _valid ? Navigator.of(context).pop(_c.text.trim()) : null,
            ),
            const SizedBox(height: 16),
            PrimaryButton(label: 'Conectar', onTap: _valid ? () => Navigator.of(context).pop(_c.text.trim()) : null),
          ],
        ),
      ),
    );
  }
}
