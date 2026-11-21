// Text-to-speech. Uses Gnani Timbre when GNANI_API_KEY is set, and falls back
// to the phone's TTS engine (flutter_tts) if Gnani fails or no key is given.

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'gnani_client.dart';

class SpeechOutput {
  final FlutterTts _tts = FlutterTts();
  final AudioPlayer _player = AudioPlayer();
  final GnaniClient? _gnani;

  /// Pass a GnaniClient to speak with Gnani; null = phone TTS only.
  SpeechOutput({GnaniClient? gnani}) : _gnani = gnani;

  Future<void> init() async {
    await _tts.awaitSpeakCompletion(true);
    await _tts.setSpeechRate(0.45);
  }

  /// [ttsLocale] like 'hi-IN'. Waits until speaking is finished.
  Future<void> speak(String text, String ttsLocale) async {
    await stop();
    final gnani = _gnani;
    if (gnani != null) {
      try {
        final wav = await gnani.synthesize(text, language: ttsLocale);
        await _player.play(BytesSource(wav));
        await _player.onPlayerComplete.first
            .timeout(const Duration(seconds: 30));
        return;
      } catch (e) {
        debugPrint('Gnani TTS failed, using phone TTS: $e');
      }
    }
    await _tts.setLanguage(ttsLocale);
    await _tts.speak(text);
  }

  Future<void> stop() async {
    await _player.stop();
    await _tts.stop();
  }
}
