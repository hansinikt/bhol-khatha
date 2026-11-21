import 'package:flutter/material.dart';

import 'core/ledger_store.dart';
import 'data/prefs_ledger_store.dart';
import 'ui/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = await PrefsLedgerStore.open();
  runApp(BolKhataApp(store: store));
}

class BolKhataApp extends StatelessWidget {
  final LedgerStore store;

  const BolKhataApp({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BolKhata',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      home: HomeScreen(store: store),
    );
  }
}
