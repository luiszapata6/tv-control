import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../theme/theme.dart';
import '../theme/tokens.dart';
import 'pressable.dart';

/// Material Symbols Rounded icon (outlined at rest, filled when [filled]).
class Sym extends StatelessWidget {
  const Sym(this.icon, {super.key, this.size = 22, this.color, this.filled = false, this.weight = 450});
  final IconData icon;
  final double size;
  final Color? color;
  final bool filled;
  final double weight;

  @override
  Widget build(BuildContext context) =>
      Icon(icon, size: size, color: color ?? Tokens.ink, fill: filled ? 1 : 0, weight: weight, opticalSize: 24);
}

/// A card on the page: `card` surface with a hairline edge (depth by lightness).
class Surface extends StatelessWidget {
  const Surface({super.key, required this.child, this.padding, this.radius = Radii.card, this.color = Tokens.card});
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double radius;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: Tokens.edge),
        ),
        // List tiles and ink inside a card paint on this material, not on
        // whatever is behind the card.
        child: Material(type: MaterialType.transparency, child: child),
      );
}

class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {super.key, this.color});
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) => Text(text.toUpperCase(), style: Txt.eyebrow.copyWith(color: color));
}

/// Round icon button (44 pt hit area minimum).
class IconCircle extends StatelessWidget {
  const IconCircle({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
    this.size = 48,
    this.color = Tokens.card2,
    this.iconColor,
    this.filled = false,
    this.haptic = Haptic.selection,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final double size;
  final Color color;
  final Color? iconColor;
  final bool filled;
  final Haptic haptic;

  @override
  Widget build(BuildContext context) => Pressable(
        onTap: onTap,
        semanticLabel: label,
        haptic: haptic,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: Center(child: Sym(icon, size: size * 0.5, color: iconColor, filled: filled)),
        ),
      );
}

/// Primary call to action: accent gradient, 56 pt, top highlight, lifted.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({super.key, required this.label, this.onTap, this.icon, this.busy = false});
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final a = AccentScope.of(context);
    final enabled = onTap != null && !busy;
    return Pressable(
      onTap: enabled ? onTap : null,
      size: PressSize.big,
      haptic: Haptic.light,
      semanticLabel: label,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: onTap == null ? 0.4 : 1,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            gradient: a.gradient,
            borderRadius: BorderRadius.circular(Radii.tile),
            boxShadow: onTap == null ? const [] : [BoxShadow(color: a.glow, blurRadius: 24, offset: const Offset(0, 10))],
          ),
          foregroundDecoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Radii.tile),
            border: const Border(top: BorderSide(color: Color(0x2EFFFFFF))),
          ),
          child: Center(
            child: busy
                ? SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: a.onFill))
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[Sym(icon!, color: a.onFill), const SizedBox(width: 8)],
                      Flexible(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Txt.button.copyWith(color: a.onFill, fontSize: 16),
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

/// Secondary text button.
class GhostButton extends StatelessWidget {
  const GhostButton({super.key, required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Pressable(
        onTap: onTap,
        size: PressSize.pill,
        semanticLabel: label,
        child: SizedBox(
          height: 48,
          child: Center(child: Text(label, style: Txt.button.copyWith(color: AccentScope.of(context).ink))),
        ),
      );
}

/// Green dot that pulses three times when it turns on ("Now" pulse).
class StatusDot extends StatefulWidget {
  const StatusDot({super.key, required this.color, this.pulse = false});
  final Color color;
  final bool pulse;

  @override
  State<StatusDot> createState() => _StatusDotState();
}

class _StatusDotState extends State<StatusDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));

  @override
  void initState() {
    super.initState();
    if (widget.pulse) _run();
  }

  @override
  void didUpdateWidget(StatusDot old) {
    super.didUpdateWidget(old);
    if (widget.pulse && !old.pulse) _run();
  }

  Future<void> _run() async {
    for (var i = 0; i < 3 && mounted; i++) {
      await _c.forward(from: 0).orCancel.catchError((_) {});
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (context, _) => Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
            boxShadow: [
              if (_c.isAnimating)
                BoxShadow(
                  color: widget.color.withValues(alpha: 0.55 * (1 - _c.value)),
                  spreadRadius: 8 * _c.value,
                ),
            ],
          ),
        ),
      );
}

/// Children rise 14 pt and fade in, staggered by 60 ms (screen entry).
class RiseIn extends StatelessWidget {
  const RiseIn({super.key, required this.index, required this.child});
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduce) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Motion.durEntry + Motion.durStagger * index,
      curve: Interval((index * 60) / (520 + index * 60), 1, curve: Motion.standard),
      builder: (context, t, c) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, 14 * (1 - t)), child: c),
      ),
      child: child,
    );
  }
}

/// App icon: real PNG from the TV when available, else a gradient monogram.
class AppIcon extends StatelessWidget {
  const AppIcon({super.key, required this.label, this.png, this.size = 44, this.radius = 14});
  final String label;
  final Uint8List? png;
  final double size;
  final double radius;

  static (Color, Color) colorsFor(String label) {
    final hue = (label.codeUnits.fold<int>(0, (a, b) => a + b) * 37) % 360;
    return (
      HSLColor.fromAHSL(1, hue.toDouble(), 0.75, 0.74).toColor(),
      HSLColor.fromAHSL(1, hue.toDouble(), 0.6, 0.46).toColor(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bytes = png;
    if (bytes != null && bytes.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Container(
          width: size,
          height: size,
          color: Tokens.card3,
          child: Image.memory(bytes, fit: BoxFit.cover, gaplessPlayback: true, filterQuality: FilterQuality.medium),
        ),
      );
    }
    final (a, b) = colorsFor(label);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(colors: [a, b], begin: Alignment.topLeft, end: Alignment.bottomRight, stops: const [0, .7]),
        boxShadow: const [BoxShadow(color: Color(0x59000000), blurRadius: 16, offset: Offset(0, 6))],
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: const Border(top: BorderSide(color: Color(0x2EFFFFFF))),
      ),
      child: Text(
        label.isEmpty ? '?' : label.characters.first.toUpperCase(),
        style: TextStyle(fontSize: size * 0.42, fontWeight: FontWeight.w800, color: Colors.white),
      ),
    );
  }
}

