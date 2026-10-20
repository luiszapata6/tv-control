import 'package:flutter/material.dart';

/// Colour roles (truME v2 style: every colour has a job). Dark only.
abstract final class Tokens {
  static const bg = Color(0xFF0B0E17);
  static const card = Color(0xFF151A28);
  static const card2 = Color(0xFF1E2436);
  static const card3 = Color(0xFF262D42);
  static const edge = Color(0x0DFFFFFF);
  static const line = Color(0x12FFFFFF);
  static const ink = Color(0xFFF2F4FA);
  static const ink2 = Color(0xFFA3AAC0);
  static const ink3 = Color(0xFF636B85);
  static const success = Color(0xFF4CC27A);
  static const successFill = Color(0xFF1B873F);
  static const danger = Color(0xFFFF8A80);
  static const warn = Color(0xFFF7BD5C);
  static const scrim = Color(0xB305070C);
}

/// Brand accent. The fill goes under white (or dark) ink; `light` is the
/// gradient start; `ink` is the accent as text on dark surfaces.
class Accent {
  const Accent({
    required this.name,
    required this.fill,
    required this.light,
    required this.ink,
    required this.onFill,
  });

  final String name;
  final Color fill;
  final Color light;
  final Color ink;
  final Color onFill;

  Color get tint => fill.withValues(alpha: 0.18);
  Color get glow => fill.withValues(alpha: 0.42);

  LinearGradient get gradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [light, fill],
        stops: const [0, 0.7],
      );

  static const indigo = Accent(
    name: 'Índigo',
    fill: Color(0xFF4F5FF0),
    light: Color(0xFF8A97FF),
    ink: Color(0xFFAEB7FF),
    onFill: Colors.white,
  );
  static const amber = Accent(
    name: 'Ámbar',
    fill: Color(0xFFE08A1E),
    light: Color(0xFFF7BD5C),
    ink: Color(0xFFFFC47A),
    onFill: Color(0xFF1A1204),
  );
  static const teal = Accent(
    name: 'Agua',
    fill: Color(0xFF0F7F72),
    light: Color(0xFF3FD0BC),
    ink: Color(0xFF7FE3D4),
    onFill: Colors.white,
  );

  static const all = [indigo, amber, teal];

  static Accent byName(String? name) => all.firstWhere((a) => a.name == name, orElse: () => indigo);
}

abstract final class Radii {
  static const pill = 999.0;
  static const hero = 30.0;
  static const card = 22.0;
  static const tile = 18.0;
  static const field = 16.0;
  static const item = 14.0;
}

abstract final class Space {
  static const gutter = 20.0;
  static const inset = 18.0;
  static const stack = 12.0;
  static const section = 24.0;
  static const inline = 8.0;
}

/// Motion tokens from truME v2.
abstract final class Motion {
  static const standard = Cubic(0.2, 0.8, 0.2, 1);
  static const spring = Cubic(0.34, 1.56, 0.64, 1);
  static const press = Cubic(0.2, 0, 0, 1);
  static const releaseBig = Cubic(0.3, 1.25, 0.6, 1);
  static const durPress = Duration(milliseconds: 90);
  static const durPressMin = Duration(milliseconds: 120);
  static const durRelease = Duration(milliseconds: 320);
  static const durReleaseBig = Duration(milliseconds: 260);
  static const durEntry = Duration(milliseconds: 520);
  static const durStagger = Duration(milliseconds: 60);
  static const durSegment = Duration(milliseconds: 340);
  static const durPop = Duration(milliseconds: 180);
}

/// The selected accent, available to every widget.
class AccentScope extends InheritedWidget {
  const AccentScope({super.key, required this.accent, required super.child});
  final Accent accent;

  static Accent of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AccentScope>()?.accent ?? Accent.indigo;

  @override
  bool updateShouldNotify(AccentScope old) => old.accent != accent;
}
