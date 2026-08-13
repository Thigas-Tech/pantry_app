import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/database/firebase_cache_meta_dao.dart';
import 'package:pantry_app/firebase_cache_config.dart';
import 'package:pantry_app/models/inventory_item.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/models/product_type.dart';
import 'package:pantry_app/services/exceptions.dart';
import 'package:pantry_app/services/firebase_cache_service.dart';
import 'package:pantry_app/services/off_adapter.dart';
import 'package:pantry_app/services/produce_barcode.dart';
import 'package:pantry_app/services/produce_category_mapper.dart';
import 'package:pantry_app/services/produce_nutrition_fallback.dart';
import 'package:pantry_app/services/usda_api_client.dart';
import 'package:pantry_app/utils/logger.dart';

/// The central data access point that implements the offline‑first pattern.
///
/// [ProductRepository] coordinates between the local SQLite cache
/// ([DatabaseHelper]) and the remote API ([OffAdapter]).
///
/// ## Offline‑first strategy
///
/// For every product lookup:
/// 1. **Check local cache** – if the product exists in SQLite, return it
///    immediately without any network call.
/// 2. **Call primary API** – if not cached, fetch from the remote service
///    and store the result locally for future offline use.
/// 3. **Error handling** – if the API returns a [ProductNotFoundException],
///    rethrow it so the UI can react (e.g., redirect to OFF app). If a
///    network error occurs, throw [FetchFailedException].
///
/// ## Inventory management
///
/// The repository exposes CRUD methods for inventory items and for the
/// named inventories (pantries) themselves. All item operations are scoped
/// to a specific inventory via its [InventoryItem.inventoryId].
///
/// ## Fallback API
///
/// The constructor accepts an optional fallback [OffAdapter]. This is
/// currently unused but could be re‑enabled in the future if a second API
/// is desired.
class ProductRepository {
  /// Creates a [ProductRepository] with the given [DatabaseHelper] and
  /// primary API. An optional fallback API can be provided for future use.
  ///
  /// The optional [UsdaApiClient] is used by [addProduceToInventory] to
  /// fetch nutrition data for produce items from the USDA FoodData Central
  /// API when a product is not already cached locally.
  ///
  /// The [FirebaseCacheMetaDao] is the single source of truth for
  /// cache-staleness tracking (replacing the old SharedPreferences-based
  /// approach).
  ProductRepository(
    this._db,
    this._api, {
    required this._metaDao,
    this._fallbackApi,
    this._usdaClient,
    this._firebaseCache,
  });

  final DatabaseHelper _db;
  final OffAdapter _api;
  final OffAdapter? _fallbackApi;
  final UsdaApiClient? _usdaClient;
  final FirebaseCacheService? _firebaseCache;
  final FirebaseCacheMetaDao _metaDao;

  /// The injected [UsdaApiClient] used for produce nutrition lookups, or
  /// null when none was provided.
  UsdaApiClient? get usdaClient => _usdaClient;

  /// Returns the current application locale as a two-letter language code.
  ///
  /// Falls back to 'en' when the platform locale cannot be determined.
  String _currentLanguageCode() {
    final locale = PlatformDispatcher.instance.locale;
    final code = locale.languageCode;
    if (code.isEmpty || code == 'und') return 'en';
    return code;
  }

  /// Returns a [Product] for the given [barcode], either from cache or from
  /// the remote API.
  ///
  /// Concurrent calls for the same [barcode] share one in-flight lookup
  /// instead of issuing duplicate network requests.
  ///
  /// Throws [ProductNotFoundException] if the barcode is unknown to all
  /// sources. Throws [FetchFailedException] on network errors when no
  /// cache exists.
  Future<Product> getProduct(String barcode, {String? languageCode}) {
    final inFlight = _getProductInFlight[barcode];
    if (inFlight != null) return inFlight;
    final future = _getProductImpl(barcode, languageCode);
    _getProductInFlight[barcode] = future;
    return future.whenComplete(() {
      final _ = _getProductInFlight.remove(barcode);
    });
  }

