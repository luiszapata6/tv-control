import 'package:flutter/material.dart';

import '../theme.dart';

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.trailing});
  final String text;
  final String? trailing;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(text, style: Txt.eyebrow),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            Text(trailing!, style: Txt.hint),
          ],
        ],
      );
}

/// A remote key drawn as a keycap ("OK", "Atrás").
class KeyCap extends StatelessWidget {
  const KeyCap(this.label, {super.key});
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        height: 19,
        constraints: const BoxConstraints(minWidth: 19),
        padding: const EdgeInsets.symmetric(horizontal: 5),
        alignment: Alignment.center,
        decoration: BoxDecoration(color: const Color(0x14FFFFFF), borderRadius: BorderRadius.circular(4)),
        child: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Palette.inkSoft)),
      );
}

/// "[before] [KEY] after", e.g. "Mantén [OK] Opciones".
class KeyHint extends StatelessWidget {
  const KeyHint(this.keyLabel, this.action, {super.key, this.before});
  final String keyLabel;
  final String action;
  final String? before;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (before != null) ...[Text(before!, style: Txt.hint), const SizedBox(width: 5)],
          KeyCap(keyLabel),
          const SizedBox(width: 5),
          Text(action, style: Txt.hint),
        ],
      );
}

class KeyHints extends StatelessWidget {
  const KeyHints(this.hints, {super.key});
  final List<KeyHint> hints;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (i, h) in hints.indexed) ...[if (i > 0) const SizedBox(width: 16), h],
        ],
      );
}
