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
/// database operations use the same connection, avoiding locking issues and
/// unnecessary overhead.
///
/// For **testing** a separate instance can be created with the named
/// constructor [DatabaseHelper.withPath], which opens an in‑memory database
/// or a temporary file. This avoids interfering with the singleton’s
/// connection.
///
/// ## Platform support
///
/// This version targets **Android** (and will later support iOS). It uses the
/// standard [Sqflite] plugin. Desktop and web are not supported in this build.
///
/// ## Schema overview
///
/// Three tables are created on first launch (version 2):
///
/// - [Product] – stores immutable (or rarely‑changing) product data fetched
///   from Open Food Facts. The barcode is the primary key. Nutrition values
///   are denormalised into columns.
/// - [InventoryItem] – stores instances of a product that the user has added to
///   a specific inventory (pantry). The `inventory_id` column links to the
///   `inventories` table.
/// - **inventories** – stores named inventories (e.g. “Home”, “Work”).
///   Each inventory has an auto‑generated `id` and a `name`.
///
/// ## Migrations
///
/// - Version 1 → 2: adds the `inventories` table and `inventory_id` column to
///   `inventory`. Existing items are assigned to a default “Home” inventory.
class DatabaseHelper {
  /// Returns the single [DatabaseHelper] instance.
  factory DatabaseHelper() => _instance;

  /// Internal constructor for the singleton.
  DatabaseHelper._internal() : _customPath = null;

  /// Creates a [DatabaseHelper] that opens (or creates) a database at the
  /// given [path] instead of the default location.
  ///
  /// This constructor is intended for **unit tests** that require an isolated
  /// database. In production code the default singleton ([DatabaseHelper])
  /// should be used.
  DatabaseHelper.withPath(String path) : _customPath = path;

  /// The custom database path used
  /// when constructed via [DatabaseHelper.withPath].
  final String? _customPath;

  static final DatabaseHelper _instance = DatabaseHelper._internal();

  /// The lazily‑initialised database connection.
  ///
  /// The first access to this getter triggers [_initDatabase], which creates
  /// or opens the SQLite file and runs any necessary migrations.
  Database? _database;

