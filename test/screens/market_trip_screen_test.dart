import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/models/inventory_summary.dart';
import 'package:pantry_app/models/inventory_with_product.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/models/shopping_item.dart';
import 'package:pantry_app/providers/active_inventory_provider.dart';
import 'package:pantry_app/providers/connectivity_provider.dart';
import 'package:pantry_app/providers/database_provider.dart';
import 'package:pantry_app/providers/inventory_provider.dart';
import 'package:pantry_app/providers/pantry_provider.dart';
import 'package:pantry_app/providers/product_repository_provider.dart';
import 'package:pantry_app/providers/scanner_providers.dart';
import 'package:pantry_app/providers/shopping_list_provider.dart';
import 'package:pantry_app/providers/shopping_list_service_provider.dart';
import 'package:pantry_app/screens/add_product_screen.dart';
import 'package:pantry_app/screens/market_trip_item_screen.dart';
import 'package:pantry_app/screens/market_trip_screen.dart';
import 'package:pantry_app/screens/product_detail_screen.dart';
import 'package:pantry_app/services/shopping_list_service.dart';
import 'package:pantry_app/widgets/scanner_camera_view.dart';

import '../helpers/pump_app.dart';

class _MockDatabaseHelper extends Mock implements DatabaseHelper {}

class _MockShoppingListService extends Mock implements ShoppingListService {}

class _FakeActiveInventoryNotifier extends ActiveInventoryNotifier {
  @override
  Future<int> build() async => 1;
}

/// A shared counter of [Pantry.build] invocations.
class _BuildCounter {
  int value = 0;
}

/// A [Pantry] fake that records how many times it rebuilt.
class _FakePantry extends Pantry {
  _FakePantry(this.counter);

  final _BuildCounter counter;

  @override
  Future<List<InventoryWithProduct>> build() async {
    counter.value++;
    return const <InventoryWithProduct>[];
  }
}

/// A controllable [ScannerCamera] that never touches the camera hardware.
class _FakeScannerCamera extends ScannerCamera {
  @override
  ScannerCameraState build() => const ScannerCameraState();

  void resolve(Product product) {
    state = state.copyWith(scanResolution: ScanResolved(product));
  }

  void failNotFound(String barcode) {
    state = state.copyWith(
      scanResolution: ScanFailed('PRODUCT_NOT_FOUND', barcode: barcode),
    );
  }

  void clear() {
    state = state.copyWith(clearScanResolution: true);
  }
}

