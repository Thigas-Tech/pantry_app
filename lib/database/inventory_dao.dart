import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/models/inventory_item.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:sqflite/sqflite.dart';

/// Data-access layer for the inventory table.
///
/// All methods receive a [Database] instance so they can be used
/// independently of [DatabaseHelper] in tests.
class InventoryDao {
  /// Creates an [InventoryDao].
  const InventoryDao();

  /// Converts an [InventoryItem] to a map for database insertion.
  Map<String, dynamic> toMap(InventoryItem item) => {
    if (item.id != null) 'id': item.id,
    'barcode': item.barcode,
    'quantity': item.quantity,
    'unit': item.unit,
    'expiry_date': item.expiryDate,
    'location': item.location,
    'notes': item.notes,
    'date_added': item.dateAdded,
    'inventory_id': item.inventoryId,
    'serving_weight_g': item.servingWeightG,
  };

  /// Converts a database row map into an [InventoryItem].
  InventoryItem fromMap(Map<String, dynamic> map) => InventoryItem(
    id: map['id'] as int?,
    barcode: map['barcode'] as String,
    quantity: (map['quantity'] as num?)?.toDouble() ?? 1,
    unit: map['unit'] as String? ?? 'pieces',
    expiryDate: map['expiry_date'] as String?,
    location: map['location'] as String? ?? 'pantry',
    notes: map['notes'] as String?,
    dateAdded: map['date_added'] as int?,
    inventoryId: map['inventory_id'] as int? ?? 1,
    servingWeightG: (map['serving_weight_g'] as num?)?.toDouble(),
  );

  /// Inserts a new inventory item.
  ///
  /// Throws [ArgumentError] if the barcode is empty.
  Future<int> insert(Database db, InventoryItem item) async {
    if (item.barcode.isEmpty) {
      throw ArgumentError('inventory barcode must not be empty');
    }
    logInfo(
      'Inserting inventory item: ${item.barcode} — '
      'qty: ${item.quantity} ${item.unit}, loc: ${item.location}',
    );
    try {
      final id = await db.insert('inventory', toMap(item));
      logInfo('Inventory item inserted with id $id');
      return id;
    } on Exception catch (e) {
      logError('Failed to insert inventory item for ${item.barcode}: $e');
      rethrow;
    }
  }

  /// Inserts an inventory item, merging quantities with an existing item
  /// that represents the same batch.
  ///
  /// An item is considered the same batch when it has the same barcode,
  /// inventoryId, expiry date, unit, and location. When such an item already
  /// exists, the quantities are summed instead of creating a duplicate row.
  /// Items that differ on any of these fields (for example a different expiry
  /// date) are inserted as a new row, keeping each batch separate. NULL
  /// values are compared with the null-safe IS operator so items without an
  /// expiry date merge with each other but stay separate from dated batches.
  /// The operation runs inside a SQLite transaction to prevent race
  /// conditions.
  Future<int> insertOrMergeByBarcode(Database db, InventoryItem item) async {
    logInfo('Insert/merge inventory item: ${item.barcode}');
    try {
      return await db.transaction<int>((txn) async {
        final expiryClause = item.expiryDate == null
            ? 'expiry_date IS NULL'
            : 'expiry_date = ?';
        final existing = await txn.query(
          'inventory',
          where:
              'barcode = ? AND inventory_id = ?'
              ' AND $expiryClause AND unit IS ? AND location IS ?',
          whereArgs: [
            item.barcode,
            item.inventoryId,
            if (item.expiryDate != null) item.expiryDate,
            item.unit,
            item.location,
          ],
          limit: 1,
        );
        if (existing.isNotEmpty) {
          final existingItem = fromMap(existing.first);
          final mergedQty = existingItem.quantity + item.quantity;
          await txn.update(
            'inventory',
            {'quantity': mergedQty},
            where: 'id = ?',
            whereArgs: [existingItem.id],
          );
          logInfo(
            'Merged inventory quantity for ${item.barcode}: '
            '${existingItem.quantity} + ${item.quantity} = $mergedQty',
          );
          final existingId = existingItem.id;
          if (existingId == null) {
            throw StateError('inventory row ${existingItem.id} has no id');
          }
          return existingId;
        }
        final id = await txn.insert('inventory', toMap(item));
        logInfo('Inventory item inserted with id $id');
        return id;
      });
    } on Exception catch (e) {
      logError('Failed to insert/merge inventory item: $e');
      rethrow;
    }
  }

  /// Retrieves all inventory items for a specific [inventoryId],
  /// optionally filtered by location.
  Future<List<InventoryItem>> list(
    Database db, {
    required int inventoryId,
    String? location,
  }) async {
    if (inventoryId <= 0) {
      throw ArgumentError('inventory id must be positive');
    }
    try {
      var where = 'inventory_id = ?';
      final whereArgs = <dynamic>[inventoryId];

      if (location != null) {
        where += ' AND location = ?';
        whereArgs.add(location);
      }

      final result = await db.query(
        'inventory',
        where: where,
        whereArgs: whereArgs,
        orderBy: 'expiry_date ASC',
      );
      logInfo('Fetched ${result.length} inventory items');
      return result.map(fromMap).toList();
    } on Exception catch (e) {
      logError('Error fetching inventory items: $e');
      rethrow;
    }
  }

