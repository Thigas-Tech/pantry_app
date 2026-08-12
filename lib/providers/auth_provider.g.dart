// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the singleton [AuthService] instance.
///
/// When FIREBASE_ENABLED=true, this creates a FirebaseAuthService backed
/// by FirebaseAuth.instance. Anonymous sign-in happens in main() before
/// the widget tree mounts, so the service is ready from the first frame.
///
/// ## Lifetime
///
/// Plain keep-alive provider — the service lives for the entire
/// app session. This matches the pattern used by the firebase cache
/// provider.

@ProviderFor(authService)
final authServiceProvider = AuthServiceProvider._();

/// Provides the singleton [AuthService] instance.
///
/// When FIREBASE_ENABLED=true, this creates a FirebaseAuthService backed
/// by FirebaseAuth.instance. Anonymous sign-in happens in main() before
/// the widget tree mounts, so the service is ready from the first frame.
///
/// ## Lifetime
///
/// Plain keep-alive provider — the service lives for the entire
/// app session. This matches the pattern used by the firebase cache
/// provider.

final class AuthServiceProvider
    extends $FunctionalProvider<AuthService, AuthService, AuthService>
    with $Provider<AuthService> {
  /// Provides the singleton [AuthService] instance.
  ///
  /// When FIREBASE_ENABLED=true, this creates a FirebaseAuthService backed
  /// by FirebaseAuth.instance. Anonymous sign-in happens in main() before
  /// the widget tree mounts, so the service is ready from the first frame.
  ///
  /// ## Lifetime
  ///
  /// Plain keep-alive provider — the service lives for the entire
  /// app session. This matches the pattern used by the firebase cache
  /// provider.
  AuthServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authServiceHash();

  @$internal
  @override
  $ProviderElement<AuthService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AuthService create(Ref ref) {
    return authService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthService>(value),
    );
  }
}

String _$authServiceHash() => r'6059360b7c9687d90771b339990ccb6f64f4e448';

/// Provides a reactive stream of the current [AuthUser] or null.
///
/// Delegates to [AuthService.authStateChanges]. Starts as [AsyncLoading]
/// until the first auth state event is emitted.

@ProviderFor(authState)
final authStateProvider = AuthStateProvider._();

/// Provides a reactive stream of the current [AuthUser] or null.
///
/// Delegates to [AuthService.authStateChanges]. Starts as [AsyncLoading]
/// until the first auth state event is emitted.

final class AuthStateProvider
    extends
        $FunctionalProvider<AsyncValue<AuthUser?>, AuthUser?, Stream<AuthUser?>>
    with $FutureModifier<AuthUser?>, $StreamProvider<AuthUser?> {
  /// Provides a reactive stream of the current [AuthUser] or null.
  ///
  /// Delegates to [AuthService.authStateChanges]. Starts as [AsyncLoading]
  /// until the first auth state event is emitted.
  AuthStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authStateProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authStateHash();

  @$internal
  @override
  $StreamProviderElement<AuthUser?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<AuthUser?> create(Ref ref) {
    return authState(ref);
  }
}

String _$authStateHash() => r'fd4a1d828c393961ec8d1aadf379df6100ccc312';
