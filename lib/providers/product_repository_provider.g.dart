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
/// lookup and produce quick-add with nutrition data. The local SQLite
/// database is the only cache; the cacheStalenessStoreProvider tracks when
/// the background inventory refresh last ran.
///
/// ## Dependencies
///
/// - [databaseProvider] — supplies the [DatabaseHelper] singleton for local
///   caching and inventory operations.
/// - [apiServiceProvider] — supplies the configured OFF SDK adapter for
///   fetching product data from the internet.
/// - [cacheStalenessStoreProvider] — supplies the SharedPreferences-backed
///   store that records the last inventory refresh.
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
/// lookup and produce quick-add with nutrition data. The local SQLite
/// database is the only cache; the cacheStalenessStoreProvider tracks when
/// the background inventory refresh last ran.
///
/// ## Dependencies
///
/// - [databaseProvider] — supplies the [DatabaseHelper] singleton for local
///   caching and inventory operations.
/// - [apiServiceProvider] — supplies the configured OFF SDK adapter for
///   fetching product data from the internet.
/// - [cacheStalenessStoreProvider] — supplies the SharedPreferences-backed
///   store that records the last inventory refresh.
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
  /// lookup and produce quick-add with nutrition data. The local SQLite
  /// database is the only cache; the cacheStalenessStoreProvider tracks when
  /// the background inventory refresh last ran.
  ///
  /// ## Dependencies
  ///
  /// - [databaseProvider] — supplies the [DatabaseHelper] singleton for local
  ///   caching and inventory operations.
  /// - [apiServiceProvider] — supplies the configured OFF SDK adapter for
  ///   fetching product data from the internet.
  /// - [cacheStalenessStoreProvider] — supplies the SharedPreferences-backed
  ///   store that records the last inventory refresh.
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

String _$productRepositoryHash() => r'3fd599e9c90dabd5b12c1fb87c48952af437894c';

/// Provides the cached [Product] for a [barcode], or null.
///
/// Reads only from the local cache (never the network) so list tiles can
/// resolve product metadata — such as the image URL — cheaply while
/// rendering. Keyed by barcode so rebuilds share one lookup.

@ProviderFor(productByBarcode)
final productByBarcodeProvider = ProductByBarcodeFamily._();

/// Provides the cached [Product] for a [barcode], or null.
///
/// Reads only from the local cache (never the network) so list tiles can
/// resolve product metadata — such as the image URL — cheaply while
/// rendering. Keyed by barcode so rebuilds share one lookup.

final class ProductByBarcodeProvider
    extends
        $FunctionalProvider<AsyncValue<Product?>, Product?, FutureOr<Product?>>
    with $FutureModifier<Product?>, $FutureProvider<Product?> {
  /// Provides the cached [Product] for a [barcode], or null.
  ///
  /// Reads only from the local cache (never the network) so list tiles can
  /// resolve product metadata — such as the image URL — cheaply while
  /// rendering. Keyed by barcode so rebuilds share one lookup.
  ProductByBarcodeProvider._({
    required ProductByBarcodeFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'productByBarcodeProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$productByBarcodeHash();

  @override
  String toString() {
    return r'productByBarcodeProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Product?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Product?> create(Ref ref) {
    final argument = this.argument as String;
    return productByBarcode(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ProductByBarcodeProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$productByBarcodeHash() => r'97b451e75730d7de9def067eacb67c57eb79d9d1';

/// Provides the cached [Product] for a [barcode], or null.
///
/// Reads only from the local cache (never the network) so list tiles can
/// resolve product metadata — such as the image URL — cheaply while
/// rendering. Keyed by barcode so rebuilds share one lookup.

final class ProductByBarcodeFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Product?>, String> {
  ProductByBarcodeFamily._()
    : super(
        retry: null,
        name: r'productByBarcodeProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provides the cached [Product] for a [barcode], or null.
  ///
  /// Reads only from the local cache (never the network) so list tiles can
  /// resolve product metadata — such as the image URL — cheaply while
  /// rendering. Keyed by barcode so rebuilds share one lookup.

  ProductByBarcodeProvider call(String barcode) =>
      ProductByBarcodeProvider._(argument: barcode, from: this);

  @override
  String toString() => r'productByBarcodeProvider';
}