  /// Returns all inventory entries for a specific barcode and [inventoryId],
  /// ordered by expiry date (oldest first).
  Future<List<InventoryItem>> listByBarcode(
    Database db,
    String barcode, {
    required int inventoryId,
  }) async {
    if (inventoryId <= 0) {
      throw ArgumentError('inventory id must be positive');
    }
    try {
      final result = await db.query(
        'inventory',
        where: 'barcode = ? AND inventory_id = ?',
        whereArgs: [barcode, inventoryId],
        orderBy: 'expiry_date ASC',
      );
      logInfo('Fetched ${result.length} items for barcode $barcode');
      return result.map(fromMap).toList();
    } on Exception catch (e) {
      logError('Error fetching inventory for $barcode: $e');
      rethrow;
    }
  }

  /// Updates an existing inventory item.
  Future<int> update(Database db, InventoryItem item) async {
    logInfo(
      'Updating inventory item ${item.id}: '
      'qty=${item.quantity} ${item.unit}, loc=${item.location}',
    );
    try {
      final rows = await db.update(
        'inventory',
        toMap(item),
        where: 'id = ?',
        whereArgs: [item.id],
      );
      logInfo('Updated $rows row(s) for inventory item ${item.id}');
      return rows;
    } on Exception catch (e) {
      logError('Failed to update inventory item ${item.id}: $e');
      rethrow;
    }
  }

  /// Deletes an inventory item by its ID.
  Future<int> delete(Database db, int id) async {
    logInfo('Deleting inventory item $id');
    try {
      final rows = await db.delete(
        'inventory',
        where: 'id = ?',
        whereArgs: [id],
      );
      logInfo('Deleted $rows row(s) for inventory item $id');
      return rows;
    } on Exception catch (e) {
      logError('Failed to delete inventory item $id: $e');
      rethrow;
    }
  }

  /// Deletes multiple inventory items in one batch.
  ///
  /// Uses a single transaction-backed batch DELETE instead of one
  /// statement per id. Returns the number of deleted rows.
  Future<int> deleteMany(Database db, List<int> ids) async {
    if (ids.isEmpty) return 0;
    logInfo('Deleting ${ids.length} inventory item(s)');
    try {
      final batch = db.batch();
      for (final id in ids) {
        batch.delete('inventory', where: 'id = ?', whereArgs: [id]);
      }
      final results = await batch.commit();
      final deleted = results.fold<int>(
        0,
        (sum, r) => sum + ((r as int?) ?? 0),
      );
      logInfo('Deleted $deleted item(s) successfully');
      return deleted;
    } on Exception catch (e) {
      logError('Failed to delete inventory items: $e');
      rethrow;
    }
  }

  /// Moves multiple inventory items to a different inventory (pantry).
  ///
  /// Uses a batch UPDATE to atomically reassign all [itemIds] to the
  /// [targetInventoryId]. Logs the number of affected rows on success.
  Future<void> moveItemsToInventory(
    Database db,
    List<int> itemIds,
    int targetInventoryId,
  ) async {
    logInfo(
      'Moving ${itemIds.length} item(s) to inventory $targetInventoryId',
    );
    try {
      final batch = db.batch();
      for (final id in itemIds) {
        batch.update(
          'inventory',
          {'inventory_id': targetInventoryId},
          where: 'id = ?',
          whereArgs: [id],
        );
      }
      final results = await batch.commit(noResult: true);
      logInfo('Moved ${results.length} item(s) successfully');
    } on Exception catch (e) {
      logError('Failed to move items to inventory $targetInventoryId: $e');
      rethrow;
    }
  }

  /// Retrieves all inventory rows joined with product metadata for a
  /// specific [inventoryId].
  ///
  /// Uses a LEFT JOIN on products so that inventory items remain visible
  /// even when their product record has been deleted (e.g. after a cache
  /// flush). When the product is missing, product fields such as
  /// product_name will be NULL and should be handled by the UI (e.g.
  /// falling back to the barcode).
  Future<List<Map<String, dynamic>>> listWithProduct(
    Database db, {
    required int inventoryId,
  }) async {
    try {
      final result = await db.rawQuery(
        '''
        SELECT
          inventory.id,
          inventory.barcode,
          inventory.quantity,
          inventory.unit,
          inventory.expiry_date,
          inventory.location,
          inventory.notes,
          inventory.date_added,
          inventory.inventory_id,
          products.name AS product_name,
          products.image_url AS product_image_url,
          products.nutriscore_grade AS nutriscore_grade,
          products.nutriscore_not_applicable_category
            AS nutriscore_not_applicable_category,
          products.category AS product_category,
          products.search_text AS product_search_text,
          products.product_type AS product_type,
          inventories.name AS inventory_name
        FROM inventory
        LEFT JOIN products ON inventory.barcode = products.barcode
        INNER JOIN inventories ON inventory.inventory_id = inventories.id
        WHERE inventory.inventory_id = ?
        ORDER BY inventory.expiry_date ASC
      ''',
        [inventoryId],
      );
      logInfo('Fetched ${result.length} inventory-with-product rows');
      return result;
    } on Exception catch (e) {
      logError('Error fetching inventory with product data: $e');
      rethrow;
    }
  }

