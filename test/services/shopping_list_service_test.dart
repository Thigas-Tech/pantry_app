import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pantry_app/database/database_helper.dart';
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

    test('leaves pending (unpurchased) items untouched', () async {
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
        const ShoppingItem(name: 'Still to buy', inventoryId: 1),
      );

      final result = await service.finishShoppingTrip(inventoryId: 1);

      expect(result.movedCount, 1);
      final remaining = await db.getShoppingList(inventoryId: 1);
      expect(remaining, hasLength(1));
      expect(remaining.first.name, 'Still to buy');
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
  });
}