  /// In-flight single lookups keyed by barcode.
  final Map<String, Future<Product>> _getProductInFlight = {};

  Future<Product> _getProductImpl(
    String barcode,
    String? languageCode,
  ) async {
    logInfo('Looking up $barcode');
    final lang = languageCode ?? _currentLanguageCode();

    // 1. Local cache
    final cached = await _db.getProduct(barcode);
    if (cached != null) {
      logInfo('Cache hit for $barcode');
      return cached;
    }

    // 1.5 Firebase cache
    if (_firebaseCache != null && _firebaseCache.isAvailable) {
      try {
        final fbProduct = await _firebaseCache.resolveBarcodedProduct(
          barcode,
          languageCode: lang,
        );
        if (fbProduct != null) {
          logInfo('Firebase cache hit for $barcode');
          return fbProduct;
        }
        logInfo(
          'Firebase miss for $barcode '
          '- resolveBarcodedProduct already tried OFF; skipping retry',
        );
        // The service already tried OFF internally.  Skip the direct OFF
        // call (step 2) and proceed to the fallback chain.
        return await _fallbackOrThrow(barcode, lang);
      } on ProductNotFoundException {
        rethrow;
      } on Exception catch (e) {
        logWarning('Firebase cache lookup failed for $barcode: $e');
      }
    }

    // 2. Try primary API
    try {
      logInfo('Fetching $barcode from primary API');
      final remote = await _api.getByBarcode(barcode, languageCode: lang);
      await _db.insertProduct(remote);
      logInfo('Fetched and cached $barcode');
      return remote;
    } on ProductNotFoundException {
      logWarning('Product $barcode not found in primary API');
      return _fallbackOrThrow(barcode, lang);
    } on Exception catch (e) {
      logError('Network error for $barcode: $e');
      throw FetchFailedException(
        'Failed to fetch product. Please check your connection.',
      );
    }
  }

  /// Tries the fallback API (if configured) or throws.
  ///
  /// Shared between the direct-API path and the Firebase-cache path so the
  /// fallback behaviour is identical regardless of which source was tried
  /// first.
  Future<Product> _fallbackOrThrow(String barcode, String lang) async {
    if (_fallbackApi != null) {
      logInfo('Trying fallback API for $barcode');
      try {
        final remote = await _fallbackApi.getByBarcode(
          barcode,
          languageCode: lang,
        );
        await _db.insertProduct(remote);
        logInfo('Fetched $barcode from fallback API');
        return remote;
      } on ProductNotFoundException {
        logWarning('Product $barcode not found in fallback API');
        rethrow;
      } on Exception catch (e) {
        logError('Fallback API error for $barcode: $e');
        throw FetchFailedException(
          'Failed to fetch product. Please check your connection.',
        );
      }
    }
    throw ProductNotFoundException(barcode);
  }

  /// Checks the local cache for a product with the given [barcode].
  ///
  /// Returns the cached [Product] or null if not found in the local
  /// database. Unlike [getProduct], this method does not make any
  /// network requests.
  Future<Product?> getProductFromCache(String barcode) {
    return _db.getProduct(barcode);
  }

  /// Resolves products for multiple [barcodes] with a single cached
  /// lookup, fetching only the misses from the remote API.
  ///
  /// Returns a map keyed by barcode. Barcodes whose fetch fails (unknown
  /// product or network error) are omitted, matching the per-barcode
  /// tolerance of the recipe providers.
  Future<Map<String, Product>> getProductsForBarcodes(
    List<String> barcodes,
  ) async {
    final unique = barcodes.toSet().toList();
    final cached = await _db.getProductsByBarcodes(unique);
    final result = {for (final product in cached) product.barcode: product};
    for (final barcode in unique) {
      if (result.containsKey(barcode)) continue;
      try {
        result[barcode] = await getProduct(barcode);
      } on Exception catch (e) {
        logWarning('Could not fetch product $barcode for batch lookup: $e');
      }
    }
    return result;
  }

