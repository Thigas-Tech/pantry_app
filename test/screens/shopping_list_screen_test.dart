import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pantry_app/models/price.dart';
import 'package:pantry_app/models/shopping_item.dart';
import 'package:pantry_app/providers/active_inventory_provider.dart';
import 'package:pantry_app/providers/price_provider.dart';
import 'package:pantry_app/providers/settings_provider.dart';
import 'package:pantry_app/providers/shopping_list_provider.dart';
import 'package:pantry_app/providers/shopping_list_service_provider.dart';
import 'package:pantry_app/screens/shopping_list_screen.dart';
import 'package:pantry_app/services/shopping_list_service.dart';
import 'package:pantry_app/widgets/shopping_item_edit_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/pump_app.dart';

class MockShoppingListService extends Mock implements ShoppingListService {}

class FakeActiveInventoryNotifier extends ActiveInventoryNotifier {
  @override
  Future<int> build() async => 1;
}

class _FakeSettingsNotifierImperial extends SettingsNotifier {
  @override
  Future<Settings> build() async => const Settings(
    unitSystem: UnitSystem.imperial,
    preferredWeightUnit: WeightUnitPreference.auto,
    preferredVolumeUnit: VolumeUnitPreference.auto,
  );
}

class _FakeSettingsTrackingNotifier extends SettingsNotifier {
  @override
  Future<Settings> build() async => const Settings(priceTrackingEnabled: true);
}

