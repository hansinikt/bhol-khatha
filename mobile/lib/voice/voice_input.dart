// Common shape for every speech-to-text engine (phone recognizer or Gnani).
// HomeScreen only talks to this interface.

import 'package:flutter/foundation.dart';

import '../l10n/languages.dart';

abstract class VoiceInput {
  /// Short label shown in the app bar, e.g. 'Gnani' or 'Phone'.
  String get engineName;

  /// Last error message, for showing in a SnackBar. Null if none.
  String? get lastError;

  /// Start listening. [onResult] may be called with partial text
  /// (isFinal=false) and is always called once with isFinal=true
  /// (text may be empty if nothing was understood).
  /// Returns false if the mic/engine is not available.
  Future<bool> start({
    required AppLanguage lang,
    required void Function(String text, bool isFinal) onResult,
    VoidCallback? onDone,
  });

  /// Stop listening. For Gnani this uploads the audio and waits for the text.
  Future<void> stop();
}
