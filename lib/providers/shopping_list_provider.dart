import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/models/inventory_product_option.dart';
import 'package:pantry_app/models/shopping_item.dart';
import 'package:pantry_app/providers/active_inventory_provider.dart';
import 'package:pantry_app/providers/database_provider.dart';
import 'package:pantry_app/services/photo_service.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'shopping_list_provider.g.dart';

/// Provides a singleton [PhotoService] instance.
@Riverpod(keepAlive: true)
PhotoService photoService(Ref ref) {
  return PhotoService();
}

/// Provides all shopping list items, scoped to the active inventory.
@riverpod
Future<List<ShoppingItem>> shoppingList(Ref ref) async {
  final db = ref.watch(databaseProvider);
  final inventoryId = await ref.watch(activeInventoryProvider.future);
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
