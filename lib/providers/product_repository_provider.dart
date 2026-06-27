import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/providers/api_service_provider.dart';
import 'package:pantry_app/providers/database_provider.dart';
import 'package:pantry_app/services/product_repository.dart';

/// Provides the single [ProductRepository] instance used throughout the app.
///
/// The repository combines the local database (from [databaseProvider]) and
/// the Open Food Facts API (from [apiServiceProvider]) to implement the
/// offline‑first product lookup.
///
/// ## Dependencies
///
/// - [databaseProvider] – supplies the [DatabaseHelper] singleton for local
///   caching and inventory operations.
/// - [apiServiceProvider] – supplies the configured [OpenFoodFactsApi] for
///   fetching product data from the internet.
///
/// ## Lifetime
///
/// Because this is a [Provider] (not a [FutureProvider] or [StateProvider]),
/// the repository is created **once** and reused for the entire app session.
/// The repository itself holds no mutable state; it delegates all storage to
/// the database and all network requests to the API service.
///
/// ## Usage
///
/// Typically accessed via `ref.read(productRepositoryProvider)` in async
/// callbacks (like the scan flow) or via `ref.watch(productRepositoryProvider)`
/// in widgets that need to call repository methods inside `FutureBuilder`s.
final productRepositoryProvider = Provider<ProductRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final api = ref.watch(apiServiceProvider);
  return ProductRepository(db, api);
});
