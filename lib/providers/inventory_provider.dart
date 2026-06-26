import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/models/inventory_with_product.dart';
import 'package:pantry_app/providers/database_provider.dart';

final inventoryWithProductProvider = FutureProvider<List<InventoryWithProduct>>(
  (ref) async {
    final db = ref.watch(databaseProvider);
    final rows = await db.getInventoryWithProduct();
    return rows.map(InventoryWithProduct.fromMap).toList();
  },
);
