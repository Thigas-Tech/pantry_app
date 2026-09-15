import 'package:pantry_app/database/inventories_dao.dart';
import 'package:pantry_app/database/migrations/migration.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:sqflite/sqflite.dart';

/// The frozen baseline schema.
///
/// Creates the complete database from scratch: eleven tables, twenty-nine
/// indexes, and the default "Home" inventory. This migration is the single
/// source of truth for the schema; it must never be edited. Any later schema
/// change is a new numbered migration with its own [up] and [down].
///
/// The [down] method drops every table in reverse foreign-key dependency
/// order so the database can be reset to an empty file.
class MigrationV1 extends Migration {
  /// Creates the baseline migration.
  const MigrationV1();

  @override
  int get version => 1;

  @override
  Future<void> up(DatabaseExecutor db) async {
    await _createProducts(db);
    await _createInventories(db);
    await _createInventory(db);
    await _createProductSubmissionQueue(db);
    await _createPrices(db);
    await _createShoppingList(db);
    await _createStores(db);
    await _createRecipes(db);
    await _createRecipeIngredients(db);
    await _createRecipeHistory(db);
    await _createScanHistory(db);
    await _createIndexes(db);
    await const InventoriesDao().seedDefault(db);
    logInfo('Baseline schema created (version 1)');
  }

  @override
  Future<void> down(DatabaseExecutor db) async {
    for (final table in _tablesInDropOrder) {
      await db.execute('DROP TABLE IF EXISTS $table');
    }
    logInfo('Baseline schema dropped');
  }

  /// Tables in reverse foreign-key dependency order (children first).
  static const List<String> _tablesInDropOrder = [
    'recipe_ingredients',
    'recipes',
    'shopping_list',
    'inventory',
    'recipe_history',
    'prices',
    'product_submission_queue',
    'scan_history',
    'stores',
    'products',
    'inventories',
  ];

  Future<void> _createProducts(DatabaseExecutor db) async {
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
  }

  Future<void> _createInventories(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE inventories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');
  }

  Future<void> _createInventory(DatabaseExecutor db) async {
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
  }

  Future<void> _createProductSubmissionQueue(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE product_submission_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        barcode TEXT NOT NULL UNIQUE,
        retry_count INTEGER NOT NULL DEFAULT 0,
        max_retries INTEGER NOT NULL DEFAULT 5,
        next_retry_at INTEGER,
        created_at INTEGER NOT NULL
      )
    ''');
  }

  Future<void> _createPrices(DatabaseExecutor db) async {
    // No foreign keys by design: a price is the user's own record and must
    // survive product cache flushes and pantry deletion.
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
        inventory_id INTEGER NOT NULL DEFAULT 1
      )
    ''');
  }

  Future<void> _createShoppingList(DatabaseExecutor db) async {
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
        price_package_quantity REAL,
        price_package_unit TEXT,
        price_photo_path TEXT,
        expiry_date TEXT,
        sort_order REAL NOT NULL DEFAULT 0,
        FOREIGN KEY (barcode) REFERENCES products(barcode)
          ON DELETE SET NULL,
        FOREIGN KEY (inventory_id) REFERENCES inventories(id)
          ON DELETE SET NULL
      )
    ''');
  }

  Future<void> _createStores(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE stores (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE
      )
    ''');
  }

  Future<void> _createRecipes(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE recipes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        instructions TEXT NOT NULL DEFAULT '',
        servings INTEGER NOT NULL DEFAULT 0,
        image_path TEXT NOT NULL DEFAULT '',
        search_text TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        inventory_id INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (inventory_id) REFERENCES inventories(id)
          ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _createRecipeIngredients(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE recipe_ingredients (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        recipe_id INTEGER NOT NULL,
        barcode TEXT,
        name TEXT NOT NULL,
        quantity REAL NOT NULL DEFAULT 1.0,
        unit TEXT NOT NULL DEFAULT 'pieces',
        FOREIGN KEY (recipe_id) REFERENCES recipes(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _createRecipeHistory(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE recipe_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        recipe_id INTEGER NOT NULL,
        made_at INTEGER NOT NULL,
        cost_at_time REAL DEFAULT 0,
        ingredient_snapshot TEXT
      )
    ''');
  }

  Future<void> _createScanHistory(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE scan_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        barcode TEXT NOT NULL,
        name TEXT NOT NULL,
        scanned_at INTEGER NOT NULL,
        image_url TEXT
      )
    ''');
  }

  Future<void> _createIndexes(DatabaseExecutor db) async {
    const statements = [
      'CREATE INDEX idx_search_text ON products(search_text)',
      'CREATE INDEX idx_products_source ON products(source)',
      'CREATE INDEX idx_expiry ON inventory(expiry_date)',
      'CREATE INDEX idx_inventory_id ON inventory(inventory_id)',
      'CREATE INDEX idx_inventory_date_added ON inventory(date_added)',
      'CREATE INDEX idx_inventory_barcode_inventory_id'
          ' ON inventory(barcode, inventory_id)',
      'CREATE INDEX idx_inventory_inventory_expiry'
          ' ON inventory(inventory_id, expiry_date)',
      'CREATE INDEX idx_inventory_inventory_barcode'
          ' ON inventory(inventory_id, barcode)',
      'CREATE INDEX idx_prices_barcode ON prices(barcode)',
      'CREATE INDEX idx_prices_date ON prices(date_purchased)',
      'CREATE INDEX idx_prices_sync_status ON prices(sync_status)',
      'CREATE INDEX idx_prices_inventory_id ON prices(inventory_id)',
      'CREATE INDEX idx_prices_barcode_inventory_date'
          ' ON prices(barcode, inventory_id, date_purchased, id)',
      'CREATE INDEX idx_submission_queue_retry'
          ' ON product_submission_queue(next_retry_at)',
      'CREATE INDEX idx_shopping_barcode ON shopping_list(barcode)',
      'CREATE INDEX idx_shopping_purchased ON shopping_list(is_purchased)',
      'CREATE INDEX idx_shopping_inventory_id'
          ' ON shopping_list(inventory_id)',
      'CREATE INDEX idx_shopping_list_inventory_purchased_date'
          ' ON shopping_list(inventory_id, is_purchased, date_added)',
      'CREATE INDEX idx_shopping_inventory_purchased_sort'
          ' ON shopping_list(inventory_id, is_purchased, sort_order)',
      'CREATE INDEX idx_recipes_name ON recipes(name)',
      'CREATE INDEX idx_recipes_created_at ON recipes(created_at)',
      'CREATE INDEX idx_recipes_updated_at ON recipes(updated_at)',
      'CREATE INDEX idx_recipes_inventory_id ON recipes(inventory_id)',
      'CREATE INDEX idx_recipes_inventory_updated'
          ' ON recipes(inventory_id, updated_at)',
      'CREATE INDEX idx_recipe_ingredients_recipe_id'
          ' ON recipe_ingredients(recipe_id)',
      'CREATE INDEX idx_recipe_history_recipe'
          ' ON recipe_history(recipe_id)',
      'CREATE INDEX idx_recipe_history_made_at'
          ' ON recipe_history(made_at)',
      'CREATE INDEX idx_scan_history_scanned_at'
          ' ON scan_history(scanned_at)',
      'CREATE INDEX idx_scan_history_barcode ON scan_history(barcode)',
    ];
    for (final statement in statements) {
      await db.execute(statement);
    }
  }
}
