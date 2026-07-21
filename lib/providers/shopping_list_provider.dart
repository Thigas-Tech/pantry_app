import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/database/shopping_list_dao.dart';
import 'package:pantry_app/models/shopping_item.dart';
import 'package:pantry_app/providers/active_inventory_provider.dart';
import 'package:pantry_app/providers/database_provider.dart';
import 'package:pantry_app/providers/product_repository_provider.dart';
import 'package:pantry_app/services/exceptions.dart';
import 'package:pantry_app/services/photo_service.dart';
import 'package:pantry_app/utils/logger.dart';

/// Provides a singleton [ShoppingListDao] instance.
final shoppingListDaoProvider = Provider<ShoppingListDao>((ref) {
  return const ShoppingListDao();
});

/// Provides a singleton [PhotoService] instance.
final photoServiceProvider = Provider<PhotoService>((ref) {
  return PhotoService();
});

/// Provides all shopping list items, scoped to the active inventory.
final FutureProvider<List<ShoppingItem>> shoppingListProvider =
    FutureProvider.autoDispose<List<ShoppingItem>>((
      ref,
    ) {
      final db = ref.watch(databaseProvider);
      final inventoryId = ref.watch(activeInventoryProvider);
      return db.getShoppingList(inventoryId: inventoryId);
    });

/// Provides only pending (not purchased) shopping list items, scoped to the
/// active inventory.
final FutureProvider<List<ShoppingItem>> pendingShoppingListProvider =
    FutureProvider.autoDispose<List<ShoppingItem>>((ref) {
      final db = ref.watch(databaseProvider);
      final inventoryId = ref.watch(activeInventoryProvider);
      return db.getPendingShoppingItems(inventoryId: inventoryId);
    });

/// Provides only purchased shopping list items, scoped to the active inventory.
final FutureProvider<List<ShoppingItem>> purchasedShoppingListProvider =
    FutureProvider.autoDispose<List<ShoppingItem>>((ref) {
      final db = ref.watch(databaseProvider);
      final inventoryId = ref.watch(activeInventoryProvider);
      return db.getPurchasedShoppingItems(inventoryId: inventoryId);
    });

/// Provides the count of pending (not purchased) items, scoped to the active
/// inventory.
final FutureProvider<int> pendingShoppingCountProvider =
    FutureProvider.autoDispose<int>((ref) {
      final db = ref.watch(databaseProvider);
      final inventoryId = ref.watch(activeInventoryProvider);
      return db.getPendingShoppingCount(inventoryId: inventoryId);
    });

/// Invalidates all shopping list providers.
///
/// Call this after every mutation so the UI refreshes.
void invalidateShoppingList(WidgetRef ref) {
  ref
    ..invalidate(shoppingListProvider)
    ..invalidate(pendingShoppingListProvider)
    ..invalidate(purchasedShoppingListProvider)
    ..invalidate(pendingShoppingCountProvider);
}

