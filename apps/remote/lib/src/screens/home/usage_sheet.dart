import 'package:companion_protocol/companion_protocol.dart';
import 'package:flutter/material.dart';

import '../../services/tv_session.dart';
import '../../theme/theme.dart';
import '../../theme/tokens.dart';

/// Time per app on the TV over the last week (from the launcher).
Future<void> showUsageSheet(BuildContext context, TvSession session) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Tokens.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => _UsageSheet(future: session.usage()),
    );

String formatUsage(Duration d) {
  if (d.inMinutes < 1) return 'menos de 1 min';
  if (d.inHours == 0) return '${d.inMinutes} min';
  final m = d.inMinutes % 60;
  return m == 0 ? '${d.inHours} h' : '${d.inHours} h $m min';
}

class _UsageSheet extends StatelessWidget {
  const _UsageSheet({required this.future});
  final Future<List<UsageEntry>?> future;

  @override
  Widget build(BuildContext context) {
    final a = AccentScope.of(context);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.92,
      builder: (context, scroll) => FutureBuilder(
        future: future,
        builder: (context, snap) {
          final entries = snap.data;
          final top = entries == null || entries.isEmpty ? 1 : entries.first.foregroundMs;
          return ListView(
            controller: scroll,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: Tokens.line, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 18),
              const Text('Uso de apps', style: Txt.titleSheet),
              const SizedBox(height: 4),
              const Text('Últimos 7 días en la TV', style: Txt.bodyS),
              const SizedBox(height: 16),
              if (snap.connectionState != ConnectionState.done)
                Center(child: CircularProgressIndicator(strokeWidth: 2, color: a.light))
              else if (entries == null)
                const Text('No pude leer el uso. ¿Está el launcher conectado?', style: Txt.body)
              else if (entries.isEmpty)
                const Text('Todavía no hay uso registrado.', style: Txt.body)
              else
                for (final e in entries)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(child: Text(e.label, style: Txt.titleRow, maxLines: 1, overflow: TextOverflow.ellipsis)),
                            Text(formatUsage(e.foreground), style: Txt.bodyS),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(Radii.pill),
                          child: LinearProgressIndicator(
                            value: e.foregroundMs / top,
                            minHeight: 6,
                            color: a.light,
                            backgroundColor: Tokens.card3,
                          ),
                        ),
                      ],
                    ),
                  ),
            ],
          );
        },
      ),
    );
  }
}
