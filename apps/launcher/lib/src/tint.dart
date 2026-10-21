import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

/// The colour that represents an app icon/banner: an average of a 12x12
/// thumbnail where saturated pixels weigh most, so a white banner with a red
/// logo (YouTube) gives red, not white. Null if the image can't be decoded.
Future<ui.Color?> dominantColor(Uint8List image) async {
  try {
    final codec = await ui.instantiateImageCodec(image, targetWidth: 12, targetHeight: 12);
    final frame = await codec.getNextFrame();
    final data = await frame.image.toByteData();
    frame.image.dispose();
    codec.dispose();
    if (data == null) return null;
    var r = 0.0, g = 0.0, b = 0.0, total = 0.0;
    for (var i = 0; i + 3 < data.lengthInBytes; i += 4) {
      final pr = data.getUint8(i), pg = data.getUint8(i + 1), pb = data.getUint8(i + 2);
      final hi = math.max(pr, math.max(pg, pb)), lo = math.min(pr, math.min(pg, pb));
      final sat = hi == 0 ? 0.0 : (hi - lo) / hi;
      final w = data.getUint8(i + 3) / 255 * (0.03 + sat * sat);
      r += pr * w;
      g += pg * w;
      b += pb * w;
      total += w;
    }
    if (total == 0) return null;
    return ui.Color.fromARGB(255, (r / total).round(), (g / total).round(), (b / total).round());
  } catch (_) {
    return null;
  }
}
