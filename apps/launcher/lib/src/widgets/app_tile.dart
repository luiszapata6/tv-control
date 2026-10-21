import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../platform.dart';
import '../theme.dart';
import 'focus_tile.dart';

/// Width and height from a PNG header (the TV always sends PNG), null otherwise.
(int, int)? pngSize(Uint8List b) {
  if (b.length < 24 || b[0] != 0x89 || b[1] != 0x50 || b[2] != 0x4E || b[3] != 0x47) return null;
  final d = ByteData.sublistView(b);
  return (d.getUint32(16), d.getUint32(20));
}

/// What fills an app card: its 16:9 TV banner edge to edge, or (apps with only
/// a square icon) the icon and name on a dark tint of the app's colour.
class AppArt extends StatelessWidget {
  const AppArt({super.key, required this.app, required this.icon, this.tint, this.radius = 8});
  final LauncherApp app;
  final Future<Uint8List?> icon;

  /// The app's colour; icon-only apps sit on a dark version of it.
  final Future<Color?>? tint;
  final double radius;

  @override
  Widget build(BuildContext context) => FutureBuilder<Uint8List?>(
        future: icon,
        builder: (context, snap) {
          final Widget child;
          if (snap.connectionState != ConnectionState.done) {
            child = _Named(key: const ValueKey('loading'), app: app, color: Palette.skeleton, nameColor: Palette.ink3);
          } else {
            final bytes = snap.data;
            final size = bytes == null || bytes.isEmpty ? null : pngSize(bytes);
            final banner = size != null && size.$1 >= size.$2 * 1.4;
            child = banner
                ? Image.memory(bytes!,
                    key: const ValueKey('banner'),
                    fit: BoxFit.cover,
                    // Decode at most the on-screen width (4 columns at 1080p), not the full PNG.
                    cacheWidth: 480,
                    gaplessPlayback: true,
                    filterQuality: FilterQuality.medium)
                : FutureBuilder<Color?>(
                    key: const ValueKey('icon'),
                    future: tint,
                    builder: (context, t) =>
                        _Named(app: app, color: darkTint(t.data, app.label), icon: size == null ? null : bytes),
                  );
          }
          return DecoratedBox(
            // Hairline and top highlight so dark banners keep an edge.
            position: DecorationPosition.foreground,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: const Color(0x12FFFFFF), width: 0.5),
            ),
            child: AnimatedSwitcher(duration: Motion.iconFade, child: SizedBox.expand(key: ValueKey(child.key), child: child)),
          );
        },
      );

  /// Background for icon-only apps: the app colour, dark and muted. Without
  /// one, a hue from the name so every app still looks different.
  static Color darkTint(Color? c, String label) {
    if (c == null) {
      final hue = (label.codeUnits.fold<int>(0, (a, b) => a + b) * 37) % 360;
      return HSLColor.fromAHSL(1, hue.toDouble(), 0.4, 0.16).toColor();
    }
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness(0.17).withSaturation(hsl.saturation * 0.6).toColor();
  }
}

class _Named extends StatelessWidget {
  const _Named({super.key, required this.app, required this.color, this.icon, this.nameColor = Palette.ink});
  final LauncherApp app;
  final Color color;
  final Uint8List? icon;
  final Color nameColor;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final h = box.maxHeight.isFinite ? box.maxHeight : box.maxWidth * 9 / 16;
        final iconSide = (h * 0.4).roundToDouble();
        final loading = nameColor == Palette.ink3;
        final letter = app.label.isEmpty ? '?' : app.label.characters.first.toUpperCase();
        return DecoratedBox(
          decoration: BoxDecoration(
            color: color,
            gradient: loading
                ? null
                : RadialGradient(
                    center: Alignment.topCenter,
                    radius: 1.2,
                    colors: [Color.alphaBlend(const Color(0x1AFFFFFF), color), color],
                    stops: const [0, 0.6],
                  ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!loading) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(iconSide * 0.24),
                    child: SizedBox.square(
                      dimension: iconSide,
                      child: icon != null
                          ? Image.memory(icon!, fit: BoxFit.cover, cacheWidth: 160, gaplessPlayback: true)
                          : ColoredBox(
                              color: Palette.ink2,
                              child: Center(
                                child: Text(letter,
                                    style: TextStyle(fontSize: iconSide * 0.5, fontWeight: FontWeight.w800, color: Palette.bg)),
                              ),
                            ),
                    ),
                  ),
                  SizedBox(height: (h * 0.07).roundToDouble()),
                ],
                Text(app.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: nameColor)),
              ],
            ),
          ),
        );
      });
}

/// App card for grids: art, focus, and the name under the card while focused.
class AppTile extends StatefulWidget {
  const AppTile({
    super.key,
    required this.app,
    required this.loadIcon,
    required this.onSelect,
    this.onLongPress,
    this.autofocus = false,
    this.pinned = false,
    this.loadTint,
    this.onFocusChange,
  });

  final LauncherApp app;
  final Future<Uint8List?> Function(String package) loadIcon;
  final Future<Color?> Function(String package)? loadTint;
  final ValueChanged<bool>? onFocusChange;
  final VoidCallback onSelect;
  final VoidCallback? onLongPress;
  final bool autofocus;

  /// Shows the amber "pinned" dot (all apps screen).
  final bool pinned;

  @override
  State<AppTile> createState() => _AppTileState();
}

class _AppTileState extends State<AppTile> {
  late Future<Uint8List?> _icon = widget.loadIcon(widget.app.package);
  late Future<Color?>? _tint = widget.loadTint?.call(widget.app.package);
  bool _focused = false;

  @override
  void didUpdateWidget(AppTile old) {
    super.didUpdateWidget(old);
    if (old.app.package != widget.app.package) {
      _icon = widget.loadIcon(widget.app.package);
      _tint = widget.loadTint?.call(widget.app.package);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onSelect,
      onLongPress: widget.onLongPress,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              clipBehavior: Clip.none,
              fit: StackFit.expand,
              children: [
                FocusTile(
                  look: FocusLook.card,
                  radius: 8,
                  autofocus: widget.autofocus,
                  onSelect: widget.onSelect,
                  onLongPress: widget.onLongPress,
                  semanticLabel: widget.app.label,
                  onFocusChange: (f) {
                    setState(() => _focused = f);
                    widget.onFocusChange?.call(f);
                  },
                  builder: (context, _) => AppArt(app: widget.app, icon: _icon, tint: _tint),
                ),
                if (widget.pinned)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Palette.amber,
                        boxShadow: [BoxShadow(color: Color(0xD90A0B10), spreadRadius: 1.5)],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 18,
            child: AnimatedOpacity(
              opacity: _focused ? 1 : 0,
              duration: _focused ? Motion.focusIn : Motion.focusOut,
              child: Text(widget.app.label,
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}
