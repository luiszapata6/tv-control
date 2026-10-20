import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'tokens.dart';

/// Text styles (truME v2 scale, Manrope, tabular figures).
abstract final class Txt {
  static const _tab = [FontFeature.tabularFigures()];
  static const titleScreen = TextStyle(fontSize: 24, height: 30 / 24, fontWeight: FontWeight.w800, letterSpacing: -0.6, color: Tokens.ink);
  static const titleSheet = TextStyle(fontSize: 21, height: 26 / 21, fontWeight: FontWeight.w800, letterSpacing: -0.4, color: Tokens.ink);
  static const titleBar = TextStyle(fontSize: 17, height: 22 / 17, fontWeight: FontWeight.w800, color: Tokens.ink);
  static const titleRow = TextStyle(fontSize: 15, height: 20 / 15, fontWeight: FontWeight.w700, color: Tokens.ink);
  static const body = TextStyle(fontSize: 15, height: 21 / 15, fontWeight: FontWeight.w500, color: Tokens.ink2);
  static const bodyS = TextStyle(fontSize: 13, height: 18 / 13, fontWeight: FontWeight.w600, color: Tokens.ink2);
  static const button = TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Tokens.ink);
  static const label = TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Tokens.ink);
  static const caption = TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Tokens.ink2);
  static const eyebrow = TextStyle(fontSize: 11, height: 14 / 11, fontWeight: FontWeight.w800, letterSpacing: 1.5, color: Tokens.ink2);
  static const figure = TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Tokens.ink, fontFeatures: _tab);
  static const figureL = TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.8, color: Tokens.ink, fontFeatures: _tab);
}

ThemeData buildTheme({bool useGoogleFonts = true}) {
  final base = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    scaffoldBackgroundColor: Tokens.bg,
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF8A97FF),
      surface: Tokens.card,
      onSurface: Tokens.ink,
      error: Tokens.danger,
    ),
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.android: CupertinoPageTransitionsBuilder(),
    }),
  );
  final textTheme = base.textTheme.apply(bodyColor: Tokens.ink, displayColor: Tokens.ink);
  // Every Text inherits Manrope through the theme's default text style.
  return base.copyWith(
    textTheme: useGoogleFonts ? GoogleFonts.manropeTextTheme(textTheme) : textTheme,
  );
}
