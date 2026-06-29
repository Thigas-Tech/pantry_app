import 'package:pantry_app/models/inventory_item.dart';
import 'package:pantry_app/models/product.dart';
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
/// For **testing** a separate instance can be created with
/// [DatabaseHelper.withPath], which opens an in‑memory database or a
/// temporary file. This avoids interfering with the singleton’s connection.
///
/// ## Platform support
///
/// This version targets **Android** (and will later support iOS). It uses the
/// standard `sqflite` plugin. Desktop and web are not supported in this build.
///
/// ## Schema overview
/// … (unchanged)
class DatabaseHelper {
  /// Creates a [DatabaseHelper] that opens (or creates) a database at the
  /// given [path] instead of the default location.
  ///
  /// This constructor is intended for **unit tests** that require an isolated
  /// database. In production code the default singleton ([DatabaseHelper()])
  /// should be used.
  DatabaseHelper.withPath(String path) : _customPath = path;

  /// Returns the single [DatabaseHelper] instance.
  factory DatabaseHelper() => _instance;

  /// Internal constructor for the singleton.
  DatabaseHelper._internal() : _customPath = null;
  final String? _customPath;

  static final DatabaseHelper _instance = DatabaseHelper._internal();

  /// The lazily‑initialised database connection.
  ///
  /// The first access to [database] triggers [_initDatabase], which creates
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
    return openDatabase(
      dbPath,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Returns the default path for the database file inside the app’s
  /// documents directory.
  Future<String> _getDefaultPath() async {
    final documentsDir = await getApplicationDocumentsDirectory();
    return join(documentsDir.path, 'pantry.db');
  }

  /// Creates the `products` and `inventory` tables together with their
  /// indexes.
  ///
  /// Called automatically by [openDatabase] when the database file does not
  /// exist yet (version 1).
  Future<void> _onCreate(Database db, int version) async {
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
      CREATE TABLE inventory (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        barcode TEXT NOT NULL,
        quantity REAL DEFAULT 1,
        unit TEXT DEFAULT 'pcs',
        expiry_date TEXT,
        location TEXT DEFAULT 'pantry',
        notes TEXT,
        date_added INTEGER,
        FOREIGN KEY(barcode) REFERENCES products(barcode)
      )
    ''');

    await db.execute('CREATE INDEX idx_barcode ON products(barcode)');
    await db.execute('CREATE INDEX idx_expiry ON inventory(expiry_date)');
    await db.execute(
      'CREATE INDEX idx_inventory_barcode ON inventory(barcode)',
    );
  }

  /// Placeholder for future database migrations.
  ///
  /// When the database version is increased, add conditional blocks here to
  /// alter the schema without losing user data.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Example: if (oldVersion < 2) { … }
  }

  // --------------------- Product CRUD ---------------------

  /// Inserts a [product] into the local cache.
  ///
  /// If a product with the same barcode already exists it is **replaced**
  /// (upsert). This is the intended behaviour because product data from Open
  /// Food Facts may have been updated.
  Future<void> insertProduct(Product product) async {
    final db = await database;
    await db.insert(
      'products',
      _productToMap(product),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Looks up a single product by its barcode.
  ///
  /// Returns `null` if no product with the given barcode exists in the local
  /// cache.
  Future<Product?> getProduct(String barcode) async {
    final db = await database;
    final result = await db.query(
      'products',
      where: 'barcode = ?',
      whereArgs: [barcode],
    );
    if (result.isEmpty) return null;
    return _productFromMap(result.first);
  }

  /// Removes inventory items that were added more than 60 days ago, and then
  /// deletes any product records that are no longer referenced by the
  /// remaining inventory items.
  ///
  /// The 60‑day cutoff is currently hard‑coded; it can be made configurable in
  /// the future if user preferences demand it.
  Future<void> cleanupOldEntries() async {
    final db = await database;
    final cutoff = DateTime.now()
        .subtract(const Duration(days: 60))
        .millisecondsSinceEpoch;

    await db.delete('inventory', where: 'date_added < ?', whereArgs: [cutoff]);

    // Remove orphaned products – a product whose last inventory entry was
    // just deleted.
    await db.rawDelete('''
      DELETE FROM products
      WHERE barcode NOT IN (SELECT DISTINCT barcode FROM inventory)
    ''');
  }

  // --------------------- Inventory CRUD ---------------------

  /// Inserts a new inventory item.
  ///
  /// The returned [int] is the auto‑generated `id` of the new row. This ID
  /// can be used later for updates or deletion.
  Future<int> insertInventoryItem(InventoryItem item) async {
    final db = await database;
    return db.insert('inventory', _inventoryToMap(item));
  }

  /// Retrieves all inventory items, optionally filtered by [location].
  ///
  /// The [expired] parameter is currently unused and reserved for a future
  /// implementation using SQLite date functions.
  Future<List<InventoryItem>> getInventoryItems({
    String? location,
    bool? expired,
  }) async {
    final db = await database;
    String? where;
    List<dynamic>? whereArgs;

    if (location != null) {
      where = 'location = ?';
      whereArgs = [location];
    }

    final result = await db.query(
      'inventory',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'expiry_date ASC',
    );
    return result.map(_inventoryFromMap).toList();
  }

  /// Returns all inventory entries for a specific barcode, ordered by expiry
  /// date (oldest first).
  Future<List<InventoryItem>> getInventoryItemsByBarcode(String barcode) async {
    final db = await database;
    final result = await db.query(
      'inventory',
      where: 'barcode = ?',
      whereArgs: [barcode],
      orderBy: 'expiry_date ASC',
    );
    return result.map(_inventoryFromMap).toList();
  }

  /// Updates an existing inventory item.
  ///
  /// The [item.id] field must be set to a value that exists in the database;
  /// otherwise the update has no effect.
  Future<int> updateInventoryItem(InventoryItem item) async {
    final db = await database;
    return db.update(
      'inventory',
      _inventoryToMap(item),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  /// Deletes an inventory item by its auto‑generated [id].
  Future<int> deleteInventoryItem(int id) async {
    final db = await database;
    return db.delete('inventory', where: 'id = ?', whereArgs: [id]);
  }

  /// Retrieves all inventory rows joined with product metadata.
  ///
  /// This single query replaces multiple separate lookups and is used to build
  /// the home‑screen inventory list.
  Future<List<Map<String, dynamic>>> getInventoryWithProduct() async {
    final db = await database;
    return db.rawQuery('''
      SELECT
        inventory.id,
        inventory.barcode,
        inventory.quantity,
        inventory.unit,
        inventory.expiry_date,
        inventory.location,
        inventory.notes,
        inventory.date_added,
        products.name AS product_name,
        products.image_url AS product_image_url
      FROM inventory
      INNER JOIN products ON inventory.barcode = products.barcode
      ORDER BY inventory.expiry_date ASC
    ''');
  }

  /// Returns the total number of cached product records.
  Future<int> getProductCount() async {
    final db = await database;
    return Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM products'),
        ) ??
        0;
  }

  /// Returns the total number of rows in the inventory table.
  Future<int> getInventoryCount() async {
    final db = await database;
    return Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM inventory'),
        ) ??
        0;
  }

  /// Returns all inventory rows joined with product names and nutrition,
  /// ordered by expiry date. This is used for CSV export.
  Future<List<Map<String, dynamic>>> getExportData() async {
    final db = await database;
    return db.rawQuery('''
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
        products.salt_g
      FROM inventory
      INNER JOIN products ON inventory.barcode = products.barcode
      ORDER BY inventory.expiry_date ASC
    ''');
  }

  // --------------------- Mapping helpers ---------------------

  /// Converts a [Product] model into a row map for SQLite.
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

  /// Builds a [Product] from a raw database row.
  ///
  /// Numeric fields are read as [num] and converted to [double] because
  /// SQLite may store them as integers when the decimal part is zero.
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

  /// Converts an [InventoryItem] into a row map.
  ///
  /// If [item.id] is `null` (new item) the map does not include the `id`
  /// field, allowing SQLite to auto‑generate the primary key.
  Map<String, dynamic> _inventoryToMap(InventoryItem item) => {
    if (item.id != null) 'id': item.id,
    'barcode': item.barcode,
    'quantity': item.quantity,
    'unit': item.unit,
    'expiry_date': item.expiryDate,
    'location': item.location,
    'notes': item.notes,
    'date_added': item.dateAdded,
  };

  /// Builds an [InventoryItem] from a raw database row.
  ///
  /// Defaults are applied to [quantity], [unit], and [location] in case the
  /// database contains unexpected `NULL` values (should not happen with the
  /// current schema, but provides robustness).
  InventoryItem _inventoryFromMap(Map<String, dynamic> map) => InventoryItem(
    id: map['id'] as int?,
    barcode: map['barcode'] as String,
    quantity: (map['quantity'] as num?)?.toDouble() ?? 1,
    unit: map['unit'] as String? ?? 'pcs',
    expiryDate: map['expiry_date'] as String?,
    location: map['location'] as String? ?? 'pantry',
    notes: map['notes'] as String?,
    dateAdded: map['date_added'] as int?,
  );
}
