import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/models/inventory_item.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/services/exceptions.dart';
import 'package:pantry_app/services/product_api_service.dart';

class ProductRepository {
  ProductRepository(this._db, this._api, {this._fallbackApi});
  final DatabaseHelper _db;
  final ProductApiService _api;
  final ProductApiService? _fallbackApi;

  /// Returns the product, trying primary API then fallback if available.
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

  // ---------- Inventory methods unchanged ----------
  Future<List<InventoryItem>> getInventoryForBarcode(String barcode) =>
      _db.getInventoryItemsByBarcode(barcode);

  Future<int> addInventoryItem(InventoryItem item) =>
      _db.insertInventoryItem(item);

  Future<int> updateInventoryItem(InventoryItem item) =>
      _db.updateInventoryItem(item);

  Future<int> deleteInventoryItem(int id) => _db.deleteInventoryItem(id);

  /// Insert a product directly into the local cache (e.g., from manual entry).
  Future<void> cacheProduct(Product product) async {
    await _db.insertProduct(product);
  }
}
