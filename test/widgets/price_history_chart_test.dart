import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/l10n/app_localizations.dart';
import 'package:pantry_app/models/price_history_point.dart';
import 'package:pantry_app/providers/settings_provider.dart';
import 'package:pantry_app/widgets/price_history_chart.dart';

import '../helpers/pump_app.dart';

void main() {
  final points = [
    PriceHistoryPoint(
      date: DateTime(2026, 6, 10),
      amount: 4,
      store: 'Store A',
    ),
    PriceHistoryPoint(date: DateTime(2026, 6, 12), amount: 5),
    PriceHistoryPoint(
      date: DateTime(2026, 6, 14),
      amount: 6.5,
      store: 'Store B',
    ),
  ];

  String formatAmount(double value) => '\$${value.toStringAsFixed(2)}';

  testWidgets('renders a LineChart with one spot per point', (tester) async {
    await pumpApp(
      tester,
      PriceHistoryChart(points: points, formatAmount: formatAmount),
      overrides: [
        settingsProvider.overrideWith(FakeSettingsNotifier.new),
      ],
    );

    expect(find.byType(LineChart), findsOneWidget);
    final chart = tester.widget<LineChart>(find.byType(LineChart));
    expect(chart.data.lineBarsData.single.spots, hasLength(3));
  });

  testWidgets('renders a visible dot for a single point', (tester) async {
    await pumpApp(
      tester,
      PriceHistoryChart(
        points: [
          PriceHistoryPoint(date: DateTime(2026, 6, 10), amount: 4),
        ],
        formatAmount: formatAmount,
      ),
      overrides: [
        settingsProvider.overrideWith(FakeSettingsNotifier.new),
      ],
    );

    final chart = tester.widget<LineChart>(find.byType(LineChart));
    expect(chart.data.lineBarsData.single.spots, hasLength(1));
    expect(chart.data.lineBarsData.single.dotData.show, isTrue);
  });

  testWidgets('touch is wired to a built-in tooltip', (tester) async {
    await pumpApp(
      tester,
      SizedBox(
        width: 400,
        height: 220,
        child: PriceHistoryChart(points: points, formatAmount: formatAmount),
      ),
      overrides: [
        settingsProvider.overrideWith(FakeSettingsNotifier.new),
      ],
    );

    final chart = tester.widget<LineChart>(find.byType(LineChart));
    final touch = chart.data.lineTouchData;
    expect(touch.enabled, isTrue);
    expect(touch.touchTooltipData, isNotNull);
    // fl_chart paints tooltips on canvas, so only ensure tapping the line
    // does not throw and the tooltip stays configured.
    await tester.tapAt(const Offset(222, 110));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('formats the tooltip text with date, price, and store', (
    tester,
  ) async {
    await pumpApp(
      tester,
      const SizedBox(),
      overrides: [
        settingsProvider.overrideWith(FakeSettingsNotifier.new),
      ],
    );

    final context = tester.element(find.byType(SizedBox).first);
    final l10n = AppLocalizations.of(context)!;
    expect(
      priceChartTooltipText(
        l10n: l10n,
        date: '06/12/2026',
        price: r'$5.00',
      ),
      r'06/12/2026 - $5.00',
    );
    expect(
      priceChartTooltipText(
        l10n: l10n,
        date: '06/12/2026',
        price: r'$5.00',
        store: 'Store A',
      ),
      r'06/12/2026 - $5.00 - Store A',
    );
  });

  testWidgets('masks the chart when prices are hidden', (tester) async {
    await pumpApp(
      tester,
      PriceHistoryChart(points: points, formatAmount: formatAmount),
      overrides: [
        settingsProvider.overrideWith(
          () => FakeSettingsNotifier(const Settings(pricesHidden: true)),
        ),
      ],
    );

    expect(find.byType(LineChart), findsNothing);
    expect(find.text('Price hidden'), findsOneWidget);
  });

  testWidgets('renders nothing for an empty point list', (tester) async {
    await pumpApp(
      tester,
      PriceHistoryChart(points: const [], formatAmount: formatAmount),
      overrides: [
        settingsProvider.overrideWith(FakeSettingsNotifier.new),
      ],
    );

    expect(find.byType(LineChart), findsNothing);
  });
}
