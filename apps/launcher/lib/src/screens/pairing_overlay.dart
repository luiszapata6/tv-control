import 'dart:async';

import 'package:flutter/material.dart';

import '../theme.dart';

/// Full-screen code the iPhone must type, readable from the sofa. The code
/// lives 120 s (companion protocol TTL).
class PairingOverlay extends StatefulWidget {
  const PairingOverlay({super.key, required this.code, required this.client});
  final String code;
  final String? client;

  static const ttl = Duration(seconds: 120);

  @override
  State<PairingOverlay> createState() => _PairingOverlayState();
}

class _PairingOverlayState extends State<PairingOverlay> {
  late DateTime _shownAt = DateTime.now();
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void didUpdateWidget(PairingOverlay old) {
    super.didUpdateWidget(old);
    if (old.code != widget.code) _shownAt = DateTime.now();
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final left = PairingOverlay.ttl - DateTime.now().difference(_shownAt);
    final secs = left.inSeconds.clamp(0, PairingOverlay.ttl.inSeconds);
    final chars = widget.code.characters.toList();
    final half = (chars.length / 2).ceil();
    Widget box(String c) => Container(
          width: 78,
          height: 98,
          margin: const EdgeInsets.symmetric(horizontal: 5),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Palette.surface2,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0x1AFFFFFF)),
          ),
          child: Text(c, style: const TextStyle(fontSize: 66, height: 1, fontWeight: FontWeight.w700, fontFeatures: [FontFeature.tabularFigures()])),
        );
    return Positioned.fill(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: Motion.overlayIn,
        curve: Motion.standard,
        builder: (context, t, child) => Opacity(opacity: t, child: Transform.translate(offset: Offset(0, 6 * (1 - t)), child: child)),
        child: ColoredBox(
          color: const Color(0xEB06070B),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('VINCULAR IPHONE', style: Txt.eyebrow.copyWith(color: Palette.teal)),
              const SizedBox(height: 8),
              const Text('Escribe este código en tu iPhone', style: Txt.title),
              const SizedBox(height: 7),
              Text('${widget.client ?? 'Un iPhone'} quiere conectarse',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Palette.ink2)),
              const SizedBox(height: 36),
              Semantics(
                label: widget.code,
                excludeSemantics: true,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final c in chars.take(half)) box(c),
                    Container(width: 14, height: 4, margin: const EdgeInsets.symmetric(horizontal: 13), decoration: BoxDecoration(color: const Color(0xFF3A3E4E), borderRadius: BorderRadius.circular(2))),
                    for (final c in chars.skip(half)) box(c),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: 390,
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: secs / PairingOverlay.ttl.inSeconds,
                        minHeight: 4,
                        color: Palette.teal,
                        backgroundColor: const Color(0x14FFFFFF),
                      ),
                    ),
                    const SizedBox(height: 9),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Palette.teal,
                            boxShadow: [BoxShadow(color: Color(0xCC45CFC0), blurRadius: 7)],
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Flexible(
                          child: Text('Esperando al iPhone…',
                              maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Palette.ink2)),
                        ),
                        const Spacer(),
                        Text('Caduca en ${secs ~/ 60}:${(secs % 60).toString().padLeft(2, '0')}',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Palette.ink3, fontFeatures: [FontFeature.tabularFigures()])),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
