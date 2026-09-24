import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/database/migrations/all_migrations.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../helpers/test_database.dart';

/// Frozen expectations for the baseline schema.
///
/// This test is the guard against accidental edits to the baseline
/// migration: any schema change must fail here and be introduced as a new
/// numbered migration instead.
const Map<String, List<String>> _expectedColumns = {
  'products': [
    'barcode',
    'name',
    'brand',
    'image_url',
    'category',
    'ingredients',
    'serving_size',
    'serving_quantity',
    'quantity',
    'product_quantity',
    'energy_kcal',
    'protein_g',
    'carbs_g',
    'fat_g',
    'fiber_g',
    'salt_g',
    'additional_nutrients',
    'last_synced',
    'nutriscore_grade',
    'nutriscore_not_applicable_category',
    'source',
    'nutrition_image_path',
    'ingredients_image_path',
    'product_image_path',
    'submission_status',
    'off_nutrition_image_url',
    'off_ingredients_image_url',
    'off_product_image_url',
    'categories_hierarchy',
    'language_code',
    'search_text',
  ],
  'inventories': ['id', 'name', 'created_at'],
  'inventory': [
    'id',
    'barcode',
    'quantity',
    'unit',
    'expiry_date',
    'location',
    'notes',
    'date_added',
    'inventory_id',
    'serving_weight_g',
  ],
  'product_submission_queue': [
    'id',
    'barcode',
    'retry_count',
    'max_retries',
    'next_retry_at',
    'created_at',
  ],
  'prices': [
    'id',
    'barcode',
    'price',
    'currency',
    'store',
    'is_discounted',
    'regular_price',
    'date_purchased',
    'sync_status',
    'open_prices_id',
    'location_osm_id',
    'location_osm_type',
    'receipt_series',
    'receipt_number',
    'receipt_item_index',
    'notes',
    'package_quantity',
    'package_unit',
    'date_added',
    'inventory_id',
  ],
  'shopping_list': [
    'id',
    'barcode',
    'name',
    'quantity',
    'unit',
    'is_purchased',
    'inventory_id',
    'date_added',
    'date_purchased',
    'price_amount',
    'price_currency',
    'price_store',
    'price_package_quantity',
    'price_package_unit',
    'price_photo_path',
    'expiry_date',
    'sort_order',
  ],
  'stores': ['id', 'name'],
  'recipes': [
    'id',
    'name',
    'instructions',
    'servings',
    'image_path',
    'search_text',
    'created_at',
    'updated_at',
    'inventory_id',
  ],
  'recipe_ingredients': [
    'id',
    'recipe_id',
    'barcode',
    'name',
    'quantity',
    'unit',
  ],
  'recipe_history': [
    'id',
    'recipe_id',
    'made_at',
    'cost_at_time',
    'ingredient_snapshot',
  ],
  'scan_history': ['id', 'barcode', 'name', 'scanned_at', 'image_url'],
};

const List<String> _expectedIndexes = [
  'idx_search_text',
  'idx_products_source',
  'idx_expiry',
  'idx_inventory_id',
  'idx_inventory_date_added',
  'idx_inventory_barcode_inventory_id',
  'idx_inventory_inventory_expiry',
  'idx_inventory_inventory_barcode',
  'idx_prices_barcode',
  'idx_prices_date',
  'idx_prices_sync_status',
  'idx_prices_inventory_id',
  'idx_prices_barcode_inventory_date',
  'idx_submission_queue_retry',
  'idx_shopping_barcode',
  'idx_shopping_purchased',
  'idx_shopping_inventory_id',
  'idx_shopping_list_inventory_purchased_date',
  'idx_shopping_inventory_purchased_sort',
  'idx_recipes_name',
  'idx_recipes_created_at',
  'idx_recipes_updated_at',
  'idx_recipes_inventory_id',
  'idx_recipes_inventory_updated',
  'idx_recipe_ingredients_recipe_id',
  'idx_recipe_history_recipe',
  'idx_recipe_history_made_at',
  'idx_scan_history_scanned_at',
  'idx_scan_history_barcode',
];

Future<Set<String>> _tableNames(Database db) async {
  final rows = await db.rawQuery(
    "SELECT name FROM sqlite_master WHERE type='table'"
    " AND name NOT LIKE 'sqlite_%'",
  );
  return rows.map((r) => r['name']! as String).toSet();
}

Future<List<String>> _columnNames(Database db, String table) async {
  final rows = await db.rawQuery('PRAGMA table_info($table)');
  return rows.map((r) => r['name']! as String).toList();
}

Future<Set<String>> _indexNames(Database db) async {
  final rows = await db.rawQuery(
    "SELECT name FROM sqlite_master WHERE type='index'"
    " AND name NOT LIKE 'sqlite_%'",
  );
  return rows.map((r) => r['name']! as String).toSet();
}

Future<Set<String>> _foreignKeyTargets(Database db, String table) async {
  final rows = await db.rawQuery('PRAGMA foreign_key_list($table)');
  return rows.map((r) => r['table']! as String).toSet();
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('baseline schema', () {
    late Database db;

    setUp(() async {
      final helper = DatabaseHelper.withPath(uniqueTestDbPath());
      db = await helper.database;
    });

    tearDown(() async {
      await db.close();
    });

    test('creates exactly the expected tables', () async {
      expect(await _tableNames(db), _expectedColumns.keys.toSet());
    });

    test('every table has exactly the expected columns', () async {
      for (final entry in _expectedColumns.entries) {
        expect(
          await _columnNames(db, entry.key),
          entry.value,
          reason: 'column drift on table ${entry.key}',
        );
      }
    });

    test('creates exactly the expected indexes', () async {
      expect(await _indexNames(db), _expectedIndexes.toSet());
    });

    test('foreign keys point at the expected parents', () async {
      expect(await _foreignKeyTargets(db, 'inventory'), {
        'products',
        'inventories',
      });
      expect(await _foreignKeyTargets(db, 'shopping_list'), {
        'products',
        'inventories',
      });
      expect(await _foreignKeyTargets(db, 'recipes'), {'inventories'});
      expect(await _foreignKeyTargets(db, 'recipe_ingredients'), {'recipes'});
    });

    test('prices has no foreign keys by design', () async {
      expect(await _foreignKeyTargets(db, 'prices'), isEmpty);
    });

    test('seeds the default Home inventory', () async {
      final rows = await db.query('inventories');
      expect(rows, hasLength(1));
      expect(rows.single['name'], 'Home');
      expect(rows.single['id'], 1);
    });

    test('databaseVersion matches the highest migration', () {
      final versions = allMigrations().map((m) => m.version).toList();
      expect(versions, isNotEmpty);
      expect(versions.last, DatabaseHelper.databaseVersion);
    });
  });
}
