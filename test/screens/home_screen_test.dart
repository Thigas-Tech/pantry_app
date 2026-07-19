/// @file HomeScreen widget tests.
///
/// Tests for the main dashboard screen.  The screen displays:
///   - A loading spinner while the inventory future is pending.
///   - An error message when the inventory future fails.
///   - The empty‑state widget when the inventory list is empty.
///   - Items grouped by expiry status (Expired, Expiring soon, Good).
///   - An inventory switcher icon when more than one inventory exists.
///   - Search bar filtering and clear functionality.
///   - Navigation via the FAB (scanner flow) and settings button.
///
/// All tests use the shared `pumpApp` helper.  We override the relevant
/// Riverpod providers (`inventoryWithProductProvider`, `inventoryListProvider`,
/// `activeInventoryProvider`, `productRepositoryProvider`) with fake/mocked
/// values.  The `imageCacheProvider` is stubbed via the harness to prevent
/// errors inside `InventoryCard`'s `FutureBuilder`.
///
/// The loading test uses `settle: false` to keep the future pending, then
/// completes it manually to avoid a “pending timer” error.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pantry_app/models/inventory_item.dart';
import 'package:pantry_app/models/inventory_with_product.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/models/product_type.dart';
import 'package:pantry_app/providers/active_inventory_provider.dart';
import 'package:pantry_app/providers/connectivity_provider.dart';
import 'package:pantry_app/providers/inventory_provider.dart';
import 'package:pantry_app/providers/product_repository_provider.dart';
import 'package:pantry_app/screens/home_screen.dart';
import 'package:pantry_app/screens/pantry_shell.dart';
import 'package:pantry_app/screens/product_detail_screen.dart';
import 'package:pantry_app/screens/scanner_screen.dart';
import 'package:pantry_app/screens/search_screen.dart';
import 'package:pantry_app/services/exceptions.dart';
import 'package:pantry_app/services/scan_result.dart';
import 'package:pantry_app/widgets/inventory_card.dart';
import 'package:pantry_app/widgets/inventory_switcher_card.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/pump_app.dart';

/// A fake [ActiveInventoryNotifier] that always returns 1
/// and records the last set value.
class FakeActiveInventoryNotifier extends ActiveInventoryNotifier {
  int lastSetValue = 1;

  @override
  int build() => 1;

  @override
  set value(int newValue) {
    lastSetValue = newValue;
    super.value = newValue;
  }
}

/// Creates a lightweight [InventoryWithProduct] with sensible defaults.
InventoryWithProduct testItem(
  String name, {
  String? barcode,
  DateTime? expiryDate,
}) {
  return InventoryWithProduct(
    id: 1,
    barcode: barcode ?? name,
    quantity: 1,
    unit: 'pcs',
    location: 'pantry',
    productName: name,
    expiryDate: expiryDate?.toIso8601String().substring(0, 10),
    inventoryId: 1,
  );
}