/// Adds an item to the shopping list, merging by barcode if a pending
/// item with the same barcode and unit already exists.
///
/// When an existing pending item has the same barcode and unit, the
/// quantities are summed instead of creating a duplicate row.
/// The item's inventoryId defaults to the active inventory if not set.
///
/// Before inserting, ensures the referenced product exists in the local
/// cache to avoid FOREIGN KEY constraint failures.  If the product is
/// missing and cannot be fetched, the barcode is set to null so the
/// insert still succeeds.
Future<void> addShoppingItem(WidgetRef ref, ShoppingItem item) async {
  final db = ref.read(databaseProvider);
  final database = await db.database;
  final activeInventoryId = ref.read(activeInventoryProvider);
  final repo = ref.read(productRepositoryProvider);
  var scopedItem = item.inventoryId == null
      ? item.copyWith(inventoryId: activeInventoryId)
      : item;

  // Ensure the product exists in cache before inserting (avoid FK failure).
  if (scopedItem.barcode != null && scopedItem.barcode!.isNotEmpty) {
    final existing = await db.getProduct(scopedItem.barcode!);
    if (existing == null) {
      try {
        logInfo(
          'Product ${scopedItem.barcode} not in cache — '
          'fetching before shopping list insert',
        );
        final fetched = await repo.getProduct(scopedItem.barcode!);
        await repo.cacheProduct(fetched);
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
    await db.shoppingListDao.insertOrMergeByBarcode(database, scopedItem);
    invalidateShoppingList(ref);
  } on Exception catch (e) {
    logError('Failed to add shopping item: $e');
    rethrow;
  }
}

/// Toggles the purchased state for the item with the given [id].
Future<void> toggleShoppingItem(WidgetRef ref, int id) async {
  final db = ref.read(databaseProvider);
  logInfo('Toggle shopping item — id=$id');
  await db.toggleShoppingItemPurchased(id);
  invalidateShoppingList(ref);
}

/// Deletes a shopping list item by [id].
Future<void> deleteShoppingItem(WidgetRef ref, int id) async {
  final db = ref.read(databaseProvider);
  final photoService = ref.read(photoServiceProvider);
  logInfo('Delete shopping item — id=$id');
  try {
    await photoService.deletePhotoForItem(id);
    await db.deleteShoppingItem(id);
    invalidateShoppingList(ref);
  } on Exception catch (e) {
    logError('Failed to delete shopping item id=$id: $e');
    rethrow;
  }
}

/// Deletes all purchased shopping list items for the active inventory.
Future<int> clearPurchasedShoppingItems(WidgetRef ref) async {
  final db = ref.read(databaseProvider);
  final inventoryId = ref.read(activeInventoryProvider);
  final deleted = await db.clearPurchasedShoppingItems(
    inventoryId: inventoryId,
  );
  logInfo('Cleared purchased shopping items — count=$deleted');
  invalidateShoppingList(ref);
  return deleted;
}

/// Updates only the price fields for the shopping item with the given [id].
Future<void> updateShoppingItemPrice(
  WidgetRef ref,
  int id, {
  double? priceAmount,
  String? priceCurrency,
  String? priceStore,
  String? pricePhotoPath,
}) async {
  final db = ref.read(databaseProvider);
  await db.updateShoppingItemPriceFields(
    id,
    priceAmount: priceAmount,
    priceCurrency: priceCurrency,
    priceStore: priceStore,
    pricePhotoPath: pricePhotoPath,
  );
  invalidateShoppingList(ref);
}

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

/// Moves purchased items (with barcodes) to the active inventory.
///
/// For each purchased item with a barcode, the product is ensured to exist
/// in the cache, and an inventory item is created (or merged if the same
/// barcode already exists in the target inventory). Price data on the
/// shopping item is saved to the prices table. The shopping item is then
/// deleted.
///
/// Items without a barcode or with no matching product in the cache are
/// skipped.
///
/// Returns a [MoveToInventoryResult] with counts of moved and skipped items.
/// Runs inside a SQLite transaction — all-or-nothing.
Future<MoveToInventoryResult> movePurchasedToInventory(
  WidgetRef ref,
) async {
  final db = ref.read(databaseProvider);
  final inventoryId = ref.read(activeInventoryProvider);
  final database = await db.database;

  var movedCount = 0;
  var skippedCount = 0;

  final allPurchased = await db.getPurchasedShoppingItems(
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
        where: 'barcode = ? AND inventory_id = ?',
        whereArgs: [item.barcode, inventoryId],
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
        logInfo(
          'Saved price — barcode=${item.barcode} '
          'amount=${item.priceAmount} ${item.priceCurrency}',
        );
      }

      await txn.delete(
        'shopping_list',
        where: 'id = ?',
        whereArgs: [item.id],
      );

      movedCount++;
    }
  });

  logInfo(
    'Move completed — moved=$movedCount skipped=$skippedCount',
  );

  invalidateShoppingList(ref);
  return MoveToInventoryResult(
    movedCount: movedCount,
    skippedCount: skippedCount,
  );
}

/// Provides distinct product barcodes and names from the active inventory
/// for the "From your pantry" suggestions in the add-to-shopping-list sheet.
final FutureProvider<List<Map<String, dynamic>>> inventoryProductsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
      final db = ref.watch(databaseProvider);
      final inventoryId = ref.watch(activeInventoryProvider);
      logInfo('Fetching distinct products from inventory $inventoryId');
      return db.getDistinctProductsFromInventory(inventoryId: inventoryId);
    });
