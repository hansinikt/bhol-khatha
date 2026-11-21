import 'dart:typed_data';

abstract class SttProvider {
  String get name;
  Future<bool> isAvailable();

  /// [lang]: 'en' | 'hi' | 'kn' | 'te' | 'ta'
  Future<String> transcribe(Uint8List audio, {required String lang});
}

/// TODO: fill in from Gnani's docs (base URL, auth headers, request format).
class GnaniSttProvider implements SttProvider {
  final String apiKey;
  final String baseUrl;
  GnaniSttProvider({required this.apiKey, required this.baseUrl});

  @override
  String get name => 'gnani';

  @override
  Future<bool> isAvailable() async => apiKey.isNotEmpty;

  @override
  Future<String> transcribe(Uint8List audio, {required String lang}) async {
    // 1. POST audio to Gnani's STT endpoint with the language code.
    // 2. Parse the JSON response and return the transcript.
    throw UnimplementedError('Add Gnani endpoint details from their docs.');
  }
}