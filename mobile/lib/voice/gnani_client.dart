// Gnani Vachana REST client (speech-to-text + text-to-speech).
// Every endpoint, header and field name below comes from docs.gnani.ai
// (STT: /api/STT/speech-to-text, TTS: /api/TTS/tts-inference). Do not change them.
//
// Run with:  flutter run --dart-define=GNANI_API_KEY=your_key

import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

class GnaniConfig {
  static const String apiKey = String.fromEnvironment('GNANI_API_KEY');
  static bool get enabled => apiKey.isNotEmpty;

  /// Text-to-speech model and voice. timbre-v3.0 voices speak all 10 languages.
  static const String ttsModel = 'timbre-v3.0';
  static const String ttsVoice = 'Shivani';
}

class GnaniException implements Exception {
  final int statusCode;
  final String body;
  GnaniException(this.statusCode, this.body);

  @override
  String toString() => 'Gnani HTTP $statusCode: $body';
}

class GnaniClient {
  static const String sttUrl = 'https://api.vachana.ai/stt/v3';
  static const String ttsUrl = 'https://api.vachana.ai/api/v1/tts/inference';

  final String apiKey;
  final http.Client _http;

  GnaniClient(this.apiKey, {http.Client? client})
      : _http = client ?? http.Client();

  /// App language code -> Gnani language_code.
  /// prisma-v3.0 accepts up to 4 comma-separated languages, so we add en-IN
  /// to every Indian language to handle code-mixed speech (Hinglish etc.).
  static String sttLanguageCode(String appLang) => switch (appLang) {
        'hi' => 'hi-IN,en-IN',
        'kn' => 'kn-IN,en-IN',
        'te' => 'te-IN,en-IN',
        'ta' => 'ta-IN,en-IN',
        _ => 'en-IN',
      };

  /// [wav] = 16 kHz mono WAV, max 30 seconds. Returns '' if no speech.
  Future<String> transcribe(Uint8List wav, {required String appLang}) async {
    final req = http.MultipartRequest('POST', Uri.parse(sttUrl))
      ..headers['X-API-Key-ID'] = apiKey
      ..fields['model'] = 'prisma-v3.0'
      ..fields['language_code'] = sttLanguageCode(appLang)
      ..files.add(http.MultipartFile.fromBytes(
        'audio_file',
        wav,
        filename: 'speech.wav',
      ));

    final streamed = await _http.send(req).timeout(const Duration(seconds: 20));
    final res = await http.Response.fromStream(streamed);
    final body = utf8.decode(res.bodyBytes);
    if (res.statusCode != 200) throw GnaniException(res.statusCode, body);

    final json = jsonDecode(body) as Map<String, dynamic>;
    if (json['success'] == false) throw GnaniException(200, body);
    return ((json['transcript'] as String?) ?? '').trim();
  }

  /// Returns WAV bytes. [language] like 'hi-IN' (same as our ttsLocale).
  Future<Uint8List> synthesize(String text, {required String language}) async {
    final res = await _http
        .post(
          Uri.parse(ttsUrl),
          headers: {
            'X-API-Key-ID': apiKey,
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'text': text,
            'model': GnaniConfig.ttsModel,
            'voice': GnaniConfig.ttsVoice,
            'language': language,
            'audio_config': {
              'sample_rate': 22050,
              'container': 'wav',
            },
          }),
        )
        .timeout(const Duration(seconds: 20));
    if (res.statusCode != 200) {
      throw GnaniException(res.statusCode, utf8.decode(res.bodyBytes));
    }
    return res.bodyBytes;
  }
}
