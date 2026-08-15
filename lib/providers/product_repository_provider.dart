import 'package:flutter/widgets.dart';
import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/providers/api_service_provider.dart';
import 'package:pantry_app/providers/cache_staleness_store_provider.dart';
import 'package:pantry_app/providers/database_provider.dart';
import 'package:pantry_app/providers/usda_provider.dart';
import 'package:pantry_app/services/product_repository.dart';
import 'package:pantry_app/services/usda_api_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'product_repository_provider.g.dart';

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
@Riverpod(keepAlive: true)
ProductRepository productRepository(Ref ref) {
  final db = ref.read(databaseProvider);
  final api = ref.read(apiServiceProvider);
  return ProductRepository(
    db,
    api,
    usdaClient: ref.read(usdaApiClientProvider),
    stalenessStore: ref.read(cacheStalenessStoreProvider),
  );
}
