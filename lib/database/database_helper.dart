import 'package:pantry_app/cache_config.dart';
import 'package:pantry_app/database/inventories_dao.dart';
import 'package:pantry_app/database/inventory_dao.dart';
import 'package:pantry_app/database/migrations/all_migrations.dart';
import 'package:pantry_app/database/migrations/migration_runner.dart';
import 'package:pantry_app/database/price_dao.dart';
import 'package:pantry_app/database/product_dao.dart';
import 'package:pantry_app/database/product_submission_queue_dao.dart';
import 'package:pantry_app/database/recipe_dao.dart';
import 'package:pantry_app/database/recipe_history_dao.dart';
import 'package:pantry_app/database/recipe_ingredient_dao.dart';
import 'package:pantry_app/database/scan_history_dao.dart';
import 'package:pantry_app/database/shopping_list_dao.dart';
import 'package:pantry_app/database/store_dao.dart';
import 'package:pantry_app/models/inventory_item.dart';
import 'package:pantry_app/models/price.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/models/recipe.dart';
import 'package:pantry_app/models/recipe_history_entry.dart';
import 'package:pantry_app/models/recipe_ingredient.dart';
import 'package:pantry_app/models/scan_history_entry.dart';
import 'package:pantry_app/models/shopping_item.dart';
import 'package:pantry_app/models/store.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// Provides access to the local SQLite database.
///
/// [DatabaseHelper] is normally a **singleton** – only one instance exists
/// during the lifetime of the app. The singleton pattern guarantees that all
/// database operations use the same connection.
///
/// For **testing** a separate instance can be created with the named
/// constructor [DatabaseHelper.withPath], which opens an in‑memory database
/// or a temporary file.
///
/// ## Schema overview
///
/// Eleven tables are created on first launch:
/// - products – product data fetched from Open Food Facts.
/// - inventories – named pantries (e.g. "Home", "Work").
/// - inventory – instances of products the user has added to a pantry.
/// - product_submission_queue – offline queue for OFF product submissions.
/// - prices – purchase price observations per barcode.
/// - shopping_list – items the user intends to buy.
/// - stores – saved store names for autocomplete.
/// - recipes – user-created recipes.
/// - recipe_ingredients – ingredients linked to a recipe.
/// - recipe_history – history of cooked recipes.
/// - scan_history – snapshots of recent successful barcode/PLU scans.
///
/// ## Delegation
///
/// CRUD operations are delegated to dedicated DAO classes:
/// [ProductDao], [InventoryDao], [InventoriesDao], [PriceDao],
/// [ShoppingListDao], [StoreDao], [ProductSubmissionQueueDao],
/// [RecipeDao], [RecipeIngredientDao], [ScanHistoryDao].
///
/// See also:
/// - [sqflite](https://pub.dev/packages/sqflite) — the SQLite plugin
///   used for local storage.
/// - [path_provider](https://pub.dev/packages/path_provider)
///   — platform‑specific directory resolution.
class DatabaseHelper {
  /// Returns the single [DatabaseHelper] instance.
  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal() : _customPath = null;

  /// Creates a [DatabaseHelper] that opens a database at the given [path].
  DatabaseHelper.withPath(String path) : _customPath = path;

  final String? _customPath;

  static final DatabaseHelper _instance = DatabaseHelper._internal();

  /// DAO for the products table.
  final ProductDao productDao = const ProductDao();

  /// DAO for the inventory table.
  final InventoryDao inventoryDao = const InventoryDao();

  /// DAO for the inventories table.
  final InventoriesDao inventoriesDao = const InventoriesDao();

  /// DAO for the product_submission_queue table.
  final ProductSubmissionQueueDao productSubmissionQueueDao =
      ProductSubmissionQueueDao();

  /// DAO for the prices table.
  final PriceDao priceDao = const PriceDao();

  /// DAO for the shopping_list table.
  final ShoppingListDao shoppingListDao = const ShoppingListDao();

  /// DAO for the stores table.
  final StoreDao storeDao = const StoreDao();

  /// DAO for the recipes table.
  final RecipeDao recipeDao = const RecipeDao();

  /// DAO for the recipe_ingredients table.
  final RecipeIngredientDao recipeIngredientDao = const RecipeIngredientDao();

  /// DAO for the recipe_history table.
  final RecipeHistoryDao recipeHistoryDao = const RecipeHistoryDao();

  /// DAO for the scan_history table.
  final ScanHistoryDao scanHistoryDao = const ScanHistoryDao();

  /// The current database schema version.
  ///
  /// Must match the highest (and last) migration declared
  /// in [allMigrations].
  static const int databaseVersion = 46;

  /// The lazily‑opened database instance, with in-flight dedup so several
  /// concurrent first accesses share a single open.
  Future<Database> get database {
    return _databaseFuture ??= _initDatabase();
  }

  Future<Database>? _databaseFuture;

