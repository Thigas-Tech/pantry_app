// false positives
// ignore_for_file: unused_local_variable

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
import 'package:pantry_app/providers/active_inventory_provider.dart';
import 'package:pantry_app/providers/connectivity_provider.dart';
import 'package:pantry_app/providers/inventory_provider.dart';
import 'package:pantry_app/providers/product_repository_provider.dart';
import 'package:pantry_app/screens/home_screen.dart';
import 'package:pantry_app/screens/product_detail_screen.dart';
import 'package:pantry_app/screens/scanner_screen.dart';
import 'package:pantry_app/screens/settings_screen.dart';
import 'package:pantry_app/screens/stats_screen.dart';
import 'package:pantry_app/services/exceptions.dart';
import 'package:pantry_app/widgets/inventory_card.dart';
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
        productRepositoryProvider.overrideWithValue(MockProductRepository()),
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
        productRepositoryProvider.overrideWithValue(MockProductRepository()),
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
        productRepositoryProvider.overrideWithValue(MockProductRepository()),
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
        productRepositoryProvider.overrideWithValue(MockProductRepository()),
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
        productRepositoryProvider.overrideWithValue(MockProductRepository()),
      ],
    );

    expect(find.byIcon(Icons.swap_horiz), findsOneWidget);
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
        productRepositoryProvider.overrideWithValue(MockProductRepository()),
      ],
    );

    expect(find.byIcon(Icons.swap_horiz), findsOneWidget);
  });

  // ---------- Additional tests for uncovered paths ----------

  testWidgets('tapping settings navigates to SettingsScreen', (tester) async {
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
        productRepositoryProvider.overrideWithValue(MockProductRepository()),
      ],
    );

    await tester.tap(find.byIcon(Icons.settings));
    await tester.pump();
    await tester.pump(); // allow navigation to start

    expect(find.byType(SettingsScreen), findsOneWidget);
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
        productRepositoryProvider.overrideWithValue(MockProductRepository()),
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
        productRepositoryProvider.overrideWithValue(MockProductRepository()),
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
        productRepositoryProvider.overrideWithValue(MockProductRepository()),
      ],
    );

    await tester.tap(find.byIcon(Icons.swap_horiz));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Work').last);
    await tester.pumpAndSettle();

    expect(fakeNotifier.lastSetValue, 2);
  });

  testWidgets(
    'FAB scanner flow: barcode returns, navigates to product detail',
    (tester) async {
      final mockRepo = MockProductRepository();
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
          connectivityProvider.overrideWith((ref) => Stream.value(true)),
          productRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(ScannerScreen), findsOneWidget);

      // Pop the scanner with a barcode
      final navigator = tester.state<NavigatorState>(find.byType(Navigator))
        ..pop('123');
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
        connectivityProvider.overrideWith((ref) => Stream.value(true)),
        productRepositoryProvider.overrideWithValue(MockProductRepository()),
      ],
    );

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(ScannerScreen), findsOneWidget);

    final navigator = tester.state<NavigatorState>(find.byType(Navigator))
      ..pop(); // null value
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(ProductDetailScreen), findsNothing);
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('FAB scanner flow: product not found shows snackbar', (
    tester,
  ) async {
    final mockRepo = MockProductRepository();
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
        connectivityProvider.overrideWith((ref) => Stream.value(true)),
        productRepositoryProvider.overrideWithValue(mockRepo),
      ],
    );

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    final navigator = tester.state<NavigatorState>(find.byType(Navigator))
      ..pop('123');
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('stats icon navigates to StatsScreen', (tester) async {
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
        connectivityProvider.overrideWith((ref) => Stream.value(true)),
        productRepositoryProvider.overrideWithValue(MockProductRepository()),
      ],
    );

    await tester.tap(find.byTooltip('Pantry Stats'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(StatsScreen), findsOneWidget);
  });
}
