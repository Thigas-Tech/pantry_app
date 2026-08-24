import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/models/inventory_item.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/models/shopping_item.dart';
import 'package:pantry_app/services/product_repository.dart';
import 'package:pantry_app/services/shopping_list_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _MockProductRepository extends Mock implements ProductRepository {}

/// Integration tests for [ShoppingListService] shopping trip operations.
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late DatabaseHelper db;
  late ShoppingListService service;

  setUp(() async {
    db = DatabaseHelper.withPath(inMemoryDatabasePath);
    await db.database;
    service = ShoppingListService(db, _MockProductRepository());
  });

  tearDown(() async {
    final database = await db.database;
    await database.close();
  });

  Future<void> seedPurchasableProduct() async {
    await db.insertProduct(
      const Product(barcode: '123', name: 'Milk'),
    );
  }

  group('finishShoppingTrip', () {
    test(
      'moves purchased barcoded items to inventory and deletes them',
      () async {
        await seedPurchasableProduct();
        await db.insertShoppingItem(
          const ShoppingItem(
            name: 'Milk',
            barcode: '123',
            isPurchased: true,
            inventoryId: 1,
          ),
        );

        final result = await service.finishShoppingTrip(inventoryId: 1);

        expect(result.movedCount, 1);
        expect(result.cleanedCount, 0);
        expect(await db.getShoppingList(inventoryId: 1), isEmpty);
        final inv = await db.getInventoryWithProduct(inventoryId: 1);
        expect(inv, hasLength(1));
      },
    );

    test('removes purchased items without a barcode', () async {
      await db.insertShoppingItem(
        const ShoppingItem(
          name: 'Free text',
          isPurchased: true,
          inventoryId: 1,
        ),
      );

      final result = await service.finishShoppingTrip(inventoryId: 1);

      expect(result.movedCount, 0);
      expect(result.cleanedCount, 1);
      expect(await db.getShoppingList(inventoryId: 1), isEmpty);
    });

    test('moves pending items too when finishing a trip', () async {
      await seedPurchasableProduct();
      await db.insertShoppingItem(
        const ShoppingItem(
          name: 'Milk',
          barcode: '123',
          isPurchased: true,
          inventoryId: 1,
        ),
      );
      await db.insertShoppingItem(
        const ShoppingItem(
          name: 'Still to buy',
          barcode: '123',
          inventoryId: 1,
        ),
      );

      final result = await service.finishShoppingTrip(inventoryId: 1);

      // Both the purchased and the pending item move to inventory.
      expect(result.movedCount, 2);
      expect(result.cleanedCount, 0);
      expect(await db.getShoppingList(inventoryId: 1), isEmpty);
      final inv = await db.getInventoryWithProduct(inventoryId: 1);
      expect(inv, hasLength(1));
      expect(inv.first['quantity'], 2);
    });

    test('cleans pending items without a barcode', () async {
      await db.insertShoppingItem(
        const ShoppingItem(name: 'Free text', inventoryId: 1),
      );

      final result = await service.finishShoppingTrip(inventoryId: 1);

      expect(result.movedCount, 0);
      expect(result.cleanedCount, 1);
      expect(await db.getShoppingList(inventoryId: 1), isEmpty);
    });

    test('rolls back everything when the trip finish fails', () async {
      await seedPurchasableProduct();
      await db.insertShoppingItem(
        const ShoppingItem(
          name: 'Milk',
          barcode: '123',
          isPurchased: true,
          inventoryId: 1,
        ),
      );
      await db.insertShoppingItem(
        const ShoppingItem(
          name: 'Free text',
          isPurchased: true,
          inventoryId: 1,
        ),
      );

      final database = await db.database;
      await database.execute('''
        CREATE TRIGGER test_abort_inventory_insert
        BEFORE INSERT ON inventory
        BEGIN
          SELECT RAISE(ABORT, 'injected trip failure');
        END
      ''');

      await expectLater(
        service.finishShoppingTrip(inventoryId: 1),
        throwsA(isA<Exception>()),
      );

      // Nothing moved, nothing cleaned: the list is unchanged.
      final items = await db.getShoppingList(inventoryId: 1);
      expect(items, hasLength(2));
      expect(await db.getInventoryWithProduct(inventoryId: 1), isEmpty);

      await database.execute('DROP TRIGGER test_abort_inventory_insert');
    });

    test(
      'finish carries the item expiry into the created inventory item',
      () async {
        await seedPurchasableProduct();
        await db.insertShoppingItem(
          const ShoppingItem(
            name: 'Milk',
            barcode: '123',
            isPurchased: true,
            inventoryId: 1,
            expiryDate: '2026-12-31',
          ),
        );

        final result = await service.finishShoppingTrip(inventoryId: 1);

        expect(result.movedCount, 1);
        final inv = await db.getInventoryWithProduct(inventoryId: 1);
        expect(inv, hasLength(1));
        expect(inv.first['expiry_date'], '2026-12-31');
      },
    );

    test(
      'finish with a dated item does not merge with an undated pantry row',
      () async {
        await seedPurchasableProduct();
        // An existing undated pantry row for the same product.
        await db.insertInventoryItem(const InventoryItem(barcode: '123'));
        await db.insertShoppingItem(
          const ShoppingItem(
            name: 'Milk',
            barcode: '123',
            isPurchased: true,
            inventoryId: 1,
            expiryDate: '2026-12-31',
          ),
        );

        final result = await service.finishShoppingTrip(inventoryId: 1);

        expect(result.movedCount, 1);
        final inv = await db.getInventoryWithProduct(inventoryId: 1);
        // The undated row stays separate from the dated batch.
        expect(inv, hasLength(2));
        expect(
          inv.where((r) => r['expiry_date'] == '2026-12-31'),
          hasLength(1),
        );
      },
    );

    test(
      'finish merges quantity when the pantry row has the same expiry',
      () async {
        await seedPurchasableProduct();
        await db.insertInventoryItem(
          const InventoryItem(barcode: '123', expiryDate: '2026-12-31'),
        );
        await db.insertShoppingItem(
          const ShoppingItem(
            name: 'Milk',
            barcode: '123',
            isPurchased: true,
            inventoryId: 1,
            expiryDate: '2026-12-31',
          ),
        );

        final result = await service.finishShoppingTrip(inventoryId: 1);

        expect(result.movedCount, 1);
        final inv = await db.getInventoryWithProduct(inventoryId: 1);
        expect(inv, hasLength(1));
        expect(inv.first['expiry_date'], '2026-12-31');
        expect(inv.first['quantity'], 2);
      },
    );

    test('finish merges an undated item into an undated pantry row', () async {
      await seedPurchasableProduct();
      await db.insertInventoryItem(
        const InventoryItem(barcode: '123'),
      );
      await db.insertShoppingItem(
        const ShoppingItem(
          name: 'Milk',
          barcode: '123',
          isPurchased: true,
          inventoryId: 1,
        ),
      );

      final result = await service.finishShoppingTrip(inventoryId: 1);

      expect(result.movedCount, 1);
      final inv = await db.getInventoryWithProduct(inventoryId: 1);
      expect(inv, hasLength(1));
      expect(inv.first['expiry_date'], isNull);
      expect(inv.first['quantity'], 2);
    });
  });

  group('addShoppingItem', () {
    test('returns the id of the inserted row', () async {
      await seedPurchasableProduct();

      final id = await service.addShoppingItem(
        const ShoppingItem(name: 'Milk', barcode: '123', inventoryId: 1),
        activeInventoryId: 1,
      );

      expect(id, isPositive);
      final items = await db.getShoppingList(inventoryId: 1);
      expect(items.single.id, id);
    });
  });

  group('finish writes price history', () {
    test('records the trip item price into the prices table', () async {
      await seedPurchasableProduct();
      await db.insertShoppingItem(
        const ShoppingItem(
          name: 'Milk',
          barcode: '123',
          isPurchased: true,
          inventoryId: 1,
          priceAmount: 4.99,
          priceCurrency: 'USD',
          priceStore: 'Corner Store',
        ),
      );

      final result = await service.finishShoppingTrip(inventoryId: 1);

      expect(result.movedCount, 1);
      final database = await db.database;
      final rows = await database.query(
        'prices',
        where: 'barcode = ?',
        whereArgs: ['123'],
      );
      expect(rows, hasLength(1));
      expect(rows.first['price'], 4.99);
      expect(rows.first['currency'], 'USD');
      expect(rows.first['store'], 'Corner Store');
      expect(rows.first['date_purchased'], isNotNull);
    });

    test('does not write a price row when the item has no price', () async {
      await seedPurchasableProduct();
      await db.insertShoppingItem(
        const ShoppingItem(
          name: 'Milk',
          barcode: '123',
          isPurchased: true,
          inventoryId: 1,
        ),
      );

      await service.finishShoppingTrip(inventoryId: 1);

      final database = await db.database;
      final rows = await database.query(
        'prices',
        where: 'barcode = ?',
        whereArgs: ['123'],
      );
      expect(rows, isEmpty);
    });

    test('writes the price row into the trip inventory', () async {
      await seedPurchasableProduct();
      await db.createInventory('Work');
      await db.insertShoppingItem(
        const ShoppingItem(
          name: 'Milk',
          barcode: '123',
          isPurchased: true,
          inventoryId: 2,
          priceAmount: 4.99,
          priceCurrency: 'USD',
        ),
      );

      final result = await service.finishShoppingTrip(inventoryId: 2);

      expect(result.movedCount, 1);
      final database = await db.database;
      final rows = await database.query(
        'prices',
        where: 'barcode = ?',
        whereArgs: ['123'],
      );
      expect(rows, hasLength(1));
      expect(rows.first['inventory_id'], 2);
    });

    test('carries package fields into the price row', () async {
      await seedPurchasableProduct();
      await db.insertShoppingItem(
        const ShoppingItem(
          name: 'Eggs',
          barcode: '123',
          isPurchased: true,
          inventoryId: 1,
          priceAmount: 3.50,
          priceCurrency: 'USD',
          pricePackageQuantity: 12,
          pricePackageUnit: 'pieces',
        ),
      );

      await service.finishShoppingTrip(inventoryId: 1);

      final database = await db.database;
      final rows = await database.query(
        'prices',
        where: 'barcode = ?',
        whereArgs: ['123'],
      );
      expect(rows, hasLength(1));
      expect(rows.first['package_quantity'], 12);
      expect(rows.first['package_unit'], 'pieces');
    });
  });

  group('finish pre-caches flushed products', () {
    test('fetches a missing product so the price row is not lost', () async {
      registerFallbackValue(const Product(barcode: '', name: ''));
      final repo = _MockProductRepository();
      service = ShoppingListService(db, repo);
      when(() => repo.getProduct('123')).thenAnswer(
        (_) async => const Product(barcode: '123', name: 'Milk'),
      );
      when(() => repo.cacheProduct(any())).thenAnswer((invocation) async {
        await db.insertProduct(
          invocation.positionalArguments.first as Product,
        );
      });

      await seedPurchasableProduct();
      await db.insertShoppingItem(
        const ShoppingItem(
          name: 'Milk',
          barcode: '123',
          isPurchased: true,
          inventoryId: 1,
          priceAmount: 4.99,
          priceCurrency: 'USD',
        ),
      );
      // Simulate the product leaving the two-month cache flush.
      final database = await db.database;
      await database.execute('PRAGMA foreign_keys = OFF');
      await database.delete(
        'products',
        where: 'barcode = ?',
        whereArgs: ['123'],
      );
      await database.execute('PRAGMA foreign_keys = ON');

      final result = await service.finishShoppingTrip(inventoryId: 1);

      expect(result.movedCount, 1);
      expect(await db.getProduct('123'), isNotNull);
      final rows = await database.query(
        'prices',
        where: 'barcode = ?',
        whereArgs: ['123'],
      );
      expect(rows, hasLength(1));
    });
  });
}
