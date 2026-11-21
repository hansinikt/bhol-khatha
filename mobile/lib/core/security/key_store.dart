import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class KeyStore {
  static const _storage = FlutterSecureStorage();
  static const _keyName = 'db_key';

  /// Random 256-bit key (hex), created once and kept in the Android keystore.
  static Future<String> getOrCreateDbKey() async {
    var key = await _storage.read(key: _keyName);
    if (key == null) {
      final r = Random.secure();
      key = List.generate(32, (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
      await _storage.write(key: _keyName, value: key);
    }
    return key;
  }
}