  Future<Database> _initDatabase() async {
    final dbPath = _customPath ?? (await _getDefaultPath());
    logInfo('Opening database at $dbPath');
    try {
      final db = await openDatabase(
        dbPath,
        version: databaseVersion,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
          // Use the multiplatform helper: Android execSQL rejects the
          // row-returning PRAGMA journal_mode = WAL, so setJournalMode
          // falls back to rawQuery there (sqflite issue #929).
          await db.setJournalMode('WAL');
          await db.execute('PRAGMA synchronous = FULL');
          await db.execute('PRAGMA cache_size = -2000');
          // PRAGMA mmap_size returns the new value as a row, which Android
          // execSQL rejects; run it through rawQuery instead.
          await db.rawQuery('PRAGMA mmap_size = 268435456');
        },
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onDowngrade: onDatabaseDowngradeDelete,
        onOpen: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
          final mode = await db.rawQuery('PRAGMA journal_mode');
          if (mode.first['journal_mode'] != 'wal') {
            logWarning('WAL journal mode is not active on database open');
          }
          // Refresh the query planner statistics; cheap and recommended
          // after any schema or data changes.
          await db.execute('PRAGMA optimize');
        },
      );
      logInfo('Database opened successfully');
      return db;
    } on Exception catch (e) {
      logError('Failed to open database: $e');
      rethrow;
    }
  }

  Future<String> _getDefaultPath() async {
    final documentsDir = await getApplicationDocumentsDirectory();
    return join(documentsDir.path, 'pantry.db');
  }

  /// Runs [PRAGMA quick_check] on the database after open.
  ///
  /// Logs a warning when corruption is detected. This is a non-fatal check
  /// -- the app continues even if the integrity check reports issues.
  Future<void> _checkIntegrity(Database db) async {
    try {
      final result = await db.rawQuery('PRAGMA quick_check');
      final status = result.first.values.first as String? ?? '';
      if (status != 'ok') {
        logWarning('Database integrity check failed: $status');
      }
    } on Exception catch (e) {
      logWarning('Integrity check query failed: $e');
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    logInfo('Creating database schema (version $version)');

    await db.execute('''
      CREATE TABLE products (
        barcode TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        brand TEXT,
        image_url TEXT,
        category TEXT,
        ingredients TEXT,
        serving_size TEXT,
        serving_quantity REAL,
        quantity TEXT,
        product_quantity REAL,
        energy_kcal REAL,
        protein_g REAL,
        carbs_g REAL,
        fat_g REAL,
        fiber_g REAL,
        salt_g REAL,
        additional_nutrients TEXT,
        last_synced INTEGER,
        nutriscore_grade TEXT,
        nutriscore_not_applicable_category TEXT,
        source TEXT NOT NULL DEFAULT 'api',
        nutrition_image_path TEXT,
        ingredients_image_path TEXT,
        product_image_path TEXT,
        submission_status TEXT NOT NULL DEFAULT 'not_submitted',
        off_nutrition_image_url TEXT,
        off_ingredients_image_url TEXT,
        off_product_image_url TEXT,
        categories_hierarchy TEXT,
        language_code TEXT NOT NULL DEFAULT 'en',
        search_text TEXT,
        plu_code TEXT,
        product_type TEXT NOT NULL DEFAULT 'barcoded'
      )
    ''');

    await inventoriesDao.createTable(db);

    await db.execute('''
      CREATE TABLE inventory (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        barcode TEXT NOT NULL,
        quantity REAL DEFAULT 1,
        unit TEXT DEFAULT 'pieces',
        expiry_date TEXT,
        location TEXT DEFAULT 'pantry',
        notes TEXT,
        date_added INTEGER,
        inventory_id INTEGER NOT NULL,
        serving_weight_g REAL,
        FOREIGN KEY(barcode) REFERENCES products(barcode),
        FOREIGN KEY(inventory_id) REFERENCES inventories(id)
      )
    ''');

    await db.execute('CREATE INDEX idx_search_text ON products(search_text)');
    await db.execute('CREATE INDEX idx_expiry ON inventory(expiry_date)');
    await db.execute(
      'CREATE INDEX idx_inventory_id ON inventory(inventory_id)',
    );
    await db.execute(
      'CREATE INDEX idx_inventory_date_added ON inventory(date_added)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_inventory_barcode_inventory_id '
      'ON inventory(barcode, inventory_id)',
    );
    await db.execute(
      'CREATE INDEX idx_inventory_inventory_expiry'
      ' ON inventory(inventory_id, expiry_date)',
    );
    await db.execute(
      'CREATE INDEX idx_inventory_inventory_barcode'
      ' ON inventory(inventory_id, barcode)',
    );
    await db.execute(
      'CREATE INDEX idx_products_source ON products(source)',
    );

    await productSubmissionQueueDao.createTable(db);

    await priceDao.createTable(db);

    await db.execute(
      'CREATE INDEX idx_prices_barcode_inventory_date'
      ' ON prices(barcode, inventory_id, date_purchased)',
    );

    await _createShoppingListTable(db);

    await db.execute(
      'CREATE INDEX idx_shopping_list_inventory_purchased_date'
      ' ON shopping_list(inventory_id, is_purchased, date_added)',
    );
    await db.execute(
      'CREATE INDEX idx_shopping_inventory_purchased_sort'
      ' ON shopping_list(inventory_id, is_purchased, sort_order)',
    );

    await _createStoresTable(db);

    await recipeDao.createTable(db);

    for (final col in ['name', 'created_at', 'updated_at']) {
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_recipes_$col'
        ' ON recipes($col)',
      );
    }
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_recipes_inventory_updated'
      ' ON recipes(inventory_id, updated_at)',
    );

    await recipeIngredientDao.createTable(db);

    await recipeHistoryDao.createTable(db);

    await scanHistoryDao.createTable(db);

    await inventoriesDao.seedDefault(db);

    logInfo('Database schema created successfully');
  }

  Future<void> _createShoppingListTable(Database db) async {
    await shoppingListDao.createTable(db);
  }

  Future<void> _createStoresTable(Database db) async {
    await storeDao.createTable(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    logInfo('Database upgrade: $oldVersion → $newVersion');
    await MigrationRunner(allMigrations()).run(
      db,
      oldVersion,
      newVersion,
    );
    logInfo('Database upgrade completed successfully');
    // Verify the upgraded database is structurally sound. Running this
    // only after upgrades avoids the per-launch cost of quick_check on
    // large databases.
    await _checkIntegrity(db);
  }

  // --------------------- Product (delegating to ProductDao) -------

  /// Inserts a product into the local cache (upsert).
  Future<void> insertProduct(Product product) async {
    final db = await database;
    return productDao.insert(db, product);
  }

  /// Looks up a single product by its barcode.
  Future<Product?> getProduct(String barcode) async {
    final db = await database;
    return productDao.get(db, barcode);
  }

  /// Returns all cached products whose barcode is in [barcodes].
  Future<List<Product>> getProductsByBarcodes(List<String> barcodes) async {
    final db = await database;
    return productDao.getByBarcodes(db, barcodes);
  }

  /// Returns the total number of cached product records.
  Future<int> getProductCount() async {
    final db = await database;
    return productDao.count(db);
  }

  /// Returns all cached products.
  Future<List<Product>> getAllProducts() async {
    final db = await database;
    return productDao.all(db);
  }

  /// Searches the products table by name or barcode.
  ///
  /// Delegates to [ProductDao.search] with a case‑insensitive LIKE query.
  Future<List<Product>> searchProducts(String query) async {
    final db = await database;
    return productDao.search(db, query);
  }

  /// Returns only products fetched from the Open Food Facts API.
  ///
  /// These are safe to flush and re‑fetch. Products entered manually
  /// (source = 'manual') are excluded.
  Future<List<Product>> getCachedProducts() async {
    final db = await database;
    return productDao.getBySource(db, 'api');
  }

  /// Deletes all API‑fetched products from the local cache.
  ///
  /// Products with [Product.source] 'manual' are kept. Used during app
  /// update and manual cache flush so that user‑entered data is never lost.
  ///
  /// Foreign key enforcement is temporarily disabled because inventory rows
  /// and prices legitimately survive cache flushes (they are LEFT JOINed).
  /// Shopping list items have ON DELETE SET NULL which also requires FK
  /// enforcement to be active — after deletion, shopping list barcode
  /// references are explicitly cleaned up. PRAGMA foreign_keys is a no-op
  /// inside a transaction, so it is toggled around (not within) the
  /// transaction that makes the deletion atomic.
  Future<void> clearCachedProducts() async {
    final db = await database;
    await db.execute('PRAGMA foreign_keys = OFF');
    try {
      await db.transaction((txn) async {
        // Null out shopping list barcode refs to API products before
        // deleting.
        await txn.rawUpdate('''
          UPDATE shopping_list SET barcode = NULL
          WHERE barcode IN (SELECT barcode FROM products WHERE source = 'api')
        ''');
        final count = await txn.delete(
          'products',
          where: "source = 'api'",
        );
        logInfo('Deleted $count products with source "api"');
      });
    } finally {
      await db.execute('PRAGMA foreign_keys = ON');
    }
  }

  /// Removes API-fetched product rows whose [Product.lastSynced] timestamp is
  /// older than [maxAge].
  ///
  /// This is the age-based device cache flush: cached products older than the
  /// two-month [productCacheMaxAge] window are removed so they are re-fetched
  /// on the next access or background refresh. Manual products
  /// ([Product.source] 'manual') are always preserved. A product with a null
  /// [Product.lastSynced] is treated as expired because it was never
  /// successfully timestamped.
  ///
  /// Foreign key enforcement is temporarily disabled because inventory rows
  /// survive the flush (they are LEFT JOINed and re-fetched later), mirroring
  /// [clearCachedProducts]. Shopping list barcode references are explicitly
  /// nulled before the deletion. PRAGMA foreign_keys is a no-op inside a
  /// transaction, so it is toggled around (not within) the transaction that
  /// makes the deletion atomic.
  ///
  /// Returns the number of deleted product rows. [now] is injectable for
  /// deterministic tests and defaults to [DateTime.now].
  Future<int> flushExpiredCachedProducts({
    Duration maxAge = productCacheMaxAge,
    DateTime Function()? now,
  }) async {
    final db = await database;
    final cutoff = (now ?? DateTime.now)()
        .subtract(maxAge)
        .millisecondsSinceEpoch;
    logInfo(
      'Flushing cached products last synced before '
      '${DateTime.fromMillisecondsSinceEpoch(cutoff).toIso8601String()}'
      ' (max age: ${maxAge.inDays} days)',
    );

    await db.execute('PRAGMA foreign_keys = OFF');
    try {
      final deleted = await db.transaction<int>((txn) async {
        await txn.rawUpdate(
          '''
          UPDATE shopping_list SET barcode = NULL
          WHERE barcode IN (
            SELECT barcode FROM products
            WHERE source = 'api' AND (last_synced IS NULL OR last_synced < ?)
          )
        ''',
          [cutoff],
        );
        return txn.delete(
          'products',
          where: "source = 'api' AND (last_synced IS NULL OR last_synced < ?)",
          whereArgs: [cutoff],
        );
      });
      logInfo('Removed $deleted expired cached products');
      await db.execute('PRAGMA optimize');
      return deleted;
    } finally {
      await db.execute('PRAGMA foreign_keys = ON');
    }
  }

  /// Deletes every product from the products table.
  ///
  /// Intended for teardown in integration tests only. Production code
  /// should call [clearCachedProducts] instead.
  Future<void> clearAllProducts() async {
    final db = await database;
    return productDao.clear(db);
  }

  /// Removes stale inventory items and orphaned products.
  ///
  /// [retentionDays] applies to inventory items only. Price rows use
  /// [priceRetentionDays] (default 0 = keep forever).
  ///
  /// Price history is never deleted because a product is absent from the
  /// pantry: price observations are the user's own records and must survive
  /// cache maintenance. Prices are only pruned by the explicit
  /// [priceRetentionDays] retention policy.
  Future<void> cleanupOldEntries({
    int retentionDays = 60,
    int priceRetentionDays = 0,
  }) async {
    final db = await database;
    final cutoff = DateTime.now()
        .subtract(Duration(days: retentionDays))
        .millisecondsSinceEpoch;
    logInfo(
      'Cleaning up items added before '
      '${DateTime.fromMillisecondsSinceEpoch(cutoff).toIso8601String()}'
      ' (retention: $retentionDays days)',
    );

    try {
      await db.transaction((txn) async {
        final deletedItems = await txn.delete(
          'inventory',
          where: 'date_added < ?',
          whereArgs: [cutoff],
        );
        logInfo('Removed $deletedItems old inventory items');

        // Only cached (API-sourced) products that nothing references are
        // removed. Manual products and products referenced by a price row
        // are always kept.
        final deletedProducts = await txn.rawDelete('''
          DELETE FROM products
          WHERE source != 'manual'
            AND NOT EXISTS (
              SELECT 1 FROM inventory WHERE inventory.barcode = products.barcode
            )
            AND NOT EXISTS (
              SELECT 1 FROM prices WHERE prices.barcode = products.barcode
            )
        ''');
        logInfo('Removed $deletedProducts orphaned products');

        if (priceRetentionDays > 0) {
          final cutoffMillis = DateTime.now()
              .subtract(Duration(days: priceRetentionDays))
              .millisecondsSinceEpoch;
          final deletedPrices = await txn.delete(
            'prices',
            where:
                'COALESCE(date_purchased, date_added) < ?'
                ' AND sync_status != ?',
            whereArgs: [cutoffMillis, priceSyncPending],
          );
          logInfo('Removed $deletedPrices old price rows');
        }
      });

      // Self-contained and atomic; runs after the main cleanup so its own
      // PRAGMA foreign_keys toggling is not nested inside the transaction.
      await flushExpiredCachedProducts();

      // Refresh query planner statistics after the bulk deletions.
      await db.execute('PRAGMA optimize');

      logInfo('Cleanup finished');
    } on Exception catch (e) {
      logError('Cleanup failed: $e');
      rethrow;
    }
  }

  // ---- Inventories (delegating to InventoriesDao) -----------

  /// Creates a new inventory (pantry) with the given [name].
  Future<int> createInventory(String name) async {
    final db = await database;
    return inventoriesDao.create(db, name);
  }

  /// Returns all inventories, ordered by creation time.
  Future<List<Map<String, dynamic>>> getInventories() async {
    final db = await database;
    return inventoriesDao.list(db);
  }

  /// Deletes the inventory with the given [id] and all its items.
  Future<void> deleteInventory(int id) async {
    final db = await database;
    return inventoriesDao.delete(db, id);
  }

  /// Renames the inventory with the given [id].
  Future<void> renameInventory(int id, String newName) async {
    final db = await database;
    return inventoriesDao.rename(db, id, newName);
  }

  // ---- Inventory items (delegating to InventoryDao) ---------

  /// Inserts a new inventory item.
  Future<int> insertInventoryItem(InventoryItem item) async {
    final db = await database;
    return inventoryDao.insert(db, item);
  }

  /// Inserts an inventory item, merging quantities with an existing item
  /// that has the same barcode and inventoryId.
  Future<int> insertOrMergeInventoryItem(InventoryItem item) async {
    final db = await database;
    return inventoryDao.insertOrMergeByBarcode(db, item);
  }

  /// Retrieves all inventory items for a specific [inventoryId],
  /// optionally filtered by location.
  Future<List<InventoryItem>> getInventoryItems({
    required int inventoryId,
    String? location,
  }) async {
    final db = await database;
    return inventoryDao.list(db, inventoryId: inventoryId, location: location);
  }

  /// Returns all inventory entries for a specific barcode and [inventoryId],
  /// ordered by expiry date (oldest first).
  Future<List<InventoryItem>> getInventoryItemsByBarcode(
    String barcode, {
    required int inventoryId,
  }) async {
    final db = await database;
    return inventoryDao.listByBarcode(db, barcode, inventoryId: inventoryId);
  }

  /// Returns the set of barcodes from [barcodes] that have at least one
  /// inventory entry in the given [inventoryId].
  ///
  /// Useful for batch-checking whether search results already exist in the
  /// active pantry. Returns an empty set when [barcodes] is empty.
  Future<Set<String>> getBarcodesInInventory(
    Set<String> barcodes, {
    required int inventoryId,
  }) async {
    if (barcodes.isEmpty) return {};
    final placeholders = barcodes.map((_) => '?').join(',');
    final db = await database;
    final rows = await db.rawQuery(
      'SELECT DISTINCT barcode FROM inventory '
      'WHERE barcode IN ($placeholders) AND inventory_id = ?',
      [...barcodes, inventoryId],
    );
    final result = <String>{};
    for (final row in rows) {
      final barcode = row['barcode'] as String?;
      if (barcode != null && barcode.isNotEmpty) result.add(barcode);
    }
    return result;
  }

  /// Returns distinct product barcodes and names from the active inventory,
  /// limited to the most recent [limit] entries.
  Future<List<Map<String, dynamic>>> getDistinctProductsFromInventory({
    required int inventoryId,
    int limit = 20,
  }) async {
    final db = await database;
    return inventoryDao.distinctProductsFromInventory(
      db,
      inventoryId: inventoryId,
      limit: limit,
    );
  }

  /// Updates an existing inventory item.
  Future<int> updateInventoryItem(InventoryItem item) async {
    final db = await database;
    return inventoryDao.update(db, item);
  }

  /// Deletes an inventory item by its ID.
  Future<int> deleteInventoryItem(int id) async {
    final db = await database;
    return inventoryDao.delete(db, id);
  }

  /// Deletes multiple inventory items in one batch by their IDs.
  Future<int> deleteInventoryItems(List<int> ids) async {
    final db = await database;
    return inventoryDao.deleteMany(db, ids);
  }

  /// Moves multiple inventory items to a different inventory (pantry).
  Future<void> moveItemsToInventory(
    List<int> itemIds,
    int targetInventoryId,
  ) async {
    final db = await database;
    return inventoryDao.moveItemsToInventory(db, itemIds, targetInventoryId);
  }

  /// Retrieves all inventory rows joined with product metadata.
  Future<List<Map<String, dynamic>>> getInventoryWithProduct({
    required int inventoryId,
  }) async {
    final db = await database;
    return inventoryDao.listWithProduct(db, inventoryId: inventoryId);
  }

  /// Returns the most recent [InventoryItem.dateAdded] epoch across all items.
  ///
  /// Returns null if the inventory table is empty.
  Future<int?> getLastAddDate() async {
    final db = await database;
    return inventoryDao.getLastAddDate(db);
  }

  /// Returns the total number of rows in the inventory table.
  Future<int> getInventoryCount({int? inventoryId}) async {
    final db = await database;
    return inventoryDao.count(db, inventoryId: inventoryId);
  }

  // ---- Prices (delegating to PriceDao) ------------------------

  /// Inserts a price observation. Returns the new row ID.
  Future<int> insertPrice(Price price) async {
    final db = await database;
    return priceDao.insert(db, price);
  }

  /// Returns the price with the given [id], or null if not found.
  Future<Price?> getPriceById(int id) async {
    final db = await database;
    return priceDao.getById(db, id);
  }

  /// Returns all price entries for the given [barcode] and [inventoryId],
  /// ordered by date descending.
  Future<List<Price>> getPricesByBarcode(
    String barcode, {
    required int inventoryId,
    int? limit,
    int? offset,
  }) async {
    final db = await database;
    return priceDao.listByBarcode(
      db,
      barcode,
      inventoryId: inventoryId,
      limit: limit,
      offset: offset,
    );
  }

  /// Returns the most recent price for the given [barcode] and
  /// [inventoryId], or null.
  Future<Price?> getLatestPrice(
    String barcode, {
    required int inventoryId,
  }) async {
    final db = await database;
    return priceDao.getLatest(db, barcode, inventoryId: inventoryId);
  }

  /// Updates an existing price row.
  Future<int> updatePrice(Price price) async {
    final db = await database;
    return priceDao.update(db, price);
  }

  /// Deletes the price with the given [id].
  Future<int> deletePrice(int id) async {
    final db = await database;
    return priceDao.delete(db, id);
  }

  /// Returns the total number of prices for the given [barcode].
  Future<int> getPriceCountByBarcode(String barcode) async {
    final db = await database;
    return priceDao.countByBarcode(db, barcode);
  }

  /// Returns the total number of prices on record.
  Future<int> getPriceCount() async {
    final db = await database;
    return priceDao.count(db);
  }

  /// Returns the sum of the most recent price per distinct product in the
  /// given inventory.
  Future<double?> getTotalInventoryValue(int inventoryId) async {
    final db = await database;
    return priceDao.totalInventoryValue(db, inventoryId);
  }

  /// Returns the average of the most recent price per distinct product in
  /// the given inventory.
  Future<double?> getAverageItemPrice(int inventoryId) async {
    final db = await database;
    return priceDao.averageItemPrice(db, inventoryId);
  }

  /// Returns the count of distinct inventory items that have at least one
  /// price.
  Future<int> getPricedItemCount(int inventoryId) async {
    final db = await database;
    return priceDao.pricedItemCount(db, inventoryId);
  }

  /// Returns prices with the given [syncStatus] for Open Prices sync.
  Future<List<Price>> getPricesBySyncStatus(String syncStatus) async {
    final db = await database;
    return priceDao.getBySyncStatus(db, syncStatus);
  }

  /// Counts prices with the given [syncStatus] without loading the rows.
  Future<int> countPricesBySyncStatus(String syncStatus) async {
    final db = await database;
    return priceDao.countBySyncStatus(db, syncStatus);
  }

  // ---- Shopping list (delegating to ShoppingListDao) ------------

  /// Inserts a shopping list item. Returns the new row ID.
  Future<int> insertShoppingItem(ShoppingItem item) async {
    final db = await database;
    return shoppingListDao.insert(db, item);
  }

  /// Returns all shopping list items, ordered by dateAdded desc.
  Future<List<ShoppingItem>> getShoppingList({int? inventoryId}) async {
    final db = await database;
    return shoppingListDao.listAll(db, inventoryId: inventoryId);
  }

  /// Returns only pending (not purchased) items.
  Future<List<ShoppingItem>> getPendingShoppingItems({int? inventoryId}) async {
    final db = await database;
    return shoppingListDao.listPending(db, inventoryId: inventoryId);
  }

  /// Returns only purchased items.
  Future<List<ShoppingItem>> getPurchasedShoppingItems({
    int? inventoryId,
  }) async {
    final db = await database;
    return shoppingListDao.listPurchased(db, inventoryId: inventoryId);
  }

  /// Updates a shopping list item.
  Future<int> updateShoppingItem(ShoppingItem item) async {
    final db = await database;
    return shoppingListDao.update(db, item);
  }

  /// Reorders pending shopping items to match the given [itemIds] order.
  Future<void> reorderShoppingItems(List<int> itemIds) async {
    final db = await database;
    return shoppingListDao.reorder(db, itemIds);
  }

  /// Updates only the price-related columns for the shopping item
  /// with the given [id].
  Future<int> updateShoppingItemPriceFields(
    int id, {
    double? priceAmount,
    String? priceCurrency,
    String? priceStore,
    double? pricePackageQuantity,
    String? pricePackageUnit,
  }) async {
    final db = await database;
    return shoppingListDao.updatePriceFields(
      db,
      id,
      priceAmount: priceAmount,
      priceCurrency: priceCurrency,
      priceStore: priceStore,
      pricePackageQuantity: pricePackageQuantity,
      pricePackageUnit: pricePackageUnit,
    );
  }

  /// Updates only the expiry date for the shopping item with the given [id].
  Future<int> updateShoppingItemExpiry(
    int id, {
    required String? expiryDate,
  }) async {
    final db = await database;
    return shoppingListDao.updateExpiryFields(db, id, expiryDate: expiryDate);
  }

  /// Deletes a shopping list item by [id].
  Future<int> deleteShoppingItem(int id) async {
    final db = await database;
    return shoppingListDao.delete(db, id);
  }

  /// Toggles the purchased state for the item with the given [id].
  Future<void> toggleShoppingItemPurchased(int id) async {
    final db = await database;
    return shoppingListDao.togglePurchased(db, id);
  }

  /// Deletes all purchased shopping list items, optionally scoped to an
  /// inventory.
  ///
  /// When [inventoryId] is non-null, only purchased items belonging to
  /// that inventory are deleted.
  Future<int> clearPurchasedShoppingItems({int? inventoryId}) async {
    final db = await database;
    return shoppingListDao.clearPurchased(db, inventoryId: inventoryId);
  }

  /// Marks items matching the given [barcode] as purchased, optionally
  /// scoped to an inventory.
  Future<int> markShoppingItemsByBarcode(
    String barcode, {
    int? inventoryId,
  }) async {
    final db = await database;
    return shoppingListDao.markPurchasedByBarcode(
      db,
      barcode,
      inventoryId: inventoryId,
    );
  }

  /// Returns the count of pending (not purchased) shopping list items.
  Future<int> getPendingShoppingCount({int? inventoryId}) async {
    final db = await database;
    return shoppingListDao.pendingCount(db, inventoryId: inventoryId);
  }

  /// Returns all saved stores, ordered alphabetically.
  Future<List<Store>> getAllStores() async {
    final db = await database;
    return storeDao.getAll(db);
  }

  // ---- Recipe (delegating to RecipeDao + RecipeIngredientDao) -------

  /// Inserts a new recipe and returns its row ID.
  Future<int> insertRecipe(Recipe recipe) async {
    final db = await database;
    return recipeDao.insert(db, recipe);
  }

  /// Returns the recipe with the given [id], or null.
  Future<Recipe?> getRecipe(int id) async {
    final db = await database;
    return recipeDao.get(db, id);
  }

  /// Returns all recipes for the given [inventoryId],
  /// ordered by updated_at descending.
  Future<List<Recipe>> getAllRecipes(int inventoryId) async {
    final db = await database;
    return recipeDao.listAll(db, inventoryId);
  }

  /// Updates an existing recipe. Returns rows affected.
  Future<int> updateRecipe(Recipe recipe) async {
    final db = await database;
    return recipeDao.update(db, recipe);
  }

  /// Deletes the recipe with the given [id]. Returns rows deleted.
  Future<int> deleteRecipe(int id) async {
    final db = await database;
    return recipeDao.delete(db, id);
  }

  /// Returns the total number of recipes.
  Future<int> getRecipeCount() async {
    final db = await database;
    return recipeDao.count(db);
  }

  /// Inserts a recipe ingredient and returns its row ID.
  Future<int> insertRecipeIngredient(RecipeIngredient ingredient) async {
    final db = await database;
    return recipeIngredientDao.insert(db, ingredient);
  }

  /// Returns all ingredients for the given [recipeId].
  Future<List<RecipeIngredient>> getRecipeIngredients(int recipeId) async {
    final db = await database;
    return recipeIngredientDao.listByRecipeId(db, recipeId);
  }

  /// Deletes all ingredients for the given [recipeId]. Returns rows deleted.
  Future<int> deleteRecipeIngredients(int recipeId) async {
    final db = await database;
    return recipeIngredientDao.deleteByRecipeId(db, recipeId);
  }

  /// Inserts a recipe and its ingredients in a single transaction.
  ///
  /// Returns the generated recipe id on success. If any insert fails the
  /// entire transaction is rolled back.
  Future<int> insertRecipeWithIngredients(
    Recipe recipe,
    List<RecipeIngredient> ingredients,
  ) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final stamped = recipe.createdAt == 0
        ? recipe.copyWith(createdAt: now)
        : recipe;
    final finalRecipe = stamped.updatedAt == 0
        ? stamped.copyWith(updatedAt: now)
        : stamped;
    final recipeMap = recipeDao.toMap(finalRecipe)..remove('id');

    return db.transaction<int>((txn) async {
      final recipeId = await txn.insert('recipes', recipeMap);
      for (final ingredient in ingredients) {
        final ingMap = recipeIngredientDao.toMap(
          ingredient.copyWith(recipeId: recipeId),
        )..remove('id');
        await txn.insert('recipe_ingredients', ingMap);
      }
      return recipeId;
    });
  }

  /// Updates a recipe and replaces all of its ingredients in a single
  /// transaction.
  ///
  /// Old ingredients are deleted and the new [ingredients] list is inserted.
  /// If any step fails the entire transaction is rolled back.
  Future<void> updateRecipeWithIngredients(
    Recipe recipe,
    List<RecipeIngredient> ingredients,
  ) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;

    // Preserve original createdAt and inventory_id.
    final existing = await recipeDao.get(db, recipe.id!);
    final preserved = existing?.createdAt ?? recipe.createdAt;
    final preservedInventory = existing?.inventoryId ?? recipe.inventoryId;
    final updated = recipe.copyWith(
      createdAt: preserved,
      inventoryId: preservedInventory,
      updatedAt: now,
    );
    final recipeMap = recipeDao.toMap(updated);

    return db.transaction((txn) async {
      await txn.update(
        'recipes',
        recipeMap,
        where: 'id = ?',
        whereArgs: [recipe.id],
      );
      await txn.delete(
        'recipe_ingredients',
        where: 'recipe_id = ?',
        whereArgs: [recipe.id],
      );
      for (final ingredient in ingredients) {
        final ingMap = recipeIngredientDao.toMap(
          ingredient.copyWith(recipeId: recipe.id!),
        )..remove('id');
        await txn.insert('recipe_ingredients', ingMap);
      }
    });
  }

  // ---- Recipe History (delegating to RecipeHistoryDao) -------

  /// Inserts a recipe history entry and returns its row ID.
  Future<int> insertRecipeHistory(RecipeHistoryEntry entry) async {
    final db = await database;
    return recipeHistoryDao.insert(db, entry);
  }

  /// Returns all history entries for the given [recipeId], newest first.
  Future<List<RecipeHistoryEntry>> getRecipeHistory(int recipeId) async {
    final db = await database;
    return recipeHistoryDao.getByRecipeId(db, recipeId);
  }

  /// Returns all history entries made at or after [sinceMillis].
  Future<List<RecipeHistoryEntry>> getRecentRecipeHistory(
    int sinceMillis,
  ) async {
    final db = await database;
    return recipeHistoryDao.getRecent(db, sinceMillis);
  }

  /// Deletes the history entry with the given [historyId].
  Future<void> deleteRecipeHistory(int historyId) async {
    final db = await database;
    return recipeHistoryDao.deleteById(db, historyId);
  }

  // ---- Scan history (delegating to ScanHistoryDao) -------

  /// Records a successful scan and prunes the table to its cap.
  ///
  /// Inserts [entry], then deletes all rows beyond
  /// [ScanHistoryDao.defaultKeepCount] so the table never grows unbounded.
  /// Both operations run inside a single transaction.
  Future<int> recordScan(ScanHistoryEntry entry) async {
    final db = await database;
    return db.transaction<int>((txn) async {
      final id = await scanHistoryDao.insert(txn, entry);
      await scanHistoryDao.deleteOld(txn);
      return id;
    });
  }

  /// Returns the most recent scan history entries, newest first.
  Future<List<ScanHistoryEntry>> getRecentScanHistory({
    int limit = ScanHistoryDao.defaultKeepCount,
  }) async {
    final db = await database;
    return scanHistoryDao.getRecent(db, limit: limit);
  }

  /// Deletes every row from the scan_history table.
  ///
  /// Returns the number of rows removed.
  Future<int> clearScanHistory() async {
    final db = await database;
    return scanHistoryDao.clear(db);
  }

  // ---- FEFO inventory query -------

  /// Returns inventory rows matching [barcode] in the given [inventoryId],
  /// ordered by expiry_date ASC (nulls last) for FEFO deduction.
  Future<List<Map<String, dynamic>>> getInventoryRowsByBarcode({
    required String barcode,
    required int inventoryId,
  }) async {
    final db = await database;
    return db.rawQuery(
      'SELECT * FROM inventory WHERE barcode = ? AND inventory_id = ?'
      ' ORDER BY (expiry_date IS NULL), expiry_date ASC',
      [barcode, inventoryId],
    );
  }

  /// Returns inventory rows whose linked product name contains [name],
  /// ordered by expiry_date ASC (nulls last) for FEFO deduction.
  ///
  /// The search is case-insensitive and trims the input to reduce false
  /// negatives from whitespace mismatch. This is a fallback when exact
  /// barcode lookup returns no results. The leading-wildcard LIKE forces
  /// a scan, so results are capped at [limit] rows (default 20). LIKE
  /// wildcards in [name] are escaped so a literal '%' or '_' cannot act
  /// as a wildcard (mirrors [ProductDao.search]).
  Future<List<Map<String, dynamic>>> getInventoryRowsByProductName({
    required String name,
    required int inventoryId,
    int limit = 20,
  }) async {
    final db = await database;
    final normalized = name.trim().toLowerCase();
    final escaped = normalized.replaceAll('%', r'\%').replaceAll('_', r'\_');
    return db.rawQuery(
      'SELECT i.* FROM inventory i'
      ' INNER JOIN products p ON p.barcode = i.barcode'
      r" WHERE LOWER(p.name) LIKE ? ESCAPE '\' AND i.inventory_id = ?"
      ' ORDER BY (i.expiry_date IS NULL), i.expiry_date ASC'
      ' LIMIT ?',
      ['%$escaped%', inventoryId, limit],
    );
  }
}
