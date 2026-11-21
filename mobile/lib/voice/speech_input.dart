// Speech-to-text using the phone's built-in recognizer (package: speech_to_text).
// PROTOTYPE: needs internet for kn/te/ta on most phones. Gnani replaces this later
// behind the same start()/stop() shape.

import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

class SpeechInput {
  final SpeechToText _stt = SpeechToText();
  bool _ready = false;
  VoidCallback? _onDone;

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
        _onDone?.call();
      },
    );
    return _ready;
  }

  bool get isListening => _stt.isListening;

  /// Starts listening. [onResult] gets partial text (isFinal=false) and then
  /// the final text (isFinal=true). [onDone] fires when listening stops.
  /// Returns false if speech recognition is not available on this device.
  Future<bool> start({
    required String localeId,
    required void Function(String text, bool isFinal) onResult,
    VoidCallback? onDone,
  }) async {
    if (!await init()) return false;
    _onDone = onDone;
    await _stt.listen(
      onResult: (SpeechRecognitionResult r) =>
          onResult(r.recognizedWords, r.finalResult),
      localeId: localeId,
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

  Future<void> stop() => _stt.stop();
}
