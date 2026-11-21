import 'package:flutter/material.dart';
import 'data/local/database.dart';
import 'features/home/home_screen.dart';

class BolKhataApp extends StatelessWidget {
  final AppDatabase db;
  const BolKhataApp({super.key, required this.db});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BolKhata',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      home: HomeScreen(db: db),
    );
  }
}