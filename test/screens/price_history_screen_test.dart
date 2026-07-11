import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/models/price.dart';
import 'package:pantry_app/providers/price_provider.dart';
import 'package:pantry_app/screens/price_history_screen.dart';

import '../helpers/pump_app.dart';

void main() {
  const barcode = 'test-barcode';
  const productName = 'Test Product';
  final testPrices = [
    const Price(
      barcode: 'test-barcode',
      price: 10.5,
      store: 'Store A',
      datePurchased: 1719792000000,
    ),
    const Price(
      barcode: 'test-barcode',
      price: 5,
      store: 'Store B',
      datePurchased: 1719705600000,
    ),
  ];

  testWidgets('shows loading spinner while data is pending', (tester) async {
    final completer = Completer<List<Price>>();

    await pumpApp(
      tester,
      const PriceHistoryScreen(barcode: barcode, productName: productName),
      settle: false,
      overrides: [
        priceHistoryProvider(barcode).overrideWith(
          (ref) => Completer<List<Price>>().future,
        ),
      ],
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete([]);
    await tester.pump();
  });

  testWidgets('shows empty state when no prices recorded', (tester) async {
    await pumpApp(
      tester,
      const PriceHistoryScreen(barcode: barcode, productName: productName),
      overrides: [
        priceHistoryProvider(barcode).overrideWith(
          (ref) => <Price>[],
        ),
      ],
    );

    expect(find.text('No prices recorded.'), findsOneWidget);
  });

  testWidgets('shows price list when prices exist', (tester) async {
    await pumpApp(
      tester,
      const PriceHistoryScreen(barcode: barcode, productName: productName),
      overrides: [
        priceHistoryProvider(barcode).overrideWith(
          (ref) => testPrices,
        ),
      ],
    );

    expect(find.text('Store A'), findsOneWidget);
    expect(find.text('Store B'), findsOneWidget);
    expect(find.text('USD 10.50'), findsOneWidget);
    expect(find.text('USD 5.00'), findsOneWidget);
  });
}
