import 'package:flutter/material.dart';

/// Colours of the dark-only launcher (same family as the iPhone app).
abstract final class Palette {
  static const bg = Color(0xFF0B0E17);
  static const card = Color(0xFF151A28);
  static const card2 = Color(0xFF1E2436);
  static const line = Color(0x14FFFFFF);
  static const ink = Color(0xFFF2F4FA);
  static const ink2 = Color(0xFFA3AAC0);
  static const ink3 = Color(0xFF636B85);
  static const accent = Color(0xFF8A97FF);
  static const accentDeep = Color(0xFF4F5FF0);
  static const success = Color(0xFF4CC27A);
  static const warn = Color(0xFFF7BD5C);
}

abstract final class Motion {
  static const standard = Cubic(0.2, 0.8, 0.2, 1);
  static const spring = Cubic(0.34, 1.56, 0.64, 1);
  static const focus = Duration(milliseconds: 260);
  static const entry = Duration(milliseconds: 520);
}

ThemeData buildTheme() {
  final base = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    scaffoldBackgroundColor: Palette.bg,
    colorScheme: const ColorScheme.dark(
      primary: Palette.accent,
      secondary: Palette.accent,
      surface: Palette.card,
      onSurface: Palette.ink,
    ),
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    focusColor: Colors.transparent,
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(bodyColor: Palette.ink, displayColor: Palette.ink, fontFamily: 'sans-serif'),
  );
}
