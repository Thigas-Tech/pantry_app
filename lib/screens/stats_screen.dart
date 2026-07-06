import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/l10n/app_localizations.dart';
import 'package:pantry_app/models/pantry_stats.dart';
import 'package:pantry_app/providers/stats_provider.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:pantry_app/widgets/coming_soon_view.dart';
import 'package:pantry_app/widgets/error_view.dart';

/// Displays aggregated statistics for the active pantry.
///
/// Shows summary cards, Nutri-Score distribution, category breakdown,
/// location breakdown, expiry donut, photo completeness, and Coming Soon
/// stubs for price tracking and NFC-e receipts.
class StatsScreen extends ConsumerWidget {
  /// Creates a [StatsScreen].
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final statsAsync = ref.watch(statsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.pantryStats)),
      body: statsAsync.when(
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
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(statsProvider);
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
                child: _buildNutriScoreBar(context, stats),
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
                child: ComingSoonView(
                  title: l10n.priceTracking,
                  subtitle: l10n.priceTrackingDescription,
                ),
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
        radius: 40,
        titleStyle: const TextStyle(color: Colors.white, fontSize: 14),
      ),
      PieChartSectionData(
        value: stats.expiringSoonCount.toDouble(),
        color: Colors.orange.shade400,
        title: stats.expiringSoonCount > 0
            ? stats.expiringSoonCount.toString()
            : '',
        radius: 40,
        titleStyle: const TextStyle(color: Colors.white, fontSize: 14),
      ),
      PieChartSectionData(
        value: stats.goodCount.toDouble(),
        color: Colors.green.shade400,
        title: stats.goodCount > 0 ? stats.goodCount.toString() : '',
        radius: 40,
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _legendDot(Colors.red.shade400, l10n.expired),
            _legendDot(Colors.orange.shade400, l10n.expiringSoon),
            _legendDot(Colors.green.shade400, l10n.good),
          ],
        ),
      ],
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
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

  Widget _buildNutriScoreBar(BuildContext context, PantryStats stats) {
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
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: count.toDouble(),
              color: colors[i],
              width: 20,
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
        _buildSectionTitle(context, 'Nutri-Score'),
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
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
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
    final textColor = Theme.of(context).colorScheme.onSurface;
    if (stats.categoriesTop.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(context, l10n.categoryLabel),
          ComingSoonView(title: l10n.noCategories),
        ],
      );
    }

    final barGroups = <BarChartGroupData>[];
    for (var i = 0; i < stats.categoriesTop.length; i++) {
      final cat = stats.categoriesTop[i];
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: cat.count.toDouble(),
              color: Theme.of(context).colorScheme.primary,
              width: 16,
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
        _buildSectionTitle(context, l10n.categoryLabel),
        const SizedBox(height: 8),
        SizedBox(
          height: barGroups.length * 36.0 + 20,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.center,
              maxY:
                  barGroups
                      .map((g) => g.barRods.first.toY)
                      .reduce((a, b) => a > b ? a : b) +
                  1,
              barGroups: barGroups,
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    reservedSize: 120,
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();
                      if (i >= 0 && i < stats.categoriesTop.length) {
                        var label = stats.categoriesTop[i].category;
                        if (label.length > 20) {
                          label = '${label.substring(0, 20)}...';
                        }
                        return Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              label,
                              style: TextStyle(fontSize: 11, color: textColor),
                            ),
                          ),
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),
                leftTitles: const AxisTitles(),
                topTitles: const AxisTitles(),
                rightTitles: const AxisTitles(),
              ),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
            ),
            duration: Duration.zero,
          ),
        ),
      ],
    );
  }

  Widget _buildLocationChart(BuildContext context, PantryStats stats) {
    if (stats.itemsByLocation.isEmpty) {
      return const SizedBox.shrink();
    }
    final textColor = Theme.of(context).colorScheme.onSurface;
    final l10n = AppLocalizations.of(context)!;

    final entries = stats.itemsByLocation.entries.toList();
    final barGroups = <BarChartGroupData>[];

    for (var i = 0; i < entries.length; i++) {
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: entries[i].value.toDouble(),
              color: Theme.of(context).colorScheme.secondary,
              width: 16,
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
        _buildSectionTitle(context, l10n.locationStats),
        const SizedBox(height: 8),
        SizedBox(
          height: barGroups.length * 36.0 + 20,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.center,
              maxY:
                  barGroups
                      .map((g) => g.barRods.first.toY)
                      .reduce((a, b) => a > b ? a : b) +
                  1,
              barGroups: barGroups,
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    reservedSize: 80,
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();
                      if (i >= 0 && i < entries.length) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Text(
                            entries[i].key,
                            style: TextStyle(color: textColor),
                          ),
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),
                leftTitles: const AxisTitles(),
                topTitles: const AxisTitles(),
                rightTitles: const AxisTitles(),
              ),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
            ),
            duration: Duration.zero,
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
          height: 100,
          child: Row(
            children: [
              Expanded(
                child: _PhotoCard(
                  icon: Icons.restaurant_menu,
                  label: l10n.nutritionPhoto,
                  local: stats.localPhotos.withNutrition,
                  off: stats.offPhotos.withNutrition,
                  total: stats.localPhotos.total,
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
                logInfo('Contribute Photos tapped — not yet implemented');
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
  });

  final IconData icon;
  final String label;
  final int local;
  final int off;
  final int total;

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
              '$local / $total',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            if (off > 0)
              Text(
                'OFF: $off',
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
