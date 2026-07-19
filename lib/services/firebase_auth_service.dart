import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:pantry_app/models/auth_user.dart';
import 'package:pantry_app/services/auth_service.dart';
import 'package:pantry_app/utils/logger.dart';

/// [AuthService] implementation backed by Firebase Authentication.
///
/// Uses FirebaseAuth for anonymous sign-in and streams auth state changes.
/// All failures are caught and logged — the service returns `null` instead of
/// throwing, following the app's graceful degradation pattern.
///
/// ## Future migration
///
/// To add Google sign-in, add a method:
/// ```dart
/// Future<AuthUser?> signInWithGoogle() async { ... }
/// ```
/// and use `FirebaseAuth.instance.currentUser!.linkWithCredential` to preserve
/// anonymous data under the permanent account.
class FirebaseAuthService implements AuthService {
  /// Creates a [FirebaseAuthService] implementing [AuthService] using the
  /// given Firebase Auth instance.
  FirebaseAuthService(this._auth)
    : _controller = StreamController<AuthUser?>.broadcast() {
    _authSubscription = _auth.authStateChanges().listen(
      _onAuthStateChanged,
      onError: _onAuthError,
    );
  }

  final fb.FirebaseAuth _auth;
  AuthUser? _currentUser;
  final StreamController<AuthUser?> _controller;
  StreamSubscription<fb.User?>? _authSubscription;

  void _onAuthStateChanged(fb.User? firebaseUser) {
    if (firebaseUser != null) {
      _currentUser = _fromFirebaseUser(firebaseUser);
    } else {
      _currentUser = null;
    }
    _controller.add(_currentUser);
  }

  void _onAuthError(Object error) {
    logError('Auth state stream error: $error');
    _currentUser = null;
    _controller.add(null);
  }

  @override
  Future<AuthUser?> signInAnonymously() async {
    final existing = _auth.currentUser;
    if (existing != null) {
      return _currentUser = _fromFirebaseUser(existing);
    }
    try {
      final cred = await _auth.signInAnonymously();
      final firebaseUser = cred.user;
      if (firebaseUser == null) {
        logWarning('Anonymous sign-in succeeded but user is null');
        return null;
      }
      return _fromFirebaseUser(firebaseUser);
    } on fb.FirebaseAuthException catch (e) {
      logWarning('Anonymous sign-in failed (auth exception): ${e.code}');
      return null;
    } on Exception catch (e) {
      logWarning('Anonymous sign-in failed: $e');
      return null;
    }
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
  }

  @override
  Stream<AuthUser?> get authStateChanges => _controller.stream;

  @override
  AuthUser? get currentUser => _currentUser;

  AuthUser _fromFirebaseUser(fb.User user) => AuthUser(
    uid: user.uid,
    isAnonymous: user.isAnonymous,
    email: user.email,
    displayName: user.displayName,
  );

  /// Disposes the internal stream subscription.
  ///
  /// Call when the service is no longer needed (e.g., app lifecycle end).
  void dispose() {
    unawaited(_authSubscription?.cancel());
    unawaited(_controller.close());
  }
}
