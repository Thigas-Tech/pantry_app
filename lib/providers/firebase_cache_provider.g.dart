// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'firebase_cache_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the singleton [FirebaseCacheService] instance.
///
/// When [AppConfig.firebaseEnabled] is true, the provider attempts to
/// initialise a [FirebaseFirestoreClientAdapter] wrapping
/// [FirebaseFirestore.instance]. If that call fails (e.g. missing
/// google-services.json), the cache service is created with
/// [FirebaseCacheService.isAvailable] is false and all operations are no-ops.
///
/// When [AppConfig.firebaseEnabled] is false (default), the cache service
/// is created in disabled mode without any Firebase interaction.
///
/// ## Dependencies
///
/// - The database provider for cache metadata.
/// - The API service provider (OFF SDK wrapper).
/// - [UsdaApiClient] for USDA fallback lookups.
///
/// ## Lifetime
///
/// This is a plain keep-alive provider so the service lives for the
/// entire app session. The service is stateless between lookups; it
/// holds no mutable state.

@ProviderFor(firebaseCache)
final firebaseCacheProvider = FirebaseCacheProvider._();

/// Provides the singleton [FirebaseCacheService] instance.
///
/// When [AppConfig.firebaseEnabled] is true, the provider attempts to
/// initialise a [FirebaseFirestoreClientAdapter] wrapping
/// [FirebaseFirestore.instance]. If that call fails (e.g. missing
/// google-services.json), the cache service is created with
/// [FirebaseCacheService.isAvailable] is false and all operations are no-ops.
///
/// When [AppConfig.firebaseEnabled] is false (default), the cache service
/// is created in disabled mode without any Firebase interaction.
///
/// ## Dependencies
///
/// - The database provider for cache metadata.
/// - The API service provider (OFF SDK wrapper).
/// - [UsdaApiClient] for USDA fallback lookups.
///
/// ## Lifetime
///
/// This is a plain keep-alive provider so the service lives for the
/// entire app session. The service is stateless between lookups; it
/// holds no mutable state.

final class FirebaseCacheProvider
    extends
        $FunctionalProvider<
          FirebaseCacheService,
          FirebaseCacheService,
          FirebaseCacheService
        >
    with $Provider<FirebaseCacheService> {
  /// Provides the singleton [FirebaseCacheService] instance.
  ///
  /// When [AppConfig.firebaseEnabled] is true, the provider attempts to
  /// initialise a [FirebaseFirestoreClientAdapter] wrapping
  /// [FirebaseFirestore.instance]. If that call fails (e.g. missing
  /// google-services.json), the cache service is created with
  /// [FirebaseCacheService.isAvailable] is false and all operations are no-ops.
  ///
  /// When [AppConfig.firebaseEnabled] is false (default), the cache service
  /// is created in disabled mode without any Firebase interaction.
  ///
  /// ## Dependencies
  ///
  /// - The database provider for cache metadata.
  /// - The API service provider (OFF SDK wrapper).
  /// - [UsdaApiClient] for USDA fallback lookups.
  ///
  /// ## Lifetime
  ///
  /// This is a plain keep-alive provider so the service lives for the
  /// entire app session. The service is stateless between lookups; it
  /// holds no mutable state.
  FirebaseCacheProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'firebaseCacheProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$firebaseCacheHash();

  @$internal
  @override
  $ProviderElement<FirebaseCacheService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FirebaseCacheService create(Ref ref) {
    return firebaseCache(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FirebaseCacheService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FirebaseCacheService>(value),
    );
  }
}

String _$firebaseCacheHash() => r'68e7d990c003635c751a762a59127cc753c8bade';
