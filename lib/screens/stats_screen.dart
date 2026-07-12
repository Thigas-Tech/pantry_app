import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/l10n/app_localizations.dart';
import 'package:pantry_app/models/pantry_stats.dart';
import 'package:pantry_app/providers/price_repository_provider.dart';
import 'package:pantry_app/providers/settings_provider.dart';
import 'package:pantry_app/providers/stats_provider.dart';
import 'package:pantry_app/screens/coming_soon_screen.dart';
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

    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.pantryStats),
        actions: [
          if (settings.priceTrackingEnabled) const PriceVisibilityToggle(),
        ],
      ),
      body: previousStats != null
          ? _buildBody(context, l10n, previousStats, ref)
          : statsAsync.when(
              data: (stats) => _buildBody(context, l10n, stats, ref),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => ErrorView(
                message: error.toString(),
                onRetry: () => WidgetsBinding.instance.addPostFrameCallback(
                  (_) => ref.invalidate(statsProvider),
                ),
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
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => ref.invalidate(statsProvider),
        );
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 8,
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
                child: _buildPriceSection(context, l10n, stats),
              );
            case 7:
              return RepaintBoundary(
                child: ComingSoonView(
                  title: l10n.receiptTracking,
                  subtitle: l10n.receiptTrackingDescription,
                  icon: Icons.receipt_long,
                ),
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
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 4,
        itemBuilder: (context, index) {
          final cards = [
            _SummaryCard(
              label: l10n.totalProducts,
              value: stats.totalProducts.toString(),
              icon: Icons.inventory_2,
            ),
            _SummaryCard(
              label: l10n.inventoryItems,
              value: stats.totalItems.toString(),
              icon: Icons.shopping_basket,
            ),
            _SummaryCard(
              label: l10n.addedThisWeekLabel,
              value: stats.addedThisWeek.toString(),
              icon: Icons.calendar_today,
            ),
            _SummaryCard(
              label: l10n.addedThisMonthLabel,
              value: stats.addedThisMonth.toString(),
              icon: Icons.date_range,
            ),
          ];
          return SizedBox(
            width: 140,
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: cards[index],
            ),
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

    final theme = Theme.of(context);
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
          height: 180,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sections: sections,
                  centerSpaceRadius: 36,
                  sectionsSpace: 2,
                  pieTouchData: PieTouchData(
                    touchCallback: (event, response) {
                      if (event is! FlTapUpEvent) return;
                      if (!mounted) return;
                      setState(
                        () => _touchedExpiryIndex =
                            response?.touchedSection?.touchedSectionIndex ?? -1,
                      );
                    },
                  ),
                ),
              ),
              Text(
                '$total',
                style: theme.textTheme.headlineMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 6,
          children: [
            for (var i = 0; i < 3; i++) ...[
              GestureDetector(
                onTap: () => setState(
                  () => _touchedExpiryIndex = _touchedExpiryIndex == i ? -1 : i,
                ),
                child: _legendDot(
                  [
                    Colors.red.shade400,
                    Colors.orange.shade400,
                    Colors.green.shade400,
                  ][i],
                  [l10n.expired, l10n.expiringSoon, l10n.good][i],
                  selected: _touchedExpiryIndex == i,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _legendDot(Color color, String label, {bool selected = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: selected ? 14 : 10,
          height: selected ? 14 : 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium,
      ),
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
    final colors = [
      Colors.green.shade700,
      Colors.lightGreen,
      Colors.yellow.shade700,
      Colors.orange,
      Colors.red,
    ];
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
        ) ...[
          GestureDetector(
            onTap: () => setState(
              () => _touchedCategoryIndex = _touchedCategoryIndex == i ? -1 : i,
            ),
            child: Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: _touchedCategoryIndex == i
                    ? theme.colorScheme.surfaceContainerHighest
                    : null,
                borderRadius: BorderRadius.circular(8),
              ),
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
                      _truncatedLabel(stats.categoriesTop[i].category),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: _touchedCategoryIndex == i
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                  Text(
                    '${stats.categoriesTop[i].count}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _truncatedLabel(String label) {
    if (label.length <= 25) return label;
    return '${label.substring(0, 25)}\u2026';
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
                    entry.key,
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
                  width: 30,
                  child: Text(
                    '${entry.value}',
                    textAlign: TextAlign.right,
                    style: theme.textTheme.bodyMedium,
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

  Widget _buildPriceSection(
    BuildContext context,
    AppLocalizations l10n,
    PantryStats stats,
  ) {
    final settings = ref.watch(settingsProvider);
    if (!settings.priceTrackingEnabled) return const SizedBox.shrink();

    final repo = ref.read(priceRepositoryProvider);
    final baseCurrency = settings.baseCurrency;
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
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge,
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
