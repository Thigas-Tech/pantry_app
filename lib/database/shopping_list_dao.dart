import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/models/shopping_item.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:sqflite/sqflite.dart';

/// Data-access layer for the `shopping_list` table.
///
/// All methods receive a [Database] instance so they can be used
/// independently of [DatabaseHelper] in tests.
class ShoppingListDao {
  /// Creates a [ShoppingListDao].
  const ShoppingListDao();

  /// Creates the `shopping_list` table.
  Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE shopping_list (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        barcode TEXT,
        name TEXT NOT NULL,
        quantity REAL NOT NULL DEFAULT 1.0,
        unit TEXT NOT NULL DEFAULT 'pieces',
        is_purchased INTEGER NOT NULL DEFAULT 0,
        inventory_id INTEGER,
        date_added INTEGER NOT NULL,
        date_purchased INTEGER,
        price_amount REAL,
        price_currency TEXT,
        price_store TEXT,
        price_photo_path TEXT,
        FOREIGN KEY (barcode) REFERENCES products(barcode)
          ON DELETE SET NULL,
        FOREIGN KEY (inventory_id) REFERENCES inventories(id)
          ON DELETE SET NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_shopping_barcode ON shopping_list(barcode)',
    );
    await db.execute(
      'CREATE INDEX idx_shopping_purchased ON shopping_list(is_purchased)',
    );
    await db.execute(
      'CREATE INDEX idx_shopping_inventory_id ON shopping_list(inventory_id)',
    );
  }

  /// Converts a [ShoppingItem] to a map for database insertion.
  Map<String, dynamic> toMap(ShoppingItem item) => {
    'barcode': item.barcode,
    'name': item.name,
    'quantity': item.quantity,
    'unit': item.unit,
    'is_purchased': item.isPurchased ? 1 : 0,
    'inventory_id': item.inventoryId,
    'date_added': item.dateAdded ?? DateTime.now().millisecondsSinceEpoch,
    'date_purchased': item.datePurchased,
    'price_amount': item.priceAmount,
    'price_currency': item.priceCurrency,
    'price_store': item.priceStore,
    'price_photo_path': item.pricePhotoPath,
  };

  /// Converts a database row map into a [ShoppingItem].
  ShoppingItem fromMap(Map<String, dynamic> map) => ShoppingItem(
    name: map['name'] as String,
    barcode: map['barcode'] as String?,
    quantity: (map['quantity'] as num?)?.toDouble() ?? 1.0,
    unit: map['unit'] as String? ?? 'pieces',
    isPurchased: (map['is_purchased'] as int? ?? 0) == 1,
    id: map['id'] as int?,
    inventoryId: map['inventory_id'] as int?,
    dateAdded: map['date_added'] as int?,
    datePurchased: map['date_purchased'] as int?,
    priceAmount: (map['price_amount'] as num?)?.toDouble(),
    priceCurrency: map['price_currency'] as String?,
    priceStore: map['price_store'] as String?,
    pricePhotoPath: map['price_photo_path'] as String?,
  );

  /// Inserts a shopping list item and returns its row ID.
  Future<int> insert(Database db, ShoppingItem item) async {
    logInfo('Inserting shopping item: ${item.name}');
    try {
      final id = await db.insert('shopping_list', toMap(item));
      logInfo('Shopping item inserted with id $id');
      return id;
    } on Exception catch (e) {
      logError('Failed to insert shopping item: $e');
      rethrow;
    }
  }

  /// Inserts a shopping list item, merging quantities with an existing
  /// pending item that has the same barcode and unit.
  ///
  /// When a pending (not purchased) item with the same barcode and unit
  /// already exists, the quantities are summed instead of creating a
  /// duplicate row. Items with a null/empty barcode or different units
  /// are always inserted as new rows. The operation runs inside a
  /// SQLite transaction to prevent double-tap race conditions.
  Future<int> insertOrMergeByBarcode(Database db, ShoppingItem item) async {
    logInfo('Insert/merge shopping item: ${item.name}');
    try {
      return await db.transaction<int>((txn) async {
        if (item.barcode != null && item.barcode!.isNotEmpty) {
          final existing = await txn.query(
            'shopping_list',
            where: 'barcode = ? AND is_purchased = 0 AND unit = ?',
            whereArgs: [item.barcode, item.unit],
            limit: 1,
          );
          if (existing.isNotEmpty) {
            final existingItem = fromMap(existing.first);
            final mergedQty = existingItem.quantity + item.quantity;
            await txn.update(
              'shopping_list',
              {'quantity': mergedQty},
              where: 'id = ?',
              whereArgs: [existingItem.id],
            );
            logInfo(
              'Merged quantity for ${item.barcode}: '
              '${existingItem.quantity} + ${item.quantity} = $mergedQty',
            );
            return existingItem.id!;
          }
        }
        final id = await txn.insert('shopping_list', toMap(item));
        logInfo('Shopping item inserted with id $id');
        return id;
      });
    } on Exception catch (e) {
      logError('Failed to insert/merge shopping item: $e');
      rethrow;
    }
  }

  /// Returns all shopping list items, optionally scoped to an inventory.
  ///
  /// When [inventoryId] is non-null, only items for that inventory are
  /// returned. Ordered by dateAdded descending.
  Future<List<ShoppingItem>> listAll(Database db, {int? inventoryId}) async {
    try {
      final result = await db.query(
        'shopping_list',
        where: inventoryId != null ? 'inventory_id = ?' : null,
        whereArgs: inventoryId != null ? [inventoryId] : null,
        orderBy: 'date_added DESC',
      );
      return result.map(fromMap).toList();
    } on Exception catch (e) {
      logError('Error listing shopping items: $e');
      rethrow;
    }
  }

  /// Returns only pending (not purchased) items, optionally scoped to an
  /// inventory. Ordered by dateAdded desc.
  Future<List<ShoppingItem>> listPending(
    Database db, {
    int? inventoryId,
  }) async {
    try {
      final where = inventoryId != null
          ? 'is_purchased = 0 AND inventory_id = ?'
          : 'is_purchased = 0';
      final whereArgs = inventoryId != null ? [inventoryId] : null;
      final result = await db.query(
        'shopping_list',
        where: where,
        whereArgs: whereArgs,
        orderBy: 'date_added DESC',
      );
      return result.map(fromMap).toList();
    } on Exception catch (e) {
      logError('Error listing pending shopping items: $e');
      rethrow;
    }
  }

  /// Returns only purchased items, optionally scoped to an inventory.
  /// Ordered by datePurchased desc.
  Future<List<ShoppingItem>> listPurchased(
    Database db, {
    int? inventoryId,
  }) async {
    try {
      final where = inventoryId != null
          ? 'is_purchased = 1 AND inventory_id = ?'
          : 'is_purchased = 1';
      final whereArgs = inventoryId != null ? [inventoryId] : null;
      final result = await db.query(
        'shopping_list',
        where: where,
        whereArgs: whereArgs,
        orderBy: 'date_purchased DESC',
      );
      return result.map(fromMap).toList();
    } on Exception catch (e) {
      logError('Error listing purchased shopping items: $e');
      rethrow;
    }
  }

  /// Updates an existing shopping list item. Returns rows affected.
  Future<int> update(Database db, ShoppingItem item) async {
    logInfo('Updating shopping item ${item.id}');
    try {
      final affected = await db.update(
        'shopping_list',
        toMap(item),
        where: 'id = ?',
        whereArgs: [item.id],
      );
      logInfo('Shopping item ${item.id} updated');
      return affected;
    } on Exception catch (e) {
      logError('Failed to update shopping item ${item.id}: $e');
      rethrow;
    }
  }

  /// Updates only the price-related columns for the shopping item
  /// with the given [id]. Leaves all other columns unchanged.
  Future<int> updatePriceFields(
    Database db,
    int id, {
    double? priceAmount,
    String? priceCurrency,
    String? priceStore,
    String? pricePhotoPath,
  }) async {
    logInfo('Updating price fields for shopping item $id');
    try {
      final affected = await db.update(
        'shopping_list',
        {
          'price_amount': priceAmount,
          'price_currency': priceCurrency,
          'price_store': priceStore,
          'price_photo_path': pricePhotoPath,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
      logInfo('Price fields updated for shopping item $id');
      return affected;
    } on Exception catch (e) {
      logError('Failed to update price fields for item $id: $e');
      rethrow;
    }
  }

  /// Deletes the item with the given [id]. Returns rows deleted.
  Future<int> delete(Database db, int id) async {
    logInfo('Deleting shopping item $id');
    try {
      final affected = await db.delete(
        'shopping_list',
        where: 'id = ?',
        whereArgs: [id],
      );
      logInfo('Shopping item $id deleted');
      return affected;
    } on Exception catch (e) {
      logError('Failed to delete shopping item $id: $e');
      rethrow;
    }
  }

  /// Toggles isPurchased for the item with the given [id].
  ///
  /// Sets datePurchased to now when marking as purchased, or null when
  /// un-marking.
  Future<void> togglePurchased(Database db, int id) async {
    logInfo('Toggling purchased state for item $id');
    try {
      final item = await getById(db, id);
      if (item == null) {
        logWarning('Item $id not found for toggle');
        return;
      }
      final now = DateTime.now().millisecondsSinceEpoch;
      await db.update(
        'shopping_list',
        {
          'is_purchased': item.isPurchased ? 0 : 1,
          'date_purchased': item.isPurchased ? null : now,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
      logInfo('Shopping item $id toggled');
    } on Exception catch (e) {
      logError('Failed to toggle item $id: $e');
      rethrow;
    }
  }

  /// Returns the item with the given [id], or `null`.
  Future<ShoppingItem?> getById(Database db, int id) async {
    try {
      final result = await db.query(
        'shopping_list',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (result.isEmpty) return null;
      return fromMap(result.first);
    } on Exception catch (e) {
      logError('Error looking up shopping item $id: $e');
      rethrow;
    }
  }

  /// Deletes all purchased items. Returns the number of rows deleted.
  Future<int> clearPurchased(Database db) async {
    logInfo('Clearing all purchased shopping items');
    try {
      final affected = await db.delete(
        'shopping_list',
        where: 'is_purchased = 1',
      );
      logInfo('Cleared $affected purchased items');
      return affected;
    } on Exception catch (e) {
      logError('Failed to clear purchased items: $e');
      rethrow;
    }
  }

  /// Marks items matching the given [barcode] as purchased.
  ///
  /// Used by NFC-e receipt scanning to auto-clear shopping list items
  /// when their barcode appears on a receipt.
  Future<int> markPurchasedByBarcode(Database db, String barcode) async {
    logInfo('Marking items with barcode $barcode as purchased');
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final affected = await db.update(
        'shopping_list',
        {'is_purchased': 1, 'date_purchased': now},
        where: 'barcode = ? AND is_purchased = 0',
        whereArgs: [barcode],
      );
      if (affected > 0) {
        logInfo('Marked $affected items as purchased via barcode $barcode');
      }
      return affected;
    } on Exception catch (e) {
      logError('Failed to mark by barcode $barcode: $e');
      rethrow;
    }
  }

  /// Returns the count of pending items, optionally scoped to an inventory.
  Future<int> pendingCount(Database db, {int? inventoryId}) async {
    final query = inventoryId != null
        ? 'SELECT COUNT(*) FROM shopping_list '
              'WHERE is_purchased = 0 AND inventory_id = ?'
        : 'SELECT COUNT(*) FROM shopping_list WHERE is_purchased = 0';
    final args = inventoryId != null ? [inventoryId] : null;
    return Sqflite.firstIntValue(await db.rawQuery(query, args)) ?? 0;
  }
}
