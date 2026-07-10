import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/database/shopping_list_dao.dart';
import 'package:pantry_app/models/shopping_item.dart';
import 'package:pantry_app/providers/database_provider.dart';

/// Provides a singleton [ShoppingListDao] instance.
final shoppingListDaoProvider = Provider<ShoppingListDao>((ref) {
  return const ShoppingListDao();
});

/// Provides all shopping list items, ordered by dateAdded descending.
// ignore: specify_nonobvious_property_types
final shoppingListProvider = FutureProvider.autoDispose<List<ShoppingItem>>((
  ref,
) {
  final db = ref.watch(databaseProvider);
  return db.getShoppingList();
});

/// Provides only pending (not purchased) shopping list items.
// ignore: specify_nonobvious_property_types
final pendingShoppingListProvider =
    FutureProvider.autoDispose<List<ShoppingItem>>((ref) {
      final db = ref.watch(databaseProvider);
      return db.getPendingShoppingItems();
    });

/// Provides only purchased shopping list items.
// ignore: specify_nonobvious_property_types
final purchasedShoppingListProvider =
    FutureProvider.autoDispose<List<ShoppingItem>>((ref) {
      final db = ref.watch(databaseProvider);
      return db.getPurchasedShoppingItems();
    });

/// Provides the count of pending (not purchased) items.
// ignore: specify_nonobvious_property_types
final pendingShoppingCountProvider = FutureProvider.autoDispose<int>((ref) {
  final db = ref.watch(databaseProvider);
  return db.getPendingShoppingCount();
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
Future<void> addShoppingItem(WidgetRef ref, ShoppingItem item) async {
  final db = ref.read(databaseProvider);
  final database = await db.database;
  await db.shoppingListDao.insertOrMergeByBarcode(database, item);
  invalidateShoppingList(ref);
}

/// Toggles the purchased state for the item with the given [id].
Future<void> toggleShoppingItem(WidgetRef ref, int id) async {
  final db = ref.read(databaseProvider);
  await db.toggleShoppingItemPurchased(id);
  invalidateShoppingList(ref);
}

/// Deletes a shopping list item by [id].
Future<void> deleteShoppingItem(WidgetRef ref, int id) async {
  final db = ref.read(databaseProvider);
  await db.deleteShoppingItem(id);
  invalidateShoppingList(ref);
}

/// Deletes all purchased shopping list items.
Future<int> clearPurchasedShoppingItems(WidgetRef ref) async {
  final db = ref.read(databaseProvider);
  final deleted = await db.clearPurchasedShoppingItems();
  invalidateShoppingList(ref);
  return deleted;
}
