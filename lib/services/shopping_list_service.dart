import 'dart:async';

import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/models/shopping_item.dart';
import 'package:pantry_app/services/exceptions.dart';
import 'package:pantry_app/services/product_repository.dart';
import 'package:pantry_app/utils/logger.dart';

/// Holds the result of a move-to-inventory operation.
class MoveToInventoryResult {
  /// Creates a [MoveToInventoryResult].
  const MoveToInventoryResult({
    required this.movedCount,
    required this.skippedCount,
  });

  /// Number of items successfully moved to inventory.
  final int movedCount;

  /// Number of items skipped (no barcode or no product in cache).
  final int skippedCount;
}

/// Owns all shopping list business logic: adding, toggling, deleting,
/// price updates and the move-purchased-to-inventory transaction.
///
/// Kept free of Riverpod so every method is testable with plain
/// dependencies. The active inventory id is passed in by the caller (which
/// reads it from the provider).
class ShoppingListService {
  /// Creates a [ShoppingListService].
  ShoppingListService(
    this._db,
    this._productRepository,
  );

  final DatabaseHelper _db;
  final ProductRepository _productRepository;

  /// Adds an item to the shopping list, merging by barcode if a pending
  /// item with the same barcode and unit already exists.
  ///
  /// When an existing pending item has the same barcode and unit, the
  /// quantities are summed instead of creating a duplicate row.
  /// The item's inventoryId defaults to the active inventory if not set.
  ///
  /// Before inserting, ensures the referenced product exists in the local
  /// cache to avoid FOREIGN KEY constraint failures. If the product is
  /// missing and cannot be fetched, the barcode is set to null so the
  /// insert still succeeds.
  Future<void> addShoppingItem(
    ShoppingItem item, {
    required int activeInventoryId,
  }) async {
    final database = await _db.database;
    var scopedItem = item.inventoryId == null
        ? item.copyWith(inventoryId: activeInventoryId)
        : item;

    // Ensure the product exists in cache before inserting (avoid FK failure).
    if (scopedItem.barcode != null && scopedItem.barcode!.isNotEmpty) {
      final existing = await _db.getProduct(scopedItem.barcode!);
      if (existing == null) {
        try {
          logInfo(
            'Product ${scopedItem.barcode} not in cache — '
            'fetching before shopping list insert',
          );
          final fetched = await _productRepository.getProduct(
            scopedItem.barcode!,
          );
          await _productRepository.cacheProduct(fetched);
        } on ProductNotFoundException {
          logWarning(
            'Product ${scopedItem.barcode} not found anywhere — '
            'adding without barcode',
          );
          scopedItem = scopedItem.copyWith(barcode: null);
        } on FetchFailedException {
          logWarning(
            'Could not fetch product ${scopedItem.barcode} — '
            'adding without barcode',
          );
          scopedItem = scopedItem.copyWith(barcode: null);
        }
      }
    }

    logInfo(
      'Add shopping item — barcode=${scopedItem.barcode ?? 'none'} '
      'name="${scopedItem.name}" qty=${scopedItem.quantity} '
      'inventoryId=${scopedItem.inventoryId}',
    );
    try {
      await _db.shoppingListDao.insertOrMergeByBarcode(database, scopedItem);
    } on Exception catch (e) {
      logError('Failed to add shopping item: $e');
      rethrow;
    }
  }

  /// Toggles the purchased state for the item with the given [id].
  Future<void> toggleShoppingItem(int id) async {
    logInfo('Toggle shopping item — id=$id');
    await _db.toggleShoppingItemPurchased(id);
  }

  /// Deletes a shopping list item by [id].
  Future<void> deleteShoppingItem(int id) async {
    logInfo('Delete shopping item — id=$id');
    try {
      await _db.deleteShoppingItem(id);
    } on Exception catch (e) {
      logError('Failed to delete shopping item id=$id: $e');
      rethrow;
    }
  }

  /// Deletes all purchased shopping list items for the given
  /// [inventoryId].
  Future<int> clearPurchasedShoppingItems({required int inventoryId}) async {
    final deleted = await _db.clearPurchasedShoppingItems(
      inventoryId: inventoryId,
    );
    logInfo('Cleared purchased shopping items — count=$deleted');
    return deleted;
  }

  /// Updates only the price fields for the shopping item with the given
  /// [id].
  Future<void> updateShoppingItemPrice(
    int id, {
    double? priceAmount,
    String? priceCurrency,
    String? priceStore,
  }) async {
    await _db.updateShoppingItemPriceFields(
      id,
      priceAmount: priceAmount,
      priceCurrency: priceCurrency,
      priceStore: priceStore,
    );
  }

