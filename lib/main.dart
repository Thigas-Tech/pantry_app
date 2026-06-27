import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/screens/home_screen.dart';
import 'package:pantry_app/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  unawaited(NotificationService.initialize());
  unawaited(NotificationService.requestPermission()); // one‑time prompt

  // Run database cleanup
  final dbHelper = DatabaseHelper();
  await dbHelper.cleanupOldEntries();

  runApp(const ProviderScope(child: PantryApp()));
}

class PantryApp extends StatelessWidget {
  const PantryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pantry',
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      home: const HomeScreen(),
    );
  }
}
