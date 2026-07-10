import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/models/shopping_item.dart';
import 'package:pantry_app/providers/shopping_list_provider.dart';
import 'package:pantry_app/screens/shopping_list_screen.dart';

import '../helpers/pump_app.dart';

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
}
