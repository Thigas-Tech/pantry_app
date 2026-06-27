import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/models/inventory_with_product.dart';
import 'package:pantry_app/providers/database_provider.dart';

/// Provides the joined list of inventory items with their product metadata.
///
/// This [FutureProvider] is watched by the [HomeScreen] to display the pantry
/// contents grouped by expiry status. It reads the [DatabaseHelper] via the
/// [databaseProvider] and calls [DatabaseHelper.getInventoryWithProduct],
/// which performs a single `INNER JOIN` query between `inventory` and
/// `products`.
///
/// ## Reactivity
///
/// The provider is **automatically invalidated** by the [HomeScreen] after a
/// new product is scanned and added to inventory, or after an inventory item
/// is created / updated / deleted. The manual refresh button in the app bar
/// also calls `ref.invalidate(inventoryWithProductProvider)` to force a
/// re‑fetch.
///
/// ## States
///
/// As a [FutureProvider], it exposes three states to the UI:
/// - **loading** – while the database query is running. The home screen shows
///   a shimmer placeholder during this time.
/// - **error** – if the database query throws an exception. The home screen
///   displays the error message.
/// - **data** – the list of [InventoryWithProduct] items, possibly empty.
final inventoryWithProductProvider = FutureProvider<List<InventoryWithProduct>>(
  (ref) async {
    final db = ref.watch(databaseProvider);
    final rows = await db.getInventoryWithProduct();
    return rows.map(InventoryWithProduct.fromMap).toList();
  },
);