void main() {
  late MockImageCacheService mockImageCache;

  setUp(() {
    mockImageCache = MockImageCacheService();
    when(
      () => mockImageCache.cacheImage(any(), any()),
    ).thenAnswer((_) async => null);
  });

  // ---------- Original tests (unchanged) ----------

  testWidgets('shows loading spinner when inventory is loading', (
    tester,
  ) async {
    final completer = Completer<List<InventoryWithProduct>>();

    await pumpApp(
      tester,
      const HomeScreen(),
      imageCacheMock: mockImageCache,
      settle: false,
      overrides: [
        inventoryWithProductProvider.overrideWith((ref) => completer.future),
        inventoryListProvider.overrideWith(
          (ref) => <Map<String, dynamic>>[],
        ),
        activeInventoryProvider.overrideWith(FakeActiveInventoryNotifier.new),
        productRepositoryProvider.overrideWithValue(
          createMockProductRepository(),
        ),
      ],
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete([]);
    await tester.pumpAndSettle();
  });

  testWidgets('shows error message when inventory fails', (tester) async {
    await pumpApp(
      tester,
      const HomeScreen(),
      imageCacheMock: mockImageCache,
      overrides: [
        inventoryWithProductProvider.overrideWith(
          (ref) => Future.error('test error'),
        ),
        inventoryListProvider.overrideWith(
          (ref) => <Map<String, dynamic>>[],
        ),
        activeInventoryProvider.overrideWith(FakeActiveInventoryNotifier.new),
        productRepositoryProvider.overrideWithValue(
          createMockProductRepository(),
        ),
      ],
    );

    expect(find.text('Failed to load inventory.'), findsAtLeast(1));
  });

  testWidgets('shows empty state when inventory list is empty', (tester) async {
    await pumpApp(
      tester,
      const HomeScreen(),
      imageCacheMock: mockImageCache,
      overrides: [
        inventoryWithProductProvider.overrideWith(
          (ref) => <InventoryWithProduct>[],
        ),
        inventoryListProvider.overrideWith(
          (ref) => <Map<String, dynamic>>[],
        ),
        activeInventoryProvider.overrideWith(FakeActiveInventoryNotifier.new),
        productRepositoryProvider.overrideWithValue(
          createMockProductRepository(),
        ),
      ],
    );

    expect(find.text('Your pantry is empty'), findsOneWidget);
  });

  testWidgets('shows inventory items grouped by expiry', (tester) async {
    final now = DateTime.now();
    final items = [
      testItem(
        'expired',
        barcode: '1',
        expiryDate: now.subtract(const Duration(days: 1)),
      ),
      testItem(
        'expiringSoon',
        barcode: '2',
        expiryDate: now.add(const Duration(days: 1)),
      ),
      testItem(
        'good',
        barcode: '3',
        expiryDate: now.add(const Duration(days: 30)),
      ),
      testItem('no expiry', barcode: '4'),
    ];

    await pumpApp(
      tester,
      const HomeScreen(),
      imageCacheMock: mockImageCache,
      overrides: [
        inventoryWithProductProvider.overrideWith((ref) => items),
        inventoryListProvider.overrideWith(
          (ref) => <Map<String, dynamic>>[
            {'id': 1, 'name': 'Home'},
          ],
        ),
        activeInventoryProvider.overrideWith(FakeActiveInventoryNotifier.new),
        productRepositoryProvider.overrideWithValue(
          createMockProductRepository(),
        ),
      ],
    );

    expect(find.text('Expired'), findsAtLeast(1));
    expect(find.text('Expiring soon'), findsAtLeast(1));
    expect(find.text('Good'), findsAtLeast(1));
  });

  testWidgets('shows inventory switcher when multiple inventories exist', (
    tester,
  ) async {
    await pumpApp(
      tester,
      const HomeScreen(),
      imageCacheMock: mockImageCache,
      overrides: [
        inventoryWithProductProvider.overrideWith(
          (ref) => <InventoryWithProduct>[],
        ),
        inventoryListProvider.overrideWith(
          (ref) => <Map<String, dynamic>>[
            {'id': 1, 'name': 'Home'},
            {'id': 2, 'name': 'Work'},
          ],
        ),
        activeInventoryProvider.overrideWith(FakeActiveInventoryNotifier.new),
        productRepositoryProvider.overrideWithValue(
          createMockProductRepository(),
        ),
      ],
    );

    expect(find.byType(InventorySwitcherCard), findsOneWidget);
    expect(find.byIcon(Icons.arrow_drop_down), findsOneWidget);
  });

  testWidgets('does not show switcher when only one inventory exists', (
    tester,
  ) async {
    await pumpApp(
      tester,
      const HomeScreen(),
      imageCacheMock: mockImageCache,
      overrides: [
        inventoryWithProductProvider.overrideWith(
          (ref) => <InventoryWithProduct>[],
        ),
        inventoryListProvider.overrideWith(
          (ref) => <Map<String, dynamic>>[
            {'id': 1, 'name': 'Home'},
          ],
        ),
        activeInventoryProvider.overrideWith(FakeActiveInventoryNotifier.new),
        productRepositoryProvider.overrideWithValue(
          createMockProductRepository(),
        ),
      ],
    );

    // Still shows card (with just pantry name, no dropdown needed).
    expect(find.byType(InventorySwitcherCard), findsOneWidget);
  });

  // ---------- Additional tests for uncovered paths ----------

  testWidgets('NavigationBar tabs switch content', (tester) async {
    await pumpApp(
      tester,
      const PantryShell(),
      imageCacheMock: mockImageCache,
      overrides: [
        inventoryWithProductProvider.overrideWith(
          (ref) => <InventoryWithProduct>[],
        ),
        inventoryListProvider.overrideWith(
          (ref) => <Map<String, dynamic>>[],
        ),
        inventoryCountProvider.overrideWith(
          (ref) => Future<int>.value(0),
        ),
        activeInventoryProvider.overrideWith(FakeActiveInventoryNotifier.new),
        hasConnectionProvider.overrideWith((ref) => Future.value(true)),
        connectivityProvider.overrideWith((ref) => const Stream.empty()),
        productRepositoryProvider.overrideWithValue(
          createMockProductRepository(),
        ),
      ],
      settle: false,
    );
    await tester.pump();

    // Default tab is Home.
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);

    // Tap Search tab.
    await tester.tap(find.text('Search'));
    await tester.pumpAndSettle();
    expect(find.byType(SearchScreen), findsOneWidget);
  });

  testWidgets('search filters items and shows clear button', (tester) async {
    final items = [
      testItem('Milk', barcode: '111'),
      testItem('Bread', barcode: '222'),
    ];
    await pumpApp(
      tester,
      const HomeScreen(),
      imageCacheMock: mockImageCache,
      overrides: [
        inventoryWithProductProvider.overrideWith((ref) => items),
        inventoryListProvider.overrideWith(
          (ref) => <Map<String, dynamic>>[
            {'id': 1, 'name': 'Home'},
          ],
        ),
        activeInventoryProvider.overrideWith(FakeActiveInventoryNotifier.new),
        productRepositoryProvider.overrideWithValue(
          createMockProductRepository(),
        ),
      ],
    );

    expect(find.widgetWithText(InventoryCard, 'Milk'), findsOneWidget);
    expect(find.widgetWithText(InventoryCard, 'Bread'), findsOneWidget);

    final searchField = find.byType(TextField);
    await tester.enterText(searchField, 'Milk');
    await tester.pumpAndSettle();

    expect(find.widgetWithText(InventoryCard, 'Milk'), findsOneWidget);
    expect(find.widgetWithText(InventoryCard, 'Bread'), findsNothing);

    expect(find.byIcon(Icons.clear), findsOneWidget);

    await tester.tap(find.byIcon(Icons.clear));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(InventoryCard, 'Milk'), findsOneWidget);
    expect(find.widgetWithText(InventoryCard, 'Bread'), findsOneWidget);
  });

  testWidgets('shows no items match message when search yields empty', (
    tester,
  ) async {
    final items = [testItem('Milk', barcode: '111')];
    await pumpApp(
      tester,
      const HomeScreen(),
      imageCacheMock: mockImageCache,
      overrides: [
        inventoryWithProductProvider.overrideWith((ref) => items),
        inventoryListProvider.overrideWith(
          (ref) => <Map<String, dynamic>>[],
        ),
        activeInventoryProvider.overrideWith(FakeActiveInventoryNotifier.new),
        productRepositoryProvider.overrideWithValue(
          createMockProductRepository(),
        ),
      ],
    );

    await tester.enterText(find.byType(TextField), 'XYZ');
    await tester.pumpAndSettle();

    expect(find.text('No items match your search'), findsOneWidget);
  });

  testWidgets('inventory switcher popup selects a different inventory', (
    tester,
  ) async {
    final fakeNotifier = FakeActiveInventoryNotifier();
    await pumpApp(
      tester,
      const HomeScreen(),
      imageCacheMock: mockImageCache,
      overrides: [
        inventoryWithProductProvider.overrideWith(
          (ref) => <InventoryWithProduct>[],
        ),
        inventoryListProvider.overrideWith(
          (ref) => <Map<String, dynamic>>[
            {'id': 1, 'name': 'Home'},
            {'id': 2, 'name': 'Work'},
          ],
        ),
        activeInventoryProvider.overrideWith(() => fakeNotifier),
        productRepositoryProvider.overrideWithValue(
          createMockProductRepository(),
        ),
      ],
    );

    // Tap the switcher card to open bottom sheet.
    final card = find.byType(InventorySwitcherCard);
    expect(card, findsOneWidget);
    await tester.tap(card);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Work').last);
    await tester.pumpAndSettle();

    expect(fakeNotifier.lastSetValue, 2);
  });

  testWidgets(
    'FAB scanner flow: barcode returns, navigates to product detail',
    (tester) async {
      final mockRepo = createMockProductRepository();
      const product = Product(barcode: '123', name: 'Test');
      when(() => mockRepo.getProduct('123')).thenAnswer((_) async => product);
      // Stub inventory fetch to avoid null future
      when(
        () => mockRepo.getInventoryForBarcode(
          any(),
          inventoryId: any(named: 'inventoryId'),
        ),
      ).thenAnswer((_) async => <InventoryItem>[]);

      await pumpApp(
        tester,
        const HomeScreen(),
        imageCacheMock: mockImageCache,
        overrides: [
          inventoryWithProductProvider.overrideWith(
            (ref) => <InventoryWithProduct>[],
          ),
          inventoryListProvider.overrideWith(
            (ref) => <Map<String, dynamic>>[],
          ),
          activeInventoryProvider.overrideWith(FakeActiveInventoryNotifier.new),
          hasConnectionProvider.overrideWith((ref) => Future.value(true)),
          productRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(ScannerScreen), findsOneWidget);

      // Pop the scanner with a barcode
      tester
          .state<NavigatorState>(find.byType(Navigator))
          .pop(const BarcodeResult('123'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(ProductDetailScreen), findsOneWidget);
      expect(find.text('Test'), findsOneWidget);
    },
  );

  testWidgets('FAB scanner flow: null result does nothing', (tester) async {
    await pumpApp(
      tester,
      const HomeScreen(),
      imageCacheMock: mockImageCache,
      overrides: [
        inventoryWithProductProvider.overrideWith(
          (ref) => <InventoryWithProduct>[],
        ),
        inventoryListProvider.overrideWith(
          (ref) => <Map<String, dynamic>>[],
        ),
        activeInventoryProvider.overrideWith(FakeActiveInventoryNotifier.new),
        hasConnectionProvider.overrideWith((ref) => Future.value(true)),
        productRepositoryProvider.overrideWithValue(
          createMockProductRepository(),
        ),
      ],
    );

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(ScannerScreen), findsOneWidget);

    // null value
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(ProductDetailScreen), findsNothing);
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('FAB scanner flow: product not found shows snackbar', (
    tester,
  ) async {
    final mockRepo = createMockProductRepository();
    when(
      () => mockRepo.getProduct('123'),
    ).thenThrow(ProductNotFoundException('product not found'));

    await pumpApp(
      tester,
      const HomeScreen(),
      imageCacheMock: mockImageCache,
      overrides: [
        inventoryWithProductProvider.overrideWith(
          (ref) => <InventoryWithProduct>[],
        ),
        inventoryListProvider.overrideWith(
          (ref) => <Map<String, dynamic>>[],
        ),
        activeInventoryProvider.overrideWith(FakeActiveInventoryNotifier.new),
        hasConnectionProvider.overrideWith((ref) => Future.value(true)),
        productRepositoryProvider.overrideWithValue(mockRepo),
      ],
    );

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    tester
        .state<NavigatorState>(find.byType(Navigator))
        .pop(const BarcodeResult('123'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Product not found in database.'), findsOneWidget);
  });

  testWidgets(
    'FAB scanner flow: navigates to ProductDetailScreen on barcode hit',
    (
      tester,
    ) async {
      final mockRepo = createMockProductRepository();
      const testProduct = Product(
        name: 'Test Item',
        barcode: '123',
      );
      when(
        () => mockRepo.getProduct('123'),
      ).thenAnswer((_) async => testProduct);
      when(
        () => mockRepo.getInventoryForBarcode(
          any(),
          inventoryId: any(named: 'inventoryId'),
        ),
      ).thenAnswer((_) async => []);

      await pumpApp(
        tester,
        const HomeScreen(),
        imageCacheMock: mockImageCache,
        overrides: [
          inventoryWithProductProvider.overrideWith(
            (ref) => <InventoryWithProduct>[],
          ),
          inventoryListProvider.overrideWith(
            (ref) => <Map<String, dynamic>>[],
          ),
          activeInventoryProvider.overrideWith(FakeActiveInventoryNotifier.new),
          hasConnectionProvider.overrideWith((ref) => Future.value(true)),
          productRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Pop scanner with a valid barcode.
      tester
          .state<NavigatorState>(find.byType(Navigator))
          .pop(const BarcodeResult('123'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // ProductDetailScreen should open.
      expect(find.byType(ProductDetailScreen), findsOneWidget);

      // Pop ProductDetailScreen.
      tester.state<NavigatorState>(find.byType(Navigator)).pop();
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(HomeScreen), findsOneWidget);
    },
  );

  testWidgets('NavigationBar displays all tab labels', (tester) async {
    await pumpApp(
      tester,
      const PantryShell(),
      imageCacheMock: mockImageCache,
      overrides: [
        inventoryWithProductProvider.overrideWith(
          (ref) => <InventoryWithProduct>[],
        ),
        inventoryListProvider.overrideWith(
          (ref) => <Map<String, dynamic>>[],
        ),
        inventoryCountProvider.overrideWith(
          (ref) => Future<int>.value(0),
        ),
        activeInventoryProvider.overrideWith(FakeActiveInventoryNotifier.new),
        hasConnectionProvider.overrideWith((ref) => Future.value(true)),
        productRepositoryProvider.overrideWithValue(
          createMockProductRepository(),
        ),
      ],
      settle: false,
    );
    await tester.pump();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Search'), findsOneWidget);
    expect(find.text('Stats'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('create pantry dialog creates an inventory', (tester) async {
    final mockRepo = createMockProductRepository();
    when(
      () => mockRepo.createInventory(any()),
    ).thenAnswer((_) async => 3);

    await pumpApp(
      tester,
      const HomeScreen(),
      imageCacheMock: mockImageCache,
      overrides: [
        inventoryWithProductProvider.overrideWith(
          (ref) => <InventoryWithProduct>[],
        ),
        inventoryListProvider.overrideWith(
          (ref) => <Map<String, dynamic>>[
            {'id': 1, 'name': 'Home'},
          ],
        ),
        activeInventoryProvider.overrideWith(FakeActiveInventoryNotifier.new),
        productRepositoryProvider.overrideWithValue(mockRepo),
      ],
    );

    // Tap the switcher card to open bottom sheet.
    final card = find.byType(InventorySwitcherCard);
    expect(card, findsOneWidget);
    await tester.tap(card);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Create new pantry'));
    await tester.pumpAndSettle();

    expect(find.text('New pantry'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Camping');
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    verify(() => mockRepo.createInventory('Camping')).called(1);
  });

  // ---------- Stock count badge tests ----------

  testWidgets('shows stock count badges with item counts', (tester) async {
    final now = DateTime.now();
    final items = [
      testItem(
        'Item 1',
        barcode: '1',
        expiryDate: now.add(const Duration(days: 10)), // good
      ),
      testItem(
        'Item 2',
        barcode: '2',
        expiryDate: now.add(const Duration(days: 1)), // expiring soon
      ),
      testItem(
        'Item 3',
        barcode: '3',
        expiryDate: now.subtract(const Duration(days: 1)), // expired
      ),
    ];

    await pumpApp(
      tester,
      const HomeScreen(),
      imageCacheMock: mockImageCache,
      overrides: [
        inventoryWithProductProvider.overrideWith((ref) => items),
        inventoryListProvider.overrideWith(
          (ref) => <Map<String, dynamic>>[
            {'id': 1, 'name': 'Home'},
          ],
        ),
        activeInventoryProvider.overrideWith(FakeActiveInventoryNotifier.new),
        productRepositoryProvider.overrideWithValue(
          createMockProductRepository(),
        ),
      ],
    );

    expect(find.textContaining('Total items: 3'), findsOneWidget);
    expect(find.textContaining('Expiring soon: 1'), findsOneWidget);
    expect(find.textContaining('Added this week: 0'), findsOneWidget);
  });

  testWidgets('stock count badges use correct icons', (tester) async {
    await pumpApp(
      tester,
      const HomeScreen(),
      imageCacheMock: mockImageCache,
      overrides: [
        inventoryWithProductProvider.overrideWith(
          (ref) => [
            testItem('Item', barcode: '1'),
          ],
        ),
        inventoryListProvider.overrideWith(
          (ref) => <Map<String, dynamic>>[
            {'id': 1, 'name': 'Home'},
          ],
        ),
        activeInventoryProvider.overrideWith(FakeActiveInventoryNotifier.new),
        productRepositoryProvider.overrideWithValue(
          createMockProductRepository(),
        ),
      ],
    );

    expect(find.byIcon(Icons.inventory_2_outlined), findsOneWidget);
    expect(find.byIcon(Icons.warning_amber_outlined), findsOneWidget);
    expect(find.byIcon(Icons.add_circle_outline), findsOneWidget);
  });

  // ---------- Category filter tests ----------

  testWidgets(
    'shows category filter chips when 2+ categories exist',
    skip: true,
    (
      tester,
    ) async {
      final items = [
        const InventoryWithProduct(
          barcode: '1',
          quantity: 1,
          unit: 'pcs',
          location: 'pantry',
          id: 1,
          inventoryId: 1,
          productName: 'Milk',
          productCategory: 'Dairy',
        ),
        const InventoryWithProduct(
          barcode: '2',
          quantity: 1,
          unit: 'pcs',
          location: 'pantry',
          id: 2,
          inventoryId: 1,
          productName: 'Bread',
          productCategory: 'Grains',
        ),
      ];

      await pumpApp(
        tester,
        const HomeScreen(),
        imageCacheMock: mockImageCache,
        overrides: [
          inventoryWithProductProvider.overrideWith((ref) => items),
          inventoryListProvider.overrideWith(
            (ref) => <Map<String, dynamic>>[
              {'id': 1, 'name': 'Home'},
            ],
          ),
          activeInventoryProvider.overrideWith(FakeActiveInventoryNotifier.new),
          productRepositoryProvider.overrideWithValue(
            createMockProductRepository(),
          ),
        ],
      );

      expect(find.text('All'), findsOneWidget);
      expect(find.text('Dairy'), findsOneWidget);
      expect(find.text('Grains'), findsOneWidget);
    },
  );

  testWidgets('hides category filter chips when <2 categories', (tester) async {
    final items = [
      const InventoryWithProduct(
        barcode: '1',
        quantity: 1,
        unit: 'pcs',
        location: 'pantry',
        id: 1,
        inventoryId: 1,
        productName: 'Milk',
        productCategory: 'Dairy',
      ),
    ];

    await pumpApp(
      tester,
      const HomeScreen(),
      imageCacheMock: mockImageCache,
      overrides: [
        inventoryWithProductProvider.overrideWith((ref) => items),
        inventoryListProvider.overrideWith(
          (ref) => <Map<String, dynamic>>[
            {'id': 1, 'name': 'Home'},
          ],
        ),
        activeInventoryProvider.overrideWith(FakeActiveInventoryNotifier.new),
        productRepositoryProvider.overrideWithValue(
          createMockProductRepository(),
        ),
      ],
    );

    expect(find.byType(SegmentedButton), findsNothing);
  });

  testWidgets('selecting category filter hides other items', skip: true, (
    tester,
  ) async {
    final items = [
      const InventoryWithProduct(
        barcode: '1',
        quantity: 1,
        unit: 'pcs',
        location: 'pantry',
        id: 1,
        inventoryId: 1,
        productName: 'Milk',
        productCategory: 'Dairy',
      ),
      const InventoryWithProduct(
        barcode: '2',
        quantity: 1,
        unit: 'pcs',
        location: 'pantry',
        id: 2,
        inventoryId: 1,
        productName: 'Bread',
        productCategory: 'Grains',
      ),
    ];

    await pumpApp(
      tester,
      const HomeScreen(),
      imageCacheMock: mockImageCache,
      overrides: [
        inventoryWithProductProvider.overrideWith((ref) => items),
        inventoryListProvider.overrideWith(
          (ref) => <Map<String, dynamic>>[
            {'id': 1, 'name': 'Home'},
          ],
        ),
        activeInventoryProvider.overrideWith(FakeActiveInventoryNotifier.new),
        productRepositoryProvider.overrideWithValue(
          createMockProductRepository(),
        ),
      ],
    );

    // Both items visible initially.
    expect(find.text('Milk'), findsOneWidget);
    expect(find.text('Bread'), findsOneWidget);

    // Tap the "Dairy" chip.
    await tester.tap(find.text('Dairy'));
    await tester.pumpAndSettle();

    // Only Dairy item visible.
    expect(find.text('Milk'), findsOneWidget);
    expect(find.text('Bread'), findsNothing);
  });

  testWidgets('selecting "All" resets category filter', skip: true, (
    tester,
  ) async {
    final items = [
      const InventoryWithProduct(
        barcode: '1',
        quantity: 1,
        unit: 'pcs',
        location: 'pantry',
        id: 1,
        inventoryId: 1,
        productName: 'Milk',
        productCategory: 'Dairy',
      ),
      const InventoryWithProduct(
        barcode: '2',
        quantity: 1,
        unit: 'pcs',
        location: 'pantry',
        id: 2,
        inventoryId: 1,
        productName: 'Bread',
        productCategory: 'Grains',
      ),
    ];

    await pumpApp(
      tester,
      const HomeScreen(),
      imageCacheMock: mockImageCache,
      overrides: [
        inventoryWithProductProvider.overrideWith((ref) => items),
        inventoryListProvider.overrideWith(
          (ref) => <Map<String, dynamic>>[
            {'id': 1, 'name': 'Home'},
          ],
        ),
        activeInventoryProvider.overrideWith(FakeActiveInventoryNotifier.new),
        productRepositoryProvider.overrideWithValue(
          createMockProductRepository(),
        ),
      ],
    );

    // Filter by Dairy.
    await tester.tap(find.text('Dairy'));
    await tester.pumpAndSettle();
    expect(find.text('Bread'), findsNothing);

    // Reset with "All".
    await tester.tap(find.text('All'));
    await tester.pumpAndSettle();

    expect(find.text('Milk'), findsOneWidget);
    expect(find.text('Bread'), findsOneWidget);
  });

  testWidgets(
    'category filter displays OFF taxonomy code as human-readable',
    skip: true,
    (
      tester,
    ) async {
      final items = [
        const InventoryWithProduct(
          barcode: '1',
          quantity: 1,
          unit: 'pcs',
          location: 'pantry',
          id: 1,
          inventoryId: 1,
          productName: 'Spreads',
          productCategory: 'en:spreads',
        ),
        const InventoryWithProduct(
          barcode: '2',
          quantity: 1,
          unit: 'pcs',
          location: 'pantry',
          id: 2,
          inventoryId: 1,
          productName: 'Beverage',
          productCategory: 'en:beverages',
        ),
      ];

      await pumpApp(
        tester,
        const HomeScreen(),
        imageCacheMock: mockImageCache,
        overrides: [
          inventoryWithProductProvider.overrideWith((ref) => items),
          inventoryListProvider.overrideWith(
            (ref) => <Map<String, dynamic>>[
              {'id': 1, 'name': 'Home'},
            ],
          ),
          activeInventoryProvider.overrideWith(FakeActiveInventoryNotifier.new),
          productRepositoryProvider.overrideWithValue(
            createMockProductRepository(),
          ),
        ],
      );

      // Should show human-readable names, not taxonomy codes.
      // "Spreads" appears both as product name (card) and category (chip).
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Spreads'), findsAtLeast(1));
      expect(find.text('Beverages'), findsAtLeast(1));
      // Taxonomy codes should not appear.
      expect(find.text('en:spreads'), findsNothing);
      expect(find.text('en:beverages'), findsNothing);
    },
  );

  testWidgets(
    'empty message includes active category when filtered',
    skip: true,
    (
      tester,
    ) async {
      final items = [
        const InventoryWithProduct(
          barcode: '1',
          quantity: 1,
          unit: 'pcs',
          location: 'pantry',
          id: 1,
          inventoryId: 1,
          productName: 'Milk',
          productCategory: 'Dairy',
        ),
        const InventoryWithProduct(
          barcode: '2',
          quantity: 1,
          unit: 'pcs',
          location: 'pantry',
          id: 2,
          inventoryId: 1,
          productName: 'Bread',
          productCategory: 'Grains',
        ),
      ];

      await pumpApp(
        tester,
        const HomeScreen(),
        imageCacheMock: mockImageCache,
        overrides: [
          inventoryWithProductProvider.overrideWith((ref) => items),
          inventoryListProvider.overrideWith(
            (ref) => <Map<String, dynamic>>[
              {'id': 1, 'name': 'Home'},
            ],
          ),
          activeInventoryProvider.overrideWith(FakeActiveInventoryNotifier.new),
          productRepositoryProvider.overrideWithValue(
            createMockProductRepository(),
          ),
        ],
      );

      // Search for something that doesn't match any item name.
      await tester.enterText(find.byType(TextField), 'XYZ');
      await tester.pumpAndSettle();

      expect(find.textContaining('No items match'), findsOneWidget);

      // Clear the search to dismiss the autocomplete overlay, then filter.
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Dairy'));
      await tester.pumpAndSettle();

      // Re-enter the search (no matching options, so no dropdown appears).
      await tester.enterText(find.byType(TextField), 'XYZ');
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Category: Dairy'),
        findsOneWidget,
      );
      expect(find.textContaining('No items match'), findsOneWidget);
    },
  );

  testWidgets('category filter + search query AND correctly', skip: true, (
    tester,
  ) async {
    final items = [
      const InventoryWithProduct(
        barcode: '1',
        quantity: 1,
        unit: 'pcs',
        location: 'pantry',
        id: 1,
        inventoryId: 1,
        productName: 'Milk',
        productCategory: 'Dairy',
      ),
      const InventoryWithProduct(
        barcode: '2',
        quantity: 1,
        unit: 'pcs',
        location: 'pantry',
        id: 2,
        inventoryId: 1,
        productName: 'Milk Chocolate',
        productCategory: 'Sweets',
      ),
    ];

    await pumpApp(
      tester,
      const HomeScreen(),
      imageCacheMock: mockImageCache,
      overrides: [
        inventoryWithProductProvider.overrideWith((ref) => items),
        inventoryListProvider.overrideWith(
          (ref) => <Map<String, dynamic>>[
            {'id': 1, 'name': 'Home'},
          ],
        ),
        activeInventoryProvider.overrideWith(FakeActiveInventoryNotifier.new),
        productRepositoryProvider.overrideWithValue(
          createMockProductRepository(),
        ),
      ],
    );

    // Search for "Milk" — both items match.
    await tester.enterText(find.byType(TextField), 'Milk');
    await tester.pumpAndSettle();

    expect(find.byType(InventoryCard), findsNWidgets(2));

    // Clear search to dismiss overlay, then filter by Dairy.
    await tester.tap(find.byIcon(Icons.clear));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Dairy'));
    await tester.pumpAndSettle();

    // Re-enter "Milk" — Dairy filter + search = only 1 item.
    await tester.enterText(find.byType(TextField), 'Milk');
    await tester.pumpAndSettle();

    expect(find.byType(InventoryCard), findsOneWidget);
  });

  testWidgets('batch delete selects and deletes items', skip: true, (
    tester,
  ) async {
    final mockRepo = createMockProductRepository();
    when(
      () => mockRepo.deleteInventoryItem(any()),
    ).thenAnswer((_) async => 1);

    final items = [
      const InventoryWithProduct(
        barcode: '1',
        quantity: 1,
        unit: 'pcs',
        location: 'pantry',
        id: 1,
        productName: 'Item A',
        notes: 'test',
        dateAdded: 0,
        inventoryId: 1,
      ),
      const InventoryWithProduct(
        barcode: '2',
        quantity: 2,
        unit: 'L',
        location: 'fridge',
        id: 2,
        productName: 'Item B',
        notes: 'test',
        dateAdded: 0,
        inventoryId: 1,
      ),
    ];

    await pumpApp(
      tester,
      const HomeScreen(),
      imageCacheMock: mockImageCache,
      overrides: [
        inventoryWithProductProvider.overrideWith((ref) => items),
        inventoryListProvider.overrideWith(
          (ref) => <Map<String, dynamic>>[
            {'id': 1, 'name': 'Home'},
          ],
        ),
        activeInventoryProvider.overrideWith(FakeActiveInventoryNotifier.new),
        productRepositoryProvider.overrideWithValue(mockRepo),
      ],
    );

    // Tap the checklist icon to enter selection mode
    await tester.tap(find.byIcon(Icons.checklist));
    await tester.pumpAndSettle();

    // Checkboxes should be visible
    expect(find.byType(Checkbox), findsNWidgets(2));

    // Select the first item
    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();

    // Tap delete (should show confirmation)
    await tester.tap(find.byIcon(Icons.delete));
    await tester.pumpAndSettle();

    // Confirm deletion
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    verify(() => mockRepo.deleteInventoryItem(1)).called(1);
    verifyNever(() => mockRepo.deleteInventoryItem(2));
  });

  // ---------- Autocomplete tests ----------

  testWidgets('autocomplete shows matching suggestions', skip: true, (
    tester,
  ) async {
    final items = [
      const InventoryWithProduct(
        barcode: '111111',
        quantity: 1,
        unit: 'pcs',
        location: 'pantry',
        id: 1,
        inventoryId: 1,
        productName: 'Milk',
      ),
      const InventoryWithProduct(
        barcode: '222222',
        quantity: 1,
        unit: 'pcs',
        location: 'pantry',
        id: 2,
        inventoryId: 1,
        productName: 'Bread',
      ),
    ];

    await pumpApp(
      tester,
      const HomeScreen(),
      imageCacheMock: mockImageCache,
      overrides: [
        inventoryWithProductProvider.overrideWith((ref) => items),
        inventoryListProvider.overrideWith(
          (ref) => <Map<String, dynamic>>[
            {'id': 1, 'name': 'Home'},
          ],
        ),
        activeInventoryProvider.overrideWith(FakeActiveInventoryNotifier.new),
        productRepositoryProvider.overrideWithValue(
          createMockProductRepository(),
        ),
      ],
    );

    // Type a partial name.
    await tester.enterText(find.byType(TextField), 'Mil');
    await tester.pumpAndSettle();

    // The suggestion dropdown should show "Milk" and "111111"
    // (title and subtitle respectively).
    expect(find.text('Milk'), findsWidgets);
    expect(find.text('111111'), findsOneWidget);

    // "Bread" / "222222" should not appear in suggestions.
    expect(find.text('222222'), findsNothing);
  });

  testWidgets('autocomplete respects category filter', skip: true, (
    tester,
  ) async {
    final items = [
      const InventoryWithProduct(
        barcode: '111111',
        quantity: 1,
        unit: 'pcs',
        location: 'pantry',
        id: 1,
        inventoryId: 1,
        productName: 'Milk',
        productCategory: 'Dairy',
      ),
      const InventoryWithProduct(
        barcode: '222222',
        quantity: 1,
        unit: 'pcs',
        location: 'pantry',
        id: 2,
        inventoryId: 1,
        productName: 'Milk Chocolate',
        productCategory: 'Sweets',
      ),
    ];

    await pumpApp(
      tester,
      const HomeScreen(),
      imageCacheMock: mockImageCache,
      overrides: [
        inventoryWithProductProvider.overrideWith((ref) => items),
        inventoryListProvider.overrideWith(
          (ref) => <Map<String, dynamic>>[
            {'id': 1, 'name': 'Home'},
          ],
        ),
        activeInventoryProvider.overrideWith(FakeActiveInventoryNotifier.new),
        productRepositoryProvider.overrideWithValue(
          createMockProductRepository(),
        ),
      ],
    );

    // First, filter by "Dairy".
    await tester.tap(find.text('Dairy'));
    await tester.pumpAndSettle();

    // Type "Milk".
    await tester.enterText(find.byType(TextField), 'Milk');
    await tester.pumpAndSettle();

    // Only the Dairy "Milk" (barcode 111111) should be suggested.
    expect(find.text('111111'), findsOneWidget);
    // "Milk Chocolate" (Sweets, barcode 222222) should not appear.
    expect(find.text('222222'), findsNothing);
  });

  testWidgets(
    'suggestion shows barcode avatar when no product image',
    (tester) async {
      // productImageUrl is null by default in InventoryWithProduct.
      const item = InventoryWithProduct(
        barcode: '123',
        quantity: 1,
        unit: 'pcs',
        location: 'pantry',
        id: 1,
        inventoryId: 1,
        productName: 'Test Product',
      );

      await pumpApp(
        tester,
        const HomeScreen(),
        imageCacheMock: mockImageCache,
        overrides: [
          inventoryWithProductProvider.overrideWith((ref) => [item]),
          inventoryListProvider.overrideWith(
            (ref) => <Map<String, dynamic>>[
              {'id': 1, 'name': 'Home'},
            ],
          ),
          activeInventoryProvider.overrideWith(FakeActiveInventoryNotifier.new),
          productRepositoryProvider.overrideWithValue(
            createMockProductRepository(),
          ),
        ],
      );

      await tester.enterText(find.byType(TextField), 'Test');
      await tester.pumpAndSettle();

      // The suggestion should show a CircleAvatar with barcode initials.
      // find.byType(CircleAvatar) — there is at least 1 from the suggestion.
      // (InventoryCard's _buildLeadingImage may also use CircleAvatar for
      // fallback, so we check for at least 1.)
      expect(find.byType(CircleAvatar), findsWidgets);
    },
  );

  testWidgets('accent-insensitive search filtering', (tester) async {
    final items = [
      const InventoryWithProduct(
        barcode: '111111',
        quantity: 1,
        unit: 'pcs',
        location: 'pantry',
        id: 1,
        inventoryId: 1,
        productName: 'Café crème',
      ),
      const InventoryWithProduct(
        barcode: '222222',
        quantity: 1,
        unit: 'pcs',
        location: 'pantry',
        id: 2,
        inventoryId: 1,
        productName: 'Müsli',
      ),
    ];

    await pumpApp(
      tester,
      const HomeScreen(),
      imageCacheMock: mockImageCache,
      overrides: [
        inventoryWithProductProvider.overrideWith((ref) => items),
        inventoryListProvider.overrideWith(
          (ref) => <Map<String, dynamic>>[
            {'id': 1, 'name': 'Home'},
          ],
        ),
        activeInventoryProvider.overrideWith(FakeActiveInventoryNotifier.new),
        productRepositoryProvider.overrideWithValue(
          createMockProductRepository(),
        ),
      ],
    );

    // Both items visible initially.
    expect(find.byType(InventoryCard), findsNWidgets(2));

    // Type "cafe" — should match "Café crème" via normalizeForSearch.
    await tester.enterText(find.byType(TextField), 'cafe');
    await tester.pumpAndSettle();

    expect(find.byType(InventoryCard), findsOneWidget);
    expect(find.text('222222'), findsNothing);

    // Clear, then type "musli" — should match "Müsli" via normalizeForSearch.
    await tester.tap(find.byIcon(Icons.clear));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'musli');
    await tester.pumpAndSettle();

    expect(find.byType(InventoryCard), findsOneWidget);
    expect(find.text('111111'), findsNothing);
  });

  // ---------- Long-press selection tests ----------

  testWidgets('long-press enters selection mode and selects item', (
    tester,
  ) async {
    final mockRepo = createMockProductRepository();
    final items = [
      const InventoryWithProduct(
        barcode: '1',
        quantity: 1,
        unit: 'pcs',
        location: 'pantry',
        id: 1,
        productName: 'Item A',
        notes: 'test',
        dateAdded: 0,
        inventoryId: 1,
      ),
      const InventoryWithProduct(
        barcode: '2',
        quantity: 2,
        unit: 'L',
        location: 'fridge',
        id: 2,
        productName: 'Item B',
        notes: 'test',
        dateAdded: 0,
        inventoryId: 1,
      ),
    ];

    await pumpApp(
      tester,
      const HomeScreen(),
      imageCacheMock: mockImageCache,
      overrides: [
        inventoryWithProductProvider.overrideWith((ref) => items),
        inventoryListProvider.overrideWith(
          (ref) => <Map<String, dynamic>>[
            {'id': 1, 'name': 'Home'},
          ],
        ),
        activeInventoryProvider.overrideWith(FakeActiveInventoryNotifier.new),
        productRepositoryProvider.overrideWithValue(mockRepo),
      ],
    );

    // Long-press the first card.
    await tester.longPress(find.byType(InventoryCard).first);
    await tester.pumpAndSettle();

    // Selection mode should be active: checkboxes visible.
    expect(find.byType(Checkbox), findsNWidgets(2));

    // The first checkbox should be checked.
    final firstCheckbox = tester.widget<Checkbox>(
      find.byType(Checkbox).first,
    );
    expect(firstCheckbox.value, isTrue);
  });

  testWidgets('tap still navigates when not in selection mode', (
    tester,
  ) async {
    final mockRepo = createMockProductRepository();
    const product = Product(barcode: '1', name: 'Item A');
    when(() => mockRepo.getProduct('1')).thenAnswer((_) async => product);
    when(
      () => mockRepo.getInventoryForBarcode(
        any(),
        inventoryId: any(named: 'inventoryId'),
      ),
    ).thenAnswer((_) async => <InventoryItem>[]);

    final items = [
      const InventoryWithProduct(
        barcode: '1',
        quantity: 1,
        unit: 'pcs',
        location: 'pantry',
        id: 1,
        productName: 'Item A',
        notes: 'test',
        dateAdded: 0,
        inventoryId: 1,
      ),
    ];

    await pumpApp(
      tester,
      const HomeScreen(),
      imageCacheMock: mockImageCache,
      overrides: [
        inventoryWithProductProvider.overrideWith((ref) => items),
        inventoryListProvider.overrideWith(
          (ref) => <Map<String, dynamic>>[
            {'id': 1, 'name': 'Home'},
          ],
        ),
        activeInventoryProvider.overrideWith(FakeActiveInventoryNotifier.new),
        productRepositoryProvider.overrideWithValue(mockRepo),
      ],
    );

    await tester.tap(find.byType(InventoryCard));
    await tester.pumpAndSettle();

    expect(find.byType(ProductDetailScreen), findsOneWidget);
  });

  group('quick-add produce carousel', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets(
      'tapping produce chip resolves and navigates to ProductDetailScreen',
      (
        tester,
      ) async {
        final mockRepo = createMockProductRepository();
        const product = Product(
          barcode: 'produce-Apple',
          name: 'Apple',
          productType: ProductType.produce,
          source: 'manual',
        );
        when(
          () => mockRepo.resolveProduceProduct('Apple'),
        ).thenAnswer((_) async => product);
        when(
          () => mockRepo.getInventoryForBarcode(
            any(),
            inventoryId: any(named: 'inventoryId'),
          ),
        ).thenAnswer((_) async => <InventoryItem>[]);

        await pumpApp(
          tester,
          const HomeScreen(),
          imageCacheMock: mockImageCache,
          overrides: [
            inventoryWithProductProvider.overrideWith(
              (ref) => <InventoryWithProduct>[],
            ),
            inventoryListProvider.overrideWith(
              (ref) => <Map<String, dynamic>>[],
            ),
            activeInventoryProvider.overrideWith(
              FakeActiveInventoryNotifier.new,
            ),
            productRepositoryProvider.overrideWithValue(mockRepo),
          ],
        );

        // Wait for _loadQuickAddItems to populate the carousel
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump();

        expect(find.text('Apple'), findsOneWidget);

        await tester.tap(find.text('Apple'));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        verify(() => mockRepo.resolveProduceProduct('Apple')).called(1);
        expect(find.byType(ProductDetailScreen), findsOneWidget);
      },
    );

    testWidgets('shows loading spinner on tapped chip while resolving', (
      tester,
    ) async {
      final mockRepo = createMockProductRepository();
      final completer = Completer<Product>();
      when(
        () => mockRepo.resolveProduceProduct('Apple'),
      ).thenAnswer((_) => completer.future);

      await pumpApp(
        tester,
        const HomeScreen(),
        imageCacheMock: mockImageCache,
        overrides: [
          inventoryWithProductProvider.overrideWith(
            (ref) => <InventoryWithProduct>[],
          ),
          inventoryListProvider.overrideWith(
            (ref) => <Map<String, dynamic>>[],
          ),
          activeInventoryProvider.overrideWith(
            FakeActiveInventoryNotifier.new,
          ),
          productRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );

      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();

      await tester.tap(find.text('Apple'));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error snackbar when resolveProduceProduct fails', (
      tester,
    ) async {
      final mockRepo = createMockProductRepository();
      when(
        () => mockRepo.resolveProduceProduct('Apple'),
      ).thenThrow(Exception('Network error'));

      await pumpApp(
        tester,
        const HomeScreen(),
        imageCacheMock: mockImageCache,
        overrides: [
          inventoryWithProductProvider.overrideWith(
            (ref) => <InventoryWithProduct>[],
          ),
          inventoryListProvider.overrideWith(
            (ref) => <Map<String, dynamic>>[],
          ),
          activeInventoryProvider.overrideWith(
            FakeActiveInventoryNotifier.new,
          ),
          productRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );

      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();

      await tester.tap(find.text('Apple'));
      await tester.pumpAndSettle();

      expect(find.text('Could not create inventory.'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('rapid tap same chip does not call resolve twice', (
      tester,
    ) async {
      final mockRepo = createMockProductRepository();
      final completer = Completer<Product>();
      when(
        () => mockRepo.resolveProduceProduct('Apple'),
      ).thenAnswer((_) => completer.future);

      await pumpApp(
        tester,
        const HomeScreen(),
        imageCacheMock: mockImageCache,
        overrides: [
          inventoryWithProductProvider.overrideWith(
            (ref) => <InventoryWithProduct>[],
          ),
          inventoryListProvider.overrideWith(
            (ref) => <Map<String, dynamic>>[],
          ),
          activeInventoryProvider.overrideWith(
            FakeActiveInventoryNotifier.new,
          ),
          productRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );

      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();

      await tester.tap(find.text('Apple'));
      await tester.pump();
      // Second tap: text is now replaced by spinner, tap the first chip
      await tester.tap(find.byType(ActionChip).first);
      await tester.pump();

      verify(() => mockRepo.resolveProduceProduct('Apple')).called(1);
    });
  });

  group('background refresh — overdue and pull-to-refresh', () {
    testWidgets(
      'overdue check calls refreshInventoryProducts (not background variant)',
      (tester) async {
        final mockRepo = createMockProductRepository();
        when(mockRepo.isCacheOverdue).thenAnswer((_) async => true);
        when(
          () => mockRepo.refreshInventoryProducts(any()),
        ).thenAnswer((_) async => 1);
        when(mockRepo.setLastRefreshTime).thenAnswer((_) async {});

        await pumpApp(
          tester,
          const HomeScreen(),
          imageCacheMock: mockImageCache,
          overrides: [
            inventoryWithProductProvider.overrideWith(
              (ref) => <InventoryWithProduct>[],
            ),
            inventoryListProvider.overrideWith(
              (ref) => <Map<String, dynamic>>[],
            ),
            activeInventoryProvider.overrideWith(
              FakeActiveInventoryNotifier.new,
            ),
            hasConnectionProvider.overrideWith(
              (ref) => Future.value(true),
            ),
            productRepositoryProvider.overrideWithValue(mockRepo),
          ],
        );

        // Wait for initState → addPostFrameCallback → _refreshIfOverdue
        await tester.pumpAndSettle();

        verify(() => mockRepo.refreshInventoryProducts(any())).called(1);
        verifyNever(() => mockRepo.refreshInventoryProductsBackground(any()));
      },
    );

    testWidgets(
      'pull-to-refresh awaits refreshInventoryProducts then invalidates',
      (tester) async {
        final mockRepo = createMockProductRepository();
        final refreshCompleter = Completer<int>();
        when(
          () => mockRepo.refreshInventoryProducts(any()),
        ).thenAnswer((_) => refreshCompleter.future);
        when(mockRepo.setLastRefreshTime).thenAnswer((_) async {});

        await pumpApp(
          tester,
          const HomeScreen(),
          imageCacheMock: mockImageCache,
          settle: false,
          overrides: [
            inventoryWithProductProvider.overrideWith(
              (ref) => <InventoryWithProduct>[
                testItem('Existing', barcode: '1'),
              ],
            ),
            inventoryListProvider.overrideWith(
              (ref) => <Map<String, dynamic>>[
                {'id': 1, 'name': 'Home'},
              ],
            ),
            activeInventoryProvider.overrideWith(
              FakeActiveInventoryNotifier.new,
            ),
            hasConnectionProvider.overrideWith(
              (ref) => Future.value(true),
            ),
            productRepositoryProvider.overrideWithValue(mockRepo),
          ],
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        // Verify the provider loaded data
        expect(find.text('Existing'), findsOneWidget);

        // Drag down on RefreshIndicator to trigger pull-to-refresh
        await tester.fling(
          find.byType(RefreshIndicator),
          const Offset(0, 300),
          1000,
        );
        await tester.pump();

        // Refresh shouldn't have completed yet — provider shouldn't re-fetch
        expect(find.text('Existing'), findsOneWidget);

        // Complete the refresh
        refreshCompleter.complete(1);
        await tester.pumpAndSettle();

        // Verify the correct methods were called
        verify(() => mockRepo.refreshInventoryProducts(any())).called(1);
        verifyNever(() => mockRepo.refreshInventoryProductsBackground(any()));
      },
    );
  });

  group('FAB scanner flow — add item and pop back', () {
    testWidgets(
      'returns to HomeScreen without unhandled exceptions',
      (tester) async {
        final mockRepo = createMockProductRepository();
        when(
          () => mockRepo.getProduct('123'),
        ).thenAnswer(
          (_) async => const Product(name: 'Bisnaguinha', barcode: '123'),
        );
        when(
          () => mockRepo.getInventoryForBarcode(
            any(),
            inventoryId: any(named: 'inventoryId'),
          ),
        ).thenAnswer((_) async => []);

        await pumpApp(
          tester,
          const HomeScreen(),
          imageCacheMock: mockImageCache,
          overrides: [
            inventoryWithProductProvider.overrideWith(
              (ref) => <InventoryWithProduct>[],
            ),
            inventoryListProvider.overrideWith(
              (ref) => <Map<String, dynamic>>[],
            ),
            activeInventoryProvider.overrideWith(
              FakeActiveInventoryNotifier.new,
            ),
            hasConnectionProvider.overrideWith(
              (ref) => Future.value(true),
            ),
            productRepositoryProvider.overrideWithValue(mockRepo),
          ],
        );

        // Scan → ProductDetailScreen
        await tester.tap(find.byType(FloatingActionButton));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        tester
            .state<NavigatorState>(find.byType(Navigator))
            .pop(const BarcodeResult('123'));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        // ProductDetailScreen should open.
        expect(find.byType(ProductDetailScreen), findsOneWidget);

        // Wait for all async operations to complete
        await tester.pumpAndSettle();

        // Pop ProductDetailScreen back to HomeScreen
        tester.state<NavigatorState>(find.byType(Navigator)).pop();
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        // pumpAndSettle will throw if setState-during-build occurs
        await tester.pumpAndSettle();
        expect(find.byType(HomeScreen), findsOneWidget);
      },
    );
  });
}
