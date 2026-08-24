import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/l10n/app_localizations.dart';
import 'package:pantry_app/models/price.dart';
import 'package:pantry_app/providers/active_inventory_provider.dart';
import 'package:pantry_app/providers/price_provider.dart';
import 'package:pantry_app/providers/price_repository_provider.dart';
import 'package:pantry_app/providers/settings_provider.dart';
import 'package:pantry_app/utils/date_helpers.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:pantry_app/utils/progress_indicator_helper.dart';
import 'package:pantry_app/utils/snackbar_helper.dart';
import 'package:pantry_app/widgets/price_history_chart.dart';
import 'package:pantry_app/widgets/price_mask.dart';
import 'package:pantry_app/widgets/price_visibility_toggle.dart'
    show PriceVisibilityToggle;
import 'package:pantry_app/widgets/unit_price_label.dart';

/// Displays the price history for a single product.
///
/// Shows a line chart of the full history at the top, followed by a
/// scrollable list of all recorded prices for the given [barcode], sorted
/// by purchase date descending. Each row shows the date, price (masked if
/// privacy hiding is enabled), and sync status, with an explicit delete
/// button.
class PriceHistoryScreen extends ConsumerWidget {
  /// Creates a [PriceHistoryScreen].
  const PriceHistoryScreen({
    required this.barcode,
    required this.productName,
    super.key,
  });

  /// The product barcode whose prices to show.
  final String barcode;

  /// The product name for the app bar title.
  final String productName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final activeId = ref.watch(activeInventoryProvider).value ?? 1;
    final historyAsync = ref.watch(priceHistoryProvider((barcode, activeId)));

    final priceTrackingEnabled =
        ref.watch(settingsProvider).value?.priceTrackingEnabled ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text('${l10n.priceHistory} — $productName'),
        actions: [
          if (priceTrackingEnabled) const PriceVisibilityToggle(),
        ],
      ),
      body: historyAsync.when(
        data: (prices) {
          if (prices.isEmpty) {
            return Center(
              child: Text(
                l10n.noPrices,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            );
          }
          return Column(
            children: [
              _buildChart(ref),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: prices.length,
                  itemBuilder: (context, index) => _PriceHistoryTile(
                    price: prices[index],
                    onDelete: () => _deletePrice(context, ref, prices[index]),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => Center(child: ProgressIndicatorHelper.build()),
        error: (error, _) => Center(child: Text(l10n.errorGeneric)),
      ),
    );
  }

  /// Builds the history chart from chart-ready points, hidden until at
  /// least two points exist.
  Widget _buildChart(WidgetRef ref) {
    final activeId = ref.watch(activeInventoryProvider).value ?? 1;
    final baseCurrency =
        ref.watch(settingsProvider).value?.baseCurrency ?? 'USD';
    final chartAsync = ref.watch(
      priceChartPointsProvider((barcode, activeId, baseCurrency)),
    );
    final repo = ref.read(priceRepositoryProvider);
    return chartAsync.when(
      data: (points) => points.length >= 2
          ? Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: PriceHistoryChart(
                points: points,
                formatAmount: (value) => repo.formatPrice(value, baseCurrency),
              ),
            )
          : const SizedBox.shrink(),
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Future<void> _deletePrice(
    BuildContext context,
    WidgetRef ref,
    Price price,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final activeId = await ref.read(activeInventoryProvider.future);
    if (price.id != null) {
      try {
        await ref.read(priceRepositoryProvider).deletePrice(price.id!);
        if (context.mounted) {
          SnackbarHelper.showUndo(
            context,
            l10n.priceDeleted,
            () async {
              await ref.read(priceRepositoryProvider).addPrice(price);
              if (context.mounted) {
                SnackbarHelper.showInfo(context, l10n.priceAdded);
              }
            },
          );
          ref
            ..invalidate(priceHistoryProvider((barcode, activeId)))
            ..invalidate(latestPriceProvider((barcode, activeId)));
        }
      } on Exception catch (e) {
        logError('Failed to delete price: $e');
        if (context.mounted) {
          SnackbarHelper.showError(context, l10n.errorGeneric);
        }
      }
    }
  }
}

class _PriceHistoryTile extends ConsumerWidget {
  const _PriceHistoryTile({
    required this.price,
    required this.onDelete,
  });

  final Price price;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final repo = ref.read(priceRepositoryProvider);
    final formattedDate = price.datePurchased != null
        ? formatShortDate(
            DateTime.fromMillisecondsSinceEpoch(price.datePurchased!),
          )
        : '\u2014';
    final formattedPrice = repo.formatPrice(price.price, price.currency);
    final syncLabel = switch (price.syncStatus) {
      'synced' => l10n.priceSyncStatus,
      'pending' => l10n.priceSyncPending,
      _ => null,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Text(
          formattedDate,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        title: PriceMask(
          formattedPrice: formattedPrice,
          child: Text(
            formattedPrice,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (price.store != null) Text(price.store!),
            UnitPriceLabel(price: price),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (syncLabel != null)
              Text(
                syncLabel,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: price.syncStatus == 'synced'
                      ? Colors.green
                      : Colors.orange,
                ),
              ),
            IconButton(
              icon: const Icon(Icons.delete, size: 20),
              onPressed: onDelete,
              tooltip: l10n.deletePrice,
            ),
          ],
        ),
      ),
    );
  }
}
