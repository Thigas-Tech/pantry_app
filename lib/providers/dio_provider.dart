import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/config.dart';

/// Provides a shared [Dio] HTTP client for the entire app.
///
/// A single Dio instance is created with:
/// - 10‑second connect and receive timeouts.
/// - A `User-Agent` header identifying the app and a contact email (required
///   by Open Food Facts).
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'User-Agent': 'PantryApp/1.0 (${AppConfig.contactEmail})',
      },
    ),
  );
  return dio;
});
