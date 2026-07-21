/// @file DAO null-safety guard tests.
///
/// Tests that aggregate DAO methods and model deserialization do not
/// crash on null, empty, or missing fields.  Uses sqflite_common_ffi
/// with an in-memory database for fast, isolated DAO-level tests.
///
/// SQLite returns NULL for SUM on empty result sets — the DAO layer
/// must handle this with null-coalescing (??) instead of !.
/// Similarly, [ProductDao.fromMap] and [InventoryDao.fromMap] must
/// gracefully handle missing columns with sensible defaults.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/database/inventory_dao.dart';
import 'package:pantry_app/database/product_dao.dart';
import 'package:pantry_app/models/inventory_item.dart';
import 'package:pantry_app/models/product.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late DatabaseHelper db;

  setUp(() async {
    db = DatabaseHelper.withPath(inMemoryDatabasePath);
    await db.database;
  });

  tearDown(() async {
    final database = await db.database;
    await database.close();
  });

  group('photoCompleteness on empty database', () {
    /// Verifies all photo completeness fields return zero on an empty DB.
    test('returns zeros for all fields', () async {
      final database = await db.database;
      final result = await db.productDao.photoCompleteness(database);
      expect(result['total'], 0);
      expect(result['nutrition'], 0);
      expect(result['ingredients'], 0);
      expect(result['product'], 0);
    });
  });

  group('offPhotoCompleteness on empty database', () {
    /// Verifies all OFF photo completeness fields return zero on empty DB.
    test('returns zeros for all fields', () async {
      final database = await db.database;
      final result = await db.productDao.offPhotoCompleteness(database);
      expect(result['total'], 0);
      expect(result['nutrition'], 0);
      expect(result['ingredients'], 0);
      expect(result['product'], 0);
    });
  });

  group('locationDistribution on empty database', () {
    /// Verifies an empty map is returned when no inventory items exist.
    test('returns empty map', () async {
      final database = await db.database;
      final result = await db.inventoryDao.locationDistribution(
        database,
        inventoryId: 1,
      );
      expect(result, isEmpty);
    });
  });

  group('productDao.fromMap', () {
    /// Verifies that [ProductDao.fromMap] provides sensible defaults
    /// for missing optional fields.
    test('defaults source to api when missing', () {
      final map = {'barcode': '123', 'name': 'Test'};
      final product = db.productDao.fromMap(map);
      expect(product.source, 'api');
    });

    /// Verifies that [ProductDao.fromMap] defaults submission status
    /// when the column is not present.
    test('defaults submissionStatus when missing', () {
      final map = {'barcode': '123', 'name': 'Test'};
      final product = db.productDao.fromMap(map);
      expect(product.submissionStatus, 'not_submitted');
    });

    /// Verifies that [ProductDao.fromMap] handles null optional fields
    /// without crashing.
    test('handles null optional fields', () {
      final map = {
        'barcode': '123',
        'name': 'Test',
        'brand': null,
        'image_url': null,
        'category': null,
        'ingredients': null,
        'serving_size': null,
        'energy_kcal': null,
        'protein_g': null,
        'carbs_g': null,
        'fat_g': null,
        'fiber_g': null,
        'salt_g': null,
        'last_synced': null,
        'nutriscore_grade': null,
        'nutriscore_not_applicable_category': null,
        'nutrition_image_path': null,
        'ingredients_image_path': null,
        'product_image_path': null,
        'off_nutrition_image_url': null,
        'off_ingredients_image_url': null,
        'off_product_image_url': null,
      };
      final product = db.productDao.fromMap(map);
      expect(product.barcode, '123');
      expect(product.name, 'Test');
      expect(product.brand, isNull);
      expect(product.category, isNull);
      expect(product.nutriscoreGrade, isNull);
    });

    /// Verifies [ProductDao.fromMap] parses categories_hierarchy JSON
    /// into a List<String>.
    test('parses categoriesHierarchy JSON', () {
      final map = {
        'barcode': '123',
        'name': 'Test',
        'categories_hierarchy': '["en:dairy","en:milk"]',
      };
      final product = db.productDao.fromMap(map);
      expect(product.categoriesHierarchy, ['en:dairy', 'en:milk']);
    });

    /// Verifies [ProductDao.fromMap] handles null categories_hierarchy.
    test('handles null categoriesHierarchy', () {
      final map = {
        'barcode': '123',
        'name': 'Test',
        'categories_hierarchy': null,
      };
      final product = db.productDao.fromMap(map);
      expect(product.categoriesHierarchy, isNull);
    });

    /// Verifies explicit source is preserved.
    test('preserves explicit source', () {
      final map = {'barcode': '123', 'name': 'Test', 'source': 'manual'};
      final product = db.productDao.fromMap(map);
      expect(product.source, 'manual');
    });
  });

  group('inventoryDao.fromMap', () {
    /// Verifies [InventoryDao.fromMap] defaults quantity to 1.0 when
    /// the column is missing or null.
    test('defaults quantity to 1.0 when missing', () {
      final map = {'barcode': '123'};
      final item = db.inventoryDao.fromMap(map);
      expect(item.quantity, 1.0);
    });

    /// Verifies [InventoryDao.fromMap] defaults unit to 'pieces' when
    /// the column is missing.
    test('defaults unit to pieces when missing', () {
      final map = {'barcode': '123'};
      final item = db.inventoryDao.fromMap(map);
      expect(item.unit, 'pieces');
    });

    /// Verifies [InventoryDao.fromMap] defaults location to 'pantry'
    /// when the column is missing.
    test('defaults location to pantry when missing', () {
      final map = {'barcode': '123'};
      final item = db.inventoryDao.fromMap(map);
      expect(item.location, 'pantry');
    });

    /// Verifies [InventoryDao.fromMap] defaults inventoryId to 1 when
    /// the column is missing.
    test('defaults inventoryId to 1 when missing', () {
      final map = {'barcode': '123'};
      final item = db.inventoryDao.fromMap(map);
      expect(item.inventoryId, 1);
    });

    /// Verifies [InventoryDao.getLastAddDate] returns null for empty tables.
    test('getLastAddDate returns null for empty inventory', () async {
      final rawDb = await db.database;
      final result = await db.inventoryDao.getLastAddDate(rawDb);
      expect(result, isNull);
    });

    /// Verifies [InventoryDao.getLastAddDate] returns the max date_added.
    test('getLastAddDate returns latest dateAdded', () async {
      final rawDb = await db.database;
      await db.insertProduct(
        const Product(barcode: '111', name: '111'),
      );
      await db.insertProduct(
        const Product(barcode: '222', name: '222'),
      );
      await db.insertProduct(
        const Product(barcode: '333', name: '333'),
      );
      await db.inventoryDao.insert(
        rawDb,
        const InventoryItem(
          barcode: '111',
          id: 1,
          dateAdded: 1000,
        ),
      );
      await db.inventoryDao.insert(
        rawDb,
        const InventoryItem(
          barcode: '222',
          id: 2,
          dateAdded: 3000,
        ),
      );
      await db.inventoryDao.insert(
        rawDb,
        const InventoryItem(
          barcode: '333',
          id: 3,
          dateAdded: 2000,
        ),
      );
      final result = await db.inventoryDao.getLastAddDate(rawDb);
      expect(result, 3000);
    });

    /// Verifies [InventoryDao.fromMap] handles null id, notes, dateAdded.
    test('handles null optional fields', () {
      final map = {
        'barcode': '123',
        'id': null,
        'expiry_date': null,
        'notes': null,
        'date_added': null,
        'quantity': 2.5,
        'unit': 'kg',
        'location': 'fridge',
        'inventory_id': 3,
      };
      final item = db.inventoryDao.fromMap(map);
      expect(item.id, isNull);
      expect(item.expiryDate, isNull);
      expect(item.notes, isNull);
      expect(item.dateAdded, isNull);
      expect(item.quantity, 2.5);
      expect(item.unit, 'kg');
      expect(item.location, 'fridge');
      expect(item.inventoryId, 3);
    });
  });
}
