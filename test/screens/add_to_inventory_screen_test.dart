/// Tests for [AddToInventoryScreen].
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/l10n/app_localizations.dart';
import 'package:pantry_app/models/inventory_item.dart';
import 'package:pantry_app/models/product.dart';
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
          product: product,
        ),
      );

      final dropdown = find.text('ml');
      expect(dropdown, findsOneWidget);
    });

    testWidgets('pre-fills mg amount and unit from product data', (
      tester,
    ) async {
      final product = productWithQuantity(
        productQuantity: 500,
        quantity: '500 mg',
      );
      await _pumpScreen(
        tester,
        AddToInventoryScreen(
          barcode: '123456789',
          inventoryId: 1,
          product: product,
        ),
      );

      final textFields = find.byType(TextField);
      final quantityField = tester.widget<TextField>(textFields.first);
      expect(quantityField.controller?.text, '500.0');
      expect(find.text('mg'), findsOneWidget);
    });

    testWidgets('pre-fills mcg amount and unit from product data', (
      tester,
    ) async {
      final product = productWithQuantity(
        productQuantity: 200,
        quantity: '200 mcg',
      );
      await _pumpScreen(
        tester,
        AddToInventoryScreen(
          barcode: '123456789',
          inventoryId: 1,
          product: product,
        ),
      );

      final textFields = find.byType(TextField);
      final quantityField = tester.widget<TextField>(textFields.first);
      expect(quantityField.controller?.text, '200.0');
      expect(find.text('mcg'), findsOneWidget);
    });

    testWidgets('shows custom option for a non-preset unit', (tester) async {
      await _pumpScreen(
        tester,
        const AddToInventoryScreen(
          barcode: '123456789',
          inventoryId: 1,
          existingItem: InventoryItem(
            barcode: '123456789',
            quantity: 2,
            unit: 'gallon',
          ),
        ),
      );

      expect(find.text('...'), findsOneWidget);
    });

    testWidgets('pre-fills from parsed quantity string alone', (tester) async {
      final product = productWithQuantity(quantity: '3 x 150 g');
      await _pumpScreen(
        tester,
        AddToInventoryScreen(
          barcode: '123456789',
          inventoryId: 1,
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
  });
}