  /// Returns the total number of rows in the inventory table.
  Future<int> count(Database db, {int? inventoryId}) async {
    if (inventoryId != null) {
      return Sqflite.firstIntValue(
            await db.rawQuery(
              'SELECT COUNT(*) FROM inventory WHERE inventory_id = ?',
              [inventoryId],
            ),
          ) ??
          0;
    }
    return Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM inventory'),
        ) ??
        0;
  }

  /// Returns counts of items grouped by storage location.
  Future<Map<String, int>> locationDistribution(
    Database db, {
    required int inventoryId,
  }) async {
    final rows = await db.rawQuery(
      '''
      SELECT location, COUNT(*) as cnt
      FROM inventory
      WHERE inventory_id = ?
      GROUP BY location
    ''',
      [inventoryId],
    );
    return {
      for (final r in rows)
        r['location'] as String? ?? 'unknown': r['cnt'] as int? ?? 0,
    };
  }

  /// Returns counts grouped by expiry status.
  ///
  /// Items with a NULL expiry date are counted as good. Items expiring
  /// within [expiringSoonDays] days are counted as expiring. Items with
  /// a date before today are counted as expired.
  Future<Map<String, int>> expiryDistribution(
    Database db, {
    required int inventoryId,
    required int expiringSoonDays,
  }) async {
    final rows = await db.rawQuery(
      '''
      SELECT
        CASE
          WHEN expiry_date IS NULL THEN 'good'
          WHEN date(expiry_date) < date('now') THEN 'expired'
          WHEN date(expiry_date) <= date('now', '+' || ? || ' days')
            THEN 'expiring'
          ELSE 'good'
        END as status,
        COUNT(*) as cnt
      FROM inventory
      WHERE inventory_id = ?
      GROUP BY status
    ''',
      [expiringSoonDays, inventoryId],
    );
    return {
      for (final r in rows)
        r['status'] as String? ?? 'good': r['cnt'] as int? ?? 0,
    };
  }

  /// Returns the most recent [InventoryItem.dateAdded] across all inventories.
  ///
  /// Returns null if the inventory table is empty.
  Future<int?> getLastAddDate(Database db) async {
    try {
      final result = await db.rawQuery(
        'SELECT MAX(date_added) AS last_added FROM inventory',
      );
      return result.first['last_added'] as int?;
    } on Exception catch (e) {
      logError('Failed to get last add date: $e');
      return null;
    }
  }

  /// Returns weekly item-addition counts for the last [weeks] weeks.
  ///
  /// Items without a [InventoryItem.dateAdded] are excluded.
  Future<List<Map<String, dynamic>>> weeklyAdditions(
    Database db, {
    required int inventoryId,
    int weeks = 8,
  }) {
    return db.rawQuery(
      '''
      SELECT
        strftime('%Y-%W', date_added / 1000, 'unixepoch') as week,
        COUNT(*) as cnt
      FROM inventory
      WHERE inventory_id = ?
        AND date_added IS NOT NULL
      GROUP BY week
      ORDER BY week DESC
      LIMIT ?
    ''',
      [inventoryId, weeks],
    );
  }

  /// Returns distinct product barcodes and names from the inventory
  /// for a given [inventoryId], limited to [limit] most recent entries.
  ///
  /// Useful for suggesting "from your pantry" items when adding to a
  /// shopping list.
  Future<List<Map<String, dynamic>>> distinctProductsFromInventory(
    Database db, {
    required int inventoryId,
    int limit = 20,
  }) async {
    try {
      final result = await db.rawQuery(
        '''
        SELECT
          products.barcode,
          products.name,
          products.image_url,
          products.product_type,
          MAX(inventory.date_added) AS last_added
        FROM inventory
        INNER JOIN products ON inventory.barcode = products.barcode
        WHERE inventory.inventory_id = ?
        GROUP BY products.barcode
        ORDER BY last_added DESC
        LIMIT ?
      ''',
        [inventoryId, limit],
      );
      logInfo(
        'Fetched ${result.length} distinct products from inventory',
      );
      return result;
    } on Exception catch (e) {
      logError('Error fetching distinct products from inventory: $e');
      rethrow;
    }
  }
}
