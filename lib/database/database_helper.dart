import 'package:pantry_app/database/feedback_queue_dao.dart';
import 'package:pantry_app/database/firebase_cache_meta_dao.dart';
import 'package:pantry_app/database/inventories_dao.dart';
import 'package:pantry_app/database/inventory_dao.dart';
import 'package:pantry_app/database/price_dao.dart';
import 'package:pantry_app/database/product_dao.dart';
import 'package:pantry_app/database/product_submission_queue_dao.dart';
import 'package:pantry_app/database/recipe_dao.dart';
import 'package:pantry_app/database/recipe_history_dao.dart';
import 'package:pantry_app/database/recipe_ingredient_dao.dart';
import 'package:pantry_app/database/shopping_list_dao.dart';
import 'package:pantry_app/database/store_dao.dart';
import 'package:pantry_app/models/inventory_item.dart';
import 'package:pantry_app/models/price.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/models/recipe.dart';
import 'package:pantry_app/models/recipe_history_entry.dart';
import 'package:pantry_app/models/recipe_ingredient.dart';
import 'package:pantry_app/models/shopping_item.dart';
import 'package:pantry_app/models/store.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:pantry_app/utils/search_utils.dart';
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
/// Twelve tables are created on first launch (version 26):
/// - products – product data fetched from Open Food Facts.
/// - inventories – named pantries (e.g. "Home", "Work").
/// - inventory – instances of products the user has added to a pantry.
/// - feedback_queue – offline queue for GitHub issue reports.
/// - product_submission_queue – offline queue for OFF product submissions.
/// - prices – purchase price observations per barcode.
/// - shopping_list – items the user intends to buy.
/// - stores – saved store names for autocomplete.
/// - firebase_cache_meta – Firestore cache sync metadata.
/// - recipes – user-created recipes.
/// - recipe_ingredients – ingredients linked to a recipe.
///
/// ## Delegation
///
/// CRUD operations are delegated to dedicated DAO classes:
/// [ProductDao], [InventoryDao], [InventoriesDao], [PriceDao],
/// [ShoppingListDao], [StoreDao], [FeedbackQueueDao],
/// [ProductSubmissionQueueDao], [FirebaseCacheMetaDao],
/// [RecipeDao], [RecipeIngredientDao].
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

  Database? _database;

  /// DAO for the products table.
  final ProductDao productDao = const ProductDao();

  /// DAO for the inventory table.
  final InventoryDao inventoryDao = const InventoryDao();

  /// DAO for the inventories table.
  final InventoriesDao inventoriesDao = const InventoriesDao();

  /// DAO for the feedback_queue table.
  final FeedbackQueueDao feedbackQueueDao = const FeedbackQueueDao();

  /// DAO for the product_submission_queue table.
  final ProductSubmissionQueueDao productSubmissionQueueDao =
      const ProductSubmissionQueueDao();

  /// DAO for the prices table.
  final PriceDao priceDao = const PriceDao();

  /// DAO for the shopping_list table.
  final ShoppingListDao shoppingListDao = const ShoppingListDao();

  /// DAO for the stores table.
  final StoreDao storeDao = const StoreDao();

  /// DAO for the firebase_cache_meta table.
  final FirebaseCacheMetaDao firebaseCacheMetaDao =
      const FirebaseCacheMetaDao();

  /// DAO for the recipes table.
  final RecipeDao recipeDao = const RecipeDao();

  /// DAO for the recipe_ingredients table.
  final RecipeIngredientDao recipeIngredientDao = const RecipeIngredientDao();

  /// DAO for the recipe_history table.
  final RecipeHistoryDao recipeHistoryDao = const RecipeHistoryDao();

  /// The lazily‑opened database instance.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = _customPath ?? (await _getDefaultPath());
    logInfo('Opening database at $dbPath');
    try {
      final db = await openDatabase(
        dbPath,
        version: 26,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
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
        energy_kcal REAL,
        protein_g REAL,
        carbs_g REAL,
        fat_g REAL,
        fiber_g REAL,
        salt_g REAL,
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

    await db.execute('CREATE INDEX idx_barcode ON products(barcode)');
    await db.execute('CREATE INDEX idx_search_text ON products(search_text)');
    await db.execute('CREATE INDEX idx_expiry ON inventory(expiry_date)');
    await db.execute(
      'CREATE INDEX idx_inventory_barcode ON inventory(barcode)',
    );
    await db.execute(
      'CREATE INDEX idx_inventory_id ON inventory(inventory_id)',
    );
    await db.execute(
      'CREATE INDEX idx_inventory_date_added ON inventory(date_added)',
    );

    await feedbackQueueDao.createTable(db);

    await productSubmissionQueueDao.createTable(db);

    await _createPricesTable(db);

    await _createShoppingListTable(db);

    await _createStoresTable(db);

    await firebaseCacheMetaDao.createTable(db);

    await recipeDao.createTable(db);

    await recipeIngredientDao.createTable(db);

    await recipeHistoryDao.createTable(db);

    await inventoriesDao.seedDefault(db);

    logInfo('Database schema created successfully');
  }

  Future<void> _createPricesTable(Database db) async {
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
        date_added INTEGER NOT NULL,
        FOREIGN KEY (barcode) REFERENCES products(barcode)
      )
    ''');
    await db.execute('CREATE INDEX idx_prices_barcode ON prices(barcode)');
    await db.execute(
      'CREATE INDEX idx_prices_date ON prices(date_purchased)',
    );
    await db.execute(
      'CREATE INDEX idx_prices_sync_status ON prices(sync_status)',
    );
  }

  Future<void> _createShoppingListTable(Database db) async {
    await shoppingListDao.createTable(db);
  }

  Future<void> _createStoresTable(Database db) async {
    await storeDao.createTable(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    logInfo('Database upgrade: $oldVersion → $newVersion');

    if (oldVersion < 2) {
      await inventoriesDao.createTable(db);

      await db.execute(
        'ALTER TABLE inventory ADD COLUMN inventory_id INTEGER',
      );

      final homeId = await inventoriesDao.seedDefault(db);

      await db.update(
        'inventory',
        {'inventory_id': homeId},
        where: 'inventory_id IS NULL',
      );

      logInfo('Migration to version 2 completed');
    }
    if (oldVersion < 3) {
      await db.rawUpdate(
        "UPDATE inventory SET unit = 'pieces' WHERE unit = 'pcs'",
      );
      logInfo('Migration to version 3 completed');
    }
    if (oldVersion < 4) {
      await db.execute(
        'ALTER TABLE products ADD COLUMN nutriscore_grade TEXT',
      );
      logInfo('Migration to version 4 completed');
    }
    if (oldVersion < 5) {
      await db.execute(
        'ALTER TABLE products ADD COLUMN nutriscore_not_applicable_category '
        'TEXT',
      );
      logInfo('Migration to version 5 completed');
    }
    if (oldVersion < 6) {
      await db.execute(
        "ALTER TABLE products ADD COLUMN source TEXT NOT NULL DEFAULT 'api'",
      );
      logInfo('Migration to version 6 completed');
    }
    if (oldVersion < 7) {
      await db.execute(
        'ALTER TABLE products ADD COLUMN nutrition_image_path TEXT',
      );
      await db.execute(
        'ALTER TABLE products ADD COLUMN ingredients_image_path TEXT',
      );
      await db.execute(
        'ALTER TABLE products ADD COLUMN product_image_path TEXT',
      );
      logInfo('Migration to version 7 completed');
    }
    if (oldVersion < 8) {
      await db.execute(
        'ALTER TABLE products ADD COLUMN submission_status '
        "TEXT NOT NULL DEFAULT 'not_submitted'",
      );
      logInfo('Migration to version 8 completed');
    }
    if (oldVersion < 9) {
      try {
        await db.execute(
          'ALTER TABLE products ADD COLUMN off_nutrition_image_url TEXT',
        );
        await db.execute(
          'ALTER TABLE products ADD COLUMN off_ingredients_image_url TEXT',
        );
        await db.execute(
          'ALTER TABLE products ADD COLUMN off_product_image_url TEXT',
        );
        logInfo('Migration to version 9 completed');
      } on Exception catch (e) {
        logWarning('Migration v9 failed (columns may already exist): $e');
      }
    }
    if (oldVersion < 10) {
      try {
        await db.execute(
          'ALTER TABLE products ADD COLUMN categories_hierarchy TEXT',
        );
        logInfo('Migration to version 10 completed');
      } on Exception catch (e) {
        logWarning('Migration v10 failed (column may already exist): $e');
      }
    }
    if (oldVersion < 11) {
      await feedbackQueueDao.createTable(db);
      logInfo('Migration to version 11 completed');
    }
    if (oldVersion < 12) {
      await _createPricesTable(db);
      logInfo('Migration to version 12 completed');
    }
    if (oldVersion < 13) {
      await _createShoppingListTable(db);
      logInfo('Migration to version 13 completed');
    }
    if (oldVersion < 14) {
      try {
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_inventory_date_added'
          ' ON inventory(date_added)',
        );
        logInfo('Migration to version 14 completed');
      } on Exception catch (e) {
        logWarning('Migration v14 failed (table may not exist): $e');
      }
    }
    if (oldVersion < 15) {
      try {
        await db.execute(
          'ALTER TABLE products ADD COLUMN language_code TEXT'
          " NOT NULL DEFAULT 'en'",
        );
        logInfo('Migration to version 15 completed');
      } on Exception catch (e) {
        logWarning('Migration v15 failed (column may already exist): $e');
      }
    }
    if (oldVersion < 16) {
      try {
        await productSubmissionQueueDao.createTable(db);
        logInfo('Migration to version 16 completed');
      } on Exception catch (e) {
        logWarning('Migration v16 failed: $e');
      }
    }
    if (oldVersion < 17) {
      try {
        await db.execute('ALTER TABLE products ADD COLUMN search_text TEXT');
        final allProducts = await productDao.all(db);
        await db.transaction((txn) async {
          for (final product in allProducts) {
            await txn.update(
              'products',
              {'search_text': buildSearchText(product)},
              where: 'barcode = ?',
              whereArgs: [product.barcode],
            );
          }
        });
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_search_text ON products(search_text)',
        );
        logInfo('Migration to version 17 (search_text column) completed');
      } on Exception catch (e) {
        logWarning('Migration v17 failed: $e');
      }
    }
    if (oldVersion < 18) {
      try {
        await db.execute(
          'ALTER TABLE shopping_list ADD COLUMN price_amount REAL',
        );
        await db.execute(
          'ALTER TABLE shopping_list ADD COLUMN price_currency TEXT',
        );
        await db.execute(
          'ALTER TABLE shopping_list ADD COLUMN price_store TEXT',
        );
        await db.execute(
          'ALTER TABLE shopping_list ADD COLUMN price_photo_path TEXT',
        );
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_shopping_inventory_id'
          ' ON shopping_list(inventory_id)',
        );
        logInfo('Migration to version 18 completed');
      } on Exception catch (e) {
        logWarning('Migration v18 failed (columns may already exist): $e');
      }
    }
    if (oldVersion < 19) {
      try {
        await _createStoresTable(db);

        await db.execute(
          'INSERT OR IGNORE INTO stores (name)'
          ' SELECT DISTINCT TRIM(store) FROM prices'
          " WHERE store IS NOT NULL AND TRIM(store) != ''",
        );
        await db.execute(
          'INSERT OR IGNORE INTO stores (name)'
          ' SELECT DISTINCT TRIM(price_store) FROM shopping_list'
          " WHERE price_store IS NOT NULL AND TRIM(price_store) != ''",
        );

        logInfo('Migration to version 19 completed');
      } on Exception catch (e) {
        logWarning('Migration v19 failed: $e');
      }
    }
    if (oldVersion < 20) {
      try {
        final minId = await db.rawQuery(
          'SELECT COALESCE('
          '(SELECT id FROM inventories ORDER BY id ASC LIMIT 1),'
          ' 1'
          ') AS result',
        );
        final defaultId = minId.first['result'] as int? ?? 1;
        await db.rawUpdate(
          'UPDATE shopping_list SET inventory_id = ?'
          ' WHERE inventory_id IS NULL',
          [defaultId],
        );
        logInfo(
          'Migration to version 20 completed'
          ' (backfilled null inventory_id to $defaultId)',
        );
      } on Exception catch (e) {
        logWarning('Migration v20 failed: $e');
      }
    }
    if (oldVersion < 21) {
      try {
        await db.execute('ALTER TABLE products ADD COLUMN plu_code TEXT');
        await db.execute(
          'ALTER TABLE products ADD COLUMN product_type TEXT'
          " NOT NULL DEFAULT 'barcoded'",
        );
        logInfo('Migration to version 21 completed');
      } on Exception catch (e) {
        logWarning('Migration v21 failed (columns may already exist): $e');
      }
    }
    if (oldVersion < 22) {
      try {
        await db.execute(
          'ALTER TABLE inventory ADD COLUMN serving_weight_g REAL',
        );
        logInfo('Migration to version 22 completed');
      } on Exception catch (e) {
        logWarning(
          'Migration v22 failed (column may already exist): $e',
        );
      }
    }
    if (oldVersion < 23) {
      try {
        await db.rawUpdate(
          "UPDATE products SET category = 'Fruits and vegetables based foods'"
          " WHERE product_type = 'produce' AND category IS NULL",
        );
        logInfo(
          'Migration to version 23 completed'
          ' (backfilled produce category)',
        );
      } on Exception catch (e) {
        logWarning('Migration v23 failed: $e');
      }
    }
    if (oldVersion < 24) {
      try {
        await firebaseCacheMetaDao.createTable(db);
        logInfo('Migration to version 24 (firebase_cache_meta) completed');
      } on Exception catch (e) {
        logWarning('Migration v24 failed: $e');
      }
    }
    if (oldVersion < 25) {
      try {
        await recipeDao.createTable(db);
        await recipeIngredientDao.createTable(db);
        logInfo(
          'Migration to version 25 (recipes + recipe_ingredients) completed',
        );
      } on Exception catch (e) {
        logWarning('Migration v25 failed: $e');
      }
    }
    if (oldVersion < 26) {
      try {
        await recipeHistoryDao.createTable(db);
        logInfo('Migration to version 26 (recipe_history) completed');
      } on Exception catch (e) {
        logWarning('Migration v26 failed: $e');
      }
    }
    logInfo('Database upgrade completed');
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
  /// references are explicitly cleaned up.
  Future<void> clearCachedProducts() async {
    final db = await database;
    await db.execute('PRAGMA foreign_keys = OFF');
    try {
      // Null out shopping list barcode refs to API products before deleting.
      await db.rawUpdate('''
        UPDATE shopping_list SET barcode = NULL
        WHERE barcode IN (SELECT barcode FROM products WHERE source = 'api')
      ''');
      return productDao.deleteBySource(db, 'api');
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

  /// Removes stale inventory items, orphaned products, and old prices.
  ///
  /// [retentionDays] applies to inventory items only. Price rows use
  /// [priceRetentionDays] (default 0 = keep forever).
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
      final deletedItems = await db.delete(
        'inventory',
        where: 'date_added < ?',
        whereArgs: [cutoff],
      );
      logInfo('Removed $deletedItems old inventory items');

      await db.rawDelete('''
        DELETE FROM prices
        WHERE barcode NOT IN (SELECT DISTINCT barcode FROM inventory)
      ''');

      final deletedProducts = await db.rawDelete('''
        DELETE FROM products
        WHERE barcode NOT IN (SELECT DISTINCT barcode FROM inventory)
      ''');
      logInfo('Removed $deletedProducts orphaned products');

      if (priceRetentionDays > 0) {
        final deletedPrices = await priceDao.deleteStale(
          db,
          priceRetentionDays,
        );
        logInfo('Removed $deletedPrices old price rows');
      }

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

  // ---- Feedback queue (delegating to FeedbackQueueDao) ------

  /// Queues a feedback issue for offline submission.
  Future<int> queueFeedbackIssue({
    required String title,
    required String body,
    String? label,
    String? screenshotPath,
  }) async {
    final db = await database;
    return feedbackQueueDao.insert(
      db,
      title: title,
      body: body,
      label: label,
      screenshotPath: screenshotPath,
    );
  }

  /// Returns all pending (non-failed) feedback queue rows.
  Future<List<Map<String, dynamic>>> getPendingFeedbackIssues() async {
    final db = await database;
    return feedbackQueueDao.getAllPending(db);
  }

  /// Deletes a feedback queue row.
  Future<void> deleteFeedbackIssue(int id) async {
    final db = await database;
    return feedbackQueueDao.delete(db, id);
  }

  /// Increments the retry count for a feedback queue row.
  Future<void> incrementFeedbackRetry(int id) async {
    final db = await database;
    return feedbackQueueDao.incrementRetry(db, id);
  }

  /// Marks a feedback queue row as permanently failed.
  Future<void> markFeedbackFailed(int id) async {
    final db = await database;
    return feedbackQueueDao.markFailed(db, id);
  }

  /// Deletes stale failed feedback queue rows.
  Future<int> deleteStaleFeedbackFailures({int olderThanDays = 30}) async {
    final db = await database;
    return feedbackQueueDao.deleteStaleFailures(
      db,
      olderThanDays: olderThanDays,
    );
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

  /// Returns all price entries for the given [barcode], ordered by date
  /// descending.
  Future<List<Price>> getPricesByBarcode(
    String barcode, {
    int? limit,
    int? offset,
  }) async {
    final db = await database;
    return priceDao.listByBarcode(db, barcode, limit: limit, offset: offset);
  }

  /// Returns the most recent price for the given [barcode], or null.
  Future<Price?> getLatestPrice(String barcode) async {
    final db = await database;
    return priceDao.getLatest(db, barcode);
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

  /// Updates only the price-related columns for the shopping item
  /// with the given [id].
  Future<int> updateShoppingItemPriceFields(
    int id, {
    double? priceAmount,
    String? priceCurrency,
    String? priceStore,
    String? pricePhotoPath,
  }) async {
    final db = await database;
    return shoppingListDao.updatePriceFields(
      db,
      id,
      priceAmount: priceAmount,
      priceCurrency: priceCurrency,
      priceStore: priceStore,
      pricePhotoPath: pricePhotoPath,
    );
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

  /// Returns all recipes, ordered by updated_at descending.
  Future<List<Recipe>> getAllRecipes() async {
    final db = await database;
    return recipeDao.listAll(db);
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
    final recipeMap = recipeDao.toMap(finalRecipe);
    // Remove id so SQLite auto-generates it.
    recipeMap.remove('id');

    return db.transaction<int>((txn) async {
      final recipeId = await txn.insert('recipes', recipeMap);
      for (final ingredient in ingredients) {
        final ingMap = recipeIngredientDao.toMap(
          ingredient.copyWith(recipeId: recipeId),
        );
        ingMap.remove('id');
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

    // Preserve original createdAt.
    final existing = await recipeDao.get(db, recipe.id!);
    final preserved = existing?.createdAt ?? recipe.createdAt;
    final updated = recipe.copyWith(createdAt: preserved, updatedAt: now);
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
        );
        ingMap.remove('id');
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
      ' ORDER BY expiry_date ASC NULLS LAST',
      [barcode, inventoryId],
    );
  }
}
