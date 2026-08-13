import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pantry_app/models/inventory_item.dart';
import 'package:pantry_app/models/inventory_with_product.dart';
import 'package:pantry_app/models/price.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/models/product_type.dart';
import 'package:pantry_app/providers/price_provider.dart';
import 'package:pantry_app/providers/product_repository_provider.dart';
import 'package:pantry_app/providers/settings_provider.dart';
import 'package:pantry_app/screens/product_detail_screen.dart';
import 'package:pantry_app/widgets/inventory_card.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/pump_app.dart';

class _FakeSettingsNotifierImperial extends SettingsNotifier {
  @override
  Future<Settings> build() async => const Settings(
    unitSystem: UnitSystem.imperial,
    preferredWeightUnit: WeightUnitPreference.auto,
    preferredVolumeUnit: VolumeUnitPreference.auto,
  );
}

InventoryWithProduct createItem({
  String? name = 'Test Item',
  String barcode = '123',
  double quantity = 2,
  String unit = 'pcs',
  String location = 'pantry',
  String? expiryDate,
  String? imageUrl,
  String? nutriscoreGrade,
  ProductType? productType,
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
    productType: productType,
  );
}

/// A settings notifier whose value can be pushed from the test.
class _MutableSettingsNotifier extends SettingsNotifier {
  _MutableSettingsNotifier([Settings initial = const Settings()])
    : _settings = initial;

  Settings _settings;

  @override
  Future<Settings> build() async => _settings;

  void push(Settings settings) {
    _settings = settings;
    state = AsyncValue.data(settings);
  }
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
    expect(find.textContaining('3 L'), findsOneWidget);
    expect(find.textContaining('Pantry'), findsOneWidget);
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
    var longPressed = false;

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
    var longPressed = false;

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

  group('produce localization', () {
    testWidgets('localizes produce item name in Portuguese', (tester) async {
      final item = createItem(
        name: 'Apple',
        productType: ProductType.produce,
      );

      await pumpApp(
        tester,
        InventoryCard(item: item),
        locale: const Locale('pt'),
        imageCacheMock: mockImageCache,
        overrides: [
          productRepositoryProvider.overrideWithValue(
            MockProductRepository(),
          ),
        ],
      );

      expect(find.text('Maça'), findsOneWidget);
      expect(find.text('Apple'), findsNothing);
    });

    testWidgets('shows English name for produce item in English locale', (
      tester,
    ) async {
      final item = createItem(
        name: 'Carrot',
        productType: ProductType.produce,
      );

      await pumpApp(
        tester,
        InventoryCard(item: item),
        imageCacheMock: mockImageCache,
        overrides: [
          productRepositoryProvider.overrideWithValue(
            MockProductRepository(),
          ),
        ],
      );

      expect(find.text('Carrot'), findsOneWidget);
    });

    testWidgets('does not localize non-produce item names', (tester) async {
      final item = createItem(
        name: 'Apple Juice',
        productType: ProductType.barcoded,
      );

      await pumpApp(
        tester,
        InventoryCard(item: item),
        locale: const Locale('pt'),
        imageCacheMock: mockImageCache,
        overrides: [
          productRepositoryProvider.overrideWithValue(
            MockProductRepository(),
          ),
        ],
      );

      // Non-produce items should show the stored name, not localized.
      expect(find.text('Apple Juice'), findsOneWidget);
    });

    testWidgets('falls back to barcode when productName is null', (
      tester,
    ) async {
      final item = createItem(
        name: null,
        productType: ProductType.produce,
        barcode: 'produce-Banana',
      );

      await pumpApp(
        tester,
        InventoryCard(item: item),
        imageCacheMock: mockImageCache,
        overrides: [
          productRepositoryProvider.overrideWithValue(
            MockProductRepository(),
          ),
        ],
      );

      expect(find.text('produce-Banana'), findsOneWidget);
    });
  });

  group('unit conversion', () {
    testWidgets('converts metric to imperial under imperial settings', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final item = createItem(name: 'Milk', quantity: 2000, unit: 'g');

      await pumpApp(
        tester,
        InventoryCard(item: item),
        imageCacheMock: mockImageCache,
        overrides: [
          productRepositoryProvider.overrideWithValue(
            MockProductRepository(),
          ),
          settingsProvider.overrideWith(
            _FakeSettingsNotifierImperial.new,
          ),
        ],
      );

      // 2000 g -> ~4 lb (auto: >16 oz → lb, rounded to whole)
      expect(find.textContaining('4 lb'), findsOneWidget);
    });

    testWidgets('pieces remain unchanged under imperial settings', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final item = createItem(name: 'Eggs', quantity: 6);

      await pumpApp(
        tester,
        InventoryCard(item: item),
        imageCacheMock: mockImageCache,
        overrides: [
          productRepositoryProvider.overrideWithValue(
            MockProductRepository(),
          ),
          settingsProvider.overrideWith(
            _FakeSettingsNotifierImperial.new,
          ),
        ],
      );

      expect(find.textContaining('6 pcs'), findsOneWidget);
    });

