import 'dart:typed_data';
import 'stt_provider.dart';

class OnDeviceSttProvider implements SttProvider {
  @override
  String get name => 'ondevice';

  @override
  Future<bool> isAvailable() async => false; // enable once a model is bundled

  @override
  Future<String> transcribe(Uint8List audio, {required String lang}) async {
    throw SttException('On-device STT not implemented yet');
  }
}
