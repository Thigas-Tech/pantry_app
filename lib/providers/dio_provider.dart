import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides a shared [Dio] HTTP client for the entire app.
///
/// A single Dio instance is created with:
/// - 10‑second connect and receive timeouts.
/// - A `User-Agent` header identifying the app and a contact email (required
///   by Open Food Facts).
///
/// ## Why a shared instance?
///
/// Using a single Dio instance allows:
/// - Consistent configuration (timeouts, headers).
/// - Interceptors (e.g., logging, retry) to be added in one place.
/// - Connection reuse (HTTP keep‑alive), which improves performance.
///
/// ## Future improvements
///
/// - Add an interceptor to log network calls in debug mode.
/// - Add a retry interceptor for transient failures.
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'User-Agent': 'PantryApp/1.0 (thiago.assisfernandes@gmail.com)',
      },
    ),
  );
  return dio;
});
