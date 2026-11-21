import 'dart:typed_data';

abstract class SttProvider {
  String get name;
  Future<bool> isAvailable();

  /// [lang]: 'en' | 'hi' | 'kn' | 'te' | 'ta'
  Future<String> transcribe(Uint8List audio, {required String lang});
}

class SttException implements Exception {
  final String message;
  SttException(this.message);
  @override
  String toString() => 'SttException: $message';
}
