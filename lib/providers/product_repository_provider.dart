import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/providers/api_service_provider.dart';
import 'package:pantry_app/providers/database_provider.dart';
import 'package:pantry_app/providers/firebase_cache_provider.dart';
import 'package:pantry_app/services/firebase_cache_service.dart';
import 'package:pantry_app/services/product_repository.dart';
import 'package:pantry_app/services/usda_api_client.dart';

/// Provides the single [ProductRepository] instance used throughout the app.
///
/// The repository combines the local database (from [databaseProvider]),
/// the Open Food Facts SDK adapter (from [apiServiceProvider]), and the
/// USDA FoodData Central API client to implement offline-first product
/// lookup and produce quick-add with nutrition data.
///
/// When the Firebase cache provider creates a [FirebaseCacheService] with
/// `isAvailable == true`, the repository also consults the shared Firebase
/// cache before falling through to the primary API.
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
/// Because this is a [Provider] (not a [FutureProvider] or [NotifierProvider]),
/// the repository is created **once** and reused for the entire app session.
/// The repository itself holds no mutable state; it delegates all storage to
/// the database and all network requests to the SDK adapter.
///
/// ## Usage
///
/// Typically accessed via `ref.read(productRepositoryProvider)` in async
/// callbacks (like the scan flow) or via `ref.watch(productRepositoryProvider)`
/// in widgets that need to call repository methods inside [FutureBuilder]s.
final productRepositoryProvider = Provider<ProductRepository>((ref) {
  final db = ref.read(databaseProvider);
  final api = ref.read(apiServiceProvider);
  final firebaseCache = ref.read(firebaseCacheProvider);
  return ProductRepository(
    db,
    api,
    usdaClient: UsdaApiClient(),
    firebaseCache: firebaseCache,
  );
});
