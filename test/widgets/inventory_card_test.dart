/// @file InventoryCard widget tests.
///
/// Tests the card that represents one inventory item on the home screen.
/// We validate:
///   - The product name and subtitle (quantity, unit, location) are displayed.
///   - An expiry prefix is shown when an expiry date is provided.
///   - A red dot appears for expired items.
///
/// All tests use the `pumpApp` helper. The `imageCacheProvider` is overridden
/// with a stubbed mock (so `InventoryCard._buildLeadingImage` doesn't crash),
/// and the `productRepositoryProvider` is overridden with a fresh mock in
/// every test to avoid “double override” errors.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pantry_app/models/inventory_with_product.dart';
import 'package:pantry_app/providers/product_repository_provider.dart';
import 'package:pantry_app/widgets/inventory_card.dart';
import '../helpers/pump_app.dart';

/// Creates a fully‑populated [InventoryWithProduct] with the given values.
/// Defaults produce a typical non‑expired item in the pantry.
InventoryWithProduct createItem({
  String name = 'Test Item',
  String barcode = '123',
  double quantity = 2,
  String unit = 'pcs',
  String location = 'pantry',
  String? expiryDate,
}) {
  return InventoryWithProduct(
    id: 1,
    barcode: barcode,
    quantity: quantity,
    unit: unit,
    location: location,
    productName: name,
    expiryDate: expiryDate,
    inventoryId: 1,
  );
}

void main() {
  late MockImageCacheService mockImageCache;

  setUp(() {
    mockImageCache = MockImageCacheService();
    // Stub cacheImage to return null → widget falls back to fallback icon.
    when(
      () => mockImageCache.cacheImage(any(), any()),
    ).thenAnswer((_) async => null);
  });

  /// Checks that the product name, quantity+unit substring, and location
  /// appear. Note that [quantity] is a double, so `3` becomes `"3.0"`.
  testWidgets('displays product name and subtitle', (tester) async {
    final item = createItem(name: 'Milk', quantity: 3, unit: 'L');

    await pumpApp(
      tester,
      InventoryCard(item: item),
      imageCacheMock: mockImageCache,
      overrides: [
        productRepositoryProvider.overrideWithValue(MockProductRepository()),
      ],
    );

    expect(find.text('Milk'), findsOneWidget);
    expect(find.textContaining('3.0 L'), findsOneWidget);
    expect(find.textContaining('pantry'), findsOneWidget);
  });

  /// Verifies that the subtitle includes "Exp: 2026-12-31" when an expiry
  /// date is present.
  testWidgets('shows expiry prefix when date is present', (tester) async {
    final item = createItem(name: 'Cheese', expiryDate: '2026-12-31');

    await pumpApp(
      tester,
      InventoryCard(item: item),
      imageCacheMock: mockImageCache,
      overrides: [
        productRepositoryProvider.overrideWithValue(MockProductRepository()),
      ],
    );

    expect(find.textContaining('Exp: 2026-12-31'), findsOneWidget);
  });

  /// Checks that the trailing circle icon is red when the item is expired
  /// (expiry date before today).
  testWidgets('shows red dot when expired', (tester) async {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final item = createItem(
      name: 'Old Milk',
      expiryDate: yesterday.toIso8601String().substring(0, 10),
    );

    await pumpApp(
      tester,
      InventoryCard(item: item),
      imageCacheMock: mockImageCache,
      overrides: [
        productRepositoryProvider.overrideWithValue(MockProductRepository()),
      ],
    );

    // The last Icon inside InventoryCard should be the trailing dot.
    final icon = tester.widget<Icon>(
      find.descendant(
        of: find.byType(InventoryCard),
        matching: find.byType(Icon).last,
      ),
    );
    expect(icon.color, Colors.red);
  });
}
