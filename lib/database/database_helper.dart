import 'package:pantry_app/models/inventory_item.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/utils/platform_utils.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseHelper {
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();
  static final DatabaseHelper _instance = DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    if (!isMobile) {
      databaseFactory = databaseFactoryFfi;
    }
    final documentsDir = await getApplicationDocumentsDirectory();
    final dbPath = join(documentsDir.path, 'pantry.db');
    return openDatabase(
      dbPath,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

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

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Placeholder for future migrations
    // Example: if (oldVersion < 2) { ... }
  }

  // ---------- Product CRUD ----------
  Future<void> insertProduct(Product product) async {
    final db = await database;
    await db.insert(
      'products',
      _productToMap(product),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

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

  // ---------- Inventory CRUD ----------
  Future<int> insertInventoryItem(InventoryItem item) async {
    final db = await database;
    // id is auto-generated, so omit if null
    return db.insert('inventory', _inventoryToMap(item));
  }

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

    // For expiry filtering you'd add a condition like
    // "expiry_date < date('now')" – we'll handle that later via providers.

    final result = await db.query(
      'inventory',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'expiry_date ASC',
    );
    return result.map(_inventoryFromMap).toList();
  }

  // Get all inventory items for a specific barcode
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

  Future<int> updateInventoryItem(InventoryItem item) async {
    final db = await database;
    return db.update(
      'inventory',
      _inventoryToMap(item),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> deleteInventoryItem(int id) async {
    final db = await database;
    return db.delete('inventory', where: 'id = ?', whereArgs: [id]);
  }

  /// Returns inventory items joined with the product name and image.
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

  // ---------- Mapping helpers ----------
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
  );
}
