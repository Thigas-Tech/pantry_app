import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/database/database_helper.dart';
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

/// Tests for [DatabaseHelper] using an in-memory SQLite database.
///
/// Each test runs against a fresh database created with
/// [DatabaseHelper.withPath], which applies the baseline migration.
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
        final freshSync = DateTime.now().millisecondsSinceEpoch;
        await db.insertProduct(
          const Product(
            barcode: 'p1',
            name: 'P1',
          ).copyWith(lastSynced: freshSync),
        );
        await db.insertProduct(
          const Product(
            barcode: 'p2',
            name: 'P2',
          ).copyWith(lastSynced: freshSync),
        );
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

    test('preserves price history for products not in the pantry', () async {
      await db.insertProduct(const Product(barcode: 'p1', name: 'P1'));
      await db.insertPrice(const Price(barcode: 'p1', price: 9.99));

      await db.cleanupOldEntries();

      expect(await db.getPriceCountByBarcode('p1'), 1);
    });

    test('preserves manual products even when not in the pantry', () async {
      await db.insertProduct(
        const Product(barcode: 'manual1', name: 'Manual', source: 'manual'),
      );

      await db.cleanupOldEntries();

      expect(await db.getProduct('manual1'), isNotNull);
    });

    test('preserves cached products referenced by prices', () async {
      final freshSync = DateTime.now().millisecondsSinceEpoch;
      await db.insertProduct(
        const Product(barcode: 'p1', name: 'P1').copyWith(
          lastSynced: freshSync,
        ),
      );
      await db.insertPrice(const Price(barcode: 'p1', price: 9.99));

      await db.cleanupOldEntries();

      expect(await db.getProduct('p1'), isNotNull);
    });

    test('prunes prices older than the configured retention', () async {
      await db.insertProduct(const Product(barcode: 'p1', name: 'P1'));
      await db.insertPrice(
        Price(
          barcode: 'p1',
          price: 9.99,
          datePurchased: DateTime.now()
              .subtract(const Duration(days: 100))
              .millisecondsSinceEpoch,
        ),
      );

      await db.cleanupOldEntries(priceRetentionDays: 60);

      expect(await db.getPriceCountByBarcode('p1'), 0);
    });

    test('keeps recent prices when retention is configured', () async {
      await db.insertProduct(const Product(barcode: 'p1', name: 'P1'));
      await db.insertPrice(
        Price(
          barcode: 'p1',
          price: 9.99,
          datePurchased: DateTime.now()
              .subtract(const Duration(days: 10))
              .millisecondsSinceEpoch,
        ),
      );

      await db.cleanupOldEntries(priceRetentionDays: 60);

      expect(await db.getPriceCountByBarcode('p1'), 1);
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

  group('database getter dedup', () {
    test('returns the same future for concurrent first accesses', () async {
      final helper = DatabaseHelper.withPath(inMemoryDatabasePath);
      addTearDown(() async {
        final db = await helper.database;
        await db.close();
      });

      final first = helper.database;
      final second = helper.database;
      final third = helper.database;

      expect(identical(first, second), isTrue);
      expect(identical(first, third), isTrue);

      final db = await first;
      expect(await second, same(db));
      expect(await third, same(db));
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

  group('database getter dedup', () {
    test('returns the same future for concurrent first accesses', () async {
      final helper = DatabaseHelper.withPath(inMemoryDatabasePath);
      addTearDown(() async {
        final db = await helper.database;
        await db.close();
      });

      final first = helper.database;
      final second = helper.database;
      final third = helper.database;

      expect(identical(first, second), isTrue);
      expect(identical(first, third), isTrue);

      final db = await first;
      expect(await second, same(db));
      expect(await third, same(db));
    });
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

    test('treats % and _ in the search term as literals', () async {
      await db.insertProduct(
        const Product(barcode: 'pct', name: 'Butter 100%'),
      );
      await db.insertInventoryItem(
        const InventoryItem(barcode: 'pct'),
      );
      // False positives: without escaping, "100%" matches "1000" and
      // "a_b" matches "acb".
      await db.insertProduct(
        const Product(barcode: 'pct0', name: 'Butter 1000g'),
      );
      await db.insertInventoryItem(
        const InventoryItem(barcode: 'pct0'),
      );
      await db.insertProduct(
        const Product(barcode: 'snake', name: 'Snake a_b'),
      );
      await db.insertInventoryItem(
        const InventoryItem(barcode: 'snake'),
      );
      await db.insertProduct(
        const Product(barcode: 'snake2', name: 'Snake acb'),
      );
      await db.insertInventoryItem(
        const InventoryItem(barcode: 'snake2'),
      );

      // A literal % must not act as a wildcard.
      var rows = await db.getInventoryRowsByProductName(
        name: 'Butter 100%',
        inventoryId: 1,
      );
      expect(rows.map((r) => r['barcode']).toList(), ['pct']);

      // A literal _ must not act as a single-char wildcard.
      rows = await db.getInventoryRowsByProductName(
        name: 'Snake a_b',
        inventoryId: 1,
      );
      expect(rows.map((r) => r['barcode']).toList(), ['snake']);
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
