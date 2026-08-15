import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pantry_app/models/price.dart';
import 'package:pantry_app/models/shopping_item.dart';
import 'package:pantry_app/providers/active_inventory_provider.dart';
import 'package:pantry_app/providers/price_provider.dart';
import 'package:pantry_app/providers/price_repository_provider.dart';
import 'package:pantry_app/providers/settings_provider.dart';
import 'package:pantry_app/providers/shopping_list_provider.dart';
import 'package:pantry_app/providers/shopping_list_service_provider.dart';
import 'package:pantry_app/services/price_repository.dart';
import 'package:pantry_app/services/shopping_list_service.dart';
import 'package:pantry_app/widgets/shopping_item_tile.dart';

import '../helpers/pump_app.dart';

class MockShoppingListService extends Mock implements ShoppingListService {}

class MockPriceRepository extends Mock implements PriceRepository {}

class _FakeActiveInventoryNotifier extends ActiveInventoryNotifier {
  @override
  Future<int> build() async => 1;
}

class _FakeSettingsNotifier extends SettingsNotifier {
  _FakeSettingsNotifier(this.settings);

  final Settings settings;

  @override
  Future<Settings> build() async => settings;
}

void main() {
  setUpAll(() {
    registerFallbackValue(const ShoppingItem(name: ''));
  });

  Future<void> pumpTile(
    WidgetTester tester, {
    required ShoppingItem item,
    Settings settings = const Settings(),
    MockPriceRepository? priceRepo,
  }) async {
    final repo = priceRepo ?? MockPriceRepository();
    when(() => repo.formatPrice(any(), any())).thenAnswer(
      (inv) => '\$${inv.positionalArguments[0]}',
    );
    await pumpApp(
      tester,
      ShoppingItemTile(item: item),
      overrides: [
        settingsProvider.overrideWith(() => _FakeSettingsNotifier(settings)),
        activeInventoryProvider.overrideWith(
          _FakeActiveInventoryNotifier.new,
        ),
        latestPriceProvider((
          item.barcode ?? '',
          1,
        )).overrideWith((ref) => null),
        priceRepositoryProvider.overrideWithValue(repo),
        shoppingListServiceProvider.overrideWithValue(
          MockShoppingListService(),
        ),
        shoppingListProvider.overrideWith((ref) => <ShoppingItem>[]),
      ],
    );
  }

  group('ShoppingItemTile', () {
    testWidgets('shows entered price without an Est. prefix', (tester) async {
      const item = ShoppingItem(
        name: 'Milk',
        barcode: '123',
        priceAmount: 4.99,
        priceCurrency: 'USD',
      );
      await pumpTile(tester, item: item);

      expect(find.text(r'Est. $4.99'), findsNothing);
      expect(find.text(r'$4.99'), findsOneWidget);
    });

    testWidgets(
      'shows Est. price when tracked price exists and no entered price',
      (tester) async {
        const item = ShoppingItem(name: 'Milk', barcode: '123');
        final repo = MockPriceRepository();
        when(() => repo.formatPrice(any(), any())).thenAnswer((_) => r'$4.99');
        await pumpApp(
          tester,
          const ShoppingItemTile(
            item: ShoppingItem(name: 'Milk', barcode: '123'),
          ),
          overrides: [
            settingsProvider.overrideWith(
              () => _FakeSettingsNotifier(
                const Settings(priceTrackingEnabled: true),
              ),
            ),
            activeInventoryProvider.overrideWith(
              _FakeActiveInventoryNotifier.new,
            ),
            latestPriceProvider((item.barcode!, 1)).overrideWith(
              (ref) => const Price(barcode: '123', price: 4.99),
            ),
            priceRepositoryProvider.overrideWithValue(repo),
            shoppingListServiceProvider.overrideWithValue(
              MockShoppingListService(),
            ),
            shoppingListProvider.overrideWith((ref) => <ShoppingItem>[]),
          ],
        );

        expect(find.text(r'Est. $4.99'), findsOneWidget);
      },
    );

    testWidgets('hides estimate when no tracked price', (tester) async {
      const item = ShoppingItem(name: 'Milk', barcode: '123');
      await pumpTile(
        tester,
        item: item,
        settings: const Settings(priceTrackingEnabled: true),
      );

      expect(find.textContaining('Est.'), findsNothing);
    });

    testWidgets('hides estimate when price tracking is disabled', (
      tester,
    ) async {
      const item = ShoppingItem(name: 'Milk', barcode: '123');
      await pumpTile(tester, item: item);

      expect(find.textContaining('Est.'), findsNothing);
    });

    testWidgets('hides estimate for items without a barcode', (tester) async {
      const item = ShoppingItem(name: 'Milk');
      await pumpTile(
        tester,
        item: item,
        settings: const Settings(priceTrackingEnabled: true),
      );

      expect(find.textContaining('Est.'), findsNothing);
    });

    testWidgets('does not overflow with a long name and estimate', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const item = ShoppingItem(
        name: 'Creme de Leite Qualitá Ultra Pasteurizado',
        barcode: '123',
      );
      final repo = MockPriceRepository();
      when(() => repo.formatPrice(any(), any())).thenAnswer((_) => r'$4.99');
      await pumpApp(
        tester,
        const ShoppingItemTile(
          item: ShoppingItem(
            name: 'Creme de Leite Qualitá Ultra Pasteurizado',
            barcode: '123',
          ),
        ),
        overrides: [
          settingsProvider.overrideWith(
            () => _FakeSettingsNotifier(
              const Settings(priceTrackingEnabled: true),
            ),
          ),
          activeInventoryProvider.overrideWith(
            _FakeActiveInventoryNotifier.new,
          ),
          latestPriceProvider((item.barcode!, 1)).overrideWith(
            (ref) => const Price(barcode: '123', price: 4.99),
          ),
          priceRepositoryProvider.overrideWithValue(repo),
          shoppingListServiceProvider.overrideWithValue(
            MockShoppingListService(),
          ),
          shoppingListProvider.overrideWith((ref) => <ShoppingItem>[]),
        ],
      );

      expect(tester.takeException(), isNull);
      expect(find.textContaining('Est.'), findsOneWidget);
    });

    testWidgets('does not overflow a purchased item with a long name', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const item = ShoppingItem(
        name: 'Creme de Leite Qualitá Ultra Pasteurizado',
        barcode: '123',
        isPurchased: true,
      );
      await pumpTile(tester, item: item);

      expect(tester.takeException(), isNull);
    });
  });
}
