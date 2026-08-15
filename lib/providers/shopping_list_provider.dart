import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/models/inventory_product_option.dart';
import 'package:pantry_app/models/shopping_item.dart';
import 'package:pantry_app/providers/active_inventory_provider.dart';
import 'package:pantry_app/providers/database_provider.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'shopping_list_provider.g.dart';

/// Provides all shopping list items, scoped to the active inventory.
@riverpod
Future<List<ShoppingItem>> shoppingList(Ref ref) async {
  final db = ref.watch(databaseProvider);
  final inventoryId = await ref.watch(activeInventoryProvider.future);
  return db.getShoppingList(inventoryId: inventoryId);
}

/// Provides all shopping list items for a specific [inventoryId].
///
/// Unlike [shoppingList] (which follows the active inventory), this family
/// is keyed by an explicit inventory so the market trip can operate on a
/// chosen pantry independently of the active one.
@riverpod
Future<List<ShoppingItem>> shoppingListByInventory(
  Ref ref,
  int inventoryId,
) {
  final db = ref.watch(databaseProvider);
  return db.getShoppingList(inventoryId: inventoryId);
}

/// Provides only pending (not purchased) shopping list items, scoped to the
/// active inventory.
@riverpod
Future<List<ShoppingItem>> pendingShoppingList(Ref ref) async {
  final db = ref.watch(databaseProvider);
  final inventoryId = await ref.watch(activeInventoryProvider.future);
  return db.getPendingShoppingItems(inventoryId: inventoryId);
}

/// Provides only purchased shopping list items, scoped to the active inventory.
@riverpod
Future<List<ShoppingItem>> purchasedShoppingList(Ref ref) async {
  final db = ref.watch(databaseProvider);
  final inventoryId = await ref.watch(activeInventoryProvider.future);
  return db.getPurchasedShoppingItems(inventoryId: inventoryId);
}

/// Provides the count of pending (not purchased) items, scoped to the active
/// inventory.
@riverpod
Future<int> pendingShoppingCount(Ref ref) async {
  final db = ref.watch(databaseProvider);
  final inventoryId = await ref.watch(activeInventoryProvider.future);
  return db.getPendingShoppingCount(inventoryId: inventoryId);
}

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

/// Invalidates the shopping list providers for a specific [inventoryId].
///
/// Invalidates [shoppingListByInventoryProvider] (used by the market trip,
/// which is scoped to a chosen pantry rather than the active one) in
/// addition to the active-inventory providers via [invalidateShoppingList].
/// Call this after every mutation that targets [inventoryId].
void invalidateShoppingListForInventory(WidgetRef ref, int inventoryId) {
  invalidateShoppingList(ref);
  ref.invalidate(shoppingListByInventoryProvider(inventoryId));
}

/// Provides distinct product barcodes and names from the active inventory
/// for the "From your pantry" suggestions in the add-to-shopping-list sheet.
@riverpod
Future<List<InventoryProductOption>> inventoryProducts(
  Ref ref,
) async {
  final db = ref.watch(databaseProvider);
  final inventoryId = await ref.watch(activeInventoryProvider.future);
  logInfo('Fetching distinct products from inventory $inventoryId');
  final rows = await db.getDistinctProductsFromInventory(
    inventoryId: inventoryId,
  );
  return rows.map(InventoryProductOption.fromMap).toList();
}
