import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/l10n/app_localizations.dart';
import 'package:pantry_app/l10n/l10n_extensions.dart';
import 'package:pantry_app/models/pantry_stats.dart';
import 'package:pantry_app/providers/price_repository_provider.dart';
import 'package:pantry_app/providers/settings_provider.dart';
import 'package:pantry_app/providers/stats_provider.dart';
import 'package:pantry_app/screens/coming_soon_screen.dart';
import 'package:pantry_app/utils/nutriscore.dart';
import 'package:pantry_app/widgets/coming_soon_view.dart';
import 'package:pantry_app/widgets/error_view.dart';
import 'package:pantry_app/widgets/price_mask.dart';
import 'package:pantry_app/widgets/price_visibility_toggle.dart';

/// Displays aggregated statistics for the active pantry.
///
/// Shows summary cards, Nutri-Score distribution, category breakdown,
/// location breakdown, expiry donut, photo completeness, and Coming Soon
/// stubs for price tracking and NFC-e receipts.
///
/// Uses fl_chart for PieChart and BarChart. All charts support touch
/// interaction (tap a section to highlight it and its legend).
///
/// See: https://pub.dev/packages/fl_chart
/// Docs: https://pub.dev/documentation/fl_chart/
/// Examples: https://github.com/imaNNeo/fl_chart/tree/main/example
class StatsScreen extends ConsumerStatefulWidget {
  /// Creates a [StatsScreen].
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  int _touchedExpiryIndex = -1;
  int _touchedCategoryIndex = -1;
  int _touchedNutriIndex = -1;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final statsAsync = ref.watch(statsProvider);
    final previousStats = statsAsync.asData?.value;

