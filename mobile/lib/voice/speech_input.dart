// Speech-to-text using the phone's built-in recognizer (package: speech_to_text).
// Used when no GNANI_API_KEY is given, or as the fallback engine.

import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../l10n/languages.dart';
import 'voice_input.dart';

class SpeechInput implements VoiceInput {
  final SpeechToText _stt = SpeechToText();
  bool _ready = false;
  VoidCallback? _onDone;
  String? _lastError;

  @override
  String get engineName => 'Phone';

  @override
  String? get lastError => _lastError;

  Future<bool> init() async {
    if (_ready) return true;
    _ready = await _stt.initialize(
      onStatus: (status) {
        debugPrint('STT status: $status');
        if (status == SpeechToText.doneStatus ||
            status == SpeechToText.notListeningStatus) {
          _onDone?.call();
        }
      },
      onError: (SpeechRecognitionError e) {
        debugPrint('STT error: ${e.errorMsg} permanent=${e.permanent}');
        _lastError = e.errorMsg;
        _onDone?.call();
      },
    );
    return _ready;
  }

  @override
  Future<bool> start({
    required AppLanguage lang,
    required void Function(String text, bool isFinal) onResult,
    VoidCallback? onDone,
  }) async {
    _lastError = null;
    if (!await init()) {
      _lastError = 'Speech recognition not available';
      return false;
    }
    _onDone = onDone;
    await _stt.listen(
      onResult: (SpeechRecognitionResult r) =>
          onResult(r.recognizedWords, r.finalResult),
      localeId: lang.sttLocale,
      listenFor: const Duration(seconds: 20),
      pauseFor: const Duration(seconds: 3),
      listenOptions: SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
        listenMode: ListenMode.dictation,
      ),
    );
    return true;
  }

  @override
  Future<void> stop() => _stt.stop();
}
