import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/models/inventory_with_product.dart';
import 'package:pantry_app/providers/active_inventory_provider.dart';
import 'package:pantry_app/providers/database_provider.dart';
import 'package:pantry_app/providers/product_repository_provider.dart';

/// Provides the joined list of inventory items for the currently active
/// pantry.
///
/// This [AsyncNotifierProvider] is watched by the home screen to display
/// the pantry contents grouped by expiry status. It reads the active
/// inventory ID from [activeInventoryProvider] and calls
/// [DatabaseHelper.getInventoryWithProduct] with that ID.
///
/// Mutations (add, delete, move) should be performed through the notifier
/// methods, which update the provider state automatically so that any
/// widget watching [pantryProvider] is notified immediately.
class Pantry extends AsyncNotifier<List<InventoryWithProduct>> {
  @override
  Future<List<InventoryWithProduct>> build() async {
    final activeId = ref.watch(activeInventoryProvider);
    final db = ref.watch(databaseProvider);
    final rows = await db.getInventoryWithProduct(inventoryId: activeId);
    return rows.map(InventoryWithProduct.fromMap).toList();
  }

  /// Refreshes all inventory products for the active inventory.
  Future<void> refresh() async {
    final activeId = ref.read(activeInventoryProvider);
    final repo = ref.read(productRepositoryProvider);
    await repo.refreshInventoryProducts(activeId);
    await repo.setLastRefreshTime();
    ref.invalidateSelf();
  }
}

/// Provides the joined list of inventory items for the currently active
/// pantry. Watched by the home screen and invalidated after mutations.
final pantryProvider =
    AsyncNotifierProvider<Pantry, List<InventoryWithProduct>>(Pantry.new);
