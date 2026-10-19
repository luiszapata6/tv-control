import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../platform.dart';
import '../theme.dart';
import 'focus_tile.dart';

/// App card with its real icon (from the TV) and its name underneath.
class AppTile extends StatefulWidget {
  const AppTile({
    super.key,
    required this.app,
    required this.loadIcon,
    required this.onSelect,
    this.onLongPress,
    this.autofocus = false,
  });

  final LauncherApp app;
  final Future<Uint8List?> Function(String package) loadIcon;
  final VoidCallback onSelect;
  final VoidCallback? onLongPress;
  final bool autofocus;

  @override
  State<AppTile> createState() => _AppTileState();
}

class _AppTileState extends State<AppTile> {
  late Future<Uint8List?> _icon = widget.loadIcon(widget.app.package);
  bool _focused = false;

  @override
  void didUpdateWidget(AppTile old) {
    super.didUpdateWidget(old);
    if (old.app.package != widget.app.package) _icon = widget.loadIcon(widget.app.package);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: FocusTile(
            autofocus: widget.autofocus,
            onSelect: widget.onSelect,
            onLongPress: widget.onLongPress,
            semanticLabel: widget.app.label,
            onFocusChange: (f) => setState(() => _focused = f),
            borderRadius: 18,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(17),
              child: FutureBuilder<Uint8List?>(
                future: _icon,
                builder: (context, snap) {
                  final bytes = snap.data;
                  if (bytes != null && bytes.isNotEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(10),
                      child: Image.memory(bytes, fit: BoxFit.contain, gaplessPlayback: true, filterQuality: FilterQuality.medium),
                    );
                  }
                  return _Monogram(label: widget.app.label);
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: TextStyle(
            fontSize: 13,
            fontWeight: _focused ? FontWeight.w800 : FontWeight.w600,
            color: _focused ? Palette.ink : Palette.ink2,
          ),
          child: Text(widget.app.label, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}

class _Monogram extends StatelessWidget {
  const _Monogram({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final letter = label.isEmpty ? '?' : label.characters.first.toUpperCase();
    final hue = (label.codeUnits.fold<int>(0, (a, b) => a + b) * 37) % 360;
    final a = HSLColor.fromAHSL(1, hue.toDouble(), 0.6, 0.72).toColor();
    final b = HSLColor.fromAHSL(1, hue.toDouble(), 0.55, 0.45).toColor();
    return Center(
      child: Container(
        width: 52,
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(colors: [a, b], begin: Alignment.topLeft, end: Alignment.bottomRight, stops: const [0, .7]),
        ),
        child: Text(letter, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
      ),
    );
  }
}
