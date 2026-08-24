import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/l10n/app_localizations.dart';
import 'package:pantry_app/models/price_history_point.dart';
import 'package:pantry_app/providers/price_provider.dart';
import 'package:pantry_app/utils/date_helpers.dart';

/// Builds the tooltip text for a price point: date, price, and store.
///
/// The [store] is appended only when non-empty. Kept visible for testing
/// because fl_chart paints tooltips on canvas, which widget finders cannot
/// see.
@visibleForTesting
String priceChartTooltipText({
  required AppLocalizations l10n,
  required String date,
  required String price,
  String? store,
}) {
  final base = l10n.priceChartTooltip(date, price);
  return store != null && store.isNotEmpty ? '$base - $store' : base;
}

/// A line chart of a product's price history.
///
/// [points] are expected sorted by date ascending, with amounts already
/// converted to the user's base currency. Observations are spaced equally
/// along the X axis with the purchase date as each label, which keeps the
/// chart readable for irregular recording dates.
///
/// Touch shows a built-in tooltip with the purchase date, the formatted
/// price, and the store. When price hiding is enabled the chart is replaced
/// by a masked placeholder so no monetary value leaks. A single point is
/// rendered as a visible dot, and an empty list renders nothing.
///
/// The chart is wrapped in a [RepaintBoundary] and keeps no touch state of
/// its own (fl_chart's built-in tooltip handling), so surrounding lists are
/// not invalidated while the user interacts with it.
class PriceHistoryChart extends ConsumerWidget {
  /// Creates a [PriceHistoryChart].
  const PriceHistoryChart({
    required this.points,
    required this.formatAmount,
    this.height = 160,
    super.key,
  });

  /// The history points to plot, oldest first.
  final List<PriceHistoryPoint> points;

  /// Formats an amount in the chart's currency for axis labels and
  /// tooltips.
  final String Function(double amount) formatAmount;

  /// The chart height in logical pixels.
  final double height;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (points.isEmpty) return const SizedBox.shrink();

    final hidden = ref.watch(pricesHiddenProvider);
    if (hidden) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            AppLocalizations.of(context)!.priceHidden,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }

    return RepaintBoundary(
      child: SizedBox(height: height, child: LineChart(_chartData(context))),
    );
  }

  /// Builds the [LineChartData] from [points].
  LineChartData _chartData(BuildContext context) {
    final theme = Theme.of(context);
    final spots = <FlSpot>[
      for (var i = 0; i < points.length; i++)
        FlSpot(i.toDouble(), points[i].amount),
    ];

    final amounts = points.map((p) => p.amount);
    var minY = amounts.reduce((a, b) => a < b ? a : b);
    var maxY = amounts.reduce((a, b) => a > b ? a : b);
    final pad = (maxY - minY).abs() < 0.0001
        ? (minY == 0 ? 1.0 : minY * 0.1)
        : (maxY - minY) * 0.1;
    minY -= pad;
    maxY += pad;

    return LineChartData(
      minX: points.length == 1 ? -0.5 : 0,
      maxX: points.length == 1 ? 0.5 : (points.length - 1).toDouble(),
      minY: minY,
      maxY: maxY,
      gridData: const FlGridData(show: false),
      borderData: FlBorderData(show: false),
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          fitInsideHorizontally: true,
          fitInsideVertically: true,
          getTooltipColor: (_) => theme.colorScheme.inverseSurface,
          getTooltipItems: (touchedSpots) => [
            for (final spot in touchedSpots) _tooltipItem(context, spot),
          ],
        ),
      ),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 24,
            getTitlesWidget: (value, _) {
              final i = value.round();
              if (i < 0 || i >= points.length) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  formatShortDate(points[i].date),
                  style: theme.textTheme.labelSmall,
                ),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 44,
            getTitlesWidget: (value, _) => Text(
              _shortLabel(value),
              style: theme.textTheme.labelSmall,
            ),
          ),
        ),
        topTitles: const AxisTitles(),
        rightTitles: const AxisTitles(),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          color: theme.colorScheme.primary,
          barWidth: 2.5,
          dotData: FlDotData(show: points.length <= 8),
          belowBarData: BarAreaData(
            color: theme.colorScheme.primary.withValues(alpha: 0.12),
          ),
        ),
      ],
    );
  }

  /// Builds the tooltip for a touched [spot]: date, price, and store.
  LineTooltipItem _tooltipItem(BuildContext context, LineBarSpot spot) {
    final theme = Theme.of(context);
    final i = spot.x.round();
    if (i < 0 || i >= points.length) {
      return LineTooltipItem('', theme.textTheme.labelMedium!);
    }
    final point = points[i];
    final l10n = AppLocalizations.of(context)!;
    final text = priceChartTooltipText(
      l10n: l10n,
      date: formatShortDate(point.date),
      price: formatAmount(point.amount),
      store: point.store,
    );
    return LineTooltipItem(
      text,
      theme.textTheme.labelMedium!.copyWith(
        color: theme.colorScheme.onInverseSurface,
      ),
    );
  }

  /// Shortens a formatted currency value for the compact Y axis labels.
  String _shortLabel(double value) {
    return formatAmount(
      value,
    ).replaceAll(RegExp(r'[,.]\d{2}$'), '').replaceAll(RegExp(r'\s+'), '');
  }
}
