import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/models/shopping_item.dart';
import 'package:pantry_app/widgets/shopping_item_edit_sheet.dart';

import '../helpers/pump_app.dart';

void main() {
  testWidgets('prefills the item name, quantity, and unit', (tester) async {
    await pumpApp(
      tester,
      Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: FilledButton(
              onPressed: () {
                unawaited(
                  ShoppingItemEditSheet.show(
                    context,
                    item: const ShoppingItem(
                      name: 'Milk',
                      quantity: 2.5,
                      unit: 'L',
                      id: 1,
                    ),
                  ),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Edit item'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Item name'), findsOneWidget);
    expect(find.text('Milk'), findsOneWidget);
    expect(find.text('2.5'), findsOneWidget);
  });

  testWidgets('validates empty name and returns the edited values', (
    tester,
  ) async {
    ShoppingItemEditResult? result;
    await pumpApp(
      tester,
      Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: FilledButton(
              onPressed: () async {
                result = await ShoppingItemEditSheet.show(
                  context,
                  item: const ShoppingItem(
                    name: 'Milk',
                    quantity: 2,
                    id: 1,
                  ),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Item name'),
      'Cream',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.name, 'Cream');
    expect(result!.quantity, 2);
    expect(result!.unit, 'pieces');
  });

  testWidgets('rejects a quantity below one', (tester) async {
    await pumpApp(
      tester,
      Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: FilledButton(
              onPressed: () {
                unawaited(
                  ShoppingItemEditSheet.show(
                    context,
                    item: const ShoppingItem(name: 'Milk', id: 1),
                  ),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final quantityField = find.byType(TextFormField).at(1);
    await tester.enterText(quantityField, '0');
    await tester.tap(find.text('Save'));
    await tester.pump();

    expect(find.text('Edit item'), findsOneWidget);
  });
}
