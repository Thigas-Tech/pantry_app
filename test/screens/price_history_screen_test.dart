import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/models/price.dart';
import 'package:pantry_app/models/price_history_point.dart';
import 'package:pantry_app/providers/price_provider.dart';
import 'package:pantry_app/screens/price_history_screen.dart';
import 'package:pantry_app/widgets/price_history_chart.dart';

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
        priceHistoryProvider((barcode, 1)).overrideWith(
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
        priceHistoryProvider((barcode, 1)).overrideWith(
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
        priceHistoryProvider((barcode, 1)).overrideWith(
          (ref) => testPrices,
        ),
      ],
    );

    expect(find.text('Store A'), findsOneWidget);
    expect(find.text('Store B'), findsOneWidget);
    expect(find.text(r'$10.50'), findsOneWidget);
    expect(find.text(r'$5.00'), findsOneWidget);
  });

  testWidgets('shows the history chart at the top with two or more prices', (
    tester,
  ) async {
    final points = [
      PriceHistoryPoint(date: DateTime(2026, 6, 10), amount: 5),
      PriceHistoryPoint(date: DateTime(2026, 6, 15), amount: 10.5),
    ];
    await pumpApp(
      tester,
      const PriceHistoryScreen(barcode: barcode, productName: productName),
      overrides: [
        priceHistoryProvider((barcode, 1)).overrideWith(
          (ref) => testPrices,
        ),
        priceChartPointsProvider((barcode, 1, 'USD')).overrideWith(
          (ref) => points,
        ),
      ],
    );

    expect(find.byType(PriceHistoryChart), findsOneWidget);
  });

  testWidgets('shows the per-unit price when the price has a package size', (
    tester,
  ) async {
    final packagedPrices = [
      const Price(
        barcode: 'test-barcode',
        price: 9.99,
        store: 'Store A',
        datePurchased: 1719792000000,
        packageQuantity: 12,
        packageUnit: 'pieces',
      ),
    ];

    await pumpApp(
      tester,
      const PriceHistoryScreen(barcode: barcode, productName: productName),
      overrides: [
        priceHistoryProvider((
          barcode,
          1,
        )).overrideWith((ref) => packagedPrices),
      ],
    );

    expect(find.textContaining('/unit'), findsOneWidget);
  });

  testWidgets('hides the per-unit price without a package size', (
    tester,
  ) async {
    await pumpApp(
      tester,
      const PriceHistoryScreen(barcode: barcode, productName: productName),
      overrides: [
        priceHistoryProvider((barcode, 1)).overrideWith((ref) => testPrices),
      ],
    );

    expect(find.textContaining('/unit'), findsNothing);
  });

  testWidgets('is scoped to the active inventory', (tester) async {
    // Inventory 1 has no prices; inventory 2 does. The screen must read the
    // (barcode, 1) key and show the empty state.
    await pumpApp(
      tester,
      const PriceHistoryScreen(barcode: barcode, productName: productName),
      overrides: [
        priceHistoryProvider((barcode, 1)).overrideWith((ref) => <Price>[]),
        priceHistoryProvider((barcode, 2)).overrideWith(
          (ref) => testPrices,
        ),
      ],
    );

    expect(find.text('No prices recorded.'), findsOneWidget);
  });
}
