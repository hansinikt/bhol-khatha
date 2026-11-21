// Records the mic to a 16 kHz mono WAV (same settings as Mrudhula's recorder),
// then sends it to Gnani when stop() is called.

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../l10n/languages.dart';
import 'gnani_client.dart';
import 'voice_input.dart';

class GnaniSpeechInput implements VoiceInput {
  final GnaniClient _client;
  final AudioRecorder _rec = AudioRecorder();

  void Function(String text, bool isFinal)? _onResult;
  VoidCallback? _onDone;
  String _appLang = 'hi';
  bool _recording = false;
  Timer? _cap;
  String? _lastError;

  GnaniSpeechInput(this._client);

  @override
  String get engineName => 'Gnani';

  @override
  String? get lastError => _lastError;

  @override
  Future<bool> start({
    required AppLanguage lang,
    required void Function(String text, bool isFinal) onResult,
    VoidCallback? onDone,
  }) async {
    _lastError = null;
    if (!await _rec.hasPermission()) {
      _lastError = 'Microphone permission denied';
      return false;
    }
    _onResult = onResult;
    _onDone = onDone;
    _appLang = lang.code;

    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/utt_${DateTime.now().millisecondsSinceEpoch}.wav';
    await _rec.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
        numChannels: 1,
        noiseSuppress: true,
        autoGain: true,
        echoCancel: true,
      ),
      path: path,
    );
    _recording = true;
    // Gnani REST accepts max 30 s. Stop at 25 s to be safe.
    _cap = Timer(const Duration(seconds: 25), stop);
    return true;
  }

  @override
  Future<void> stop() async {
    if (!_recording) return;
    _recording = false;
    _cap?.cancel();
    final onResult = _onResult;
    try {
      final path = await _rec.stop();
      if (path == null) {
        _lastError = 'No audio recorded';
        onResult?.call('', true);
        return;
      }
      final file = File(path);
      final bytes = await file.readAsBytes();
      await file.delete();
      final text = await _client.transcribe(bytes, appLang: _appLang);
      onResult?.call(text, true);
    } catch (e) {
      debugPrint('Gnani STT error: $e');
      _lastError = '$e';
      onResult?.call('', true);
    } finally {
      _onDone?.call();
    }
  }
}
