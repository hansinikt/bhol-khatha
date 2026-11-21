import 'package:flutter/material.dart';
import 'app.dart';
import 'core/security/key_store.dart';
import 'data/local/database.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final key = await KeyStore.getOrCreateDbKey();
  runApp(BolKhataApp(db: AppDatabase(key)));
}