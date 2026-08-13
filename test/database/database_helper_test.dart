import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/database/firebase_cache_meta_dao.dart';
import 'package:pantry_app/database/migrations/migration_runner.dart';
import 'package:pantry_app/database/migrations/v13_shopping_list_table.dart';
import 'package:pantry_app/database/migrations/v20_backfill_inventory_id.dart';
import 'package:pantry_app/database/migrations/v24_firebase_cache_meta.dart';
import 'package:pantry_app/database/migrations/v28_normalize_produce_barcodes.dart';
import 'package:pantry_app/database/migrations/v3_normalize_units.dart';
import 'package:pantry_app/models/inventory_item.dart';
import 'package:pantry_app/models/price.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/models/product_nutrient.dart';
import 'package:pantry_app/models/recipe.dart';
import 'package:pantry_app/models/recipe_history_entry.dart';
import 'package:pantry_app/models/recipe_ingredient.dart';
import 'package:pantry_app/models/scan_history_entry.dart';
import 'package:pantry_app/models/shopping_item.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Tests for [DatabaseHelper] using an in‑memory SQLite database.
///
/// Each test runs against a fresh database created with
/// [DatabaseHelper.withPath]. The schema is version 2, which
/// includes the inventories table and the inventory_id column.
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

  group('Product CRUD', () {
    const product = Product(barcode: '123', name: 'Test', energyKcal: 100);

    test('insert and getProduct', () async {
      await db.insertProduct(product);
      final fetched = await db.getProduct('123');
      expect(fetched, isNotNull);
      expect(fetched!.name, 'Test');
      expect(fetched.energyKcal, 100);
    });

    test('upsert replaces existing', () async {
      await db.insertProduct(product);
      final updated = product.copyWith(name: 'Updated');
      await db.insertProduct(updated);
      final fetched = await db.getProduct('123');
      expect(fetched!.name, 'Updated');
    });

    test('getProduct returns null for missing barcode', () async {
      final result = await db.getProduct('nonexistent');
      expect(result, isNull);
    });

    test('insert and getProduct round-trips additional nutrients', () async {
      const product = Product(
        barcode: '123',
        name: 'Test',
        energyKcal: 100,
        additionalNutrients: [
          ProductNutrient(offTag: 'vitamin-c', value: 20, unit: 'mg'),
          ProductNutrient(offTag: 'sodium', value: 0.5, unit: 'g'),
        ],
      );
      await db.insertProduct(product);
      final fetched = await db.getProduct('123');
      expect(fetched!.additionalNutrients, product.additionalNutrients);
    });

    test(
      'insert and getProduct round-trips empty additional nutrients',
      () async {
        const product = Product(barcode: '123', name: 'Test');
        await db.insertProduct(product);
        final fetched = await db.getProduct('123');
        expect(fetched!.additionalNutrients, isEmpty);
      },
    );
  });

  group('Inventories CRUD', () {
    test('createInventory and getInventories', () async {
      await db.createInventory('Work');
      await db.createInventory('Camping');
      final list = await db.getInventories();
      expect(list.length, 3);
      expect(
        list.map((e) => e['name']),
        containsAll(['Home', 'Work', 'Camping']),
      );
    });

    test('renameInventory changes the name', () async {
      final id = await db.createInventory('Old');
      await db.renameInventory(id, 'New');
      final list = await db.getInventories();
      final renamed = list.firstWhere((e) => e['id'] == id);
      expect(renamed['name'], 'New');
    });

    test('deleteInventory removes the inventory and its items', () async {
      final id = await db.createInventory('Temp');
      await db.insertProduct(const Product(barcode: 'p1', name: 'P1'));
      await db.insertInventoryItem(
        InventoryItem(barcode: 'p1', inventoryId: id),
      );
      // Item in the default Home inventory (no explicit inventoryId needed).
      await db.insertInventoryItem(
        const InventoryItem(barcode: 'p1'),
      );

      await db.deleteInventory(id);

      final list = await db.getInventories();
      expect(list.any((e) => e['id'] == id), isFalse);

      final items = await db.getInventoryItems(inventoryId: 1);
      expect(items.length, 1);

      final tempItems = await db.getInventoryItems(inventoryId: id);
      expect(tempItems, isEmpty);
    });
  });

  group('Prices per inventory', () {
    test('getLatestPrice and getPricesByBarcode are scoped', () async {
      await db.insertProduct(const Product(barcode: '123', name: 'Coffee'));
      final workId = await db.createInventory('Work');

      await db.insertPrice(
        const Price(barcode: '123', price: 10, datePurchased: 100),
      );
      await db.insertPrice(
        Price(
          barcode: '123',
          price: 20,
          inventoryId: workId,
          datePurchased: 200,
        ),
      );

      final homeLatest = await db.getLatestPrice(
        '123',
        inventoryId: 1,
      );
      final workLatest = await db.getLatestPrice(
        '123',
        inventoryId: workId,
      );
      expect(homeLatest!.price, 10);
      expect(workLatest!.price, 20);

      final homeHistory = await db.getPricesByBarcode(
        '123',
        inventoryId: 1,
      );
      expect(homeHistory, hasLength(1));
      expect(homeHistory.first.price, 10);
    });

    test('deleteInventory preserves price rows', () async {
      await db.insertProduct(const Product(barcode: '123', name: 'Coffee'));
      final workId = await db.createInventory('Work');

      await db.insertPrice(
        const Price(barcode: '123', price: 10, datePurchased: 100),
      );
      await db.insertPrice(
        Price(
          barcode: '123',
          price: 20,
          inventoryId: workId,
          datePurchased: 200,
        ),
      );

      await db.deleteInventory(workId);

      // The inventory is gone...
      final list = await db.getInventories();
      expect(list.any((e) => e['id'] == workId), isFalse);

      // ...but both price rows survive (barcode observations are not deleted).
      expect(
        (await db.getLatestPrice('123', inventoryId: 1))!.price,
        10,
      );
      expect(
        (await db.getLatestPrice('123', inventoryId: workId))!.price,
        20,
      );
    });
  });

  group('Recipes per inventory', () {
    test('getAllRecipes filters by inventory', () async {
      final workId = await db.createInventory('Work');
      await db.insertRecipe(
        const Recipe(name: 'Home Soup'),
      );
      await db.insertRecipe(
        Recipe(name: 'Work Salad', inventoryId: workId),
      );

      final homeRecipes = await db.getAllRecipes(1);
      final workRecipes = await db.getAllRecipes(workId);

      expect(homeRecipes.map((r) => r.name), ['Home Soup']);
      expect(workRecipes.map((r) => r.name), ['Work Salad']);
    });

    test('insertRecipeWithIngredients persists inventory_id', () async {
      final workId = await db.createInventory('Work');
      final recipeId = await db.insertRecipeWithIngredients(
        Recipe(name: 'Work Soup', inventoryId: workId),
        const [
          RecipeIngredient(recipeId: 0, name: 'Carrots', quantity: 3),
        ],
      );

      final recipe = await db.getRecipe(recipeId);
      expect(recipe!.inventoryId, workId);

      final ingredients = await db.getRecipeIngredients(recipeId);
      expect(ingredients, hasLength(1));
    });

    test(
      'updateRecipeWithIngredients preserves existing inventory_id',
      () async {
        final workId = await db.createInventory('Work');
        final recipeId = await db.insertRecipeWithIngredients(
          Recipe(name: 'Work Soup', inventoryId: workId),
          const [
            RecipeIngredient(recipeId: 0, name: 'Carrots', quantity: 3),
          ],
        );

        // Caller passes default inventoryId (1) — must NOT move the recipe.
        await db.updateRecipeWithIngredients(
          Recipe(id: recipeId, name: 'Work Soup V2'),
          const [
            RecipeIngredient(recipeId: 0, name: 'Carrots', quantity: 5),
          ],
        );

        final recipe = await db.getRecipe(recipeId);
        expect(recipe!.name, 'Work Soup V2');
        expect(recipe.inventoryId, workId);
      },
    );

    test(
      "deleteInventory deletes that inventory's recipes, ingredients,"
      " and history but leaves other inventories' recipes intact",
      () async {
        final workId = await db.createInventory('Work');

        // A recipe in the work inventory with ingredients + history.
        final workRecipeId = await db.insertRecipeWithIngredients(
          Recipe(name: 'Work Soup', inventoryId: workId),
          const [
            RecipeIngredient(recipeId: 0, name: 'Carrots', quantity: 3),
          ],
        );
        await db.insertRecipeHistory(
          RecipeHistoryEntry(
            recipeId: workRecipeId,
            madeAt: 1000,
            ingredientSnapshot: '[]',
          ),
        );

        // A recipe in the Home inventory that must survive.
        await db.insertRecipeWithIngredients(
          const Recipe(name: 'Home Soup'),
          const [
            RecipeIngredient(recipeId: 0, name: 'Onions', quantity: 2),
          ],
        );

        await db.deleteInventory(workId);

        expect(await db.getRecipe(workRecipeId), isNull);
        expect(await db.getRecipeIngredients(workRecipeId), isEmpty);
        expect(await db.getRecipeHistory(workRecipeId), isEmpty);

        final homeRecipes = await db.getAllRecipes(1);
        expect(homeRecipes.map((r) => r.name), ['Home Soup']);
      },
    );

    test(
      "deleteInventory nulls that inventory's shopping list items",
      () async {
        final workId = await db.createInventory('Work');
        await db.insertShoppingItem(
          ShoppingItem(
            name: 'Work Milk',
            inventoryId: workId,
          ),
        );
        await db.insertShoppingItem(
          const ShoppingItem(
            name: 'Home Bread',
            inventoryId: 1,
          ),
        );

        await db.deleteInventory(workId);

        // The work item keeps its row but loses the dangling inventory ref,
        // mirroring the ON DELETE SET NULL FK intent that foreign-key
        // enforcement cannot apply here (FK is off during the delete).
        final all = await db.getShoppingList();
        final workItem = all.firstWhere((i) => i.name == 'Work Milk');
        expect(workItem.inventoryId, isNull);

        final homeItem = all.firstWhere((i) => i.name == 'Home Bread');
        expect(homeItem.inventoryId, 1);
      },
    );

    test(
      'insertRecipeWithIngredients writes search_text',
      () async {
        final recipeId = await db.insertRecipeWithIngredients(
          const Recipe(
            name: 'Crème Brûlée',
            instructions: 'à la mode',
          ),
          const [
            RecipeIngredient(recipeId: 0, name: 'Sugar'),
          ],
        );

        final database = await db.database;
        final rows = await database.rawQuery(
          'SELECT search_text FROM recipes WHERE id = ?',
          [recipeId],
        );
        expect(rows, isNotEmpty);
        expect(rows.first['search_text'], 'creme brulee a la mode');
      },
    );

    test(
      'updateRecipeWithIngredients recomputes search_text on rename',
      () async {
        final recipeId = await db.insertRecipeWithIngredients(
          const Recipe(
            name: 'Crème Brûlée',
            instructions: 'à la mode',
          ),
          const [
            RecipeIngredient(recipeId: 0, name: 'Sugar'),
          ],
        );

        await db.updateRecipeWithIngredients(
          Recipe(id: recipeId, name: 'Café au Lait', instructions: 'Heat milk'),
          const [
            RecipeIngredient(recipeId: 0, name: 'Milk'),
          ],
        );

        final database = await db.database;
        final rows = await database.rawQuery(
          'SELECT search_text FROM recipes WHERE id = ?',
          [recipeId],
        );
        expect(rows, isNotEmpty);
        expect(rows.first['search_text'], 'cafe au lait heat milk');
      },
    );
  });

  group('Inventory Item CRUD', () {
    const product = Product(barcode: '123', name: 'Test');

    setUp(() async {
      await db.insertProduct(product);
    });

    test('insert and retrieve inventory items', () async {
      const item = InventoryItem(
        barcode: '123',
        quantity: 2,
        unit: 'kg',
      );
      final id = await db.insertInventoryItem(item);
      expect(id, greaterThan(0));

      final items = await db.getInventoryItems(inventoryId: 1);
      expect(items.length, 1);
      expect(items.first.quantity, 2);
    });

    test('getInventoryItemsByBarcode filters correctly', () async {
      final workId = await db.createInventory('Work');
      await db.insertInventoryItem(
        const InventoryItem(barcode: '123'),
      );
      await db.insertInventoryItem(
        InventoryItem(barcode: '123', quantity: 3, inventoryId: workId),
      );

      final homeItems = await db.getInventoryItemsByBarcode(
        '123',
        inventoryId: 1,
      );
      final workItems = await db.getInventoryItemsByBarcode(
        '123',
        inventoryId: workId,
      );
      expect(homeItems.length, 1);
      expect(workItems.length, 1);
      expect(workItems.first.quantity, 3);
    });

    test('updateInventoryItem modifies existing', () async {
      const item = InventoryItem(barcode: '123');
      final id = await db.insertInventoryItem(item);
      final updated = item.copyWith(id: id, quantity: 5);
      await db.updateInventoryItem(updated);
      final items = await db.getInventoryItems(inventoryId: 1);
      expect(items.first.quantity, 5);
    });

    test('deleteInventoryItem removes item', () async {
      final id = await db.insertInventoryItem(
        const InventoryItem(barcode: '123'),
      );
      await db.deleteInventoryItem(id);
      final items = await db.getInventoryItems(inventoryId: 1);
      expect(items, isEmpty);
    });

    test('moveItemsToInventory reassigns items to target inventory', () async {
      // Create two inventories.
      await db.createInventory('Pantry A');
      await db.createInventory('Pantry B');

      // Insert products.
      await db.insertProduct(
        const Product(barcode: '001', name: 'Test'),
      );
      await db.insertProduct(
        const Product(barcode: '002', name: 'Test 2'),
      );

      // Insert two items in Pantry A.
      final id1 = await db.insertInventoryItem(
        const InventoryItem(barcode: '001'),
      );
      final id2 = await db.insertInventoryItem(
        const InventoryItem(barcode: '002', quantity: 2),
      );
      await db.moveItemsToInventory([id1, id2], 2);

      // Verify they now belong to Pantry B.
      final itemsInB = await db.getInventoryItems(inventoryId: 2);
      expect(itemsInB.length, 2);

      // Verify they no longer belong to Pantry A.
      final itemsInA = await db.getInventoryItems(inventoryId: 1);
      expect(itemsInA.length, 0);
    });
  });

  group('cleanupOldEntries', () {
    test(
      'removes items older than retention days and orphaned products',
      () async {
        await db.insertProduct(const Product(barcode: 'p1', name: 'P1'));
        await db.insertProduct(const Product(barcode: 'p2', name: 'P2'));
        final oldItem = InventoryItem(
          barcode: 'p1',
          dateAdded: DateTime.now()
              .subtract(const Duration(days: 70))
              .millisecondsSinceEpoch,
        );
        final newItem = InventoryItem(
          barcode: 'p2',
          dateAdded: DateTime.now()
              .subtract(const Duration(days: 10))
              .millisecondsSinceEpoch,
        );
        await db.insertInventoryItem(oldItem);
        await db.insertInventoryItem(newItem);

        await db.cleanupOldEntries();

        final remaining = await db.getInventoryItems(inventoryId: 1);
        expect(remaining, hasLength(1));
        expect(remaining.first.barcode, 'p2');
        expect(remaining.first.dateAdded, newItem.dateAdded);

        final product = await db.getProduct('p2');
        expect(product, isNotNull);
      },
    );

    test('removes orphaned product after all items are cleaned', () async {
      await db.insertProduct(const Product(barcode: 'p2', name: 'P2'));
      await db.insertInventoryItem(
        InventoryItem(
          barcode: 'p2',
          dateAdded: DateTime.now()
              .subtract(const Duration(days: 70))
              .millisecondsSinceEpoch,
        ),
      );

      await db.cleanupOldEntries();

      final product = await db.getProduct('p2');
      expect(product, isNull);
    });
  });

  group('getInventoryWithProduct', () {
    test('returns joined data with inventory name', () async {
      await db.insertProduct(
        const Product(barcode: 'p1', name: 'Prod1', imageUrl: 'img'),
      );
      await db.insertInventoryItem(
        const InventoryItem(
          barcode: 'p1',
          quantity: 3,
          unit: 'kg',
          expiryDate: '2026-01-01',
        ),
      );

      final rows = await db.getInventoryWithProduct(inventoryId: 1);
      expect(rows.length, 1);
      expect(rows.first['product_name'], 'Prod1');
      expect(rows.first['product_image_url'], 'img');
      expect(rows.first['quantity'], 3);
      expect(rows.first['inventory_name'], 'Home');
    });
  });

  group('getInventoryRowsByProductName', () {
    test('caps the name-based FEFO fallback at the limit', () async {
      for (var i = 0; i < 25; i++) {
        await db.insertProduct(
          Product(barcode: 'n$i', name: 'Milk Brand $i'),
        );
        await db.insertInventoryItem(
          InventoryItem(
            barcode: 'n$i',
            expiryDate: '2027-01-${(i % 9) + 1}0',
          ),
        );
      }

      final rows = await db.getInventoryRowsByProductName(
        name: 'milk',
        inventoryId: 1,
      );

      expect(rows.length, lessThanOrEqualTo(20));
    });

    test('returns all matches when under the limit', () async {
      await db.insertProduct(const Product(barcode: 'a', name: 'Milk'));
      await db.insertInventoryItem(
        const InventoryItem(barcode: 'a', expiryDate: '2027-01-01'),
      );

      final rows = await db.getInventoryRowsByProductName(
        name: 'milk',
        inventoryId: 1,
      );

      expect(rows, hasLength(1));
    });
  });

  group('counts', () {
    test('getProductCount and getInventoryCount', () async {
      await db.insertProduct(const Product(barcode: 'a', name: 'A'));
      await db.insertProduct(const Product(barcode: 'b', name: 'B'));
      await db.insertInventoryItem(
        const InventoryItem(barcode: 'a'),
      );
      expect(await db.getProductCount(), 2);
      expect(await db.getInventoryCount(), 1);
      expect(await db.getInventoryCount(inventoryId: 1), 1);
    });
  });

  group('Migration v1 → v2', () {
    test('upgrades a v1 database correctly', () async {
      // Create a temporary file for the v1 database.
      final tempDir = Directory.systemTemp.createTempSync('pantry_v1_');
      final v1Path = '${tempDir.path}/pantry.db';
      final v1Db = await openDatabase(
        v1Path,
        version: 1,
        onCreate: (db, _) async {
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
              unit TEXT DEFAULT 'pieces',
              expiry_date TEXT,
              location TEXT DEFAULT 'pantry',
              notes TEXT,
              date_added INTEGER,
              FOREIGN KEY(barcode) REFERENCES products(barcode)
            )
          ''');
          // Insert a product and an old inventory item.
          await db.insert('products', {
            'barcode': 'old',
            'name': 'Old Product',
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
          });
          await db.insert('inventory', {
            'barcode': 'old',
            'quantity': 2,
            'unit': 'pieces',
            'expiry_date': '2025-12-31',
            'location': 'pantry',
            'notes': 'old item',
            'date_added': 12345,
          });
        },
      );
      await v1Db.close();

      // 2. Open with the current DatabaseHelper – the upgrade from v1 to v2
      //    will run automatically.
      final dbHelper = DatabaseHelper.withPath(v1Path);
      await dbHelper.database;

      // 3. Verify the migration outcome.
      final inventories = await dbHelper.getInventories();
      expect(inventories.length, 1);
      expect(inventories.first['name'], 'Home');

      final items = await dbHelper.getInventoryItems(inventoryId: 1);
      expect(items.length, 1);
      expect(items.first.barcode, 'old');
      expect(items.first.dateAdded, 12345);
      expect(items.first.inventoryId, 1);

      final product = await dbHelper.getProduct('old');
      expect(product, isNotNull);
      expect(product!.name, 'Old Product');

      // Clean up.
      final migratedDb = await dbHelper.database;
      await migratedDb.close();
      // Delete the temporary directory.
      tempDir.deleteSync(recursive: true);
    });
  });
  group('Migration v2 → v3', () {
    test('updates pcs units to pieces', () async {
      final tempDir = Directory.systemTemp.createTempSync('pantry_v2_');
      final v2Path = '${tempDir.path}/pantry.db';
      final v2Db = await openDatabase(
        v2Path,
        version: 2,
        onCreate: (db, _) async {
          await db.execute('''
            CREATE TABLE products (
              barcode TEXT PRIMARY KEY,
              name TEXT NOT NULL
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
              inventory_id INTEGER NOT NULL
            )
          ''');
          await db.insert('inventories', {
            'name': 'Home',
            'created_at': DateTime.now().millisecondsSinceEpoch,
          });
        },
      );

      await v2Db.insert('products', {'barcode': 'a', 'name': 'A'});
      await v2Db.insert('products', {'barcode': 'b', 'name': 'B'});
      await v2Db.insert('inventory', {
        'barcode': 'a',
        'unit': 'pcs',
        'location': 'pantry',
        'inventory_id': 1,
      });
      await v2Db.insert('inventory', {
        'barcode': 'b',
        'unit': 'kg',
        'location': 'fridge',
        'inventory_id': 1,
      });
      await v2Db.close();

      // Reopen and run only the v3 migration. The hand-rolled v2 schema
      // above is intentionally minimal (only the tables v3 touches), so
      // the full v3→v38 chain cannot apply to it — run the migration
      // under test directly instead.
      final migratedDb = await openDatabase(v2Path);
      await MigrationRunner([MigrationV3()]).run(migratedDb, 2, 3);

      final rows = await migratedDb.query('inventory');
      final unitA = rows.firstWhere((r) => r['barcode'] == 'a')['unit'];
      final unitB = rows.firstWhere((r) => r['barcode'] == 'b')['unit'];
      expect(unitA, 'pieces');
      expect(unitB, 'kg');

      await migratedDb.close();
      tempDir.deleteSync(recursive: true);
    });
  });
  group('Migration v5 → v6', () {
    test('adds source column with default api', () async {
      final tempDir = Directory.systemTemp.createTempSync('pantry_v5_');
      final v5Path = '${tempDir.path}/pantry.db';
      final v5Db = await openDatabase(
        v5Path,
        version: 5,
        onCreate: (db, _) async {
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
              nutriscore_not_applicable_category TEXT
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
              unit TEXT DEFAULT 'pieces',
              expiry_date TEXT,
              location TEXT DEFAULT 'pantry',
              notes TEXT,
              date_added INTEGER,
              inventory_id INTEGER NOT NULL
            )
          ''');
          await db.insert('inventories', {
            'name': 'Home',
            'created_at': DateTime.now().millisecondsSinceEpoch,
          });
        },
      );

      await v5Db.insert('products', {'barcode': 'a', 'name': 'A'});
      await v5Db.insert('products', {'barcode': 'b', 'name': 'B'});
      await v5Db.close();

      final dbHelper = DatabaseHelper.withPath(v5Path);
      final products = await dbHelper.getAllProducts();

      expect(products, hasLength(2));
      // Existing products get the default source.
      expect(products.every((p) => p.source == 'api'), isTrue);

      final apiProducts = await dbHelper.getCachedProducts();
      expect(apiProducts, hasLength(2));

      // clearCachedProducts removes only api-sourced products.
      await dbHelper.clearCachedProducts();
      final remaining = await dbHelper.getAllProducts();
      expect(remaining, isEmpty);

      final migratedDb = await dbHelper.database;
      await migratedDb.close();
      tempDir.deleteSync(recursive: true);
    });
  });

  group('clearCachedProducts', () {
    test('deletes api products but preserves manual products', () async {
      await db.insertProduct(
        const Product(barcode: 'api1', name: 'API1'),
      );
      await db.insertProduct(
        const Product(barcode: 'manual1', name: 'Manual1', source: 'manual'),
      );
      await db.insertProduct(
        const Product(barcode: 'manual2', name: 'Manual2', source: 'manual'),
      );

      expect(await db.getProductCount(), 3);

      await db.clearCachedProducts();

      // API product deleted.
      expect(await db.getProduct('api1'), isNull);
      // Manual products preserved.
      expect((await db.getProduct('manual1'))!.name, 'Manual1');
      expect((await db.getProduct('manual2'))!.name, 'Manual2');
      expect(await db.getProductCount(), 2);
    });

    test('no-op when there are no api products', () async {
      await db.insertProduct(
        const Product(barcode: 'm1', name: 'M1', source: 'manual'),
      );
      expect(await db.getProductCount(), 1);
      await db.clearCachedProducts();
      expect(await db.getProductCount(), 1);
    });

    test('getCachedProducts excludes manual products', () async {
      await db.insertProduct(
        const Product(barcode: 'a1', name: 'A1'),
      );
      await db.insertProduct(
        const Product(barcode: 'm1', name: 'M1', source: 'manual'),
      );
      final cached = await db.getCachedProducts();
      expect(cached, hasLength(1));
      expect(cached.first.barcode, 'a1');
    });
  });

  group('clearAllProducts', () {
    test('deletes all products regardless of source', () async {
      await db.insertProduct(
        const Product(barcode: 'a1', name: 'A1'),
      );
      await db.insertProduct(
        const Product(barcode: 'm1', name: 'M1', source: 'manual'),
      );
      expect(await db.getProductCount(), 2);
      await db.clearAllProducts();
      expect(await db.getProductCount(), 0);
    });
  });

  group('Migration v12 -> v13', () {
    test('shopping_list table is created on upgrade', () async {
      final tempDir = Directory.systemTemp.createTempSync('pantry_v12_');
      final v12Path = '${tempDir.path}/pantry.db';
      final v12Db = await openDatabase(
        v12Path,
        version: 12,
        onCreate: (db, _) async {
          await db.execute('''
            CREATE TABLE products (
              barcode TEXT PRIMARY KEY,
              name TEXT NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE inventories (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              created_at INTEGER
            )
          ''');
          await db.execute("INSERT INTO inventories VALUES (1, 'Default', 0)");
        },
      );
      await v12Db.close();

      // Reopen and run only the v13 migration. The hand-rolled v12 schema
      // above is intentionally minimal, so the full v13→v38 chain cannot
      // apply to it — run the migration under test directly instead.
      final migratedDb = await openDatabase(v12Path);
      await MigrationRunner([MigrationV13()]).run(migratedDb, 12, 13);

      final id = await migratedDb.insert('shopping_list', {
        'name': 'Milk',
        'date_added': DateTime.now().millisecondsSinceEpoch,
      });
      expect(id, isNonNegative);
      final items = await migratedDb.query('shopping_list');
      expect(items.length, 1);
      expect(items[0]['name'], 'Milk');

      await migratedDb.close();
      tempDir.deleteSync(recursive: true);
    });
  });

  group('Migration v19 → v20', () {
    test('backfills null inventory_id on shopping list items', () async {
      final tempDir = Directory.systemTemp.createTempSync('pantry_v19_');
      final v19Path = '${tempDir.path}/v19.db';
      final v19Db = await openDatabase(
        v19Path,
        version: 19,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE inventories (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              created_at INTEGER NOT NULL
            )
          ''');
          await db.execute(
            "INSERT INTO inventories (name, created_at) VALUES ('Home', 1)",
          );
          await db.execute(
            "INSERT INTO inventories (name, created_at) VALUES ('Work', 2)",
          );
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
              price_photo_path TEXT,
              FOREIGN KEY (inventory_id) REFERENCES inventories(id)
                ON DELETE SET NULL
            )
          ''');
          await db.insert('shopping_list', {
            'name': 'Milk',
            'inventory_id': null,
            'date_added': 1,
          });
          await db.insert('shopping_list', {
            'name': 'Bread',
            'inventory_id': 1,
            'date_added': 2,
          });
        },
      );
      await v19Db.close();

      // Reopen and run only the v20 migration. The hand-rolled v19 schema
      // above is intentionally minimal, so the full v20→v38 chain cannot
      // apply to it — run the migration under test directly instead.
      final migratedDb = await openDatabase(v19Path);
      await MigrationRunner([MigrationV20()]).run(migratedDb, 19, 20);

      final items = await migratedDb.query('shopping_list');
      expect(items.length, 2);
      expect(items[0]['inventory_id'], isNotNull);
      expect(items[1]['inventory_id'], 1);

      await migratedDb.close();
      tempDir.deleteSync(recursive: true);
    });
  });

  group('Migration v22 — serving_weight_g', () {
    test('fresh v22 DB has serving_weight_g column on inventory', () async {
      final database = await db.database;
      final columns = await database.rawQuery(
        "PRAGMA table_info('inventory')",
      );
      final columnNames = columns
          .map((c) => (c['name'] as String?) ?? '')
          .toList();
      expect(columnNames, contains('serving_weight_g'));
    });

    test(
      'insert and retrieve inventory item with servingWeightG survives '
      'round-trip',
      () async {
        await db.insertProduct(
          const Product(barcode: 'produce', name: 'Apple'),
        );
        const item = InventoryItem(
          barcode: 'produce',
          unit: 'medium apple',
          servingWeightG: 182,
        );
        final id = await db.insertInventoryItem(item);
        final items = await db.getInventoryItems(inventoryId: 1);
        final saved = items.firstWhere((i) => i.id == id);
        expect(saved.servingWeightG, 182);
        expect(saved.unit, 'medium apple');
      },
    );
  });

  group('Migration v23 → v24', () {
    test(
      'creates firebase_cache_meta table and preserves existing data',
      () async {
        final tempDir = Directory.systemTemp.createTempSync('pantry_v23_');
        final v23Path = '${tempDir.path}/pantry.db';

        // Create a v23 database with the core tables.
        final v23Db = await openDatabase(
          v23Path,
          version: 23,
          onCreate: (db, _) async {
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
                unit TEXT DEFAULT 'pieces',
                expiry_date TEXT,
                location TEXT DEFAULT 'pantry',
                notes TEXT,
                date_added INTEGER,
                inventory_id INTEGER NOT NULL DEFAULT 1,
                serving_weight_g REAL,
                FOREIGN KEY(barcode) REFERENCES products(barcode),
                FOREIGN KEY(inventory_id) REFERENCES inventories(id)
              )
            ''');
            // Insert seed data
            await db.insert('inventories', {
              'id': 1,
              'name': 'Home',
              'created_at': DateTime.now().millisecondsSinceEpoch,
            });
            await db.insert('products', {
              'barcode': 'test-barcode-123',
              'name': 'Surviving Product',
              'product_type': 'barcoded',
            });
            await db.insert('inventory', {
              'barcode': 'test-barcode-123',
              'inventory_id': 1,
              'date_added': DateTime.now().millisecondsSinceEpoch,
            });
          },
        );
        await v23Db.close();

        // Reopen and run only the v24 migration. The hand-rolled v23
        // schema above is intentionally minimal, so the full v24→v38
        // chain cannot apply to it — run the migration under test
        // directly instead.
        final migratedDb = await openDatabase(v23Path);
        await MigrationRunner([MigrationV24()]).run(migratedDb, 23, 24);

        // Verify firebase_cache_meta table exists.
        final tableResult = await migratedDb.rawQuery(
          'SELECT name FROM sqlite_master '
          "WHERE type='table' AND name='firebase_cache_meta'",
        );
        expect(tableResult, isNotEmpty);

        // Verify migration is idempotent.
        await MigrationRunner([MigrationV24()]).run(migratedDb, 23, 24);

        // Verify existing data is intact.
        final products = await migratedDb.query(
          'products',
          where: 'barcode = ?',
          whereArgs: ['test-barcode-123'],
        );
        expect(products, isNotEmpty);
        expect(products.first['name'], 'Surviving Product');

        // Verify we can insert into the new table.
        await const FirebaseCacheMetaDao().upsert(
          migratedDb,
          'test-barcode-123',
          'barcoded',
          lastRefreshedAt: 1000,
          nextRefreshAt: 1000 + (180 * 24 * 60 * 60 * 1000),
        );
        final metaEntry = await const FirebaseCacheMetaDao().get(
          migratedDb,
          'test-barcode-123',
        );
        expect(metaEntry, isNotNull);
        expect(metaEntry!['cache_type'], 'barcoded');

        await migratedDb.close();
        tempDir.deleteSync(recursive: true);
      },
    );
  });

  group('getInventoryRowsByProductName', () {
    test('matches case-insensitively', () async {
      await db.insertProduct(
        const Product(
          barcode: 'produce-apple',
          name: 'Apple',
          source: 'manual',
        ),
      );
      await db.insertInventoryItem(
        const InventoryItem(barcode: 'produce-apple'),
      );

      // Search with different case than the stored name.
      final rows = await db.getInventoryRowsByProductName(
        name: 'APPLE',
        inventoryId: 1,
      );
      expect(rows, hasLength(1));
      expect(rows.first['barcode'], 'produce-apple');
    });

    test('matches with whitespace differences', () async {
      await db.insertProduct(
        const Product(
          barcode: 'produce-organic_banana',
          name: 'Organic Banana',
          source: 'manual',
        ),
      );
      await db.insertInventoryItem(
        const InventoryItem(barcode: 'produce-organic_banana'),
      );

      // Search with extra whitespace.
      final rows = await db.getInventoryRowsByProductName(
        name: '  Organic Banana  ',
        inventoryId: 1,
      );
      expect(rows, hasLength(1));
    });

    test('returns empty for non-matching name', () async {
      await db.insertProduct(
        const Product(barcode: '001', name: 'Milk'),
      );
      await db.insertInventoryItem(
        const InventoryItem(barcode: '001'),
      );

      final rows = await db.getInventoryRowsByProductName(
        name: 'Bread',
        inventoryId: 1,
      );
      expect(rows, isEmpty);
    });
  });

  group('getInventoryRowsByBarcode', () {
    Future<void> seedItem({
      required String barcode,
      required double quantity,
      String? expiryDate,
    }) {
      return db.insertInventoryItem(
        InventoryItem(
          barcode: barcode,
          expiryDate: expiryDate,
          quantity: quantity,
        ),
      );
    }

    test('returns rows ordered by expiry ascending', () async {
      await db.insertProduct(
        const Product(barcode: 'fefo', name: 'Fefo'),
      );
      await seedItem(
        barcode: 'fefo',
        expiryDate: '2026-06-10',
        quantity: 1,
      );
      await seedItem(
        barcode: 'fefo',
        expiryDate: '2026-05-01',
        quantity: 2,
      );

      final rows = await db.getInventoryRowsByBarcode(
        barcode: 'fefo',
        inventoryId: 1,
      );
      expect(rows.map((r) => r['expiry_date']), [
        '2026-05-01',
        '2026-06-10',
      ]);
    });

    test('sorts null-expiry rows last (FEFO deduction)', () async {
      await db.insertProduct(
        const Product(barcode: 'fefo2', name: 'Fefo2'),
      );
      await seedItem(
        barcode: 'fefo2',
        expiryDate: '2026-06-10',
        quantity: 1,
      );
      await seedItem(
        barcode: 'fefo2',
        quantity: 3,
      );
      await seedItem(
        barcode: 'fefo2',
        expiryDate: '2026-05-01',
        quantity: 2,
      );

      final rows = await db.getInventoryRowsByBarcode(
        barcode: 'fefo2',
        inventoryId: 1,
      );
      expect(rows.map((r) => r['expiry_date']), [
        '2026-05-01',
        '2026-06-10',
        null,
      ]);
    });

    test('sorts null-expiry rows last for product-name fallback', () async {
      await db.insertProduct(
        const Product(barcode: 'fefo3', name: 'Fefo Three'),
      );
      await seedItem(
        barcode: 'fefo3',
        expiryDate: '2026-06-10',
        quantity: 1,
      );
      await seedItem(
        barcode: 'fefo3',
        quantity: 4,
      );

      final rows = await db.getInventoryRowsByProductName(
        name: 'fefo three',
        inventoryId: 1,
      );
      expect(rows.map((r) => r['expiry_date']), [
        '2026-06-10',
        null,
      ]);
    });
  });

  group('Migration v28 — produce barcode normalization', () {
    test('normalizes produce barcodes in all tables', () async {
      final tempDir = Directory.systemTemp.createTempSync('pantry_v28_');
      final v27Path = '${tempDir.path}/pantry.db';

      // Create a v27 database with core tables + unnormalized produce barcodes.
      final v27Db = await openDatabase(
        v27Path,
        version: 27,
        onCreate: (db, _) async {
          await db.execute('''
            CREATE TABLE products (
              barcode TEXT PRIMARY KEY,
              name TEXT NOT NULL,
              product_type TEXT NOT NULL DEFAULT 'barcoded',
              source TEXT NOT NULL DEFAULT 'api',
              language_code TEXT NOT NULL DEFAULT 'en',
              submission_status TEXT NOT NULL DEFAULT 'not_submitted'
            )
          ''');
          await db.execute('''
            CREATE TABLE inventory (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              barcode TEXT NOT NULL,
              quantity REAL DEFAULT 1,
              unit TEXT DEFAULT 'pieces',
              inventory_id INTEGER NOT NULL DEFAULT 1
            )
          ''');
          await db.execute('''
            CREATE TABLE recipe_ingredients (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              recipe_id INTEGER NOT NULL,
              name TEXT NOT NULL,
              barcode TEXT
            )
          ''');
          await db.execute('''
            CREATE TABLE prices (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              barcode TEXT NOT NULL,
              price REAL NOT NULL,
              currency TEXT NOT NULL,
              date_added INTEGER NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE shopping_list (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              barcode TEXT,
              name TEXT NOT NULL
            )
          ''');
          // Seed data with unnormalized produce barcodes
          await db.insert('products', {
            'barcode': 'produce-Apple',
            'name': 'Apple',
            'product_type': 'produce',
          });
          await db.insert('products', {
            'barcode': 'produce-Organic Banana',
            'name': 'Organic Banana',
            'product_type': 'produce',
          });
          await db.insert('inventory', {
            'barcode': 'produce-Apple',
            'inventory_id': 1,
          });
          await db.insert('recipe_ingredients', {
            'recipe_id': 1,
            'name': 'Apple',
            'barcode': 'produce-Apple',
          });
          await db.insert('prices', {
            'barcode': 'produce-Apple',
            'price': 1.99,
            'currency': 'USD',
            'date_added': 1000,
          });
          await db.insert('shopping_list', {
            'barcode': 'produce-Organic Banana',
            'name': 'Organic Banana',
          });
        },
      );
      await v27Db.close();

      // Reopen and run only the v28 migration. The hand-rolled v27 schema
      // above is intentionally minimal (only the tables v28 touches), so
      // the full v28→v38 chain cannot apply to it — run the migration
      // under test directly instead.
      final migratedDb = await openDatabase(v27Path);
      await MigrationRunner([MigrationV28()]).run(migratedDb, 27, 28);

      // Verify products table normalization.
      final products = await migratedDb.rawQuery(
        'SELECT barcode, name FROM products ORDER BY name',
      );
      expect(products.length, 2);
      expect(products[0]['barcode'], 'produce-apple');
      expect(products[1]['barcode'], 'produce-organic_banana');

      // Verify inventory table normalization.
      final inv = await migratedDb.rawQuery(
        "SELECT barcode FROM inventory WHERE barcode LIKE 'produce-%'",
      );
      expect(inv.length, 1);
      expect(inv.first['barcode'], 'produce-apple');

      // Verify recipe_ingredients normalization.
      final ri = await migratedDb.rawQuery(
        "SELECT barcode FROM recipe_ingredients WHERE barcode LIKE 'produce-%'",
      );
      expect(ri.length, 1);
      expect(ri.first['barcode'], 'produce-apple');

      // Verify prices normalization.
      final prices = await migratedDb.rawQuery(
        "SELECT barcode FROM prices WHERE barcode LIKE 'produce-%'",
      );
      expect(prices.length, 1);
      expect(prices.first['barcode'], 'produce-apple');

      // Verify shopping_list normalization.
      final sl = await migratedDb.rawQuery(
        "SELECT barcode FROM shopping_list WHERE barcode LIKE 'produce-%'",
      );
      expect(sl.length, 1);
      expect(sl.first['barcode'], 'produce-organic_banana');

      // Verify migration is idempotent.
      await MigrationRunner([MigrationV28()]).run(migratedDb, 27, 28);
      final doubleNormalized = await migratedDb.rawQuery(
        "SELECT barcode FROM products WHERE barcode LIKE 'produce-%' "
        "AND barcode != 'produce-' || LOWER(TRIM(SUBSTR(barcode, 9)))",
      );
      expect(doubleNormalized, isEmpty);

      await migratedDb.close();
      tempDir.deleteSync(recursive: true);
    });
  });

  group('getBarcodesInInventory', () {
    setUp(() async {
      // Insert products first (FK constraint).
      await db.insertProduct(
        const Product(barcode: 'barcode1', name: 'Product 1'),
      );
      await db.insertProduct(
        const Product(barcode: 'barcode2', name: 'Product 2'),
      );
      await db.insertProduct(
        const Product(barcode: 'barcode3', name: 'Product 3'),
      );

      // Insert inventory items across two inventories.
      final workId = await db.createInventory('Work');
      await db.insertInventoryItem(
        const InventoryItem(barcode: 'barcode1'),
      );
      await db.insertInventoryItem(
        const InventoryItem(barcode: 'barcode2'),
      );
      await db.insertInventoryItem(
        InventoryItem(barcode: 'barcode3', inventoryId: workId),
      );
    });

    test('returns matching barcodes for the active inventory', () async {
      final result = await db.getBarcodesInInventory(
        {'barcode1', 'barcode2', 'barcode3'},
        inventoryId: 1,
      );

      expect(result, containsAll({'barcode1', 'barcode2'}));
    });

    test('returns empty set when no barcodes match', () async {
      final result = await db.getBarcodesInInventory(
        {'nonexistent'},
        inventoryId: 1,
      );

      expect(result, isEmpty);
    });

    test('excludes barcodes in other inventories', () async {
      final result = await db.getBarcodesInInventory(
        {'barcode1', 'barcode2', 'barcode3'},
        inventoryId: 1,
      );

      expect(result, isNot(contains('barcode3')));
    });

    test('handles empty input set', () async {
      final result = await db.getBarcodesInInventory(
        <String>{},
        inventoryId: 1,
      );

      expect(result, isEmpty);
    });

    test('allows a duplicate barcode in the same inventory', () async {
      // The setUp already inserted barcode1 in inventory 1. Since v36 the
      // inventory (barcode, inventory_id) index is non-unique, so a second
      // insert with the same barcode succeeds (distinct batches are allowed).
      final id = await db.insertInventoryItem(
        const InventoryItem(barcode: 'barcode1'),
      );

      expect(id, greaterThan(0));
      final items = await db.getInventoryItemsByBarcode(
        'barcode1',
        inventoryId: 1,
      );
      expect(items, hasLength(2));
    });
  });

  group('Scan history', () {
    ScanHistoryEntry entry(
      int scannedAt, {
      String barcode = '5012345678900',
      String? imageUrl,
    }) => ScanHistoryEntry(
      barcode: barcode,
      name: 'Product $barcode',
      scannedAt: scannedAt,
      imageUrl: imageUrl,
    );

    test('recordScan inserts an entry', () async {
      final id = await db.recordScan(entry(1000));
      expect(id, isNonNegative);

      final history = await db.getRecentScanHistory();
      expect(history, hasLength(1));
      expect(history.first.barcode, '5012345678900');
      expect(history.first.scannedAt, 1000);
    });

    test('getRecentScanHistory returns newest first', () async {
      await db.recordScan(entry(100));
      await db.recordScan(entry(300));
      await db.recordScan(entry(200));

      final history = await db.getRecentScanHistory();
      expect(history.map((e) => e.scannedAt).toList(), [300, 200, 100]);
    });

    test('getRecentScanHistory respects the limit', () async {
      await db.recordScan(entry(100));
      await db.recordScan(entry(200));
      await db.recordScan(entry(300));

      final history = await db.getRecentScanHistory(limit: 2);
      expect(history, hasLength(2));
      expect(history.map((e) => e.scannedAt).toList(), [300, 200]);
    });

    test('recordScan prunes to the default cap', () async {
      for (var i = 0; i < 55; i++) {
        await db.recordScan(entry(i));
      }

      final history = await db.getRecentScanHistory();
      expect(history, hasLength(50));
      expect(history.first.scannedAt, 54);
    });

    test('recordScan persists imageUrl when provided', () async {
      await db.recordScan(
        entry(1000, imageUrl: 'https://example.com/img.jpg'),
      );
      final history = await db.getRecentScanHistory();
      expect(history.single.imageUrl, 'https://example.com/img.jpg');
    });

    test('clearScanHistory removes all entries', () async {
      await db.recordScan(entry(1000));
      await db.recordScan(entry(2000));

      final cleared = await db.clearScanHistory();
      expect(cleared, 2);
      final history = await db.getRecentScanHistory();
      expect(history, isEmpty);
    });
  });
}
