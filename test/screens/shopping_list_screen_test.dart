import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/models/shopping_item.dart';
import 'package:pantry_app/providers/active_inventory_provider.dart';
import 'package:pantry_app/providers/settings_provider.dart';
import 'package:pantry_app/providers/shopping_list_provider.dart';
import 'package:pantry_app/screens/shopping_list_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/pump_app.dart';

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

void main() {
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
}
