import 'package:speech_to_text/speech_to_text.dart';

/// Speech recognition on the iPhone; the recognized text is sent to the TV
/// as typed text (no audio goes to the TV).
abstract class Dictation {
  /// Starts listening. [onText] receives partial results and, finally,
  /// [isFinal] true. Returns false if permission is denied or unavailable.
  Future<bool> start(void Function(String text, bool isFinal) onText);
  Future<void> stop();
}

class SpeechDictation implements Dictation {
  final _speech = SpeechToText();
  bool _ready = false;

  @override
  Future<bool> start(void Function(String text, bool isFinal) onText) async {
    if (!_ready) {
      _ready = await _speech.initialize();
      if (!_ready) return false;
    }
    final locales = await _speech.locales();
    final spanish = locales.where((l) => l.localeId.toLowerCase().startsWith('es')).map((l) => l.localeId).toList();
    final locale = spanish.contains('es_CO') ? 'es_CO' : (spanish.isNotEmpty ? spanish.first : null);
    await _speech.listen(
      onResult: (r) => onText(r.recognizedWords, r.finalResult),
      localeId: locale,
      listenFor: const Duration(seconds: 20),
      pauseFor: const Duration(seconds: 3),
    );
    return true;
  }

  @override
  Future<void> stop() => _speech.stop();
}
