import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/models/inventory_with_product.dart';
import 'package:pantry_app/providers/active_inventory_provider.dart';
import 'package:pantry_app/providers/database_provider.dart';

/// Provides the joined list of inventory items for the currently active
/// inventory.
///
/// This [FutureProvider] is watched by the HomeScreen to display the pantry
/// contents grouped by expiry status. It reads the active inventory ID from
/// [activeInventoryProvider] and calls [DatabaseHelper.getInventoryWithProduct]
/// with that ID.
///
/// ## Reactivity
///
/// The provider is **automatically invalidated** whenever the inventory data
/// changes (item added/updated/deleted) or when the active inventory is
/// switched. This ensures the home screen always shows the current data.
final inventoryWithProductProvider = FutureProvider<List<InventoryWithProduct>>(
  (ref) async {
    await Future<void>.delayed(Duration.zero);
    final activeId = ref.watch<int>(activeInventoryProvider);
    final db = ref.watch(databaseProvider);
    final rows = await db.getInventoryWithProduct(inventoryId: activeId);
    return rows.map(InventoryWithProduct.fromMap).toList();
  },
);

/// Provides the list of all inventories (id, name).
final inventoryListProvider = FutureProvider<List<Map<String, dynamic>>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.getInventories();
});
