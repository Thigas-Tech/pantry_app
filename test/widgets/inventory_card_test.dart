import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pantry_app/models/inventory_item.dart';
import 'package:pantry_app/models/inventory_with_product.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/providers/product_repository_provider.dart';
import 'package:pantry_app/screens/product_detail_screen.dart';
import 'package:pantry_app/widgets/inventory_card.dart';
import '../helpers/pump_app.dart';

InventoryWithProduct createItem({
  String name = 'Test Item',
  String barcode = '123',
  double quantity = 2,
  String unit = 'pcs',
  String location = 'pantry',
  String? expiryDate,
  String? imageUrl,
  String? nutriscoreGrade,
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
    productImageUrl: imageUrl,
    nutriscoreGrade: nutriscoreGrade,
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

    final icon = tester.widget<Icon>(
      find.descendant(
        of: find.byType(InventoryCard),
        matching: find.byType(Icon).last,
      ),
    );
    expect(icon.color, Colors.red);
  });

  testWidgets('shows fallback icon when image cache returns null', (
    tester,
  ) async {
    final item = createItem(
      name: 'NoImage',
      imageUrl: 'https://example.com/img.jpg',
    );

    await pumpApp(
      tester,
      InventoryCard(item: item),
      imageCacheMock: mockImageCache,
      overrides: [
        productRepositoryProvider.overrideWithValue(MockProductRepository()),
      ],
    );

    // Fallback icon is always present because cacheImage returns null.
    expect(find.byIcon(Icons.fastfood), findsOneWidget);
  });

  testWidgets('tapping card navigates to ProductDetailScreen', (tester) async {
    final item = createItem(barcode: '456');
    final mockRepo = MockProductRepository();
    const product = Product(barcode: '456', name: 'Toast');
    when(() => mockRepo.getProduct('456')).thenAnswer((_) async => product);
    when(
      () => mockRepo.getInventoryForBarcode(
        any(),
        inventoryId: any(named: 'inventoryId'),
      ),
    ).thenAnswer((_) async => <InventoryItem>[]);

    await pumpApp(
      tester,
      InventoryCard(item: item),
      imageCacheMock: mockImageCache,
      overrides: [
        productRepositoryProvider.overrideWithValue(mockRepo),
      ],
    );

    await tester.tap(find.byType(InventoryCard));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(ProductDetailScreen), findsOneWidget);
    expect(find.text('Toast'), findsOneWidget);
  });

  testWidgets('long-press triggers onLongPress callback', (tester) async {
    final item = createItem(name: 'LongPressItem');
    bool longPressed = false;

    await pumpApp(
      tester,
      InventoryCard(
        item: item,
        onLongPress: () => longPressed = true,
      ),
      imageCacheMock: mockImageCache,
      overrides: [
        productRepositoryProvider.overrideWithValue(MockProductRepository()),
      ],
    );

    await tester.longPress(find.byType(InventoryCard));
    await tester.pump();

    expect(longPressed, isTrue);
  });

  testWidgets('long-press suppressed when showCheckbox is true', (
    tester,
  ) async {
    final item = createItem(name: 'SelectItem');
    bool longPressed = false;

    await pumpApp(
      tester,
      InventoryCard(
        item: item,
        showCheckbox: true,
        onLongPress: () => longPressed = true,
      ),
      imageCacheMock: mockImageCache,
      overrides: [
        productRepositoryProvider.overrideWithValue(MockProductRepository()),
      ],
    );

    await tester.longPress(find.byType(InventoryCard));
    await tester.pump();

    expect(longPressed, isFalse);
  });
}