  /// Updates an existing shopping item (name, quantity, unit, or price).
  ///
  /// Persists the whole [ShoppingItem] via the DAO's update path. The
  /// caller is responsible for re-reading the item first if only some
  /// fields changed.
  Future<void> updateShoppingItem(ShoppingItem item) async {
    logInfo('Update shopping item — id=${item.id} name="${item.name}"');
    try {
      await _db.updateShoppingItem(item);
    } on Exception catch (e) {
      logError('Failed to update shopping item id=${item.id}: $e');
      rethrow;
    }
  }

  /// Persists a manual drag-to-reorder of pending items for an inventory.
  ///
  /// [itemIds] holds the pending item ids in their new visual order. The
  /// first id receives sort_order 1, and so on.
  Future<void> reorderShoppingItems(List<int> itemIds) async {
    logInfo('Reorder shopping items — count=${itemIds.length}');
    try {
      await _db.reorderShoppingItems(itemIds);
    } on Exception catch (e) {
      logError('Failed to reorder shopping items: $e');
      rethrow;
    }
  }

  /// Moves purchased items (with barcodes) to the active inventory.
  ///
  /// For each purchased item with a barcode, the product is ensured to
  /// exist in the cache, and an inventory item is created (or merged if the
  /// same batch — same barcode, unit, location, and no expiry — already
  /// exists in the target inventory). Price data on the shopping item is
  /// saved to the prices table. The shopping item is then deleted.
  ///
  /// Items without a barcode or with no matching product in the cache are
  /// skipped.
  ///
  /// Returns a [MoveToInventoryResult] with counts of moved and skipped
  /// items. Runs inside a SQLite transaction — all-or-nothing.
  Future<MoveToInventoryResult> movePurchasedToInventory({
    required int inventoryId,
  }) async {
    final database = await _db.database;

    var movedCount = 0;
    var skippedCount = 0;

    final allPurchased = await _db.getPurchasedShoppingItems(
      inventoryId: inventoryId,
    );

    logInfo(
      'Move purchased to inventory — total=${allPurchased.length} '
      'inventoryId=$inventoryId',
    );

    await database.transaction((txn) async {
      for (final item in allPurchased) {
        if (item.barcode == null || item.barcode!.isEmpty) {
          logWarning(
            'Skipped item id=${item.id} — no barcode',
          );
          skippedCount++;
          continue;
        }

        final existingProduct = await txn.query(
          'products',
          where: 'barcode = ?',
          whereArgs: [item.barcode],
          limit: 1,
        );
        if (existingProduct.isEmpty) {
          logWarning(
            'Skipped item id=${item.id} barcode=${item.barcode} — '
            'product not in cache',
          );
          skippedCount++;
          continue;
        }

        final existingInv = await txn.query(
          'inventory',
          where:
              'barcode = ? AND inventory_id = ?'
              ' AND expiry_date IS NULL AND unit = ? AND location = ?',
          whereArgs: [item.barcode, inventoryId, item.unit, 'pantry'],
          limit: 1,
        );
        if (existingInv.isNotEmpty) {
          final existingQty =
              (existingInv.first['quantity'] as num?)?.toDouble() ?? 1;
          await txn.update(
            'inventory',
            {'quantity': existingQty + item.quantity},
            where: 'id = ?',
            whereArgs: [existingInv.first['id']],
          );
          logInfo(
            'Merged inventory — barcode=${item.barcode} '
            'qty=${existingQty + item.quantity}',
          );
        } else {
          await txn.insert('inventory', {
            'barcode': item.barcode,
            'quantity': item.quantity,
            'unit': item.unit,
            'location': 'pantry',
            'inventory_id': inventoryId,
            'date_added': DateTime.now().millisecondsSinceEpoch,
          });
          logInfo(
            'Created inventory item — barcode=${item.barcode} '
            'qty=${item.quantity}',
          );
        }

        if (item.priceAmount != null) {
          await txn.insert('prices', {
            'barcode': item.barcode,
            'price': item.priceAmount,
            'currency': item.priceCurrency ?? 'USD',
            'store': item.priceStore,
            'date_purchased': DateTime.now().millisecondsSinceEpoch,
            'date_added': DateTime.now().millisecondsSinceEpoch,
            'sync_status': 'local_only',
            'is_discounted': 0,
          });
        }

        await txn.delete(
          'shopping_list',
          where: 'id = ?',
          whereArgs: [item.id],
        );
        movedCount++;
      }
    });

    return MoveToInventoryResult(
      movedCount: movedCount,
      skippedCount: skippedCount,
    );
  }
}
