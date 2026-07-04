/// @file HomeScreen widget tests.
///
/// Tests for the main dashboard screen.  The screen displays:
///   - A loading spinner while the inventory future is pending.
///   - An error message when the inventory future fails.
///   - The empty‑state widget when the inventory list is empty.
///   - Items grouped by expiry status (Expired, Expiring soon, Good).
///   - An inventory switcher icon when more than one inventory exists.
///
/// All tests use the shared `pumpApp` helper.  We override the relevant
/// Riverpod providers (`inventoryWithProductProvider`, `inventoryListProvider`,
/// `activeInventoryProvider`, `productRepositoryProvider`) with fake/mocked
/// values.  The `imageCacheProvider` is stubbed via the harness to prevent
/// errors inside `InventoryCard`'s `FutureBuilder`.
///
/// The loading test uses `settle: false` to keep the future pending, then
/// completes it manually to avoid a “pending timer” error.

// (The linter incorrectly flags the testWidgets callbacks because it doesn't
//  see the `await` inside the body.  We keep the ignore until the analyzer is
//  updated.)
// ignore_for_file: unnecessary_async
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pantry_app/models/inventory_with_product.dart';
import 'package:pantry_app/providers/active_inventory_provider.dart';
import 'package:pantry_app/providers/inventory_provider.dart';
import 'package:pantry_app/providers/product_repository_provider.dart';
import 'package:pantry_app/screens/home_screen.dart';
import '../helpers/pump_app.dart';

/// A fake [ActiveInventoryNotifier] that always returns 1.
class FakeActiveInventoryNotifier extends ActiveInventoryNotifier {
  @override
  int build() => 1;
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

  /// Loading state: a [CircularProgressIndicator] appears while the inventory
  /// future is still pending.  We keep the future open with a [Completer] and
  /// check the indicator, then complete it to clean up.
  testWidgets('shows loading spinner when inventory is loading', (
    tester,
  ) async {
    final completer = Completer<List<InventoryWithProduct>>();

    await pumpApp(
      tester,
      const HomeScreen(),
      imageCacheMock: mockImageCache,
      settle: false, // don't wait for the future to complete
      overrides: [
        inventoryWithProductProvider.overrideWith((ref) => completer.future),
        inventoryListProvider.overrideWith(
          (ref) async => <Map<String, dynamic>>[],
        ),
        activeInventoryProvider.overrideWith(FakeActiveInventoryNotifier.new),
        productRepositoryProvider.overrideWithValue(MockProductRepository()),
      ],
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete([]);
    await tester.pumpAndSettle(); // allow the widget to rebuild
  });

  /// Error state: when the inventory future completes with an error, the error
  /// message is displayed in the centre of the screen.
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
          (ref) async => <Map<String, dynamic>>[],
        ),
        activeInventoryProvider.overrideWith(FakeActiveInventoryNotifier.new),
        productRepositoryProvider.overrideWithValue(MockProductRepository()),
      ],
    );

    expect(find.text('Error: test error'), findsOneWidget);
  });

  /// Empty state: when the inventory list is empty, the [EmptyPantry] widget
  /// appears with the correct title.
  testWidgets('shows empty state when inventory list is empty', (tester) async {
    await pumpApp(
      tester,
      const HomeScreen(),
      imageCacheMock: mockImageCache,
      overrides: [
        inventoryWithProductProvider.overrideWith(
          (ref) async => <InventoryWithProduct>[],
        ),
        inventoryListProvider.overrideWith(
          (ref) async => <Map<String, dynamic>>[],
        ),
        activeInventoryProvider.overrideWith(FakeActiveInventoryNotifier.new),
        productRepositoryProvider.overrideWithValue(MockProductRepository()),
      ],
    );

    expect(find.text('Your pantry is empty'), findsOneWidget);
  });

  /// Expiry grouping: items are placed under the correct section headers
  /// "Expired", "Expiring soon", and "Good".  A fourth item without an
  /// expiry date falls into the "Good" group.
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
        inventoryWithProductProvider.overrideWith((ref) async => items),
        inventoryListProvider.overrideWith(
          (ref) async => <Map<String, dynamic>>[
            {'id': 1, 'name': 'Home'},
          ],
        ),
        activeInventoryProvider.overrideWith(FakeActiveInventoryNotifier.new),
        productRepositoryProvider.overrideWithValue(MockProductRepository()),
      ],
    );

    expect(find.text('Expired'), findsOneWidget);
    expect(find.text('Expiring soon'), findsOneWidget);
    expect(find.text('Good'), findsOneWidget);
  });

  /// Inventory switcher: when two inventories ("Home" and "Work") exist, the
  /// `swap_horiz` icon is visible in the app bar.
  testWidgets('shows inventory switcher when multiple inventories exist', (
    tester,
  ) async {
    await pumpApp(
      tester,
      const HomeScreen(),
      imageCacheMock: mockImageCache,
      overrides: [
        inventoryWithProductProvider.overrideWith(
          (ref) async => <InventoryWithProduct>[],
        ),
        inventoryListProvider.overrideWith(
          (ref) async => <Map<String, dynamic>>[
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

  /// When only one inventory exists, the switcher icon must not appear.
  testWidgets('does not show switcher when only one inventory exists', (
    tester,
  ) async {
    await pumpApp(
      tester,
      const HomeScreen(),
      imageCacheMock: mockImageCache,
      overrides: [
        inventoryWithProductProvider.overrideWith(
          (ref) async => <InventoryWithProduct>[],
        ),
        inventoryListProvider.overrideWith(
          (ref) async => <Map<String, dynamic>>[
            {'id': 1, 'name': 'Home'},
          ],
        ),
        activeInventoryProvider.overrideWith(FakeActiveInventoryNotifier.new),
        productRepositoryProvider.overrideWithValue(MockProductRepository()),
      ],
    );

    expect(find.byIcon(Icons.swap_horiz), findsNothing);
  });
}
