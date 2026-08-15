import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/models/inventory_summary.dart';
import 'package:pantry_app/models/price.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/models/shopping_item.dart';
import 'package:pantry_app/providers/active_inventory_provider.dart';
import 'package:pantry_app/providers/database_provider.dart';
import 'package:pantry_app/providers/inventory_provider.dart';
import 'package:pantry_app/providers/price_provider.dart';
import 'package:pantry_app/providers/price_repository_provider.dart';
import 'package:pantry_app/providers/scanner_providers.dart';
import 'package:pantry_app/providers/settings_provider.dart';
import 'package:pantry_app/providers/shopping_list_provider.dart';
import 'package:pantry_app/providers/shopping_list_service_provider.dart';
import 'package:pantry_app/screens/market_trip_screen.dart';
import 'package:pantry_app/services/price_repository.dart';
import 'package:pantry_app/services/shopping_list_service.dart';
import 'package:pantry_app/widgets/add_to_shopping_list_sheet.dart';
import 'package:pantry_app/widgets/scanner_camera_view.dart';

import '../helpers/pump_app.dart';

class _MockDatabaseHelper extends Mock implements DatabaseHelper {}

class _MockShoppingListService extends Mock implements ShoppingListService {}

class _MockPriceRepository extends Mock implements PriceRepository {}

class _FakeActiveInventoryNotifier extends ActiveInventoryNotifier {
  @override
  Future<int> build() async => 1;
}

class _FakeSettingsNotifier extends SettingsNotifier {
  @override
  Future<Settings> build() async => const Settings(priceTrackingEnabled: true);
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
    })
  >
  pumpTrip(
    WidgetTester tester, {
    List<InventorySummary> inventories = const [],
    List<ShoppingItem> items = const [],
    _MockShoppingListService? service,
    Price? trackedPrice,
  }) async {
    final effectiveService = service ?? _MockShoppingListService();
    final repo = _MockPriceRepository();
    when(() => repo.formatPrice(any(), any())).thenAnswer(
      (inv) =>
          r'$'
          '${inv.positionalArguments[0]}',
    );
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
        settingsProvider.overrideWith(_FakeSettingsNotifier.new),
        databaseProvider.overrideWithValue(db),
        shoppingListServiceProvider.overrideWithValue(effectiveService),
        shoppingListByInventoryProvider(1).overrideWith((ref) => items),
        shoppingListProvider.overrideWith((ref) => items),
        scannerCameraProvider.overrideWith(() => scanner),
        priceRepositoryProvider.overrideWithValue(repo),
        latestPriceProvider(('1', 1)).overrideWith((ref) => trackedPrice),
      ],
    );
    await tester.pump();
    await tester.pump();
    return (db: db, service: effectiveService, scanner: scanner);
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

    expect(find.text('Add produce'), findsOneWidget);
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
    'scanning a pending item marks it purchased without navigation',
    (tester) async {
      final setup = await pumpTrip(
        tester,
        inventories: [inventory1],
        items: const [
          ShoppingItem(name: 'Milk', barcode: '1', inventoryId: 1),
        ],
      );
      when(
        () => setup.db.markShoppingItemsByBarcode(
          any(),
          inventoryId: any(named: 'inventoryId'),
        ),
      ).thenAnswer((_) async => 1);

      // Drive a resolved scan through the fake scanner camera.
      setup.scanner.resolve(const Product(barcode: '1', name: 'Milk'));
      await tester.pump();
      await tester.pump();

      verify(
        () => setup.db.markShoppingItemsByBarcode(
          '1',
          inventoryId: 1,
        ),
      ).called(1);
    },
  );

  testWidgets(
    'scanning a new product adds it and prompts for the estimated price',
    (tester) async {
      final setup = await pumpTrip(
        tester,
        inventories: [inventory1],
        trackedPrice: const Price(barcode: '1', price: 4.99),
      );
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
      ).thenAnswer((_) async {});
      when(
        () => setup.db.getShoppingList(inventoryId: any(named: 'inventoryId')),
      ).thenAnswer(
        (_) async => const [
          ShoppingItem(name: 'Milk', barcode: '1', inventoryId: 1),
        ],
      );
      when(
        () => setup.service.updateShoppingItemPrice(
          any(),
          priceAmount: any(named: 'priceAmount'),
          priceCurrency: any(named: 'priceCurrency'),
          priceStore: any(named: 'priceStore'),
        ),
      ).thenAnswer((_) async {});

      setup.scanner.resolve(const Product(barcode: '1', name: 'Milk'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Estimated price'), findsOneWidget);
    },
  );

  testWidgets(
    'an unknown product shows a snackbar and does not open the add sheet',
    (tester) async {
      final setup = await pumpTrip(
        tester,
        inventories: [inventory1],
      );
      when(
        () => setup.db.markShoppingItemsByBarcode(
          any(),
          inventoryId: any(named: 'inventoryId'),
        ),
      ).thenAnswer((_) async => 0);

      setup.scanner.failNotFound('999');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(AddToShoppingListSheet), findsNothing);
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Product not found.'), findsOneWidget);
    },
  );

  testWidgets('scanning a new product adds it as purchased', (tester) async {
    final setup = await pumpTrip(
      tester,
      inventories: [inventory1],
    );
    when(
      () => setup.db.markShoppingItemsByBarcode(
        any(),
        inventoryId: any(named: 'inventoryId'),
      ),
    ).thenAnswer((_) async => 0);
    final captured = <ShoppingItem>[];
    when(
      () => setup.service.addShoppingItem(
        any(),
        activeInventoryId: any(named: 'activeInventoryId'),
      ),
    ).thenAnswer((inv) async {
      captured.add(inv.positionalArguments[0] as ShoppingItem);
    });

    setup.scanner.resolve(const Product(barcode: '1', name: 'Milk'));
    await tester.pump();
    await tester.pump();

    expect(captured, hasLength(1));
    expect(captured.first.barcode, '1');
    expect(captured.first.isPurchased, isTrue);
  });
}
