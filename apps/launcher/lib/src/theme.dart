import 'package:flutter/material.dart';

/// Colours of the dark-only launcher (same family as the iPhone app).
/// Sizes in this app are dp on the 960x540 canvas (1080p px / 2).
abstract final class Palette {
  static const bg = Color(0xFF0A0B10);
  static const homeBg = Color(0xFF08090D);
  static const surface1 = Color(0xFF12141C);
  static const surface2 = Color(0xFF171923);
  static const input = Color(0xFF151721);
  static const skeleton = Color(0xFF181A24);
  static const ink = Color(0xFFF4F4F8);
  static const ink2 = Color(0xFFB9BCCB);
  static const ink3 = Color(0xFF8A8EA0);
  static const ink4 = Color(0xFF6F7385);
  static const inkSoft = Color(0xFFE4E5EE);
  static const inkOnFill = Color(0xFF4A4D5C);
  static const indigo = Color(0xFF6C6CF2);
  static const indigoLight = Color(0xFFA5A6FF);
  static const amber = Color(0xFFF3B74F);
  static const teal = Color(0xFF45CFC0);
  static const green = Color(0xFF4ADE80);
  static const line = Color(0x14FFFFFF);
  static const scrim = Color(0xCC06070B);
}

abstract final class Motion {
  static const focusIn = Duration(milliseconds: 200);
  static const focusOut = Duration(milliseconds: 160);
  static const pressDown = Duration(milliseconds: 90);
  static const pressUp = Duration(milliseconds: 220);
  static const overlayIn = Duration(milliseconds: 240);
  static const panelIn = Duration(milliseconds: 280);
  static const iconFade = Duration(milliseconds: 220);
  static const standard = Cubic(0.2, 0.8, 0.2, 1);
  static const exit = Cubic(0.4, 0, 0.2, 1);
  static const bounce = Cubic(0.34, 1.4, 0.64, 1);
}

/// Text styles at 3 m: nothing below 12 dp.
abstract final class Txt {
  static const _tab = [FontFeature.tabularFigures()];
  static const eyebrow = TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 2.2, color: Palette.ink2);
  static const clock = TextStyle(fontSize: 78, height: 0.92, fontWeight: FontWeight.w200, letterSpacing: -3.5, fontFeatures: _tab);
  static const title = TextStyle(fontSize: 32, height: 1.05, fontWeight: FontWeight.w700, letterSpacing: -0.64);
  static const temp = TextStyle(fontSize: 36, height: 1, fontWeight: FontWeight.w200, letterSpacing: -1.4, fontFeatures: _tab);
  static const section = TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: -0.15);
  static const row = TextStyle(fontSize: 15, fontWeight: FontWeight.w700);
  static const body = TextStyle(fontSize: 14, fontWeight: FontWeight.w700);
  static const sub = TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Palette.ink3);
  static const hint = TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Palette.ink3);
}

ThemeData buildTheme() {
  final base = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    fontFamily: 'Manrope',
    scaffoldBackgroundColor: Palette.bg,
    colorScheme: const ColorScheme.dark(
      primary: Palette.indigoLight,
      secondary: Palette.indigoLight,
      surface: Palette.surface1,
      onSurface: Palette.ink,
    ),
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    focusColor: Colors.transparent,
  );
  return base.copyWith(textTheme: base.textTheme.apply(bodyColor: Palette.ink, displayColor: Palette.ink));
}

/// Fixed glow: deep blue at the top right over black. One cached picture
/// covering only that corner: full-screen gradients redrawn every frame cost
/// ~37 ms per frame on the Hisense GPU.
class Backdrop extends StatelessWidget {
  const Backdrop({super.key});

  @override
  Widget build(BuildContext context) => const Align(
        alignment: Alignment.topRight,
        child: FractionallySizedBox(
          widthFactor: 0.7,
          heightFactor: 0.75,
          child: RepaintBoundary(child: CustomPaint(painter: _BackdropPainter(), isComplex: true, willChange: false)),
        ),
      );
}

class _BackdropPainter extends CustomPainter {
  const _BackdropPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    const glow = RadialGradient(
      center: Alignment(0.45, -1),
      radius: 1.1,
      colors: [Color(0x52123A8C), Color(0x00123A8C)],
    );
    canvas.drawRect(rect, Paint()..shader = glow.createShader(rect));
  }

  @override
  bool shouldRepaint(_BackdropPainter old) => false;
}