    final priceTrackingEnabled = ref.watch(
      settingsProvider.select((s) => s.priceTrackingEnabled),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.pantryStats),
        actions: [
          if (priceTrackingEnabled) const PriceVisibilityToggle(),
        ],
      ),
      body: previousStats != null
          ? _buildBody(context, l10n, previousStats, ref)
          : statsAsync.when(
              data: (stats) => _buildBody(context, l10n, stats, ref),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => ErrorView(
                message: error.toString(),
                onRetry: () => ref.invalidate(statsProvider),
              ),
            ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppLocalizations l10n,
    PantryStats stats,
    WidgetRef ref,
  ) {
    if (stats.totalItems == 0) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.bar_chart,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.statsEmptyTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.statsEmptySubtitle,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(statsProvider);
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 11,
        itemBuilder: (context, index) {
          switch (index) {
            case 0:
              return RepaintBoundary(
                child: _buildSummaryCards(context, l10n, stats),
              );
            case 1:
              return RepaintBoundary(
                child: _buildExpiryDonut(context, l10n, stats),
              );
            case 2:
              return RepaintBoundary(
                child: _buildNutriScoreBar(context, l10n, stats),
              );
            case 3:
              return RepaintBoundary(
                child: _buildCategoryChart(context, l10n, stats),
              );
            case 4:
              return RepaintBoundary(
                child: _buildLocationChart(context, stats),
              );
            case 5:
              return RepaintBoundary(
                child: _buildPhotoCompleteness(context, l10n, stats),
              );
            case 6:
              return RepaintBoundary(
                child: _PricingSection(l10n: l10n, stats: stats),
              );
            case 7:
              return RepaintBoundary(
                child: ComingSoonView(
                  title: l10n.receiptTracking,
                  subtitle: l10n.receiptTrackingDescription,
                  icon: Icons.receipt_long,
                ),
              );
            case 8:
              return RepaintBoundary(
                child: _buildMonthlySpending(context, l10n, stats, ref),
              );
            case 9:
              return RepaintBoundary(
                child: _buildStoreSpending(context, l10n, stats, ref),
              );
            case 10:
              return RepaintBoundary(
                child: _buildNutriscoreByStore(context, l10n, stats),
              );
            default:
              return const SizedBox.shrink();
          }
        },
      ),
    );
  }

  Widget _buildSummaryCards(
    BuildContext context,
    AppLocalizations l10n,
    PantryStats stats,
  ) {
    final cards = [
      _SummaryCard(
        label: l10n.totalProducts,
        value: stats.totalProducts.toString(),
        icon: Icons.category,
      ),
      _SummaryCard(
        label: l10n.inventoryItems,
        value: stats.totalItems.toString(),
        icon: Icons.inventory_2,
      ),
    ];

    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: cards.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return SizedBox(
            width: 160,
            child: cards[index],
          );
        },
      ),
    );
  }

  Widget _buildExpiryDonut(
    BuildContext context,
    AppLocalizations l10n,
    PantryStats stats,
  ) {
    final total =
        stats.expiredCount + stats.expiringSoonCount + stats.goodCount;
    if (total == 0) {
      return const SizedBox.shrink();
    }

    final sections = [
      PieChartSectionData(
        value: stats.expiredCount.toDouble(),
        color: Colors.red.shade400,
        title: stats.expiredCount > 0 ? stats.expiredCount.toString() : '',
        radius: _touchedExpiryIndex == 0 ? 55 : 40,
        titleStyle: const TextStyle(color: Colors.white, fontSize: 14),
      ),
      PieChartSectionData(
        value: stats.expiringSoonCount.toDouble(),
        color: Colors.orange.shade400,
        title: stats.expiringSoonCount > 0
            ? stats.expiringSoonCount.toString()
            : '',
        radius: _touchedExpiryIndex == 1 ? 55 : 40,
        titleStyle: const TextStyle(color: Colors.white, fontSize: 14),
      ),
      PieChartSectionData(
        value: stats.goodCount.toDouble(),
        color: Colors.green.shade400,
        title: stats.goodCount > 0 ? stats.goodCount.toString() : '',
        radius: _touchedExpiryIndex == 2 ? 55 : 40,
        titleStyle: const TextStyle(color: Colors.white, fontSize: 14),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, l10n.expired),
        const SizedBox(height: 8),
        SizedBox(
          height: 160,
          child: Row(
            children: [
              Expanded(
                child: PieChart(
                  PieChartData(
                    sections: sections,
                    centerSpaceRadius: 32,
                    sectionsSpace: 2,
                    pieTouchData: PieTouchData(
                      touchCallback: (event, response) {
                        if (event is! FlTapUpEvent) return;
                        if (!mounted) return;
                        setState(
                          () => _touchedExpiryIndex =
                              response?.touchedSection?.touchedSectionIndex ??
                              -1,
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _legendItem(Colors.red.shade400, l10n.expired),
                  const SizedBox(height: 4),
                  _legendItem(Colors.orange.shade400, l10n.expiringSoon),
                  const SizedBox(height: 4),
                  _legendItem(Colors.green.shade400, l10n.good),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _buildNutriScoreBar(
    BuildContext context,
    AppLocalizations l10n,
    PantryStats stats,
  ) {
    if (stats.nutriscoreDistribution.isEmpty) {
      return const SizedBox.shrink();
    }

    final textColor = Theme.of(context).colorScheme.onSurface;
    final grades = ['a', 'b', 'c', 'd', 'e'];
    final colors = grades.map((g) => nutriscoreColorForGrade(g)!).toList();
    final barGroups = <BarChartGroupData>[];

    for (var i = 0; i < grades.length; i++) {
      final count = stats.nutriscoreDistribution[grades[i]] ?? 0;
      final touched = _touchedNutriIndex == i;
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: count.toDouble(),
              color: colors[i],
              width: touched ? 26 : 20,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(4),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, l10n.nutriScore),
        const SizedBox(height: 8),
        SizedBox(
          height: 160,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY:
                  barGroups
                      .map((g) => g.barRods.first.toY)
                      .reduce((a, b) => a > b ? a : b) +
                  1,
              barGroups: barGroups,
              barTouchData: BarTouchData(
                touchCallback: (event, response) {
                  if (event is! FlTapUpEvent) return;
                  if (!mounted) return;
                  setState(
                    () => _touchedNutriIndex =
                        response?.spot?.touchedBarGroupIndex ?? -1,
                  );
                },
              ),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();
                      if (i >= 0 && i < grades.length) {
                        return Text(
                          grades[i].toUpperCase(),
                          style: TextStyle(color: textColor),
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) => Text(
                      value.toInt().toString(),
                      style: TextStyle(color: textColor),
                    ),
                  ),
                ),
                topTitles: const AxisTitles(),
                rightTitles: const AxisTitles(),
              ),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChart(
    BuildContext context,
    AppLocalizations l10n,
    PantryStats stats,
  ) {
    if (stats.categoriesTop.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(context, l10n.categoryLabel),
          ComingSoonView(title: l10n.noCategories),
        ],
      );
    }

    final theme = Theme.of(context);
    final colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.amber,
      Colors.cyan,
    ];
    final total = stats.categoriesTop.fold<int>(
      0,
      (sum, c) => sum + c.count,
    );

    final sections = <PieChartSectionData>[];
    for (var i = 0; i < stats.categoriesTop.length && i < colors.length; i++) {
      final cat = stats.categoriesTop[i];
      sections.add(
        PieChartSectionData(
          value: cat.count.toDouble(),
          color: colors[i],
          title: cat.count > 0 ? cat.count.toString() : '',
          radius: _touchedCategoryIndex == i ? 65 : 50,
          titleStyle: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, l10n.categoryLabel),
        const SizedBox(height: 8),
        SizedBox(
          height: 180,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sections: sections,
                  centerSpaceRadius: 32,
                  sectionsSpace: 2,
                  pieTouchData: PieTouchData(
                    touchCallback: (event, response) {
                      if (event is! FlTapUpEvent) return;
                      if (!mounted) return;
                      setState(
                        () => _touchedCategoryIndex =
                            response?.touchedSection?.touchedSectionIndex ?? -1,
                      );
                    },
                  ),
                ),
              ),
              Text('$total', style: theme.textTheme.headlineMedium),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const SizedBox(height: 12),
        for (
          var i = 0;
          i < stats.categoriesTop.length && i < colors.length;
          i++
        )
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: colors[i],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${l10n.localizeCategory(stats.categoriesTop[i].category)} '
                    '(${stats.categoriesTop[i].count})',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildLocationChart(BuildContext context, PantryStats stats) {
    if (stats.itemsByLocation.isEmpty) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context)!;
    final entries = stats.itemsByLocation.entries.toList();
    final maxCount = entries
        .map((e) => e.value)
        .fold<int>(0, (a, b) => a > b ? a : b)
        .toDouble();
    final theme = Theme.of(context);
    final icons = <String, IconData>{
      'pantry': Icons.kitchen,
      'fridge': Icons.ac_unit,
      'freezer': Icons.ac_unit,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, l10n.locationStats),
        const SizedBox(height: 8),
        for (final entry in entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(
                  icons[entry.key.toLowerCase()] ?? Icons.place,
                  size: 18,
                  color: theme.colorScheme.secondary,
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 80,
                  child: Text(
                    l10n.localizeLocation(entry.key),
                    style: theme.textTheme.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: entry.value / maxCount,
                      minHeight: 10,
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 32,
                  child: Text(
                    '${entry.value}',
                    style: theme.textTheme.bodySmall,
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildPhotoCompleteness(
    BuildContext context,
    AppLocalizations l10n,
    PantryStats stats,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, l10n.photoCompletenessTitle),
        const SizedBox(height: 8),
        SizedBox(
          height: 120,
          child: Row(
            children: [
              Expanded(
                child: _PhotoCard(
                  icon: Icons.restaurant_menu,
                  label: l10n.nutritionPhoto,
                  local: stats.localPhotos.withNutrition,
                  off: stats.offPhotos.withNutrition,
                  total: stats.localPhotos.total,
                  l10n: l10n,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PhotoCard(
                  icon: Icons.list_alt,
                  label: l10n.ingredientsPhoto,
                  local: stats.localPhotos.withIngredients,
                  off: stats.offPhotos.withIngredients,
                  total: stats.localPhotos.total,
                  l10n: l10n,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PhotoCard(
                  icon: Icons.image,
                  label: l10n.productPhoto,
                  local: stats.localPhotos.withProduct,
                  off: stats.offPhotos.withProduct,
                  total: stats.localPhotos.total,
                  l10n: l10n,
                ),
              ),
            ],
          ),
        ),
        if (stats.offPhotos.total > 0) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                unawaited(
                  Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          ComingSoonScreen(title: l10n.contributePhotos),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.open_in_browser),
              label: Text(l10n.contributePhotos),
            ),
          ),
        ],
      ],
    );
  }
}

/// A generic section title rendered in the stats screen.
Widget _buildSectionTitle(BuildContext context, String title) {
  return Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 8),
    child: Text(
      title,
      style: Theme.of(context).textTheme.titleMedium,
    ),
  );
}

Widget _buildMonthlySpending(
  BuildContext context,
  AppLocalizations l10n,
  PantryStats stats,
  WidgetRef ref,
) {
  final theme = Theme.of(context);
  final priceTrackingEnabled = ref.read(
    settingsProvider.select((s) => s.priceTrackingEnabled),
  );
  if (!priceTrackingEnabled || stats.monthlySpending.isEmpty) {
    return const SizedBox.shrink();
  }

  final repo = ref.read(priceRepositoryProvider);
  final baseCurrency = ref.read(settingsProvider).baseCurrency;
  final spots = <FlSpot>[];
  for (var i = 0; i < stats.monthlySpending.length; i++) {
    final entry = stats.monthlySpending[i];
    spots.add(FlSpot(i.toDouble(), entry.total));
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildSectionTitle(context, l10n.monthlySpendingTitle),
      const SizedBox(height: 8),
      SizedBox(
        height: 200,
        child: spots.length < 2
            ? Center(
                child: Text(
                  l10n.noSpendingData,
                  style: theme.textTheme.bodyMedium,
                ),
              )
            : LineChart(
                LineChartData(
                  gridData: FlGridData(
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: theme.colorScheme.outlineVariant,
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        getTitlesWidget: (value, _) {
                          final i = value.toInt();
                          if (i < 0 || i >= stats.monthlySpending.length) {
                            return const SizedBox.shrink();
                          }
                          final m = stats.monthlySpending[i].month;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              m.substring(5),
                              style: theme.textTheme.labelSmall,
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 48,
                        maxIncluded: false,
                        getTitlesWidget: (value, _) {
                          final formatted = repo.formatPrice(
                            value,
                            baseCurrency,
                          );
                          final short = formatted
                              .replaceAll(RegExp(r'[,.]\d{2}$'), '')
                              .replaceAll(RegExp(r'\s+'), '');
                          return Text(
                            short,
                            style: theme.textTheme.labelSmall,
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(),
                    rightTitles: const AxisTitles(),
                  ),
                  borderData: FlBorderData(),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final entry = stats.monthlySpending[spot.spotIndex];
                          final formatted = repo.formatPrice(
                            entry.total,
                            baseCurrency,
                          );
                          return LineTooltipItem(
                            '${entry.month}\n$formatted',
                            TextStyle(
                              color: theme.colorScheme.onSurface,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: theme.colorScheme.primary,
                      barWidth: 3,
                      belowBarData: BarAreaData(
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    ],
  );
}

Widget _buildStoreSpending(
  BuildContext context,
  AppLocalizations l10n,
  PantryStats stats,
  WidgetRef ref,
) {
  final theme = Theme.of(context);
  final priceTrackingEnabled = ref.read(
    settingsProvider.select((s) => s.priceTrackingEnabled),
  );
  if (!priceTrackingEnabled || stats.storeSpending.isEmpty) {
    return const SizedBox.shrink();
  }

  final repo = ref.read(priceRepositoryProvider);
  final baseCurrency = ref.read(settingsProvider).baseCurrency;
  final topStores = stats.storeSpending.take(10).toList();

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildSectionTitle(context, l10n.storeSpendingTitle),
      const SizedBox(height: 8),
      SizedBox(
        height: 200,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            gridData: FlGridData(
              drawVerticalLine: false,
              getDrawingHorizontalLine: (_) => FlLine(
                color: theme.colorScheme.outlineVariant,
                strokeWidth: 1,
              ),
            ),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 32,
                  getTitlesWidget: (value, _) {
                    final i = value.toInt();
                    if (i < 0 || i >= topStores.length) {
                      return const SizedBox.shrink();
                    }
                    var name = topStores[i].store;
                    if (name.length > 10) {
                      name = '${name.substring(0, 10)}...';
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        name,
                        style: theme.textTheme.labelSmall,
                      ),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 48,
                  maxIncluded: false,
                  getTitlesWidget: (value, _) {
                    final formatted = repo.formatPrice(value, baseCurrency);
                    final short = formatted
                        .replaceAll(RegExp(r'[,.]\d{2}$'), '')
                        .replaceAll(RegExp(r'\s+'), '');
                    return Text(
                      short,
                      style: theme.textTheme.labelSmall,
                    );
                  },
                ),
              ),
              topTitles: const AxisTitles(),
              rightTitles: const AxisTitles(),
            ),
            borderData: FlBorderData(),
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final store = topStores[groupIndex];
                  final formatted = repo.formatPrice(
                    store.total,
                    baseCurrency,
                  );
                  return BarTooltipItem(
                    '${store.store}\n$formatted',
                    TextStyle(color: theme.colorScheme.onSurface),
                  );
                },
              ),
            ),
            barGroups: topStores.asMap().entries.map((e) {
              return BarChartGroupData(
                x: e.key,
                barRods: [
                  BarChartRodData(
                    toY: e.value.total,
                    color: theme.colorScheme.primary,
                    width: 20,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    ],
  );
}

Widget _buildNutriscoreByStore(
  BuildContext context,
  AppLocalizations l10n,
  PantryStats stats,
) {
  final theme = Theme.of(context);
  if (stats.nutriscoreByStore.isEmpty) {
    return const SizedBox.shrink();
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildSectionTitle(context, l10n.nutriscoreByStoreTitle),
      const SizedBox(height: 8),
      ...stats.nutriscoreByStore.map((entry) {
        final letter = nutriscoreNumericToLetter(entry.averageScore);
        final color = nutriscoreColorForNumeric(entry.averageScore);
        final ratio = (entry.averageScore / 5.0).clamp(0.0, 1.0);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  entry.store,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              Expanded(
                flex: 2,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: ratio,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    color: color,
                    minHeight: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 48,
                child: Text(
                  letter,
                  textAlign: TextAlign.end,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    ],
  );
}

/// The price-tracking section on the stats screen.
///
/// Extracted as a standalone [ConsumerWidget] so its [WidgetRef] is scoped
/// independently from the parent [_StatsScreenState]. When pricesHidden
/// changes via the eye toggle, only this widget rebuilds — the parent
/// [ListView] scroll position is preserved.
class _PricingSection extends ConsumerWidget {
  const _PricingSection({
    required this.l10n,
    required this.stats,
  });

  final AppLocalizations l10n;
  final PantryStats stats;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final priceTrackingEnabled = ref.watch(
      settingsProvider.select((s) => s.priceTrackingEnabled),
    );
    if (!priceTrackingEnabled) return const SizedBox.shrink();

    final repo = ref.watch(priceRepositoryProvider);
    final baseCurrency = ref.watch(
      settingsProvider.select((s) => s.baseCurrency),
    );
    final totalFormatted = repo.formatPrice(stats.totalValue, baseCurrency);
    final avgFormatted = repo.formatPrice(stats.averagePrice, baseCurrency);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, l10n.priceTracking),
        const SizedBox(height: 8),
        SizedBox(
          height: 120,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              SizedBox(
                width: 160,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          l10n.totalValue,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 4),
                        PriceMask(
                          formattedPrice: totalFormatted,
                          child: Text(
                            totalFormatted,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 160,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          l10n.averagePrice,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 4),
                        PriceMask(
                          formattedPrice: avgFormatted,
                          child: Text(
                            avgFormatted,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (stats.pricedItemCount > 0)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              l10n.itemWithPriceCount(
                stats.pricedItemCount,
                stats.totalItems,
              ),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 2),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge,
              maxLines: 1,
            ),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _PhotoCard extends StatelessWidget {
  const _PhotoCard({
    required this.icon,
    required this.label,
    required this.local,
    required this.off,
    required this.total,
    required this.l10n,
  });

  final IconData icon;
  final String label;
  final int local;
  final int off;
  final int total;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 4),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            Text(
              l10n.photoCoverageRatio(local, total),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            if (off > 0)
              Text(
                l10n.offPhotosCount(off),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