void main() {
  setUpAll(() {
    registerFallbackValue(const ShoppingItem(name: ''));
    registerFallbackValue(const Product(barcode: '', name: ''));
  });

  final inventory1 = InventorySummary.fromMap({
    'id': 1,
    'name': 'Home',
    'created_at': 0,
    'item_count': 0,
  });

  Future<
    ({
      _MockDatabaseHelper db,
      _MockShoppingListService service,
      _FakeScannerCamera scanner,
      MockProductRepository productRepo,
    })
  >
  pumpTrip(
    WidgetTester tester, {
    List<InventorySummary> inventories = const [],
    List<ShoppingItem> items = const [],
    _MockShoppingListService? service,
    _BuildCounter? pantryCounter,
  }) async {
    final effectiveService = service ?? _MockShoppingListService();
    final productRepo = createMockProductRepository();
    final db = _MockDatabaseHelper();
    when(db.getInventories).thenAnswer((_) async => []);
    when(
      () => db.getShoppingList(inventoryId: any(named: 'inventoryId')),
    ).thenAnswer((_) async => items);
    final scanner = _FakeScannerCamera();
    await pumpApp(
      tester,
      const MarketTripScreen(),
      settle: false,
      overrides: [
        inventoryListProvider.overrideWith((ref) => inventories),
        activeInventoryProvider.overrideWith(
          _FakeActiveInventoryNotifier.new,
        ),
        databaseProvider.overrideWithValue(db),
        shoppingListServiceProvider.overrideWithValue(effectiveService),
        shoppingListByInventoryProvider(1).overrideWith((ref) => items),
        shoppingListProvider.overrideWith((ref) => items),
        scannerCameraProvider.overrideWith(() => scanner),
        productRepositoryProvider.overrideWithValue(productRepo),
        if (pantryCounter != null)
          pantryProvider.overrideWith(() => _FakePantry(pantryCounter)),
        hasConnectionProvider.overrideWith((ref) => Future.value(true)),
      ],
    );
    await tester.pump();
    await tester.pump();
    return (
      db: db,
      service: effectiveService,
      scanner: scanner,
      productRepo: productRepo,
    );
  }

  /// Resolves a scan and settles onto the confirmation screen.
  Future<void> openConfirmation(
    WidgetTester tester,
    _FakeScannerCamera scanner, {
    String barcode = '1',
    String name = 'Milk',
    Product? product,
  }) async {
    scanner.resolve(
      product ?? Product(barcode: barcode, name: name),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  /// Stubs the common add path: nothing pending, new item inserted.
  void stubInsertPath(
    _MockDatabaseHelper db,
    _MockShoppingListService service,
  ) {
    when(
      () => db.markShoppingItemsByBarcode(
        any(),
        inventoryId: any(named: 'inventoryId'),
      ),
    ).thenAnswer((_) async => 0);
    when(
      () => service.addShoppingItem(
        any(),
        activeInventoryId: any(named: 'activeInventoryId'),
      ),
    ).thenAnswer((_) async => 1);
  }

  testWidgets('single inventory starts the trip without a prompt', (
    tester,
  ) async {
    await pumpTrip(tester, inventories: [inventory1]);

    expect(find.text('Market trip'), findsOneWidget);
    expect(find.text('Finish trip'), findsOneWidget);
    expect(find.byType(ScannerCameraView), findsOneWidget);
    // Embedded camera must not render its own AppBar inside the trip.
    expect(find.text('Scan Barcode'), findsNothing);
  });

  testWidgets('multiple inventories show a selection prompt', (tester) async {
    final inventory2 = InventorySummary.fromMap({
      'id': 2,
      'name': 'Garage',
      'created_at': 0,
      'item_count': 0,
    });
    await pumpTrip(
      tester,
      inventories: [inventory1, inventory2],
    );

    expect(find.text('Which pantry is this trip for?'), findsOneWidget);
    await tester.tap(find.text('Home'));
    await tester.pump();
    await tester.pump();
    expect(find.text('Market trip'), findsOneWidget);
  });

  testWidgets('shows the trip list items', (tester) async {
    await pumpTrip(
      tester,
      inventories: [inventory1],
      items: const [ShoppingItem(name: 'Milk', barcode: '1', inventoryId: 1)],
    );

    expect(find.text('Milk'), findsOneWidget);
  });

  testWidgets('trip list shows no purchase controls', (tester) async {
    await pumpTrip(
      tester,
      inventories: [inventory1],
      items: const [
        ShoppingItem(
          name: 'Milk',
          barcode: '1',
          isPurchased: true,
          inventoryId: 1,
        ),
      ],
    );

    expect(find.text('Milk'), findsOneWidget);
    expect(find.byType(Checkbox), findsNothing);
    expect(find.text('Add again'), findsNothing);
  });

  testWidgets('finish without produce confirms and calls finishShoppingTrip', (
    tester,
  ) async {
    final setup = await pumpTrip(
      tester,
      inventories: [inventory1],
      items: const [
        ShoppingItem(
          name: 'Milk',
          barcode: '1',
          isPurchased: true,
          inventoryId: 1,
        ),
      ],
    );
    when(
      () => setup.service.finishShoppingTrip(inventoryId: 1),
    ).thenAnswer(
      (_) async =>
          const FinishShoppingTripResult(movedCount: 1, cleanedCount: 0),
    );

    await tester.tap(find.text('Finish trip'));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('No, finish trip'), findsOneWidget);

    await tester.ensureVisible(find.text('No, finish trip'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('No, finish trip'));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.textContaining('Finish this trip?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Finish trip'));
    await tester.pump(const Duration(milliseconds: 400));

    verify(() => setup.service.finishShoppingTrip(inventoryId: 1)).called(1);
  });

  testWidgets(
    'finishing a trip defers and preserves the pantry refresh',
    (tester) async {
      final counter = _BuildCounter();
      final setup = await pumpTrip(
        tester,
        inventories: [inventory1],
        pantryCounter: counter,
      );
      when(
        () => setup.service.finishShoppingTrip(inventoryId: 1),
      ).thenAnswer(
        (_) async =>
            const FinishShoppingTripResult(movedCount: 1, cleanedCount: 0),
      );

      // Watch the pantry so the test can observe invalidations.
      ProviderScope.containerOf(
        tester.element(find.byType(MarketTripScreen)),
      ).listen(
        pantryProvider,
        (_, _) {},
        fireImmediately: true,
      );
      expect(counter.value, 1);

      await tester.tap(find.text('Finish trip'));
      await tester.pump(const Duration(milliseconds: 400));

      await tester.ensureVisible(find.text('No, finish trip'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.text('No, finish trip'));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.textContaining('Finish this trip?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Finish trip'));
      await tester.pump();

      // The refresh is deferred: the pantry must not rebuild in the frame
      // that processed the pop.
      expect(counter.value, 1);

      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();
      // The deferred invalidation still refreshed the pantry afterwards.
      expect(counter.value, greaterThanOrEqualTo(2));
    },
  );

  testWidgets('scan of a known product opens the trip confirmation screen', (
    tester,
  ) async {
    final setup = await pumpTrip(tester, inventories: [inventory1]);

    await openConfirmation(tester, setup.scanner);

    expect(find.byType(MarketTripItemScreen), findsOneWidget);
    expect(find.byType(ProductDetailScreen), findsNothing);
    expect(find.text('Milk'), findsOneWidget);
  });

  testWidgets('confirming the confirmation adds the product as purchased', (
    tester,
  ) async {
    final setup = await pumpTrip(tester, inventories: [inventory1]);
    stubInsertPath(setup.db, setup.service);
    final captured = <ShoppingItem>[];
    when(
      () => setup.service.addShoppingItem(
        any(),
        activeInventoryId: any(named: 'activeInventoryId'),
      ),
    ).thenAnswer((inv) async {
      captured.add(inv.positionalArguments[0] as ShoppingItem);
      return 1;
    });

    await openConfirmation(tester, setup.scanner);
    await tester.tap(find.text('Add to trip'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    expect(captured, hasLength(1));
    expect(captured.first.barcode, '1');
    expect(captured.first.isPurchased, isTrue);
    expect(captured.first.inventoryId, 1);
    // The confirmation screen closed and the scan resolution cleared.
    expect(find.byType(MarketTripItemScreen), findsNothing);
    expect(setup.scanner.state.scanResolution, isNull);
  });

  testWidgets('confirming never opens the pantry prompt', (tester) async {
    final setup = await pumpTrip(
      tester,
      inventories: [inventory1],
    );
    stubInsertPath(setup.db, setup.service);

    await openConfirmation(tester, setup.scanner);
    await tester.tap(find.text('Add to trip'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Add to your pantry'), findsNothing);
  });

  testWidgets('setting an expiry date in the confirmation saves it once', (
    tester,
  ) async {
    final setup = await pumpTrip(tester, inventories: [inventory1]);
    stubInsertPath(setup.db, setup.service);
    when(() => setup.service.updateShoppingItemExpiry(any(), any())).thenAnswer(
      (_) async {},
    );

    await openConfirmation(tester, setup.scanner);
    await tester.tap(find.widgetWithText(TextButton, 'Add expiry date'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // The date picker opens with today+7 preselected; confirm it.
    await tester.tap(find.text('OK'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.text('Add to trip'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    verify(() => setup.service.updateShoppingItemExpiry(1, any())).called(1);
    // No separate expiry prompt is shown after the confirmation closes.
    expect(find.text('Add expiry date'), findsNothing);
    expect(find.byType(MarketTripItemScreen), findsNothing);
  });

  testWidgets('cancelling the confirmation does not add the product', (
    tester,
  ) async {
    final setup = await pumpTrip(tester, inventories: [inventory1]);
    when(
      () => setup.service.addShoppingItem(
        any(),
        activeInventoryId: any(named: 'activeInventoryId'),
      ),
    ).thenAnswer((_) async => 1);

    await openConfirmation(tester, setup.scanner);
    Navigator.of(
      tester.element(find.byType(MarketTripItemScreen)),
    ).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    verifyNever(
      () => setup.service.addShoppingItem(
        any(),
        activeInventoryId: any(named: 'activeInventoryId'),
      ),
    );
    expect(setup.scanner.state.scanResolution, isNull);
  });

  testWidgets('a second scan while the confirmation is open is ignored', (
    tester,
  ) async {
    final setup = await pumpTrip(tester, inventories: [inventory1]);
    stubInsertPath(setup.db, setup.service);

    await openConfirmation(tester, setup.scanner);
    expect(find.byType(MarketTripItemScreen), findsOneWidget);

    setup.scanner.resolve(const Product(barcode: '2', name: 'Bread'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(MarketTripItemScreen), findsOneWidget);
  });

  testWidgets('system back is blocked while the trip add is saving', (
    tester,
  ) async {
    final setup = await pumpTrip(tester, inventories: [inventory1]);
    final gate = Completer<int>();
    final reachedGate = Completer<void>();
    when(
      () => setup.db.markShoppingItemsByBarcode(
        any(),
        inventoryId: any(named: 'inventoryId'),
      ),
    ).thenAnswer((_) async => 0);
    when(
      () => setup.service.addShoppingItem(
        any(),
        activeInventoryId: any(named: 'activeInventoryId'),
      ),
    ).thenAnswer((_) {
      reachedGate.complete();
      return gate.future;
    });

    await openConfirmation(tester, setup.scanner);
    await tester.tap(find.text('Add to trip'));
    await tester.pump();
    await reachedGate.future;

    // The system back button must not pop the confirmation while the add is
    // being persisted (PopScope blocks it, keeping the screen alive).
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.byType(MarketTripItemScreen), findsOneWidget);

    gate.complete(1);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(MarketTripItemScreen), findsNothing);
  });

  testWidgets('an unknown barcode opens the add-product screen', (
    tester,
  ) async {
    final setup = await pumpTrip(
      tester,
      inventories: [inventory1],
    );

    setup.scanner.failNotFound('999');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(AddProductScreen), findsOneWidget);
  });

  testWidgets(
    'add-product save returns to the confirmation and can be confirmed',
    (tester) async {
      final setup = await pumpTrip(
        tester,
        inventories: [inventory1],
      );
      stubInsertPath(setup.db, setup.service);
      final captured = <ShoppingItem>[];
      when(
        () => setup.service.addShoppingItem(
          any(),
          activeInventoryId: any(named: 'activeInventoryId'),
        ),
      ).thenAnswer((inv) async {
        captured.add(inv.positionalArguments[0] as ShoppingItem);
        return 2;
      });

      setup.scanner.failNotFound('999');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(AddProductScreen), findsOneWidget);

      Navigator.of(tester.element(find.byType(AddProductScreen))).pop(
        const Product(barcode: '999', name: 'New product'),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // The contributed product goes through the same single confirmation.
      expect(find.byType(MarketTripItemScreen), findsOneWidget);

      await tester.tap(find.text('Add to trip'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(captured, hasLength(1));
      expect(captured.first.barcode, '999');
      expect(captured.first.isPurchased, isTrue);
    },
  );

  testWidgets(
    'add-product back without saving does not add the product',
    (tester) async {
      final setup = await pumpTrip(
        tester,
        inventories: [inventory1],
      );

      setup.scanner.failNotFound('999');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // The user backs out (e.g. after a failed submission) without saving.
      Navigator.of(tester.element(find.byType(AddProductScreen))).pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(MarketTripItemScreen), findsNothing);
      verifyNever(
        () => setup.service.addShoppingItem(
          any(),
          activeInventoryId: any(named: 'activeInventoryId'),
        ),
      );
      expect(setup.scanner.state.scanResolution, isNull);
    },
  );
}
