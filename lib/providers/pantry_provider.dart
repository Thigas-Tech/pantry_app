import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/models/inventory_with_product.dart';
import 'package:pantry_app/providers/active_inventory_provider.dart';
import 'package:pantry_app/providers/database_provider.dart';
import 'package:pantry_app/providers/product_repository_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'pantry_provider.g.dart';

/// Provides the joined list of inventory items for the currently active
/// pantry.
///
/// This keep-alive async notifier provider is watched by the home screen to
/// display the pantry contents grouped by expiry status. It reads the active
/// inventory ID from [activeInventoryProvider] and calls
/// [DatabaseHelper.getInventoryWithProduct] with that ID.
///
/// Mutations (add, delete, move) should be performed through the notifier
/// methods, which update the provider state automatically so that any
/// widget watching [pantryProvider] is notified immediately.
@Riverpod(keepAlive: true)
class Pantry extends _$Pantry {
  @override
  Future<List<InventoryWithProduct>> build() async {
    final activeId = await ref.watch(activeInventoryProvider.future);
    final db = ref.watch(databaseProvider);
    final rows = await db.getInventoryWithProduct(inventoryId: activeId);
    return rows.map(InventoryWithProduct.fromMap).toList();
  }

  /// Refreshes all inventory products for the active inventory.
  ///
  /// Invalidates self after the next frame to avoid build-phase crashes when
  /// the invalidation chain is triggered during a widget build cycle (e.g.
  /// TickerMode.didChangeDependencies resuming paused subscriptions).
  Future<void> refresh() async {
    final activeId = await ref.read(activeInventoryProvider.future);
    final repo = ref.read(productRepositoryProvider);
    await repo.refreshInventoryProducts(activeId);
    await repo.setLastRefreshTime();
    ref.invalidateSelf();
  }
}
