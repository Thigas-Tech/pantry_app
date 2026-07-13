import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/models/inventory_item.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/services/exceptions.dart';
import 'package:pantry_app/services/off_adapter.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  /// If [SharedPreferences] is provided it is used for refresh‑time
  /// tracking; otherwise
  /// [SharedPreferences] is lazily obtained from the singleton instance.
  ProductRepository(
    this._db,
    this._api, {
    this._fallbackApi,
    this._prefs,
  });

  final DatabaseHelper _db;
  final OffAdapter _api;
  final OffAdapter? _fallbackApi;
  final SharedPreferences? _prefs;

  Future<SharedPreferences> get _sharedPrefs async =>
      _prefs ?? await SharedPreferences.getInstance();

  static const _lastRefreshKey = 'last_product_refresh';
  static const _cacheOverdueDays = 5;

  /// Returns the current application locale as a two-letter language code.
  ///
  /// Falls back to `'en'` when the platform locale cannot be determined.
  String _currentLanguageCode() {
    final locale = PlatformDispatcher.instance.locale;
    final code = locale.languageCode;
    if (code.isEmpty || code == 'und') return 'en';
    return code;
  }

  /// Returns a [Product] for the given [barcode], either from cache or from
  /// the remote API.
  ///
  /// Throws [ProductNotFoundException] if the barcode is unknown to all
  /// sources. Throws [FetchFailedException] on network errors when no
  /// cache exists.
  Future<Product> getProduct(String barcode, {String? languageCode}) async {
    logInfo('Looking up $barcode');
    final lang = languageCode ?? _currentLanguageCode();

    // 1. Local cache
    final cached = await _db.getProduct(barcode);
    if (cached != null) {
      logInfo('Cache hit for $barcode');
      return cached;
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
      } else {
        rethrow;
      }
    } on Exception catch (e) {
      logError('Network error for $barcode: $e');
      throw FetchFailedException(
        'Failed to fetch product. Please check your connection.',
      );
    }
  }

  /// Checks the local cache for a product with the given [barcode].
  ///
  /// Returns the cached [Product] or `null` if not found in the local
  /// database. Unlike [getProduct], this method does not make any
  /// network requests.
  Future<Product?> getProductFromCache(String barcode) {
    return _db.getProduct(barcode);
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
  /// or globally if `null`.
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
    final barcodes = items.map((e) => e.barcode).toSet();
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
  /// refreshes after [cacheOverdueDays] of inactivity.
  Future<void> setLastRefreshTime() async {
    final prefs = await _sharedPrefs;
    await prefs.setString(
      _lastRefreshKey,
      DateTime.now().toIso8601String(),
    );
    logInfo('Last refresh time updated');
  }

  /// Returns the stored last‑refresh timestamp, or `null` if no refresh has
  /// ever been recorded.
  Future<DateTime?> getLastRefreshTime() async {
    final prefs = await _sharedPrefs;
    final raw = prefs.getString(_lastRefreshKey);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  /// The number of days after which the cached product data is considered
  /// stale and a background refresh should be scheduled.
  int get cacheOverdueDays => _cacheOverdueDays;

  /// Returns `true` when the last refresh timestamp is missing or older than
  /// [cacheOverdueDays] days.
  ///
  /// Used at app startup and on the home screen to decide whether to fire a
  /// background refresh.
  Future<bool> isCacheOverdue() async {
    final lastRefresh = await getLastRefreshTime();
    if (lastRefresh == null) return true;
    return DateTime.now().difference(lastRefresh).inDays >= _cacheOverdueDays;
  }
}
