import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/models/price.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:sqflite/sqflite.dart';

/// Data-access layer for the prices table.
///
/// All methods receive a [Database] instance so they can be used
/// independently of [DatabaseHelper] in tests.
class PriceDao {
  /// Creates a [PriceDao].
  const PriceDao();

  /// Creates the prices table and its indexes.
  Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE prices (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        barcode TEXT NOT NULL,
        price REAL NOT NULL,
        currency TEXT NOT NULL,
        store TEXT,
        is_discounted INTEGER NOT NULL DEFAULT 0,
        regular_price REAL,
        date_purchased INTEGER,
        sync_status TEXT NOT NULL DEFAULT 'local_only',
        open_prices_id INTEGER,
        location_osm_id TEXT,
        location_osm_type TEXT,
        receipt_series TEXT,
        receipt_number TEXT,
        receipt_item_index INTEGER,
        notes TEXT,
        package_quantity REAL,
        package_unit TEXT,
        date_added INTEGER NOT NULL,
        inventory_id INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (barcode) REFERENCES products(barcode),
        FOREIGN KEY (inventory_id) REFERENCES inventories(id)
      )
    ''');
    await db.execute('CREATE INDEX idx_prices_barcode ON prices(barcode)');
    await db.execute(
      'CREATE INDEX idx_prices_date ON prices(date_purchased)',
    );
    await db.execute(
      'CREATE INDEX idx_prices_sync_status ON prices(sync_status)',
    );
    await db.execute(
      'CREATE INDEX idx_prices_inventory_id ON prices(inventory_id)',
    );
  }

  /// Converts a [Price] to a map for database insertion.
  Map<String, dynamic> toMap(Price p) => {
    'barcode': p.barcode,
    'price': p.price,
    'currency': p.currency,
    'store': p.store,
    'is_discounted': p.isDiscounted ? 1 : 0,
    'regular_price': p.regularPrice,
    'date_purchased': p.datePurchased,
    'sync_status': p.syncStatus,
    'open_prices_id': p.openPricesId,
    'location_osm_id': p.locationOsmId,
    'location_osm_type': p.locationOsmType,
    'receipt_series': p.receiptSeries,
    'receipt_number': p.receiptNumber,
    'receipt_item_index': p.receiptItemIndex,
    'notes': p.notes,
    'package_quantity': p.packageQuantity,
    'package_unit': p.packageUnit,
    'date_added': p.dateAdded ?? DateTime.now().millisecondsSinceEpoch,
    'inventory_id': p.inventoryId,
  };

  /// Converts a database row map into a [Price].
  Price fromMap(Map<String, dynamic> map) => Price(
    barcode: map['barcode'] as String,
    price: (map['price'] as num).toDouble(),
    currency: map['currency'] as String? ?? 'USD',
    id: map['id'] as int?,
    store: map['store'] as String?,
    isDiscounted: (map['is_discounted'] as int? ?? 0) == 1,
    regularPrice: (map['regular_price'] as num?)?.toDouble(),
    datePurchased: map['date_purchased'] as int?,
    syncStatus: map['sync_status'] as String? ?? priceSyncLocalOnly,
    openPricesId: map['open_prices_id'] as int?,
    locationOsmId: map['location_osm_id'] as String?,
    locationOsmType: map['location_osm_type'] as String?,
    receiptSeries: map['receipt_series'] as String?,
    receiptNumber: map['receipt_number'] as String?,
    receiptItemIndex: map['receipt_item_index'] as int?,
    notes: map['notes'] as String?,
    packageQuantity: (map['package_quantity'] as num?)?.toDouble(),
    packageUnit: map['package_unit'] as String?,
    dateAdded: map['date_added'] as int?,
    inventoryId: (map['inventory_id'] as num?)?.toInt() ?? 1,
  );

  /// Inserts a price row and returns its row ID.
  Future<int> insert(Database db, Price price) async {
    if (price.barcode.isEmpty) {
      throw ArgumentError('price barcode must not be empty');
    }
    logInfo('Inserting price for barcode ${price.barcode}');
    try {
      final id = await db.insert('prices', toMap(price));
      logInfo('Price inserted with id $id');
      return id;
    } on Exception catch (e) {
      logError('Failed to insert price: $e');
      rethrow;
    }
  }

  /// Returns the price with the given [id], or null if not found.
  Future<Price?> getById(Database db, int id) async {
    try {
      final result = await db.query(
        'prices',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (result.isEmpty) return null;
      return fromMap(result.first);
    } on Exception catch (e) {
      logError('Error looking up price $id: $e');
      rethrow;
    }
  }

  /// Returns all price entries for the given [barcode] and [inventoryId],
  /// ordered by datePurchased descending.
  Future<List<Price>> listByBarcode(
    Database db,
    String barcode, {
    required int inventoryId,
    int? limit,
    int? offset,
  }) async {
    try {
      final result = await db.query(
        'prices',
        where: 'barcode = ? AND inventory_id = ?',
        whereArgs: [barcode, inventoryId],
        orderBy: 'date_purchased DESC',
        limit: limit,
        offset: offset,
      );
      return result.map(fromMap).toList();
    } on Exception catch (e) {
      logError('Error listing prices for $barcode: $e');
      rethrow;
    }
  }

  /// Returns the most recent price for the given [barcode] and
  /// [inventoryId], or null if none exist.
  Future<Price?> getLatest(
    Database db,
    String barcode, {
    required int inventoryId,
  }) async {
    try {
      final result = await db.query(
        'prices',
        where: 'barcode = ? AND inventory_id = ?',
        whereArgs: [barcode, inventoryId],
        orderBy: 'date_purchased DESC',
        limit: 1,
      );
      if (result.isEmpty) return null;
      return fromMap(result.first);
    } on Exception catch (e) {
      logError('Error getting latest price for $barcode: $e');
      rethrow;
    }
  }

  /// Returns all prices in the database, ordered by datePurchased desc.
  Future<List<Price>> listAll(Database db, {int? limit, int? offset}) async {
    try {
      final result = await db.query(
        'prices',
        orderBy: 'date_purchased DESC',
        limit: limit,
        offset: offset,
      );
      return result.map(fromMap).toList();
    } on Exception catch (e) {
      logError('Error listing all prices: $e');
      rethrow;
    }
  }

  /// Updates an existing price row. Returns the number of rows affected.
  ///
  /// The original inventory_id is preserved from the existing row, so an
  /// update never silently moves a price to another inventory.
  Future<int> update(Database db, Price price) async {
    logInfo('Updating price ${price.id}');
    try {
      final existing = await getById(db, price.id!);
      final preservedInventoryId = existing?.inventoryId ?? price.inventoryId;
      final updated = price.copyWith(inventoryId: preservedInventoryId);
      final affected = await db.update(
        'prices',
        toMap(updated),
        where: 'id = ?',
        whereArgs: [price.id],
      );
      logInfo('Price ${price.id} updated, affected $affected rows');
      return affected;
    } on Exception catch (e) {
      logError('Failed to update price ${price.id}: $e');
      rethrow;
    }
  }

  /// Deletes the price with the given [id]. Returns the number of rows
  /// deleted.
  Future<int> delete(Database db, int id) async {
    logInfo('Deleting price $id');
    try {
      final affected = await db.delete(
        'prices',
        where: 'id = ?',
        whereArgs: [id],
      );
      logInfo('Price $id deleted');
      return affected;
    } on Exception catch (e) {
      logError('Failed to delete price $id: $e');
      rethrow;
    }
  }

  /// Returns the total number of prices on record for the given [barcode].
  Future<int> countByBarcode(Database db, String barcode) async {
    return Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM prices WHERE barcode = ?',
            [barcode],
          ),
        ) ??
        0;
  }

  /// Returns the total number of prices on record.
  Future<int> count(Database db) async {
    return Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM prices'),
        ) ??
        0;
  }

  /// Returns the total value of the most recent price for each distinct
  /// product in the given inventory, multiplied by the held quantity,
  /// summed together. Currency conversion is not applied here — the caller
  /// should convert via CurrencyService.
  ///
  /// Returns null when no items in the inventory have prices.
  Future<double?> totalInventoryValue(Database db, int inventoryId) async {
    final result = await db.rawQuery(
      '''
      SELECT SUM(p.price * i.total_quantity) as total
      FROM prices p
      INNER JOIN (
        SELECT barcode, MAX(date_purchased) as max_date
        FROM prices
        WHERE inventory_id = ?
        GROUP BY barcode
      ) latest ON p.barcode = latest.barcode
        AND p.date_purchased = latest.max_date
      INNER JOIN (
        SELECT barcode, SUM(quantity) as total_quantity
        FROM inventory
        WHERE inventory_id = ?
        GROUP BY barcode
      ) i ON i.barcode = p.barcode
      WHERE p.inventory_id = ?
    ''',
      [inventoryId, inventoryId, inventoryId],
    );
    final total = result.first['total'] as double?;
    return total;
  }

  /// Returns the total inventory value broken down by currency, using the
  /// most recent price per distinct product multiplied by the held
  /// quantity. Each row contains currency and subtotal columns.
  ///
  /// When all prices use the same currency, this returns a single row.
  /// When no items have prices, this returns an empty list.
  Future<List<Map<String, dynamic>>> totalInventoryValueByCurrency(
    Database db,
    int inventoryId,
  ) async {
    final result = await db.rawQuery(
      '''
      SELECT p.currency, SUM(p.price * i.total_quantity) as subtotal
      FROM prices p
      INNER JOIN (
        SELECT barcode, MAX(date_purchased) as max_date
        FROM prices
        WHERE inventory_id = ?
        GROUP BY barcode
      ) latest ON p.barcode = latest.barcode
        AND p.date_purchased = latest.max_date
      INNER JOIN (
        SELECT barcode, SUM(quantity) as total_quantity
        FROM inventory
        WHERE inventory_id = ?
        GROUP BY barcode
      ) i ON i.barcode = p.barcode
      WHERE p.inventory_id = ?
      GROUP BY p.currency
    ''',
      [inventoryId, inventoryId, inventoryId],
    );
    return result;
  }

  /// Returns the most recent price per distinct product in the inventory,
  /// with the total held quantity, for currency-aware averaging by the caller.
  ///
  /// Returns a list of maps with price, currency, total_quantity keys.
  Future<List<Map<String, dynamic>>> latestPricesWithCurrency(
    Database db,
    int inventoryId,
  ) async {
    final result = await db.rawQuery(
      '''
      SELECT p.price, p.currency, i.total_quantity
      FROM prices p
      INNER JOIN (
        SELECT barcode, MAX(date_purchased) as max_date
        FROM prices
        WHERE inventory_id = ?
        GROUP BY barcode
      ) latest ON p.barcode = latest.barcode
        AND p.date_purchased = latest.max_date
      INNER JOIN (
        SELECT barcode, SUM(quantity) as total_quantity
        FROM inventory
        WHERE inventory_id = ?
        GROUP BY barcode
      ) i ON i.barcode = p.barcode
      WHERE p.inventory_id = ?
    ''',
      [inventoryId, inventoryId, inventoryId],
    );
    return result;
  }

  /// Returns the quantity-weighted average of the most recent price for
  /// each distinct product in the given inventory.
  ///
  /// Returns null when no items in the inventory have prices.
  Future<double?> averageItemPrice(Database db, int inventoryId) async {
    final result = await db.rawQuery(
      '''
      SELECT SUM(p.price * i.total_quantity) as total,
             SUM(i.total_quantity) as total_qty
      FROM prices p
      INNER JOIN (
        SELECT barcode, MAX(date_purchased) as max_date
        FROM prices
        WHERE inventory_id = ?
        GROUP BY barcode
      ) latest ON p.barcode = latest.barcode
        AND p.date_purchased = latest.max_date
      INNER JOIN (
        SELECT barcode, SUM(quantity) as total_quantity
        FROM inventory
        WHERE inventory_id = ?
        GROUP BY barcode
      ) i ON i.barcode = p.barcode
      WHERE p.inventory_id = ?
    ''',
      [inventoryId, inventoryId, inventoryId],
    );
    final total = result.first['total'] as double?;
    final totalQty = result.first['total_qty'] as double?;
    if (total == null || totalQty == null || totalQty == 0) return null;
    return total / totalQty;
  }

  /// Returns the count of distinct products in the given inventory that
  /// have at least one price.
  Future<int> pricedItemCount(Database db, int inventoryId) async {
    return Sqflite.firstIntValue(
          await db.rawQuery(
            '''
        SELECT COUNT(DISTINCT i.barcode)
        FROM inventory i
        INNER JOIN prices p ON p.barcode = i.barcode
        WHERE i.inventory_id = ? AND p.inventory_id = ?
      ''',
            [inventoryId, inventoryId],
          ),
        ) ??
        0;
  }

  /// Returns prices with the given [syncStatus] for uploading to Open Prices.
  Future<List<Price>> getBySyncStatus(Database db, String syncStatus) async {
    try {
      final result = await db.query(
        'prices',
        where: 'sync_status = ?',
        whereArgs: [syncStatus],
        orderBy: 'date_purchased ASC',
      );
      return result.map(fromMap).toList();
    } on Exception catch (e) {
      logError('Error getting prices by sync status $syncStatus: $e');
      rethrow;
    }
  }

  /// Deletes price rows older than the given [retentionDays].
  ///
  /// Only deletes when [retentionDays] is positive. A value of 0 means
  /// keep prices forever (no deletion).
  Future<int> deleteStale(Database db, int retentionDays) async {
    if (retentionDays <= 0) return 0;
    final cutoff = DateTime.now()
        .subtract(Duration(days: retentionDays))
        .millisecondsSinceEpoch;
    final deleted = await db.delete(
      'prices',
      where: 'date_purchased < ? AND sync_status != ?',
      whereArgs: [cutoff, priceSyncPending],
    );
    if (deleted > 0) {
      logInfo('Deleted $deleted stale price rows');
    }
    return deleted;
  }

  /// Returns monthly expenditure grouped by ISO year-month for products
  /// in the given [inventoryId].
  ///
  /// Uses the latest price per product barcode, then groups by month of the
  /// purchase date. Returns raw rows {month, total} in base currency.
  Future<List<Map<String, dynamic>>> monthlyExpenditure(
    Database db, {
    required int inventoryId,
  }) async {
    try {
      final result = await db.rawQuery(
        '''
        WITH inventory_barcodes AS (
          SELECT barcode, SUM(quantity) AS total_quantity
          FROM inventory
          WHERE inventory_id = ?
          GROUP BY barcode
        ),
        latest_prices AS (
          SELECT p.barcode, p.price, p.date_purchased,
            ib.total_quantity,
            ROW_NUMBER() OVER (
              PARTITION BY p.barcode ORDER BY p.date_purchased DESC
            ) AS rn
          FROM prices p
          INNER JOIN inventory_barcodes ib ON p.barcode = ib.barcode
          WHERE p.inventory_id = ?
        )
        SELECT
          strftime('%Y-%m', date_purchased / 1000, 'unixepoch') AS month,
          SUM(price * total_quantity) AS total
        FROM latest_prices
        WHERE rn = 1
        GROUP BY month
        ORDER BY month ASC
      ''',
        [inventoryId, inventoryId],
      );
      logInfo(
        'Fetched monthly expenditure: ${result.length} months',
      );
      return result;
    } on Exception catch (e) {
      logError('Error fetching monthly expenditure: $e');
      rethrow;
    }
  }

  /// Returns spending grouped by store for products in the given
  /// [inventoryId].
  ///
  /// Uses the latest price per product barcode, then groups by store.
  /// Returns raw rows {store, total, item_count}.
  Future<List<Map<String, dynamic>>> storeSpending(
    Database db, {
    required int inventoryId,
  }) async {
    try {
      final result = await db.rawQuery(
        '''
        WITH inventory_barcodes AS (
          SELECT barcode, SUM(quantity) AS total_quantity
          FROM inventory
          WHERE inventory_id = ?
          GROUP BY barcode
        ),
        latest_prices AS (
          SELECT p.barcode, p.price, p.store,
            ib.total_quantity,
            ROW_NUMBER() OVER (
              PARTITION BY p.barcode ORDER BY p.date_purchased DESC
            ) AS rn
          FROM prices p
          INNER JOIN inventory_barcodes ib ON p.barcode = ib.barcode
          WHERE p.store IS NOT NULL AND p.store != ''
            AND p.inventory_id = ?
        )
        SELECT
          store,
          SUM(price * total_quantity) AS total,
          COUNT(*) AS item_count
        FROM latest_prices
        WHERE rn = 1
        GROUP BY store
        ORDER BY total DESC
      ''',
        [inventoryId, inventoryId],
      );
      logInfo('Fetched store spending: ${result.length} stores');
      return result;
    } on Exception catch (e) {
      logError('Error fetching store spending: $e');
      rethrow;
    }
  }

  /// Returns the average Nutri-Score per store for products in the
  /// given [inventoryId].
  ///
  /// Joins the prices and products tables on barcode, maps Nutri-Score grades
  /// (a-e) to numeric values (5-1), and averages per store.
  /// Stores with no priced products or null grades are excluded.
  /// Returns raw rows {store, avg_score}.
  Future<List<Map<String, dynamic>>> nutriscoreByStore(
    Database db, {
    required int inventoryId,
  }) async {
    try {
      final result = await db.rawQuery(
        '''
        WITH inventory_barcodes AS (
          SELECT DISTINCT barcode FROM inventory
          WHERE inventory_id = ?
        ),
        latest_prices AS (
          SELECT p.barcode, p.store,
            ROW_NUMBER() OVER (
              PARTITION BY p.barcode ORDER BY p.date_purchased DESC
            ) AS rn
          FROM prices p
          INNER JOIN inventory_barcodes ib ON p.barcode = ib.barcode
          WHERE p.store IS NOT NULL AND p.store != ''
            AND p.inventory_id = ?
        )
        SELECT
          lp.store,
          AVG(
            CASE pr.nutriscore_grade
              WHEN 'a' THEN 5
              WHEN 'b' THEN 4
              WHEN 'c' THEN 3
              WHEN 'd' THEN 2
              WHEN 'e' THEN 1
              ELSE NULL
            END
          ) AS avg_score
        FROM latest_prices lp
        INNER JOIN products pr ON lp.barcode = pr.barcode
        WHERE lp.rn = 1 AND pr.nutriscore_grade IS NOT NULL
        GROUP BY lp.store
        ORDER BY avg_score DESC
      ''',
        [inventoryId, inventoryId],
      );
      logInfo('Fetched Nutri-Score by store: ${result.length} stores');
      return result;
    } on Exception catch (e) {
      logError('Error fetching Nutri-Score by store: $e');
      rethrow;
    }
  }
}