void main() {
  setUpAll(() {
    registerFallbackValue(const ShoppingItem(name: ''));
  });

  testWidgets('renders AppBar with shopping list title', (tester) async {
    await pumpApp(
      tester,
      const ShoppingListScreen(),
      overrides: [
        pendingShoppingListProvider.overrideWith(
          (ref) => <ShoppingItem>[],
        ),
        purchasedShoppingListProvider.overrideWith(
          (ref) => <ShoppingItem>[],
        ),
        shoppingListProvider.overrideWith(
          (ref) => <ShoppingItem>[],
        ),
      ],
    );

    expect(find.text('Shopping List'), findsOneWidget);
  });

  testWidgets('shows empty state when no items', (tester) async {
    await pumpApp(
      tester,
      const ShoppingListScreen(),
      overrides: [
        pendingShoppingListProvider.overrideWith(
          (ref) => <ShoppingItem>[],
        ),
        purchasedShoppingListProvider.overrideWith(
          (ref) => <ShoppingItem>[],
        ),
        shoppingListProvider.overrideWith(
          (ref) => <ShoppingItem>[],
        ),
      ],
    );

    expect(find.byIcon(Icons.shopping_cart_outlined), findsOneWidget);
    expect(find.text('Your shopping list is empty'), findsOneWidget);
    expect(
      find.text('Add items from a product or tap + to add manually'),
      findsOneWidget,
    );
  });

  testWidgets('shows pending and purchased items', (tester) async {
    await pumpApp(
      tester,
      const ShoppingListScreen(),
      overrides: [
        pendingShoppingListProvider.overrideWith(
          (ref) => [
            const ShoppingItem(name: 'Milk', quantity: 2, unit: 'pcs'),
          ],
        ),
        purchasedShoppingListProvider.overrideWith(
          (ref) => [
            const ShoppingItem(
              name: 'Bread',
              unit: 'pcs',
              isPurchased: true,
            ),
          ],
        ),
        shoppingListProvider.overrideWith(
          (ref) => [
            const ShoppingItem(name: 'Milk', quantity: 2, unit: 'pcs'),
            const ShoppingItem(
              name: 'Bread',
              unit: 'pcs',
              isPurchased: true,
            ),
          ],
        ),
      ],
    );

    expect(find.text('To buy (1)'), findsOneWidget);
    expect(find.text('Milk'), findsOneWidget);
    expect(find.text('2 pcs'), findsOneWidget);
    expect(find.text('Purchased (1)'), findsOneWidget);
    expect(find.text('Bread'), findsOneWidget);
    expect(find.text('1 pcs'), findsOneWidget);
  });

  testWidgets(
    'shows items from the active inventory with inventoryId',
    (tester) async {
      await pumpApp(
        tester,
        const ShoppingListScreen(),
        overrides: [
          activeInventoryProvider.overrideWith(
            FakeActiveInventoryNotifier.new,
          ),
          pendingShoppingListProvider.overrideWith(
            (ref) => [
              const ShoppingItem(name: 'Inv1 Item', inventoryId: 1),
            ],
          ),
          purchasedShoppingListProvider.overrideWith(
            (ref) => [
              const ShoppingItem(
                name: 'Inv1 Purchased',
                inventoryId: 1,
                isPurchased: true,
              ),
            ],
          ),
          shoppingListProvider.overrideWith(
            (ref) => [
              const ShoppingItem(name: 'Inv1 Item', inventoryId: 1),
              const ShoppingItem(
                name: 'Inv1 Purchased',
                inventoryId: 1,
                isPurchased: true,
              ),
            ],
          ),
        ],
      );

      expect(find.text('Inv1 Item'), findsOneWidget);
      expect(find.text('Inv1 Purchased'), findsOneWidget);
    },
  );

  group('unit conversion', () {
    testWidgets('converts metric item to imperial under imperial settings', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await pumpApp(
        tester,
        const ShoppingListScreen(),
        overrides: [
          pendingShoppingListProvider.overrideWith(
            (ref) => [
              const ShoppingItem(name: 'Flour', quantity: 500, unit: 'g'),
            ],
          ),
          purchasedShoppingListProvider.overrideWith(
            (ref) => <ShoppingItem>[],
          ),
          shoppingListProvider.overrideWith(
            (ref) => [
              const ShoppingItem(name: 'Flour', quantity: 500, unit: 'g'),
            ],
          ),
          settingsProvider.overrideWith(
            _FakeSettingsNotifierImperial.new,
          ),
        ],
      );

      // 500 g -> ~17.6 oz (>=16) so auto -> lb: 500/453.592 = ~1.1 lb, rounded to 1 lb
      expect(find.textContaining('1 lb'), findsOneWidget);
    });

    testWidgets('pieces remain unchanged under imperial settings', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await pumpApp(
        tester,
        const ShoppingListScreen(),
        overrides: [
          pendingShoppingListProvider.overrideWith(
            (ref) => [
              const ShoppingItem(name: 'Eggs', quantity: 6, unit: 'pcs'),
            ],
          ),
          purchasedShoppingListProvider.overrideWith(
            (ref) => <ShoppingItem>[],
          ),
          shoppingListProvider.overrideWith(
            (ref) => [
              const ShoppingItem(name: 'Eggs', quantity: 6, unit: 'pcs'),
            ],
          ),
          settingsProvider.overrideWith(
            _FakeSettingsNotifierImperial.new,
          ),
        ],
      );

      expect(find.textContaining('6 pcs'), findsOneWidget);
    });

    testWidgets('metric items unchanged under default settings', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await pumpApp(
        tester,
        const ShoppingListScreen(),
        overrides: [
          pendingShoppingListProvider.overrideWith(
            (ref) => [
              const ShoppingItem(name: 'Milk', quantity: 2, unit: 'L'),
            ],
          ),
          purchasedShoppingListProvider.overrideWith(
            (ref) => <ShoppingItem>[],
          ),
          shoppingListProvider.overrideWith(
            (ref) => [
              const ShoppingItem(name: 'Milk', quantity: 2, unit: 'L'),
            ],
          ),
        ],
      );

      // Under metric, 2 L stays as "2 L"
      expect(find.textContaining('2 L'), findsOneWidget);
    });
  });

  group('quantity stepper', () {
    testWidgets('shows stepper for pending items only', (tester) async {
      await pumpApp(
        tester,
        const ShoppingListScreen(),
        overrides: [
          pendingShoppingListProvider.overrideWith(
            (ref) => const [
              ShoppingItem(name: 'Milk', quantity: 2, unit: 'pcs'),
            ],
          ),
          purchasedShoppingListProvider.overrideWith(
            (ref) => [
              const ShoppingItem(
                name: 'Bread',
                unit: 'pcs',
                isPurchased: true,
              ),
            ],
          ),
          shoppingListProvider.overrideWith(
            (ref) => [
              const ShoppingItem(name: 'Milk', quantity: 2, unit: 'pcs'),
              const ShoppingItem(
                name: 'Bread',
                unit: 'pcs',
                isPurchased: true,
              ),
            ],
          ),
        ],
      );

      expect(find.byIcon(Icons.add_circle_outline), findsOneWidget);
      expect(find.byIcon(Icons.remove_circle_outline), findsOneWidget);
      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
    });

    testWidgets('tapping plus calls updateShoppingItem', (tester) async {
      final service = MockShoppingListService();
      when(() => service.updateShoppingItem(any())).thenAnswer((_) async {});
      when(() => service.deleteShoppingItem(any())).thenAnswer((_) async {});

      await pumpApp(
        tester,
        const ShoppingListScreen(),
        overrides: [
          pendingShoppingListProvider.overrideWith(
            (ref) => const [
              ShoppingItem(name: 'Milk', quantity: 2, unit: 'pcs'),
            ],
          ),
          purchasedShoppingListProvider.overrideWith(
            (ref) => <ShoppingItem>[],
          ),
          shoppingListProvider.overrideWith(
            (ref) => const [
              ShoppingItem(name: 'Milk', quantity: 2, unit: 'pcs'),
            ],
          ),
          shoppingListServiceProvider.overrideWithValue(service),
        ],
      );

      await tester.tap(find.byIcon(Icons.add_circle_outline));
      await tester.pump();

      verify(
        () => service.updateShoppingItem(
          any(
            that: isA<ShoppingItem>().having(
              (i) => i.quantity,
              'quantity',
              3,
            ),
          ),
        ),
      ).called(1);
    });

    testWidgets('tapping minus at quantity 1 deletes with undo', (
      tester,
    ) async {
      final service = MockShoppingListService();
      when(() => service.deleteShoppingItem(any())).thenAnswer((_) async {});
      when(
        () => service.addShoppingItem(
          any(),
          activeInventoryId: any(named: 'activeInventoryId'),
        ),
      ).thenAnswer((_) async {});

      await pumpApp(
        tester,
        const ShoppingListScreen(),
        overrides: [
          pendingShoppingListProvider.overrideWith(
            (ref) => const [
              ShoppingItem(name: 'Egg', id: 1, unit: 'pcs'),
            ],
          ),
          purchasedShoppingListProvider.overrideWith(
            (ref) => <ShoppingItem>[],
          ),
          shoppingListProvider.overrideWith(
            (ref) => const [
              ShoppingItem(name: 'Egg', id: 1, unit: 'pcs'),
            ],
          ),
          shoppingListServiceProvider.overrideWithValue(service),
        ],
      );

      await tester.tap(find.byIcon(Icons.remove_circle_outline));
      await tester.pump();

      verify(() => service.deleteShoppingItem(1)).called(1);
    });
  });

  group('edit sheet', () {
    testWidgets('tapping edit icon opens the edit sheet', (tester) async {
      await pumpApp(
        tester,
        const ShoppingListScreen(),
        overrides: [
          pendingShoppingListProvider.overrideWith(
            (ref) => const [
              ShoppingItem(name: 'Milk', quantity: 2, unit: 'pcs'),
            ],
          ),
          purchasedShoppingListProvider.overrideWith(
            (ref) => <ShoppingItem>[],
          ),
          shoppingListProvider.overrideWith(
            (ref) => const [
              ShoppingItem(name: 'Milk', quantity: 2, unit: 'pcs'),
            ],
          ),
        ],
      );

      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();

      expect(find.byType(ShoppingItemEditSheet), findsOneWidget);
      expect(find.text('Edit item'), findsOneWidget);
    });

    testWidgets('saving the sheet persists the edited item', (tester) async {
      final service = MockShoppingListService();
      when(() => service.updateShoppingItem(any())).thenAnswer((_) async {});

      await pumpApp(
        tester,
        const ShoppingListScreen(),
        overrides: [
          pendingShoppingListProvider.overrideWith(
            (ref) => const [
              ShoppingItem(name: 'Milk', quantity: 2, unit: 'pcs'),
            ],
          ),
          purchasedShoppingListProvider.overrideWith(
            (ref) => <ShoppingItem>[],
          ),
          shoppingListProvider.overrideWith(
            (ref) => const [
              ShoppingItem(name: 'Milk', quantity: 2, unit: 'pcs'),
            ],
          ),
          shoppingListServiceProvider.overrideWithValue(service),
        ],
      );

      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'Cream');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      verify(
        () => service.updateShoppingItem(
          any(
            that: isA<ShoppingItem>().having(
              (i) => i.name,
              'name',
              'Cream',
            ),
          ),
        ),
      ).called(1);
    });
  });

  group('reorder', () {
    testWidgets('pending section shows drag handles', (tester) async {
      await pumpApp(
        tester,
        const ShoppingListScreen(),
        overrides: [
          pendingShoppingListProvider.overrideWith(
            (ref) => const [
              ShoppingItem(name: 'A', unit: 'pcs'),
              ShoppingItem(name: 'B', unit: 'pcs'),
            ],
          ),
          purchasedShoppingListProvider.overrideWith(
            (ref) => <ShoppingItem>[],
          ),
          shoppingListProvider.overrideWith(
            (ref) => const [
              ShoppingItem(name: 'A', unit: 'pcs'),
              ShoppingItem(name: 'B', unit: 'pcs'),
            ],
          ),
        ],
      );

      expect(find.byType(SliverReorderableList), findsOneWidget);
      expect(find.byIcon(Icons.drag_handle), findsNWidgets(2));
    });

    testWidgets('dragging reorders via the service', (tester) async {
      final service = MockShoppingListService();
      when(() => service.reorderShoppingItems(any())).thenAnswer((_) async {});

      await pumpApp(
        tester,
        const ShoppingListScreen(),
        overrides: [
          pendingShoppingListProvider.overrideWith(
            (ref) => const [
              ShoppingItem(name: 'A', id: 1, unit: 'pcs'),
              ShoppingItem(name: 'B', id: 2, unit: 'pcs'),
            ],
          ),
          purchasedShoppingListProvider.overrideWith(
            (ref) => <ShoppingItem>[],
          ),
          shoppingListProvider.overrideWith(
            (ref) => const [
              ShoppingItem(name: 'A', id: 1, unit: 'pcs'),
              ShoppingItem(name: 'B', id: 2, unit: 'pcs'),
            ],
          ),
          shoppingListServiceProvider.overrideWithValue(service),
        ],
      );

      final handle = find.byIcon(Icons.drag_handle).first;
      final gesture = await tester.startGesture(tester.getCenter(handle));
      await tester.pump(const Duration(milliseconds: 100));
      for (var i = 0; i < 10; i++) {
        await gesture.moveBy(const Offset(0, 12));
        await tester.pump(const Duration(milliseconds: 50));
      }
      await gesture.up();
      await tester.pumpAndSettle();

      verify(() => service.reorderShoppingItems(any())).called(1);
    });
  });

  group('estimated totals', () {
    testWidgets('shows total with estimated disclosure', (tester) async {
      const entered = ShoppingItem(
        name: 'Milk',
        barcode: '1',
        priceAmount: 2,
        priceCurrency: 'USD',
      );
      const estimated = ShoppingItem(name: 'Bread', barcode: '2');
      await pumpApp(
        tester,
        const ShoppingListScreen(),
        overrides: [
          activeInventoryProvider.overrideWith(
            FakeActiveInventoryNotifier.new,
          ),
          settingsProvider.overrideWith(
            _FakeSettingsTrackingNotifier.new,
          ),
          pendingShoppingListProvider.overrideWith(
            (ref) => [entered, estimated],
          ),
          purchasedShoppingListProvider.overrideWith(
            (ref) => <ShoppingItem>[],
          ),
          shoppingListProvider.overrideWith((ref) => [entered, estimated]),
          latestPriceProvider(('2', 1)).overrideWith(
            (ref) => const Price(barcode: '2', price: 3),
          ),
        ],
      );

      expect(
        find.text(r'To buy (2) — Total: $5.00 (incl. $3.00 estimated)'),
        findsOneWidget,
      );
    });
  });
}
