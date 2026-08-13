import 'package:pantry_app/models/inventory_item.dart';
import 'package:pantry_app/providers/product_repository_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'inventory_for_barcode_provider.g.dart';

/// Provides the inventory items for a specific barcode in the given
/// inventory.
///
/// Keyed by a (barcode, inventoryId) record so each pantry keeps an
/// independent, cache-isolated list, matching the price providers. The
/// provider caches the query result across rebuilds, so the screen no
/// longer re-runs the database query on every build; mutation handlers
/// invalidate the family to refresh.
@riverpod
Future<List<InventoryItem>> inventoryForBarcode(
  Ref ref,
  (String, int) args,
) {
  final (barcode, inventoryId) = args;
  return ref
      .watch(productRepositoryProvider)
      .getInventoryForBarcode(barcode, inventoryId: inventoryId);
}