    testWidgets('quantity unchanged in default metric settings', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final item = createItem(name: 'Water', quantity: 1.5, unit: 'L');

      await pumpApp(
        tester,
        InventoryCard(item: item),
        imageCacheMock: mockImageCache,
        overrides: [
          productRepositoryProvider.overrideWithValue(
            MockProductRepository(),
          ),
        ],
      );

      // Under metric, 1.5 L should remain as "1.5 L"
      expect(find.textContaining('1.5 L'), findsOneWidget);
    });
  });

  group('price line scoping', () {
    testWidgets('shows the price from the active inventory key', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final item = createItem(name: 'Milk', quantity: 1, unit: 'L');

      await pumpApp(
        tester,
        InventoryCard(item: item),
        imageCacheMock: mockImageCache,
        overrides: [
          productRepositoryProvider.overrideWithValue(
            MockProductRepository(),
          ),
          settingsProvider.overrideWith(
            _FakePriceTrackingSettingsNotifier.new,
          ),
          latestPriceProvider(('123', 1)).overrideWith(
            (ref) => const Price(
              barcode: '123',
              price: 4.99,
            ),
          ),
        ],
      );

      expect(find.text(r'$4.99'), findsOneWidget);
    });

    testWidgets(
      'shows the per-unit price when the price has a package size',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final item = createItem(name: 'Eggs', quantity: 12, unit: 'pieces');

        await pumpApp(
          tester,
          InventoryCard(item: item),
          imageCacheMock: mockImageCache,
          overrides: [
            productRepositoryProvider.overrideWithValue(
              MockProductRepository(),
            ),
            settingsProvider.overrideWith(
              _FakePriceTrackingSettingsNotifier.new,
            ),
            latestPriceProvider(('123', 1)).overrideWith(
              (ref) => const Price(
                barcode: '123',
                price: 9.99,
                packageQuantity: 12,
                packageUnit: 'pieces',
              ),
            ),
          ],
        );

        expect(find.text(r'$9.99'), findsOneWidget);
        expect(find.textContaining('/unit'), findsOneWidget);
      },
    );

    testWidgets('hides the per-unit price without a package size', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final item = createItem(name: 'Eggs', quantity: 12, unit: 'pieces');

      await pumpApp(
        tester,
        InventoryCard(item: item),
        imageCacheMock: mockImageCache,
        overrides: [
          productRepositoryProvider.overrideWithValue(
            MockProductRepository(),
          ),
          settingsProvider.overrideWith(
            _FakePriceTrackingSettingsNotifier.new,
          ),
          latestPriceProvider(('123', 1)).overrideWith(
            (ref) => const Price(barcode: '123', price: 9.99),
          ),
        ],
      );

      expect(find.text(r'$9.99'), findsOneWidget);
      expect(find.textContaining('/unit'), findsNothing);
    });

    testWidgets('hides the price when the active inventory has none', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final item = createItem(name: 'Milk', quantity: 1, unit: 'L');

      await pumpApp(
        tester,
        InventoryCard(item: item),
        imageCacheMock: mockImageCache,
        overrides: [
          productRepositoryProvider.overrideWithValue(
            MockProductRepository(),
          ),
          settingsProvider.overrideWith(
            _FakePriceTrackingSettingsNotifier.new,
          ),
          latestPriceProvider(('123', 1)).overrideWith(
            (ref) => null,
          ),
        ],
      );

      expect(find.text(r'$4.99'), findsNothing);
    });
  });
  group('settings select reactivity', () {
    testWidgets('reflects unit-system changes and survives unrelated setting '
        'changes', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final notifier = _MutableSettingsNotifier();
      final item = createItem(name: 'Milk', quantity: 1, unit: 'L');

      await pumpApp(
        tester,
        InventoryCard(item: item),
        imageCacheMock: mockImageCache,
        overrides: [
          productRepositoryProvider.overrideWithValue(
            MockProductRepository(),
          ),
          settingsProvider.overrideWith(() => notifier),
          latestPriceProvider(('123', 1)).overrideWith((ref) => null),
        ],
      );

      expect(find.textContaining('L · Pantry'), findsOneWidget);

      notifier.push(
        const Settings(amoledDarkMode: true),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.textContaining('L · Pantry'), findsOneWidget);

      notifier.push(
        const Settings(unitSystem: UnitSystem.imperial),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.textContaining('L · Pantry'), findsNothing);
    });
  });
}

class _FakePriceTrackingSettingsNotifier extends SettingsNotifier {
  @override
  Future<Settings> build() async => const Settings(priceTrackingEnabled: true);
}
