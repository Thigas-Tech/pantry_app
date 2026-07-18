import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/config.dart';
import 'package:pantry_app/models/auth_user.dart';
import 'package:pantry_app/services/auth_service.dart';
import 'package:pantry_app/services/firebase_auth_service.dart';
import 'package:pantry_app/utils/logger.dart';

/// Provides the singleton [AuthService] instance.
///
/// When `FIREBASE_ENABLED=true`, this creates a FirebaseAuthService backed
/// by FirebaseAuth.instance. Anonymous sign-in happens in main() before
/// the widget tree mounts, so the service is ready from the first frame.
///
/// ## Lifetime
///
/// Plain [Provider] (not auto-dispose) — the service lives for the entire
/// app session. This matches the pattern used by the firebase cache
/// provider.
final authServiceProvider = Provider<AuthService>((ref) {
  if (AppConfig.firebaseEnabled) {
    try {
      return FirebaseAuthService(FirebaseAuth.instance);
    } on Exception catch (e) {
      logWarning('FirebaseAuthService creation failed: $e');
    }
  }
  return _NoopAuthService();
});

/// Provides a reactive stream of the current [AuthUser] or `null`.
///
/// Delegates to [AuthService.authStateChanges]. Starts as [AsyncLoading]
/// until the first auth state event is emitted.
final authStateProvider = StreamProvider<AuthUser?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

/// No-op implementation used when Firebase is disabled.
class _NoopAuthService implements AuthService {
  @override
  Future<AuthUser?> signInAnonymously() async => null;

  @override
  Future<void> signOut() async {}

  @override
  Stream<AuthUser?> get authStateChanges => const Stream.empty();

  @override
  AuthUser? get currentUser => null;
}
