// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_repository_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the single [ProductRepository] instance used throughout the app.
///
/// The repository combines the local database (from [databaseProvider]),
/// the Open Food Facts SDK adapter (from [apiServiceProvider]), and the
/// USDA FoodData Central API client to implement offline-first product
/// lookup and produce quick-add with nutrition data.
///
/// When the Firebase cache provider creates a [FirebaseCacheService] where
/// [FirebaseCacheService.isAvailable] is true, the repository also consults
/// the shared Firebase cache before falling through to the primary API.
///
/// ## Dependencies
///
/// - [databaseProvider] — supplies the [DatabaseHelper] singleton for local
///   caching and inventory operations.
/// - [apiServiceProvider] — supplies the configured OFF SDK adapter for
///   fetching product data from the internet.
/// - [UsdaApiClient] — created inline for the USDA nutrition lookup
///   fallback chain.
///
/// ## Lifetime
///
/// Because this is a keep-alive provider (not autoDispose), the repository
/// is created **once** and reused for the entire app session. The
/// repository itself holds no mutable state; it delegates all storage to
/// the database and all network requests to the SDK adapter.
///
/// ## Usage
///
/// Typically accessed via ref.read(productRepositoryProvider) in async
/// callbacks (like the scan flow) or via ref.watch(productRepositoryProvider)
/// in widgets that need to call repository methods inside [FutureBuilder]s.

@ProviderFor(productRepository)
final productRepositoryProvider = ProductRepositoryProvider._();

/// Provides the single [ProductRepository] instance used throughout the app.
///
/// The repository combines the local database (from [databaseProvider]),
/// the Open Food Facts SDK adapter (from [apiServiceProvider]), and the
/// USDA FoodData Central API client to implement offline-first product
/// lookup and produce quick-add with nutrition data.
///
/// When the Firebase cache provider creates a [FirebaseCacheService] where
/// [FirebaseCacheService.isAvailable] is true, the repository also consults
/// the shared Firebase cache before falling through to the primary API.
///
/// ## Dependencies
///
/// - [databaseProvider] — supplies the [DatabaseHelper] singleton for local
///   caching and inventory operations.
/// - [apiServiceProvider] — supplies the configured OFF SDK adapter for
///   fetching product data from the internet.
/// - [UsdaApiClient] — created inline for the USDA nutrition lookup
///   fallback chain.
///
/// ## Lifetime
///
/// Because this is a keep-alive provider (not autoDispose), the repository
/// is created **once** and reused for the entire app session. The
/// repository itself holds no mutable state; it delegates all storage to
/// the database and all network requests to the SDK adapter.
///
/// ## Usage
///
/// Typically accessed via ref.read(productRepositoryProvider) in async
/// callbacks (like the scan flow) or via ref.watch(productRepositoryProvider)
/// in widgets that need to call repository methods inside [FutureBuilder]s.

final class ProductRepositoryProvider
    extends
        $FunctionalProvider<
          ProductRepository,
          ProductRepository,
          ProductRepository
        >
    with $Provider<ProductRepository> {
  /// Provides the single [ProductRepository] instance used throughout the app.
  ///
  /// The repository combines the local database (from [databaseProvider]),
  /// the Open Food Facts SDK adapter (from [apiServiceProvider]), and the
  /// USDA FoodData Central API client to implement offline-first product
  /// lookup and produce quick-add with nutrition data.
  ///
  /// When the Firebase cache provider creates a [FirebaseCacheService] where
  /// [FirebaseCacheService.isAvailable] is true, the repository also consults
  /// the shared Firebase cache before falling through to the primary API.
  ///
  /// ## Dependencies
  ///
  /// - [databaseProvider] — supplies the [DatabaseHelper] singleton for local
  ///   caching and inventory operations.
  /// - [apiServiceProvider] — supplies the configured OFF SDK adapter for
  ///   fetching product data from the internet.
  /// - [UsdaApiClient] — created inline for the USDA nutrition lookup
  ///   fallback chain.
  ///
  /// ## Lifetime
  ///
  /// Because this is a keep-alive provider (not autoDispose), the repository
  /// is created **once** and reused for the entire app session. The
  /// repository itself holds no mutable state; it delegates all storage to
  /// the database and all network requests to the SDK adapter.
  ///
  /// ## Usage
  ///
  /// Typically accessed via ref.read(productRepositoryProvider) in async
  /// callbacks (like the scan flow) or via ref.watch(productRepositoryProvider)
  /// in widgets that need to call repository methods inside [FutureBuilder]s.
  ProductRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'productRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$productRepositoryHash();

  @$internal
  @override
  $ProviderElement<ProductRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ProductRepository create(Ref ref) {
    return productRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProductRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProductRepository>(value),
    );
  }
}

String _$productRepositoryHash() => r'ed81001b982bab0c88f9ebea616d572819c7010f';