  /// The lazily‑opened database instance.
  ///
  /// This getter ensures that the database is opened exactly once. Subsequent
  /// calls return the already‑opened connection immediately.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Opens the database file and applies the schema.
  ///
  /// If a custom path was provided via [DatabaseHelper.withPath] it is used
  /// directly; otherwise the file is stored in the application’s documents
  /// directory so that it survives app restarts.
  Future<Database> _initDatabase() async {
    final dbPath = _customPath ?? (await _getDefaultPath());
    logInfo('Opening database at $dbPath');
    try {
      final db = await openDatabase(
        dbPath,
        version: 2,
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

  /// Returns the default path for the database file inside the app’s
  /// documents directory.
  Future<String> _getDefaultPath() async {
    final documentsDir = await getApplicationDocumentsDirectory();
    return join(documentsDir.path, 'pantry.db');
  }

  /// Creates the `products`, `inventory` (v2), and `inventories` tables
  /// together with their indexes.
  ///
  /// Called automatically by [openDatabase] when the database file does not
  /// exist yet (version 2).
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
        last_synced INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE inventories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE inventory (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        barcode TEXT NOT NULL,
        quantity REAL DEFAULT 1,
        unit TEXT DEFAULT 'pcs',
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

    // Create a default "Home" inventory.
    await db.insert('inventories', {
      'name': 'Home',
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });

    logInfo('Database schema created successfully');
  }

  /// Handles database upgrades from version 1 to version 2.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    logInfo('Database upgrade: $oldVersion → $newVersion');

    if (oldVersion < 2) {
      // Create the inventories table.
      await db.execute('''
        CREATE TABLE inventories (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          created_at INTEGER NOT NULL
        )
      ''');

      // Add inventory_id column to inventory (nullable during migration).
      await db.execute('ALTER TABLE inventory ADD COLUMN inventory_id INTEGER');

      // Create a default "Home" inventory.
      final homeId = await db.insert('inventories', {
        'name': 'Home',
        'created_at': DateTime.now().millisecondsSinceEpoch,
      });

      // Assign all existing items to the Home inventory.
      await db.update(
        'inventory',
        {'inventory_id': homeId},
        where: 'inventory_id IS NULL',
      );

      logInfo('Migration to version 2 completed');
    }
  }

  // --------------------- Inventories CRUD ---------------------

  /// Creates a new inventory with the given [name].
  Future<int> createInventory(String name) async {
    final db = await database;
    return db.insert('inventories', {
      'name': name,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Returns all inventories, ordered by creation time.
  Future<List<Map<String, dynamic>>> getInventories() async {
    final db = await database;
    return db.rawQuery(
      'SELECT id, name, created_at FROM inventories ORDER BY created_at ASC',
    );
  }

  /// Deletes the inventory with the given [id] and all its items.
  Future<void> deleteInventory(int id) async {
    final db = await database;
    await db.delete('inventory', where: 'inventory_id = ?', whereArgs: [id]);
    await db.delete('inventories', where: 'id = ?', whereArgs: [id]);
  }

  /// Renames the inventory with the given [id].
  Future<void> renameInventory(int id, String newName) async {
    final db = await database;
    await db.update(
      'inventories',
      {'name': newName},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --------------------- Product CRUD ---------------------

  /// Inserts a product into the local cache.
  ///
  /// If a product with the same barcode already exists it is **replaced**
  /// (upsert). This is the intended behaviour because product data from Open
  /// Food Facts may have been updated.
  Future<void> insertProduct(Product product) async {
    logInfo('Inserting product: ${product.barcode} — ${product.name}');
    try {
      final db = await database;
      await db.insert(
        'products',
        _productToMap(product),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      logInfo('Product ${product.barcode} inserted/updated');
    } on Exception catch (e) {
      logError('Failed to insert product ${product.barcode}: $e');
      rethrow;
    }
  }

  /// Looks up a single product by its barcode.
  ///
  /// Returns `null` if no product with the given barcode exists in the local
  /// cache.
  Future<Product?> getProduct(String barcode) async {
    try {
      final db = await database;
      final result = await db.query(
        'products',
        where: 'barcode = ?',
        whereArgs: [barcode],
      );
      if (result.isEmpty) {
        logInfo('Product $barcode not found in cache');
        return null;
      }
      logInfo('Product $barcode found in cache');
      return _productFromMap(result.first);
    } on Exception catch (e) {
      logError('Error looking up product $barcode: $e');
      rethrow;
    }
  }

  /// Removes inventory items that were added more than [retentionDays] ago,
  /// and then deletes any product records that are no longer referenced by
  /// the remaining inventory items.
  ///
  /// The default retention period is 60 days; this can be overridden by
  /// passing a value from the user’s settings.
  Future<void> cleanupOldEntries({int retentionDays = 60}) async {
    final db = await database;
    final cutoff = DateTime.now()
        .subtract(Duration(days: retentionDays))
        .millisecondsSinceEpoch;
    logInfo(
      '''Cleaning up items added before ${DateTime.fromMillisecondsSinceEpoch(cutoff).toIso8601String()} (retention: $retentionDays days)''',
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

  // --------------------- Inventory CRUD ---------------------

  /// Inserts a new inventory item.
  ///
  /// The [InventoryItem.inventoryId] must be set to a valid inventory ID.
  /// The returned integer is the auto‑generated `id` of the new row.
  Future<int> insertInventoryItem(InventoryItem item) async {
    logInfo(
      '''Inserting inventory item: ${item.barcode} — qty: ${item.quantity} ${item.unit}, loc: ${item.location}''',
    );
    try {
      final db = await database;
      final id = await db.insert('inventory', _inventoryToMap(item));
      logInfo('Inventory item inserted with id $id');
      return id;
    } on Exception catch (e) {
      logError('Failed to insert inventory item for ${item.barcode}: $e');
      rethrow;
    }
  }

  /// Retrieves all inventory items for a specific [inventoryId], optionally
  /// filtered by location.
  Future<List<InventoryItem>> getInventoryItems({
    required int inventoryId,
    String? location,
  }) async {
    try {
      final db = await database;
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
      return result.map(_inventoryFromMap).toList();
    } on Exception catch (e) {
      logError('Error fetching inventory items: $e');
      rethrow;
    }
  }

  /// Returns all inventory entries for a specific barcode and [inventoryId],
  /// ordered by expiry date (oldest first).
  Future<List<InventoryItem>> getInventoryItemsByBarcode(
    String barcode, {
    required int inventoryId,
  }) async {
    try {
      final db = await database;
      final result = await db.query(
        'inventory',
        where: 'barcode = ? AND inventory_id = ?',
        whereArgs: [barcode, inventoryId],
        orderBy: 'expiry_date ASC',
      );
      logInfo('Fetched ${result.length} inventory items for barcode $barcode');
      return result.map(_inventoryFromMap).toList();
    } on Exception catch (e) {
      logError('Error fetching inventory for $barcode: $e');
      rethrow;
    }
  }

  /// Updates an existing inventory item.
  ///
  /// The item’s `id` field must be set to a value that exists in the database;
  /// otherwise the update has no effect.
  Future<int> updateInventoryItem(InventoryItem item) async {
    logInfo(
      '''Updating inventory item ${item.id}: qty=${item.quantity} ${item.unit}, loc=${item.location}''',
    );
    try {
      final db = await database;
      final rows = await db.update(
        'inventory',
        _inventoryToMap(item),
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

  /// Deletes an inventory item by its auto‑generated id.
  Future<int> deleteInventoryItem(int id) async {
    logInfo('Deleting inventory item $id');
    try {
      final db = await database;
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

  /// Retrieves all inventory rows joined with product metadata for a specific
  /// [inventoryId].
  ///
  /// This single query replaces multiple separate lookups and is used to build
  /// the home‑screen inventory list.
  Future<List<Map<String, dynamic>>> getInventoryWithProduct({
    required int inventoryId,
  }) async {
    try {
      final db = await database;
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
          inventories.name AS inventory_name
        FROM inventory
        INNER JOIN products ON inventory.barcode = products.barcode
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

  /// Returns the total number of cached product records.
  Future<int> getProductCount() async {
    final db = await database;
    return Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM products'),
        ) ??
        0;
  }

  /// Returns the total number of rows in the inventory table for a specific
  /// [inventoryId], or globally if `null`.
  Future<int> getInventoryCount({int? inventoryId}) async {
    final db = await database;
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

  /// Returns all inventory rows joined with product names and nutrition for a
  /// specific [inventoryId], ordered by expiry date. This is used for CSV
  /// export.
  Future<List<Map<String, dynamic>>> getExportData({
    required int inventoryId,
  }) async {
    try {
      final db = await database;
      final result = await db.rawQuery(
        '''
        SELECT
          products.name AS product_name,
          products.brand,
          products.category,
          inventory.barcode,
          inventory.quantity,
          inventory.unit,
          inventory.expiry_date,
          inventory.location,
          inventory.notes,
          inventory.date_added,
          products.energy_kcal,
          products.protein_g,
          products.carbs_g,
          products.fat_g,
          products.fiber_g,
          products.salt_g,
          inventories.name AS inventory_name
        FROM inventory
        INNER JOIN products ON inventory.barcode = products.barcode
        INNER JOIN inventories ON inventory.inventory_id = inventories.id
        WHERE inventory.inventory_id = ?
        ORDER BY inventory.expiry_date ASC
      ''',
        [inventoryId],
      );
      logInfo('Export data: ${result.length} rows');
      return result;
    } on Exception catch (e) {
      logError('Error fetching export data: $e');
      rethrow;
    }
  }

  // --------------------- Mapping helpers ---------------------

  Map<String, dynamic> _productToMap(Product p) => {
    'barcode': p.barcode,
    'name': p.name,
    'brand': p.brand,
    'image_url': p.imageUrl,
    'category': p.category,
    'ingredients': p.ingredients,
    'serving_size': p.servingSize,
    'energy_kcal': p.energyKcal,
    'protein_g': p.proteinG,
    'carbs_g': p.carbsG,
    'fat_g': p.fatG,
    'fiber_g': p.fiberG,
    'salt_g': p.saltG,
    'last_synced': p.lastSynced,
  };

  Product _productFromMap(Map<String, dynamic> map) => Product(
    barcode: map['barcode'] as String,
    name: map['name'] as String,
    brand: map['brand'] as String?,
    imageUrl: map['image_url'] as String?,
    category: map['category'] as String?,
    ingredients: map['ingredients'] as String?,
    servingSize: map['serving_size'] as String?,
    energyKcal: (map['energy_kcal'] as num?)?.toDouble(),
    proteinG: (map['protein_g'] as num?)?.toDouble(),
    carbsG: (map['carbs_g'] as num?)?.toDouble(),
    fatG: (map['fat_g'] as num?)?.toDouble(),
    fiberG: (map['fiber_g'] as num?)?.toDouble(),
    saltG: (map['salt_g'] as num?)?.toDouble(),
    lastSynced: map['last_synced'] as int?,
  );

  Map<String, dynamic> _inventoryToMap(InventoryItem item) => {
    if (item.id != null) 'id': item.id,
    'barcode': item.barcode,
    'quantity': item.quantity,
    'unit': item.unit,
    'expiry_date': item.expiryDate,
    'location': item.location,
    'notes': item.notes,
    'date_added': item.dateAdded,
    'inventory_id': item.inventoryId,
  };

  InventoryItem _inventoryFromMap(Map<String, dynamic> map) => InventoryItem(
    id: map['id'] as int?,
    barcode: map['barcode'] as String,
    quantity: (map['quantity'] as num?)?.toDouble() ?? 1,
    unit: map['unit'] as String? ?? 'pcs',
    expiryDate: map['expiry_date'] as String?,
    location: map['location'] as String? ?? 'pantry',
    notes: map['notes'] as String?,
    dateAdded: map['date_added'] as int?,
    inventoryId: map['inventory_id'] as int? ?? 1,
  );
}
