/// Tests for [AddToInventoryScreen].
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/l10n/app_localizations.dart';
import 'package:pantry_app/models/inventory_item.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/models/product_type.dart';
import 'package:pantry_app/screens/add_to_inventory_screen.dart';

/// Wraps [child] in a MaterialApp with proper localization, matching
/// the setup used by the app.
Future<void> _pumpScreen(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}

void main() {
  testWidgets('defaults to unit mode for produce type', (tester) async {
    await _pumpScreen(
      tester,
      const AddToInventoryScreen(
        barcode: 'produce-Apple',
        inventoryId: 1,
        productType: ProductType.produce,
      ),
    );

    final segmentButton = tester.widget<SegmentedButton<bool>>(
      find.byType(SegmentedButton<bool>),
    );
    expect(segmentButton.selected, contains(false));
  });

  testWidgets('defaults quantity to 1 for produce', (tester) async {
    await _pumpScreen(
      tester,
      const AddToInventoryScreen(
        barcode: 'produce-Apple',
        inventoryId: 1,
        productType: ProductType.produce,
      ),
    );

    final textFields = find.byType(TextField);
    // Find the quantity field (first TextField, which is the quantity input)
    final quantityField = tester.widget<TextField>(textFields.first);
    expect(quantityField.controller?.text, '1.0');
  });

  testWidgets('does not show weight/unit toggle for non-produce', (
    tester,
  ) async {
    await _pumpScreen(
      tester,
      const AddToInventoryScreen(
        barcode: '123456789',
        inventoryId: 1,
        productType: ProductType.barcoded,
      ),
    );

    expect(find.byType(SegmentedButton<bool>), findsNothing);
  });

  testWidgets(
    'derives produce name from barcode when not explicitly provided',
    (
      tester,
    ) async {
      await _pumpScreen(
        tester,
        const AddToInventoryScreen(
          barcode: 'produce-Banana',
          inventoryId: 1,
          productType: ProductType.produce,
        ),
      );

      // Unit mode selected — _produceName should be 'Banana' from barcode
      final segmentButton = tester.widget<SegmentedButton<bool>>(
        find.byType(SegmentedButton<bool>),
      );
      expect(segmentButton.selected, contains(false));

      // Save and verify no errors (serving weight lookup succeeds)
      await tester.tap(find.widgetWithText(ElevatedButton, 'Add to Pantry'));
      await tester.pumpAndSettle();
      // No exception means the serving weight was looked up correctly
    },
  );

  group('pre-fill from Product', () {
    Product productWithQuantity({
      double? productQuantity,
      String? quantity,
    }) {
      return Product(
        barcode: '123456789',
        name: 'Test Product',
        productQuantity: productQuantity,
        quantity: quantity,
      );
    }

    testWidgets('pre-fills quantity and unit from productQuantity', (
      tester,
    ) async {
      final product = productWithQuantity(
        productQuantity: 500,
        quantity: '500 ml',
      );
      await _pumpScreen(
        tester,
        AddToInventoryScreen(
          barcode: '123456789',
          inventoryId: 1,
          productType: ProductType.barcoded,
          product: product,
        ),
      );

      final textFields = find.byType(TextField);
      final quantityField = tester.widget<TextField>(textFields.first);
      expect(quantityField.controller?.text, '500.0');
    });

    testWidgets('pre-fills unit dropdown from product data', (tester) async {
      final product = productWithQuantity(
        productQuantity: 250,
        quantity: '250 ml',
      );
      await _pumpScreen(
        tester,
        AddToInventoryScreen(
          barcode: '123456789',
          inventoryId: 1,
          productType: ProductType.barcoded,
          product: product,
        ),
      );

      final dropdown = find.text('ml');
      expect(dropdown, findsOneWidget);
    });

    testWidgets('pre-fills from parsed quantity string alone', (tester) async {
      final product = productWithQuantity(quantity: '3 x 150 g');
      await _pumpScreen(
        tester,
        AddToInventoryScreen(
          barcode: '123456789',
          inventoryId: 1,
          productType: ProductType.barcoded,
          product: product,
        ),
      );

      final textFields = find.byType(TextField);
      final quantityField = tester.widget<TextField>(textFields.first);
      // Per-unit value from multi-pack: 150
      expect(quantityField.controller?.text, '150.0');
    });

    testWidgets('leaves defaults when product has no quantity data', (
      tester,
    ) async {
      final product = productWithQuantity();
      await _pumpScreen(
        tester,
        AddToInventoryScreen(
          barcode: '123456789',
          inventoryId: 1,
          productType: ProductType.barcoded,
          product: product,
        ),
      );

      final textFields = find.byType(TextField);
      final quantityField = tester.widget<TextField>(textFields.first);
      expect(quantityField.controller?.text, '1.0');
    });

    testWidgets('does not overwrite existing item values', (tester) async {
      final product = productWithQuantity(
        productQuantity: 500,
        quantity: '500 ml',
      );
      await _pumpScreen(
        tester,
        AddToInventoryScreen(
          barcode: '123456789',
          inventoryId: 1,
          productType: ProductType.barcoded,
          product: product,
          existingItem: const InventoryItem(
            barcode: '123456789',
            quantity: 7,
            unit: 'kg',
          ),
        ),
      );

      final textFields = find.byType(TextField);
      final quantityField = tester.widget<TextField>(textFields.first);
      // Existing item value should be preserved
      expect(quantityField.controller?.text, '7.0');
    });

    testWidgets('does not pre-fill for produce type', (tester) async {
      final product = Product(
        barcode: 'produce-Apple',
        name: 'Apple',
        productQuantity: 200,
        quantity: '200 g',
        productType: ProductType.produce,
      );
      await _pumpScreen(
        tester,
        AddToInventoryScreen(
          barcode: 'produce-Apple',
          inventoryId: 1,
          productType: ProductType.produce,
          product: product,
        ),
      );

      final textFields = find.byType(TextField);
      final quantityField = tester.widget<TextField>(textFields.first);
      // Produce should use default quantity (1), not the product data
      expect(quantityField.controller?.text, '1.0');
    });
  });
}