  // ---------- Named inventories ----------

  /// Creates a new inventory (pantry) with the given [name].
  Future<int> createInventory(String name) {
    logInfo('Creating inventory "$name"');
    return _db.createInventory(name);
  }

  /// Returns all inventories.
  Future<List<Map<String, dynamic>>> getInventories() {
    return _db.getInventories();
  }

  /// Deletes the inventory with the given [id] and all its items.
  Future<void> deleteInventory(int id) {
    logInfo('Deleting inventory $id');
    return _db.deleteInventory(id);
  }

  /// Renames the inventory with the given [id].
  Future<void> renameInventory(int id, String newName) {
    logInfo('Renaming inventory $id to "$newName"');
    return _db.renameInventory(id, newName);
  }

  // ---------- Inventory items (scoped) ----------

  /// Returns all inventory items for the given [barcode] inside [inventoryId].
  Future<List<InventoryItem>> getInventoryForBarcode(
    String barcode, {
    required int inventoryId,
  }) {
    logInfo('Fetching inventory for barcode $barcode (inventory $inventoryId)');
    return _db.getInventoryItemsByBarcode(barcode, inventoryId: inventoryId);
  }

  /// Inserts a new inventory item and returns its auto‑generated ID.
  Future<int> addInventoryItem(InventoryItem item) {
    logInfo(
      '''Adding inventory item: ${item.barcode} — qty: ${item.quantity} ${item.unit}, loc: ${item.location} (inventory ${item.inventoryId})''',
    );
    return _db.insertInventoryItem(item);
  }

  /// Inserts an inventory item, merging with an existing row that
  /// represents the same batch (same barcode, inventory, expiry, unit, and
  /// location). Returns the ID of the merged or newly inserted row.
  ///
  /// This is the batch-aware add path: a second instance with a different
  /// expiry date creates a new row instead of being merged away.
  Future<int> addOrMergeInventoryItem(InventoryItem item) {
    logInfo(
      '''Adding or merging inventory item: ${item.barcode} — qty: ${item.quantity} ${item.unit}, loc: ${item.location}, expiry: ${item.expiryDate} (inventory ${item.inventoryId})''',
    );
    return _db.insertOrMergeInventoryItem(item);
  }

  /// Resolves a [Product] for [produceName] with a synthetic barcode.
  ///
  /// Generates the barcode produce-$produceName, then delegates to
  /// [_resolveProduceProduct] which tries the USDA API first, then
  /// hardcoded fallback data, and finally creates a minimal product
  /// with no nutrition values.
  ///
  /// Unlike [addProduceToInventory], this method does not write to
  /// the database or create an inventory item.
  ///
  /// Throws [ArgumentError] if [produceName] is empty.
  Future<Product> resolveProduceProduct(String produceName) {
    if (produceName.trim().isEmpty) {
      throw ArgumentError('produceName must not be empty');
    }
    final barcode = produceBarcode(produceName);
    return _resolveProduceProduct(produceName, barcode);
  }

  /// Adds a produce item to the inventory, fetching nutrition data from the
  /// USDA API when available and falling back to hardcoded data.
  ///
  /// [produceName] is the display name of the produce (e.g. "Apple"). The
  /// item will be stored with a synthetic barcode produce-$produceName
  /// and a default quantity of 150 g (overridable via [quantity]).
  ///
  /// If a product row for the synthetic barcode already exists in the local
  /// cache, the USDA / fallback lookup is skipped entirely.
  ///
  /// Nutrition lookup order:
  /// 1. USDA FoodData Central API (via [UsdaApiClient])
  /// 2. Hardcoded fallback data (via [ProduceNutritionFallback])
  /// 3. Minimal product with no nutrition values (when both sources fail)
  ///
  /// Duplicate quick-adds of the same produce are merged via
  /// [DatabaseHelper.insertOrMergeInventoryItem].
  ///
  /// Throws [ArgumentError] if [produceName] is empty.
  Future<int> addProduceToInventory(
    String produceName, {
    required int inventoryId,
    double quantity = 150,
  }) async {
    if (produceName.trim().isEmpty) {
      throw ArgumentError('produceName must not be empty');
    }

    final barcode = produceBarcode(produceName);

    final existingProduct = await _db.getProduct(barcode);
    if (existingProduct == null) {
      final product = await _resolveProduceProduct(produceName, barcode);
      await cacheProduct(product);
    }

    final item = InventoryItem(
      barcode: barcode,
      unit: 'g',
      quantity: quantity,
      inventoryId: inventoryId,
    );

    return _db.insertOrMergeInventoryItem(item);
  }

