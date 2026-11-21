import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class VoiceRecorder {
  final AudioRecorder _rec = AudioRecorder();
  String? _path;

  /// Returns false if mic permission was denied.
  Future<bool> start() async {
    if (!await _rec.hasPermission()) return false;
    final dir = await getTemporaryDirectory();
    _path = '${dir.path}/utt_${DateTime.now().millisecondsSinceEpoch}.wav';
    await _rec.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
        numChannels: 1,
        noiseSuppress: true,
        autoGain: true,
        echoCancel: true,
      ),
      path: _path!,
    );
    return true;
  }

  Future<Uint8List?> stop() async {
    final p = await _rec.stop();
    if (p == null) return null;
    final f = File(p);
    final bytes = await f.readAsBytes();
    await f.delete();
    return bytes;
  }

  Future<void> dispose() => _rec.dispose();
}