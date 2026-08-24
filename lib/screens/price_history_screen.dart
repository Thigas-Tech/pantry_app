import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/l10n/app_localizations.dart';
import 'package:pantry_app/models/price.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/providers/active_inventory_provider.dart';
import 'package:pantry_app/providers/price_provider.dart';
import 'package:pantry_app/providers/price_repository_provider.dart';
import 'package:pantry_app/providers/settings_provider.dart';
import 'package:pantry_app/utils/date_helpers.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:pantry_app/utils/product_package_size.dart';
import 'package:pantry_app/utils/progress_indicator_helper.dart';
import 'package:pantry_app/utils/snackbar_helper.dart';
import 'package:pantry_app/widgets/price_entry_sheet.dart';
import 'package:pantry_app/widgets/price_history_chart.dart';
import 'package:pantry_app/widgets/price_mask.dart';
import 'package:pantry_app/widgets/price_visibility_toggle.dart'
    show PriceVisibilityToggle;
import 'package:pantry_app/widgets/unit_price_label.dart';

/// Displays the price history for a single product.
///
/// Shows a line chart of the full history at the top (or a hint prompting
/// for a second observation while only one price exists), followed by a
/// scrollable list of all recorded prices for the given [barcode], sorted
/// by purchase date descending. Each row shows the date, price (masked if
/// privacy hiding is enabled), and sync status, with an explicit delete
/// button. New price observations can be added from the app bar.
class PriceHistoryScreen extends ConsumerWidget {
  /// Creates a [PriceHistoryScreen].
  const PriceHistoryScreen({
    required this.barcode,
    required this.productName,
    this.product,
    super.key,
  });

  /// The product barcode whose prices to show.
  final String barcode;

  /// The product name for the app bar title.
  final String productName;

  /// The product the prices belong to, used to pre-fill the package size
  /// when adding a new price. Optional so the screen can be opened from
  /// contexts that only have the barcode.
  final Product? product;

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
          _AddPriceAction(barcode: barcode, product: product),
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
              _buildChart(context, ref),
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

  /// Builds the history chart from chart-ready points, or a hint prompting
  /// for a second observation while only one price exists.
  Widget _buildChart(BuildContext context, WidgetRef ref) {
    final activeId = ref.watch(activeInventoryProvider).value ?? 1;
    final baseCurrency =
        ref.watch(settingsProvider).value?.baseCurrency ?? 'USD';
    final chartAsync = ref.watch(
      priceChartPointsProvider((barcode, activeId, baseCurrency)),
    );
    final repo = ref.read(priceRepositoryProvider);
    return chartAsync.when(
      data: (points) {
        if (points.length >= 2) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: PriceHistoryChart(
              points: points,
              formatAmount: (value) => repo.formatPrice(value, baseCurrency),
            ),
          );
        }
        if (points.length == 1) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                AppLocalizations.of(context)!.priceTrendHint,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
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
          final baseCurrency =
              ref.read(settingsProvider).value?.baseCurrency ?? 'USD';
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
            ..invalidate(latestPriceProvider((barcode, activeId)))
            ..invalidate(
              priceChartPointsProvider((barcode, activeId, baseCurrency)),
            );
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

/// The app-bar action that records a new price observation.
///
/// Owns the sheet-open guard so a double-tap cannot stack two sheets, and
/// saves the entered price into the active inventory before invalidating
/// the history, latest-price, and chart providers.
class _AddPriceAction extends ConsumerStatefulWidget {
  const _AddPriceAction({required this.barcode, this.product});

  /// The product barcode the new price is for.
  final String barcode;

  /// The product, used for package-size prefill when available.
  final Product? product;

  @override
  ConsumerState<_AddPriceAction> createState() => _AddPriceActionState();
}

class _AddPriceActionState extends ConsumerState<_AddPriceAction> {
  bool _sheetOpen = false;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.add),
      tooltip: AppLocalizations.of(context)!.addPrice,
      onPressed: _sheetOpen ? null : _addPrice,
    );
  }

  Future<void> _addPrice() async {
    final l10n = AppLocalizations.of(context)!;
    _sheetOpen = true;
    try {
      final package = widget.product != null
          ? productPackageSize(widget.product!)
          : null;
      final price = await PriceEntrySheet.show(
        context,
        barcode: widget.barcode,
        existingPackageQuantity: package?.quantity,
        existingPackageUnit: package?.unit,
      );
      if (price == null || !mounted) return;
      try {
        final activeId = await ref.read(activeInventoryProvider.future);
        final scoped = price.copyWith(inventoryId: activeId);
        await ref.read(priceRepositoryProvider).addPrice(scoped);
        if (!mounted) return;
        final baseCurrency =
            ref.read(settingsProvider).value?.baseCurrency ?? 'USD';
        ref
          ..invalidate(
            priceHistoryProvider((widget.barcode, activeId)),
          )
          ..invalidate(latestPriceProvider((widget.barcode, activeId)))
          ..invalidate(
            priceChartPointsProvider((widget.barcode, activeId, baseCurrency)),
          );
        SnackbarHelper.showInfo(context, l10n.priceAdded);
      } on Exception catch (e) {
        logError('Failed to add price from history: $e');
        if (mounted) {
          SnackbarHelper.showError(context, l10n.errorGeneric);
        }
      }
    } finally {
      if (mounted) {
        setState(() => _sheetOpen = false);
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