  /// Resolves a [Product] for [produceName] with the given [barcode].
  ///
  /// Tries the USDA API first, then hardcoded fallback data, and finally
  /// creates a minimal product with no nutrition values.
  Future<Product> _resolveProduceProduct(
    String produceName,
    String barcode,
  ) async {
    if (_firebaseCache != null && _firebaseCache.isAvailable) {
      try {
        final cached = await _firebaseCache.resolveProduceProduct(produceName);
        if (cached != null) {
          return cached.copyWith(
            barcode: barcode,
            productType: ProductType.produce,
            source: 'manual',
            category: ProduceCategoryMapper.forName(produceName),
            lastSynced: DateTime.now().millisecondsSinceEpoch,
          );
        }
        // Service already tried USDA internally; skip direct USDA call.
        return _produceFallbackOrMinimal(produceName, barcode);
      } on Exception catch (e) {
        logWarning('Firebase produce cache lookup failed: $e');
      }
    }

    if (_usdaClient != null) {
      try {
        final usdaResults = await _usdaClient.searchFood(produceName);
        if (usdaResults.isNotEmpty) {
          var usda = usdaResults.first;
          final enriched = await _usdaClient.enrichProductWithServingData(usda);
          if (enriched != null) usda = enriched;
          return usda.copyWith(
            barcode: barcode,
            name: produceName,
            productType: ProductType.produce,
            source: 'manual',
            category: ProduceCategoryMapper.forName(produceName),
            lastSynced: DateTime.now().millisecondsSinceEpoch,
          );
        }
      } on Exception catch (e) {
        logWarning('USDA lookup failed for "$produceName": $e');
      }
    }

    return _produceFallbackOrMinimal(produceName, barcode);
  }

