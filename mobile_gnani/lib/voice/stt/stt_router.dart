import 'dart:typed_data';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'stt_provider.dart';

class SttRouter {
  final List<SttProvider> online;
  final SttProvider? offline;
  SttRouter({required this.online, this.offline});

  Future<String> transcribe(Uint8List audio, {required String lang}) async {
    final conn = await Connectivity().checkConnectivity();
    final isOnline = !conn.contains(ConnectivityResult.none);

    final order = <SttProvider>[
      if (isOnline) ...online,
      if (offline != null) offline!,
    ];
    final errors = <String>[];
    for (final p in order) {
      try {
        if (!await p.isAvailable()) {
          errors.add('${p.name}: unavailable');
          continue;
        }
        return await p.transcribe(audio, lang: lang);
      } catch (e) {
        errors.add('${p.name}: $e');
      }
    }
    throw SttException(
        errors.isEmpty ? 'No STT provider available' : errors.join(' | '));
  }
}
