import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/models/inventory_with_product.dart';
import 'package:pantry_app/providers/active_inventory_provider.dart';
import 'package:pantry_app/providers/database_provider.dart';
import 'package:pantry_app/widgets/nutriscore_badge.dart';

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
/// The provider is not reactive to database changes. It must be explicitly
/// invalidated via [WidgetRef.invalidate] after every inventory mutation
/// (add, update, delete, move).
final inventoryWithProductProvider = FutureProvider<List<InventoryWithProduct>>(
  (ref) async {
    final activeId = ref.watch<int>(activeInventoryProvider);
    final db = ref.watch(databaseProvider);
    final rows = await db.getInventoryWithProduct(inventoryId: activeId);
    final result = rows.map(InventoryWithProduct.fromMap).toList();
    return result;
  },
);

/// Provides the list of all inventories (id, name).
final inventoryListProvider = FutureProvider<List<Map<String, dynamic>>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.getInventories();
});

/// Provides the count of inventory items in the active inventory.
final inventoryCountProvider = FutureProvider<int>((ref) async {
  final items = await ref.watch(inventoryWithProductProvider.future);
  return items.length;
});

/// Provides the average Nutri-Score letter for the active inventory.
///
/// Returns a grade (`'a'`–`'e'`) or `null` if none of the products in the
/// current pantry have [NutriScoreBadge] data.
final averageNutriscoreProvider = FutureProvider<String?>((ref) async {
  final items = await ref.watch(inventoryWithProductProvider.future);
  final scores = <int>[];
  for (final item in items) {
    if (item.nutriscoreGrade != null) {
      final numeric = NutriScoreBadge.toNumeric(item.nutriscoreGrade);
      if (numeric != null) scores.add(numeric);
    }
  }
  if (scores.isEmpty) return null;
  final avg = scores.reduce((a, b) => a + b) / scores.length;
  final rounded = avg.round();
  return switch (rounded) {
    5 => 'a',
    4 => 'b',
    3 => 'c',
    2 => 'd',
    1 => 'e',
    _ => null,
  };
});
