import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/models/inventory_item.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/services/exceptions.dart';
import 'package:pantry_app/services/product_api_service.dart';

/// The central data access point that implements the offline‑first pattern.
///
/// [ProductRepository] coordinates between the local SQLite cache
/// ([DatabaseHelper]) and the remote API ([ProductApiService]).
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
/// The repository also exposes CRUD methods for inventory items, delegating
/// directly to [DatabaseHelper].
///
/// ## Fallback API
///
/// The constructor accepts an optional `_fallbackApi`. This is currently
/// unused but could be re‑enabled in the future if a second API is desired.
class ProductRepository {
  /// Creates a [ProductRepository] with the given [DatabaseHelper] and
  /// primary [ProductApiService]. An optional [_fallbackApi] can be
  /// provided for future use.
  ProductRepository(this._db, this._api, {this._fallbackApi});

  final DatabaseHelper _db;
  final ProductApiService _api;
  final ProductApiService? _fallbackApi;

  /// Returns a [Product] for the given [barcode], either from cache or from
  /// the remote API.
  ///
  /// Throws [ProductNotFoundException] if the barcode is unknown to all
  /// sources. Throws [FetchFailedException] on network errors when no
  /// cache exists.
  Future<Product> getProduct(String barcode) async {
    // 1. Local cache
    final cached = await _db.getProduct(barcode);
    if (cached != null) return cached;

    // 2. Try primary API
    try {
      final remote = await _api.getByBarcode(barcode);
      await _db.insertProduct(remote);
      return remote;
    } on ProductNotFoundException {
      // Primary not found → try fallback if set
      if (_fallbackApi != null) {
        try {
          final remote = await _fallbackApi.getByBarcode(barcode);
          await _db.insertProduct(remote);
          return remote;
        } on ProductNotFoundException {
          // Both failed, rethrow
          rethrow;
        } catch (e) {
          // Network error on fallback → throw generic
          throw FetchFailedException(
            'Failed to fetch product. Please check your connection.',
          );
        }
      } else {
        rethrow;
      }
    } catch (e) {
      // Network/other error on primary, but no cache
      throw FetchFailedException(
        'Failed to fetch product. Please check your connection.',
      );
    }
  }

  /// Retrieves all inventory items for the given [barcode].
  Future<List<InventoryItem>> getInventoryForBarcode(String barcode) =>
      _db.getInventoryItemsByBarcode(barcode);

  /// Inserts a new inventory item and returns its auto‑generated ID.
  Future<int> addInventoryItem(InventoryItem item) =>
      _db.insertInventoryItem(item);

  /// Updates an existing inventory item.
  Future<int> updateInventoryItem(InventoryItem item) =>
      _db.updateInventoryItem(item);

  /// Deletes an inventory item by its [id].
  Future<int> deleteInventoryItem(int id) => _db.deleteInventoryItem(id);

  /// Inserts a product directly into the local cache.
  ///
  /// Used when the user manually creates a product (e.g., via the
  /// add‑product screen) or when the product is submitted to Open Food Facts
  /// and should be cached immediately.
  Future<void> cacheProduct(Product product) async {
    await _db.insertProduct(product);
  }
}
