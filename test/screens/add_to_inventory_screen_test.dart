/// Tests for [AddToInventoryScreen].
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/l10n/app_localizations.dart';
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
}
