import 'package:flutter/foundation.dart';

/// Represents an authenticated user.
///
/// For anonymous auth [isAnonymous] is true and [email]/[displayName] are
/// typically null. Non-anonymous (Google/email) auth is supported for future
/// migration — simply construct with isAnonymous: false and the relevant
/// fields.
@immutable
class AuthUser {
  /// Creates an [AuthUser] with the given properties.
  const AuthUser({
    required this.uid,
    this.isAnonymous = true,
    this.email,
    this.displayName,
  });

  /// Unique Firebase Auth UID.
  final String uid;

  /// Whether this user signed in anonymously.
  final bool isAnonymous;

  /// Email address, if the user signed in with a provider that exposes it.
  final String? email;

  /// Display name, if the user's provider exposes it.
  final String? displayName;

  /// Creates a copy with the given fields replaced.
  AuthUser copyWith({
    String? uid,
    bool? isAnonymous,
    String? email,
    String? displayName,
  }) => AuthUser(
    uid: uid ?? this.uid,
    isAnonymous: isAnonymous ?? this.isAnonymous,
    email: email ?? this.email,
    displayName: displayName ?? this.displayName,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthUser &&
          uid == other.uid &&
          isAnonymous == other.isAnonymous &&
          email == other.email &&
          displayName == other.displayName;

  @override
  int get hashCode => Object.hash(uid, isAnonymous, email, displayName);

  @override
  String toString() =>
      'AuthUser(uid: $uid, isAnonymous: $isAnonymous, email: $email)';
}
