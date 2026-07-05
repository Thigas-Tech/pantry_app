import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/models/inventory_item.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/services/exceptions.dart';
import 'package:pantry_app/services/open_food_facts_api.dart';
import 'package:pantry_app/utils/logger.dart';

/// The central data access point that implements the offline‑first pattern.
///
/// [ProductRepository] coordinates between the local SQLite cache
/// ([DatabaseHelper]) and the remote API (`OpenFoodFactsApi`).
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
/// The constructor accepts an optional fallback `OpenFoodFactsApi`. This is
/// currently unused but could be re‑enabled in the future if a second API
/// is desired.
class ProductRepository {
  /// Creates a [ProductRepository] with the given [DatabaseHelper] and
  /// primary API. An optional fallback API can be provided for future use.
  ProductRepository(this._db, this._api, {this._fallbackApi});

  final DatabaseHelper _db;
  final OpenFoodFactsApi _api;
  final OpenFoodFactsApi? _fallbackApi;

  /// Returns a [Product] for the given [barcode], either from cache or from
  /// the remote API.
  ///
  /// Throws [ProductNotFoundException] if the barcode is unknown to all
  /// sources. Throws [FetchFailedException] on network errors when no
  /// cache exists.
  Future<Product> getProduct(String barcode) async {
    logInfo('Looking up $barcode');

    // 1. Local cache
    final cached = await _db.getProduct(barcode);
    if (cached != null) {
      logInfo('Cache hit for $barcode');
      return cached;
    }

    // 2. Try primary API
    try {
      logInfo('Fetching $barcode from primary API');
      final remote = await _api.getByBarcode(barcode);
      await _db.insertProduct(remote);
      logInfo('Fetched and cached $barcode');
      return remote;
    } on ProductNotFoundException {
      logWarning('Product $barcode not found in primary API');
      if (_fallbackApi != null) {
        logInfo('Trying fallback API for $barcode');
        try {
          final remote = await _fallbackApi.getByBarcode(barcode);
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

  // ---------- Named inventories ----------

  /// Creates a new inventory (pantry) with the given [name].
  Future<int> createInventory(String name) => _db.createInventory(name);

  /// Returns all inventories.
  Future<List<Map<String, dynamic>>> getInventories() => _db.getInventories();

  /// Deletes the inventory with the given [id] and all its items.
  Future<void> deleteInventory(int id) => _db.deleteInventory(id);

  /// Renames the inventory with the given [id].
  Future<void> renameInventory(int id, String newName) =>
      _db.renameInventory(id, newName);

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

  /// Returns export data (joined with product info) for a given [inventoryId].
  Future<List<Map<String, dynamic>>> getExportData({
    required int inventoryId,
  }) {
    return _db.getExportData(inventoryId: inventoryId);
  }

  /// Inserts a product directly into the local cache.
  ///
  /// Used when the user manually creates a product (e.g., via the
  /// add‑product screen) or when the product is submitted to Open Food Facts
  /// and should be cached immediately.
  Future<void> cacheProduct(Product product) async {
    logInfo('Caching product: ${product.barcode} — ${product.name}');
    await _db.insertProduct(product);
  }

  /// Re‑fetches all products referenced by inventory items in [inventoryId].
  ///
  /// For each unique barcode found in the inventory table, the remote API is
  /// called. The freshly fetched data is **merged** with any cached product
  /// via `Product.mergeFromApi`, ensuring that fields the API doesn't return
  /// (e.g. Nutri-Score on staging) are preserved from the cache.
  ///
  /// ## Returns
  ///
  /// The number of successfully refreshed products. Failures are silently
  /// skipped — this is a best‑effort operation suitable for pull‑to‑refresh
  /// and post‑flush recovery.
  Future<int> refreshInventoryProducts(int inventoryId) async {
    final items = await _db.getInventoryItems(inventoryId: inventoryId);
    final barcodes = items.map((e) => e.barcode).toSet();
    if (barcodes.isEmpty) return 0;

    logInfo(
      'Refreshing ${barcodes.length} products for inventory $inventoryId',
    );
    var refreshed = 0;
    for (final barcode in barcodes) {
      try {
        final fetched = await _api.getByBarcode(barcode);
        final cached = await _db.getProduct(barcode);
        final merged = cached != null ? cached.mergeFromApi(fetched) : fetched;
        await _db.insertProduct(merged);
        refreshed++;
      } on Exception {
        // Skip individual failures — best-effort.
      }
    }
    logInfo('Refreshed $refreshed / ${barcodes.length} products');
    return refreshed;
  }
}
