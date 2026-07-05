import 'package:pantry_app/database/inventories_dao.dart';
import 'package:pantry_app/database/inventory_dao.dart';
import 'package:pantry_app/database/product_dao.dart';
import 'package:pantry_app/models/inventory_item.dart';
import 'package:pantry_app/models/product.dart';
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
/// Three tables are created on first launch (version 2):
/// - `products` – product data fetched from Open Food Facts.
/// - `inventories` – named pantries (e.g. "Home", "Work").
/// - `inventory` – instances of products the user has added to a pantry.
///
/// ## Delegation
///
/// CRUD operations are delegated to dedicated DAO classes:
/// [ProductDao], [InventoryDao], [InventoriesDao]. This keeps each file
/// focused on a single table.
class DatabaseHelper {
  /// Returns the single [DatabaseHelper] instance.
  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal() : _customPath = null;

  /// Creates a [DatabaseHelper] that opens a database at the given [path].
  DatabaseHelper.withPath(String path) : _customPath = path;

  final String? _customPath;

  static final DatabaseHelper _instance = DatabaseHelper._internal();

  Database? _database;

  /// DAO for the `products` table.
  final ProductDao productDao = const ProductDao();

  /// DAO for the `inventory` table.
  final InventoryDao inventoryDao = const InventoryDao();

  /// DAO for the `inventories` table.
  final InventoriesDao inventoriesDao = const InventoriesDao();

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
        version: 4,
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
        nutriscore_grade TEXT
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
        FOREIGN KEY(barcode) REFERENCES products(barcode),
        FOREIGN KEY(inventory_id) REFERENCES inventories(id)
      )
    ''');

    await db.execute('CREATE INDEX idx_barcode ON products(barcode)');
    await db.execute('CREATE INDEX idx_expiry ON inventory(expiry_date)');
    await db.execute(
      'CREATE INDEX idx_inventory_barcode ON inventory(barcode)',
    );
    await db.execute(
      'CREATE INDEX idx_inventory_id ON inventory(inventory_id)',
    );

    await inventoriesDao.seedDefault(db);

    logInfo('Database schema created successfully');
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

  /// Deletes all cached products from the database.
  ///
  /// Used during app update to force a full re-fetch from Open Food Facts,
  /// ensuring new fields (e.g. `nutriscore_grade`) are populated.
  Future<void> clearProducts() async {
    final db = await database;
    return productDao.clear(db);
  }

  /// Removes stale inventory items and orphaned products.
  Future<void> cleanupOldEntries({int retentionDays = 60}) async {
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

      final deletedProducts = await db.rawDelete('''
        DELETE FROM products
        WHERE barcode NOT IN (SELECT DISTINCT barcode FROM inventory)
      ''');
      logInfo('Removed $deletedProducts orphaned products');
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

  /// Retrieves all inventory rows joined with product metadata.
  Future<List<Map<String, dynamic>>> getInventoryWithProduct({
    required int inventoryId,
  }) async {
    final db = await database;
    return inventoryDao.listWithProduct(db, inventoryId: inventoryId);
  }

  /// Returns the total number of rows in the inventory table.
  Future<int> getInventoryCount({int? inventoryId}) async {
    final db = await database;
    return inventoryDao.count(db, inventoryId: inventoryId);
  }

  /// Returns inventory rows joined with product nutrition for CSV export.
  Future<List<Map<String, dynamic>>> getExportData({
    required int inventoryId,
  }) async {
    final db = await database;
    return inventoryDao.exportData(db, inventoryId: inventoryId);
  }
}
