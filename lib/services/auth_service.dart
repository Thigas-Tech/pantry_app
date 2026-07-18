import 'dart:async';

import 'package:pantry_app/models/auth_user.dart';

/// Abstract interface for authentication.
///
/// The app depends on this interface, never on FirebaseAuth directly.
/// This makes testing trivial and enables future migration to non-anonymous
/// auth (Google, email) by swapping the implementation.
///
/// ## Future migration
///
/// To add Google sign-in, extend this interface with methods like:
/// ```dart
/// Future<AuthUser?> signInWithGoogle();
/// ```
/// and create a GoogleAuthService that implements them. The rest of the
/// app is unaffected because it already depends on [AuthService].
abstract class AuthService {
  /// Signs in anonymously and returns an [AuthUser] on success, or `null` on
  /// failure (network error, Firebase misconfiguration, etc.).
  Future<AuthUser?> signInAnonymously();

  /// Signs the current user out.
  Future<void> signOut();

  /// Stream that emits the current [AuthUser] or `null` when signed out.
  Stream<AuthUser?> get authStateChanges;

  /// The currently signed-in user, or `null` if not signed in.
  AuthUser? get currentUser;
}
