import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/models/inventory_item.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/services/exceptions.dart';
import 'package:pantry_app/services/product_api_service.dart';

class ProductRepository {
  ProductRepository(this._db, this._api);
  final DatabaseHelper _db;
  final ProductApiService _api;

  /// Returns the product, either from local cache or remote API.
  /// Throws [ProductNotFoundException] if the barcode is unknown to all sources
  /// and Throws [FetchFailedException] on network errors when no cache exists.
  Future<Product> getProduct(String barcode) async {
    // 1. Check local cache
    final cached = await _db.getProduct(barcode);
    if (cached != null) return cached;

    // 2. Not cached – try API
    try {
      final remote = await _api.getByBarcode(barcode);
      await _db.insertProduct(remote);
      return remote;
    } on ProductNotFoundException {
      // Known barcode not found at source
      rethrow;
    } catch (e) {
      // 3. Network or other error – no cached version
      throw FetchFailedException(
        'Failed to fetch product. Please check your connection.',
      );
    }
  }

  // ---------- Inventory ----------
  Future<List<InventoryItem>> getInventoryForBarcode(String barcode) =>
      _db.getInventoryItemsByBarcode(barcode);

  Future<int> addInventoryItem(InventoryItem item) =>
      _db.insertInventoryItem(item);

  Future<int> updateInventoryItem(InventoryItem item) =>
      _db.updateInventoryItem(item);

  Future<int> deleteInventoryItem(int id) => _db.deleteInventoryItem(id);
}
