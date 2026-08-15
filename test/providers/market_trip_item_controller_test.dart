import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/models/product_type.dart';
import 'package:pantry_app/models/shopping_item.dart';
import 'package:pantry_app/providers/database_provider.dart';
import 'package:pantry_app/providers/market_trip_item_provider.dart';
import 'package:pantry_app/providers/shopping_list_provider.dart';
import 'package:pantry_app/providers/shopping_list_service_provider.dart';
import 'package:pantry_app/services/shopping_list_service.dart';

class _MockDatabaseHelper extends Mock implements DatabaseHelper {}

class _MockShoppingListService extends Mock implements ShoppingListService {}

void main() {
  setUpAll(() {
    registerFallbackValue(const ShoppingItem(name: ''));
  });

  late _MockDatabaseHelper db;
  late _MockShoppingListService service;
  late ProviderContainer container;

  setUp(() {
    db = _MockDatabaseHelper();
    service = _MockShoppingListService();
    when(
      () => db.markShoppingItemsByBarcode(
        any(),
        inventoryId: any(named: 'inventoryId'),
      ),
    ).thenAnswer((_) async => 0);
    when(
      () => db.getShoppingList(inventoryId: any(named: 'inventoryId')),
    ).thenAnswer((_) async => const <ShoppingItem>[]);
    when(
      () => service.addShoppingItem(
        any(),
        activeInventoryId: any(named: 'activeInventoryId'),
      ),
    ).thenAnswer((_) async => 7);
    when(() => service.updateShoppingItem(any())).thenAnswer((_) async {});
    when(
      () => service.updateShoppingItemPrice(
        any(),
        priceAmount: any(named: 'priceAmount'),
        priceCurrency: any(named: 'priceCurrency'),
        priceStore: any(named: 'priceStore'),
      ),
    ).thenAnswer((_) async {});
    when(() => service.updateShoppingItemExpiry(any(), any())).thenAnswer(
      (_) async {},
    );

    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        shoppingListServiceProvider.overrideWithValue(service),
      ],
    );
    addTearDown(container.dispose);
  });

  MarketTripItemController controller() =>
      container.read(marketTripItemControllerProvider(1).notifier);

  const product = Product(barcode: '1', name: 'Milk');

  test('marks an existing pending row and returns its id', () async {
    when(() => db.markShoppingItemsByBarcode('1', inventoryId: 1)).thenAnswer(
      (_) async => 1,
    );
    when(
      () => db.getShoppingList(inventoryId: 1),
    ).thenAnswer(
      (_) async => const [
        ShoppingItem(
          name: 'Milk',
          barcode: '1',
          isPurchased: true,
          id: 5,
          inventoryId: 1,
        ),
      ],
    );

    final id = await controller().addScannedProduct(product);

    expect(id, 5);
    verify(() => db.markShoppingItemsByBarcode('1', inventoryId: 1)).called(1);
    verifyNever(
      () => service.addShoppingItem(
        any(),
        activeInventoryId: any(named: 'activeInventoryId'),
      ),
    );
    verifyNever(() => service.updateShoppingItem(any()));
  });

  test('inserts a new purchased item when nothing exists', () async {
    ShoppingItem? captured;
    when(
      () => service.addShoppingItem(
        any(),
        activeInventoryId: any(named: 'activeInventoryId'),
      ),
    ).thenAnswer((inv) async {
      captured = inv.positionalArguments[0] as ShoppingItem;
      return 7;
    });

    final id = await controller().addScannedProduct(product);

    expect(id, 7);
    expect(captured?.barcode, '1');
    expect(captured?.isPurchased, isTrue);
    expect(captured?.inventoryId, 1);
    expect(captured?.name, 'Milk');
  });

  test('uses the barcode as the name for an unknown product', () async {
    ShoppingItem? captured;
    when(
      () => service.addShoppingItem(
        any(),
        activeInventoryId: any(named: 'activeInventoryId'),
      ),
    ).thenAnswer((inv) async {
      captured = inv.positionalArguments[0] as ShoppingItem;
      return 8;
    });

    await controller().addScannedProduct(
      const Product(barcode: '2', name: 'Unknown'),
    );

    expect(captured?.name, '2');
  });

  test('produces a grams unit for produce products', () async {
    ShoppingItem? captured;
    when(
      () => service.addShoppingItem(
        any(),
        activeInventoryId: any(named: 'activeInventoryId'),
      ),
    ).thenAnswer((inv) async {
      captured = inv.positionalArguments[0] as ShoppingItem;
      return 9;
    });

    await controller().addScannedProduct(
      const Product(
        barcode: 'plu-1',
        name: 'Tomato',
        productType: ProductType.produce,
      ),
    );

    expect(captured?.unit, 'g');
  });

  test(
    'merges quantity into an existing purchased row instead of inserting',
    () async {
      when(
        () => db.getShoppingList(inventoryId: 1),
      ).thenAnswer(
        (_) async => const [
          ShoppingItem(
            name: 'Milk',
            barcode: '1',
            isPurchased: true,
            id: 5,
            inventoryId: 1,
          ),
        ],
      );

      final id = await controller().addScannedProduct(product);

      expect(id, 5);
      final captured = verify(
        () => service.updateShoppingItem(captureAny()),
      ).captured;
      expect((captured.first as ShoppingItem).quantity, 2);
      verifyNever(
        () => service.addShoppingItem(
          any(),
          activeInventoryId: any(named: 'activeInventoryId'),
        ),
      );
    },
  );

  test('writes an explicit price to the item', () async {
    when(() => db.markShoppingItemsByBarcode('1', inventoryId: 1)).thenAnswer(
      (_) async => 1,
    );
    when(
      () => db.getShoppingList(inventoryId: 1),
    ).thenAnswer(
      (_) async => const [
        ShoppingItem(
          name: 'Milk',
          barcode: '1',
          isPurchased: true,
          id: 5,
          inventoryId: 1,
        ),
      ],
    );

    await controller().addScannedProduct(
      product,
      price: const TripItemPriceInput(
        amount: 4.99,
        currency: 'USD',
        store: 'Corner Store',
      ),
    );

    verify(
      () => service.updateShoppingItemPrice(
        5,
        priceAmount: 4.99,
        priceCurrency: 'USD',
        priceStore: 'Corner Store',
      ),
    ).called(1);
  });

  test('writes an expiry date to the item', () async {
    when(() => db.markShoppingItemsByBarcode('1', inventoryId: 1)).thenAnswer(
      (_) async => 1,
    );
    when(
      () => db.getShoppingList(inventoryId: 1),
    ).thenAnswer(
      (_) async => const [
        ShoppingItem(
          name: 'Milk',
          barcode: '1',
          isPurchased: true,
          id: 5,
          inventoryId: 1,
        ),
      ],
    );

    await controller().addScannedProduct(product, expiryDate: '2030-01-01');

    verify(() => service.updateShoppingItemExpiry(5, '2030-01-01')).called(1);
  });

  test('rejects an expiry date before today', () async {
    when(() => db.markShoppingItemsByBarcode('1', inventoryId: 1)).thenAnswer(
      (_) async => 1,
    );
    when(
      () => db.getShoppingList(inventoryId: 1),
    ).thenAnswer(
      (_) async => const [
        ShoppingItem(
          name: 'Milk',
          barcode: '1',
          isPurchased: true,
          id: 5,
          inventoryId: 1,
        ),
      ],
    );

    await expectLater(
      controller().addScannedProduct(product, expiryDate: '2000-01-01'),
      throwsA(isA<ArgumentError>()),
    );
    verifyNever(() => service.updateShoppingItemExpiry(any(), any()));
  });

  test(
    'ignores a second add for the same barcode while one is in flight',
    () async {
      final gate = Completer<int>();
      final reachedGate = Completer<void>();
      when(
        () => service.addShoppingItem(
          any(),
          activeInventoryId: any(named: 'activeInventoryId'),
        ),
      ).thenAnswer((_) {
        reachedGate.complete();
        return gate.future;
      });

      final first = controller().addScannedProduct(product);
      // Wait until the first call is suspended on the (uncompleted) add.
      await reachedGate.future;

      final second = await controller().addScannedProduct(product);
      expect(second, isNull);

      gate.complete(7);
      expect(await first, 7);
      verify(
        () => service.addShoppingItem(
          any(),
          activeInventoryId: any(named: 'activeInventoryId'),
        ),
      ).called(1);
    },
  );

  test('propagates a service error and records it on state', () async {
    when(() => db.markShoppingItemsByBarcode('1', inventoryId: 1)).thenThrow(
      Exception('boom'),
    );

    await expectLater(
      controller().addScannedProduct(product),
      throwsException,
    );
    expect(controller().state.lastError, contains('boom'));
  });

  test('invalidates the trip shopping list providers after an add', () async {
    var rebuilds = 0;
    container.listen(
      shoppingListByInventoryProvider(1),
      (_, _) => rebuilds++,
      fireImmediately: true,
    );
    expect(rebuilds, 1);

    await controller().addScannedProduct(product);
    await container.read(shoppingListByInventoryProvider(1).future);

    expect(rebuilds, greaterThan(1));
  });

  test('returns null without touching state when disposed mid-add', () async {
    final gate = Completer<int>();
    final reachedGate = Completer<void>();
    when(
      () => db.markShoppingItemsByBarcode('1', inventoryId: 1),
    ).thenAnswer((_) {
      reachedGate.complete();
      return gate.future;
    });

    final future = controller().addScannedProduct(product);
    await reachedGate.future;

    // The owning screen popped while the add was in flight, disposing the
    // autoDispose notifier. The add must complete cleanly instead of throwing
    // "Ref after it has been disposed".
    container.dispose();
    gate.complete(0);

    expect(await future, isNull);
  });

  test('returns null when disposed after the insert was reached', () async {
    final gate = Completer<int>();
    final reachedGate = Completer<void>();
    when(
      () => service.addShoppingItem(
        any(),
        activeInventoryId: any(named: 'activeInventoryId'),
      ),
    ).thenAnswer((_) {
      reachedGate.complete();
      return gate.future;
    });

    final future = controller().addScannedProduct(product);
    await reachedGate.future;

    container.dispose();
    gate.complete(1);

    expect(await future, isNull);
  });
}
