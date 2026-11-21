// Text-to-speech using the phone's TTS engine (package: flutter_tts).
// Gnani Timbre replaces this later behind the same speak()/stop() shape.

import 'package:flutter_tts/flutter_tts.dart';

class SpeechOutput {
  final FlutterTts _tts = FlutterTts();

  Future<void> init() async {
    await _tts.awaitSpeakCompletion(true);
    await _tts.setSpeechRate(0.45);
  }

  /// [ttsLocale] like 'hi-IN'. Waits until speaking is finished.
  Future<void> speak(String text, String ttsLocale) async {
    await _tts.stop();
    await _tts.setLanguage(ttsLocale);
    await _tts.speak(text);
  }

  Future<void> stop() async {
    await _tts.stop();
  }
}
