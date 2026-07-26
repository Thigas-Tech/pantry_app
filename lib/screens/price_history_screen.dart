import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/l10n/app_localizations.dart';
import 'package:pantry_app/models/price.dart';
import 'package:pantry_app/providers/price_provider.dart';
import 'package:pantry_app/providers/price_repository_provider.dart';
import 'package:pantry_app/providers/settings_provider.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:pantry_app/utils/progress_indicator_helper.dart';
import 'package:pantry_app/utils/snackbar_helper.dart';
import 'package:pantry_app/widgets/price_mask.dart';
import 'package:pantry_app/widgets/price_visibility_toggle.dart'
    show PriceVisibilityToggle;

/// Displays the price history for a single product.
///
/// Shows a scrollable list of all recorded prices for the given [barcode],
/// sorted by purchase date descending. Each row shows the date, price
/// (masked if privacy hiding is enabled, and sync status.
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
    final historyAsync = ref.watch(priceHistoryProvider(barcode));

    final priceTrackingEnabled = ref.watch(
      settingsProvider.select((s) => s.priceTrackingEnabled),
    );

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
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: prices.length,
            itemBuilder: (context, index) => _PriceHistoryTile(
              price: prices[index],
              onDelete: () => _deletePrice(context, ref, prices[index]),
            ),
          );
        },
        loading: () => Center(child: ProgressIndicatorHelper.build()),
        error: (error, _) => Center(child: Text(error.toString())),
      ),
    );
  }

  Future<void> _deletePrice(
    BuildContext context,
    WidgetRef ref,
    Price price,
  ) async {
    final l10n = AppLocalizations.of(context)!;
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
            ..invalidate(priceHistoryProvider(barcode))
            ..invalidate(latestPriceProvider(barcode));
        }
      } on Exception catch (e) {
        logError('Failed to delete price: $e');
        if (context.mounted) {
          SnackbarHelper.showError(context, e.toString());
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
    final dateStr = price.datePurchased != null
        ? DateTime.fromMillisecondsSinceEpoch(price.datePurchased!)
        : null;
    final formattedDate = dateStr != null
        ? '${dateStr.day.toString().padLeft(2, '0')}/'
              '${dateStr.month.toString().padLeft(2, '0')}/'
              '${dateStr.year}'
        : '\u2014';
    final formattedPrice = repo.formatPrice(price.price, price.currency);
    final syncLabel = switch (price.syncStatus) {
      'synced' => l10n.priceSyncStatus,
      'pending' => l10n.priceSyncPending,
      _ => null,
    };

    return Dismissible(
      key: ValueKey(price.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: Card(
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
          subtitle: price.store != null ? Text(price.store!) : null,
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
      ),
    );
  }
}
