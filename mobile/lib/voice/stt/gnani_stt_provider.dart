import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'stt_provider.dart';

class GnaniSttProvider implements SttProvider {
  final String apiKey;
  final String baseUrl;
  GnaniSttProvider({required this.apiKey, required this.baseUrl});

  // TODO: confirm Gnani's real language codes.
  static const _langCodes = {
    'en': 'en-IN',
    'hi': 'hi-IN',
    'kn': 'kn-IN',
    'te': 'te-IN',
    'ta': 'ta-IN',
  };

  @override
  String get name => 'gnani';

  @override
  Future<bool> isAvailable() async => apiKey.isNotEmpty && baseUrl.isNotEmpty;

  @override
  Future<String> transcribe(Uint8List audio, {required String lang}) async {
    final req = http.MultipartRequest('POST', Uri.parse(baseUrl))
      // TODO: use Gnani's real auth header names.
      ..headers['Authorization'] = 'Bearer $apiKey'
      ..fields['language'] = _langCodes[lang] ?? 'hi-IN'
      ..files.add(http.MultipartFile.fromBytes('audio', audio, filename: 'speech.wav'));

    final streamed = await req.send().timeout(const Duration(seconds: 15));
    final body = await streamed.stream.bytesToString();
    if (streamed.statusCode != 200) {
      throw SttException('Gnani HTTP ${streamed.statusCode}: $body');
    }
    final json = jsonDecode(body) as Map<String, dynamic>;
    // TODO: use the real response field name from Gnani's docs.
    final text = (json['transcript'] ?? json['text'] ?? '') as String;
    if (text.trim().isEmpty) throw SttException('Empty transcript');
    return text;
  }
}