  /// Returns a hardcoded fallback product for [produceName], or a minimal
  /// product with no nutrition data when no fallback is available.
  Product _produceFallbackOrMinimal(String produceName, String barcode) {
    final fallback = ProduceNutritionFallback.forName(produceName);
    if (fallback != null) {
      return Product(
        barcode: barcode,
        name: produceName,
        productType: ProductType.produce,
        source: 'manual',
        category: ProduceCategoryMapper.forName(produceName),
        energyKcal: fallback.energyKcal,
        proteinG: fallback.proteinG,
        carbsG: fallback.carbsG,
        fatG: fallback.fatG,
        fiberG: fallback.fiberG,
        lastSynced: DateTime.now().millisecondsSinceEpoch,
      );
    }

    return Product(
      barcode: barcode,
      name: produceName,
      productType: ProductType.produce,
      source: 'manual',
      category: ProduceCategoryMapper.forName(produceName),
      lastSynced: DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Updates an existing inventory item.
  Future<int> updateInventoryItem(InventoryItem item) {
    logInfo(
      '''Updating inventory item ${item.id}: qty=${item.quantity} ${item.unit}, loc=${item.location}''',
    );
    return _db.updateInventoryItem(item);
  }

  /// Deletes an inventory item by its [id].
  Future<int> deleteInventoryItem(int id) {
    logInfo('Deleting inventory item $id');
    return _db.deleteInventoryItem(id);
  }

  /// Deletes multiple inventory items in one batch by their [ids].
  Future<int> deleteInventoryItems(List<int> ids) {
    logInfo('Deleting ${ids.length} inventory item(s) in batch');
    return _db.deleteInventoryItems(ids);
  }

  /// Moves multiple inventory items to a different inventory (pantry).
  Future<void> moveItemsToInventory(
    List<int> itemIds,
    int targetInventoryId,
  ) {
    logInfo(
      'Moving ${itemIds.length} item(s) to inventory $targetInventoryId',
    );
    return _db.moveItemsToInventory(itemIds, targetInventoryId);
  }

  /// Returns joined inventory-with-product rows for a given [inventoryId].
  Future<List<Map<String, dynamic>>> getInventoryWithProduct({
    required int inventoryId,
  }) {
    return _db.getInventoryWithProduct(inventoryId: inventoryId);
  }

  /// Returns the total number of inventory items for a given [inventoryId]
  /// or globally if null.
  Future<int> getInventoryCount({int? inventoryId}) {
    return _db.getInventoryCount(inventoryId: inventoryId);
  }

  /// Inserts a product directly into the local cache, merging with any
  /// existing cached product for the same barcode.
  ///
  /// Used when the user manually creates a product (e.g., via the
  /// add‑product screen) or when the product is submitted to Open Food Facts
  /// and should be cached immediately.
  ///
  /// ## Merge strategy
  ///
  /// - Manual entries merge via [ProductMerge.mergeFromManual] so that rich
  ///   API data (Nutri-Score, nutrition facts, OFF image URLs) is preserved
  ///   when the user only entered a subset of fields.
  /// - API entries merge via [ProductMerge.mergeFromApi] so that local-only
  ///   fields (image paths, submission status) are never overwritten by an
  ///   incomplete API response.
  /// - When no existing cache record exists, the product is inserted as-is.
  Future<void> cacheProduct(Product incoming) async {
    logInfo('Caching product: ${incoming.barcode} — ${incoming.name}');
    var toInsert = incoming;
    final existing = await _db.getProduct(incoming.barcode);
    if (existing != null) {
      if (incoming.source == 'manual') {
        toInsert = existing.mergeFromManual(incoming);
      } else {
        toInsert = existing.mergeFromApi(incoming);
      }
    }
    await _db.insertProduct(toInsert);
  }

  /// Re‑fetches all products referenced by inventory items in [inventoryId].
  ///
  /// The method runs **two passes**. The first pass iterates every barcode
  /// sequentially with a **500 ms delay** between calls. A second pass retries
  /// only the barcodes that failed on the first pass (timeout, 5xx, 429, or
  /// any other [Exception]), again with 500 ms spacing. This two‑pass strategy
  /// absorbs transient rate‑limiting or server hiccups without blocking the
  /// UI for longer than necessary.
  ///
  /// Each individual API call may fail transiently; the two-pass
  /// strategy absorbs rate-limiting and server hiccups.
  ///
  /// Freshly fetched data is **merged** with any cached product via
  /// a merge-from-API helper on [Product], ensuring that fields the API
  /// doesn't return
  /// (e.g. Nutri-Score on staging) are preserved from the cache.
  ///
  /// ## Returns
  ///
  /// The number of successfully refreshed products. Individual failures are
  /// silently skipped — this is a best‑effort operation suitable for
  /// pull‑to‑refresh and post‑flush recovery.
  Future<int> refreshInventoryProducts(int inventoryId) async {
    final items = await _db.getInventoryItems(inventoryId: inventoryId);
    final allBarcodes = items.map((e) => e.barcode).toSet();
    final barcodes = allBarcodes.where((b) {
      return !b.startsWith('produce-') && !b.startsWith('plu-');
    }).toSet();
    final skipped = allBarcodes.length - barcodes.length;
    if (skipped > 0) {
      logInfo('Skipped $skipped synthetic produce barcodes during refresh');
    }
    if (barcodes.isEmpty) return 0;

    logInfo(
      'Refreshing ${barcodes.length} products for inventory $inventoryId',
    );

    var refreshed = 0;

    // ---- Pass 1: attempt every barcode ----
    var result = await _refreshBatch(barcodes);
    refreshed += result.refreshed;

    // ---- Pass 2: retry only failures ----
    if (result.failed.isNotEmpty) {
      logInfo('Retrying ${result.failed.length} failed products');
      await Future<void>.delayed(const Duration(seconds: 2));
      result = await _refreshBatch(Set<String>.of(result.failed));
      refreshed += result.refreshed;
    }

    logInfo('Refreshed $refreshed / ${barcodes.length} products');
    return refreshed;
  }

  /// Fires‑off [refreshInventoryProducts] without awaiting the result.
  ///
  /// Use this for background refreshes where the caller does not need to
  /// know when the operation completes (e.g., on‑startup cache refresh).
  void refreshInventoryProductsBackground(int inventoryId) {
    unawaited(refreshInventoryProducts(inventoryId));
  }

  /// Iterates [barcodes] sequentially, fetching and merging each one.
  ///
  /// Returns a record with the number of successfully refreshed products and
  /// a list of barcodes that failed. A 500 ms delay separates consecutive
  /// requests to reduce the risk of rate limiting.
  Future<({int refreshed, List<String> failed})> _refreshBatch(
    Set<String> barcodes,
  ) async {
    var refreshed = 0;
    final failed = <String>[];
    var index = 0;
    for (final barcode in barcodes) {
      if (index > 0) {
        await Future<void>.delayed(const Duration(milliseconds: 500));
      }
      try {
        final fetched = await _api.getByBarcode(
          barcode,
          languageCode: _currentLanguageCode(),
        );
        final cached = await _db.getProduct(barcode);
        final merged = cached != null ? cached.mergeFromApi(fetched) : fetched;
        await _db.insertProduct(merged);
        refreshed++;
      } on Exception {
        failed.add(barcode);
        logWarning('Refresh failed for $barcode — will retry');
      }
      index++;
    }
    return (refreshed: refreshed, failed: failed);
  }

  /// Records the current time as the last successful product refresh.
  ///
  /// Used together with [isCacheOverdue] to trigger automatic background
  /// refreshes after [cacheOverdueDays] of inactivity. Delegates to
  /// [FirebaseCacheMetaDao.setGlobalRefreshTime], which is the single source
  /// of truth for cache staleness.
  Future<void> setLastRefreshTime() async {
    final db = await _db.database;
    await _metaDao.setGlobalRefreshTime(db);
    logInfo('Last refresh time updated');
  }

  /// Returns the stored last‑refresh timestamp, or null if no refresh has
  /// ever been recorded. Reads from [FirebaseCacheMetaDao] instead of
  /// SharedPreferences.
  Future<DateTime?> getLastRefreshTime() async {
    final db = await _db.database;
    final entry = await _metaDao.getGlobalRefreshTime(db);
    if (entry == null) return null;
    final raw = entry['last_refreshed_at'] as int?;
    if (raw == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(raw);
  }

  /// The number of days after which the cached product data is considered
  /// stale and a background refresh should be scheduled.
  int get cacheOverdueDays => inventoryRefreshOverdueDays;

  /// Returns true when the last refresh timestamp is missing or older than
  /// [cacheOverdueDays] days.
  ///
  /// Queries [FirebaseCacheMetaDao] for the global refresh entry instead of
  /// reading from local preferences. When the entry is missing or its
  /// nextRefreshAt column has passed, the cache is considered overdue.
  Future<bool> isCacheOverdue() async {
    final db = await _db.database;
    final entry = await _metaDao.getGlobalRefreshTime(db);
    if (entry == null) return true;
    final nextRefreshAt = entry['next_refresh_at'] as int?;
    if (nextRefreshAt == null) return true;
    return DateTime.now().millisecondsSinceEpoch >= nextRefreshAt;
  }
}
