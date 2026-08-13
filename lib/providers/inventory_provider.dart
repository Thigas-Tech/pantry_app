import 'package:pantry_app/models/inventory_summary.dart';
import 'package:pantry_app/providers/database_provider.dart';
import 'package:pantry_app/providers/pantry_provider.dart';
import 'package:pantry_app/widgets/nutriscore_badge.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'inventory_provider.g.dart';

/// Provides the list of all inventories as typed [InventorySummary] rows.
@Riverpod(keepAlive: true)
Future<List<InventorySummary>> inventoryList(Ref ref) async {
  final db = ref.watch(databaseProvider);
  final rows = await db.getInventories();
  return rows.map(InventorySummary.fromMap).toList();
}

/// Provides the count of inventory items in the active pantry.
@Riverpod(keepAlive: true)
Future<int> inventoryCount(Ref ref) async {
  final items = await ref.watch(pantryProvider.future);
  return items.length;
}

/// Provides the total count of inventory items across ALL inventories.
///
/// Used to detect the first item ever added to any pantry (0→1 transition)
/// so the empty-pantry onboarding can auto-dismiss. Uses COUNT queries
/// instead of materializing the full joined rows just to take their length.
@Riverpod(keepAlive: true)
Future<int> totalInventoryCount(Ref ref) async {
  final db = ref.watch(databaseProvider);
  final inventories = await db.getInventories();
  var total = 0;
  for (final inv in inventories) {
    final summary = InventorySummary.fromMap(inv);
    total += await db.getInventoryCount(inventoryId: summary.id);
  }
  return total;
}

/// Provides the average Nutri-Score letter for the active inventory.
///
/// Returns a grade ('a'–'e') or null if none of the products in the
/// current pantry have [NutriScoreBadge] data.
@Riverpod(keepAlive: true)
Future<String?> averageNutriscore(Ref ref) async {
  final items = await ref.watch(pantryProvider.future);
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
}
