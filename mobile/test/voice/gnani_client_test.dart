import 'dart:convert';

import 'package:bolkhata/voice/gnani_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('STT request uses the exact Gnani header, fields and URL', () async {
    late http.Request seen;
    final client = MockClient((req) async {
      seen = req;
      return http.Response(
        jsonEncode({'success': true, 'transcript': 'Ramesh ne 340 udhaar liya'}),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final gnani = GnaniClient('test-key', client: client);

    final text = await gnani.transcribe(
      utf8.encode('RIFF-fake-wav'),
      appLang: 'hi',
    );

    expect(text, 'Ramesh ne 340 udhaar liya');
    expect(seen.url.toString(), 'https://api.vachana.ai/stt/v3');
    expect(seen.headers['X-API-Key-ID'], 'test-key');
    final body = utf8.decode(seen.bodyBytes, allowMalformed: true);
    expect(body, contains('name="audio_file"'));
    expect(body, contains('name="language_code"'));
    expect(body, contains('hi-IN,en-IN'));
    expect(body, contains('prisma-v3.0'));
  });

  test('STT non-200 throws GnaniException', () async {
    final client = MockClient((_) async => http.Response('{"detail":"bad key"}', 401));
    final gnani = GnaniClient('bad', client: client);
    expect(
      () => gnani.transcribe(utf8.encode('x'), appLang: 'en'),
      throwsA(isA<GnaniException>()),
    );
  });

  test('TTS request body has model, voice, language, audio_config', () async {
    late http.Request seen;
    final client = MockClient((req) async {
      seen = req;
      return http.Response.bytes([1, 2, 3], 200);
    });
    final gnani = GnaniClient('test-key', client: client);

    final wav = await gnani.synthesize('नमस्ते', language: 'hi-IN');

    expect(wav, [1, 2, 3]);
    expect(seen.url.toString(), 'https://api.vachana.ai/api/v1/tts/inference');
    expect(seen.headers['X-API-Key-ID'], 'test-key');
    final json = jsonDecode(seen.body) as Map<String, dynamic>;
    expect(json['model'], 'timbre-v3.0');
    expect(json['voice'], 'Shivani');
    expect(json['language'], 'hi-IN');
    expect((json['audio_config'] as Map)['container'], 'wav');
  });

  test('language codes', () {
    expect(GnaniClient.sttLanguageCode('kn'), 'kn-IN,en-IN');
    expect(GnaniClient.sttLanguageCode('en'), 'en-IN');
  });
}
