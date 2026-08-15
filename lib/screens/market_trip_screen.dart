import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/l10n/app_localizations.dart';
import 'package:pantry_app/l10n/l10n_extensions.dart';
import 'package:pantry_app/models/inventory_summary.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/models/shopping_item.dart';
import 'package:pantry_app/providers/active_inventory_provider.dart';
import 'package:pantry_app/providers/database_provider.dart';
import 'package:pantry_app/providers/inventory_provider.dart';
import 'package:pantry_app/providers/pantry_provider.dart';
import 'package:pantry_app/providers/price_provider.dart';
import 'package:pantry_app/providers/price_repository_provider.dart';
import 'package:pantry_app/providers/product_repository_provider.dart';
import 'package:pantry_app/providers/scanner_providers.dart';
import 'package:pantry_app/providers/settings_provider.dart';
import 'package:pantry_app/providers/shopping_list_provider.dart';
import 'package:pantry_app/providers/shopping_list_service_provider.dart';
import 'package:pantry_app/services/currency_service.dart';
import 'package:pantry_app/utils/bottom_sheet_helper.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:pantry_app/utils/progress_indicator_helper.dart';
import 'package:pantry_app/utils/shopping_price.dart';
import 'package:pantry_app/utils/snackbar_helper.dart';
import 'package:pantry_app/widgets/add_to_shopping_list_sheet.dart';
import 'package:pantry_app/widgets/price_entry_sheet.dart';
import 'package:pantry_app/widgets/produce_search_sheet.dart';
import 'package:pantry_app/widgets/scanner_camera_view.dart';
import 'package:pantry_app/widgets/shopping_item_tile.dart';

/// A scanning-driven shopping trip for a single pantry.
///
/// The user picks the target pantry (when more than one exists), scans items
/// in sequence with the embedded camera, optionally confirms estimated
/// prices, adds non-barcoded produce at the end, and finishes the trip to
/// move purchased items into the pantry.
///
/// The trip operates on the same shopping list data as the shopping list
/// tab, scoped to the chosen inventory via the per-inventory shopping list
/// provider.
class MarketTripScreen extends ConsumerStatefulWidget {
  /// Creates a [MarketTripScreen].
  const MarketTripScreen({super.key});

  @override
  ConsumerState<MarketTripScreen> createState() => _MarketTripScreenState();
}

class _MarketTripScreenState extends ConsumerState<MarketTripScreen> {
  int? _tripInventoryId;

  @override
  void initState() {
    super.initState();
    unawaited(_resolveTripInventory());
  }

  Future<void> _resolveTripInventory() async {
    final asyncValue = await ref.read(inventoryListProvider.future);
    final inventories = asyncValue;
    int? target;
    if (inventories.length > 1) {
      target = await _pickInventory(inventories);
    } else if (inventories.length == 1) {
      target = inventories.first.id;
    } else {
      target = await ref.read(activeInventoryProvider.future);
    }
    if (!mounted || target == null) return;
    setState(() => _tripInventoryId = target);
  }

  Future<int?> _pickInventory(List<InventorySummary> inventories) async {
    final l10n = AppLocalizations.of(context)!;
    final selected = await showModalBottomSheet<int>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                l10n.chooseTripInventory,
                style: Theme.of(ctx).textTheme.titleMedium,
              ),
            ),
            for (final inv in inventories)
              ListTile(
                title: Text(l10n.displayInventoryName(inv.name)),
                onTap: () => Navigator.pop(ctx, inv.id),
              ),
          ],
        ),
      ),
    );
    return selected;
  }

  void _onScanStateChanged(
    ScannerCameraState? prev,
    ScannerCameraState next,
  ) {
    final resolution = next.scanResolution;
    if (resolution == null) return;
    if (prev?.scanResolution == resolution && resolution is! ScanResolving) {
      return;
    }

    final tripId = _tripInventoryId;
    if (tripId == null) return;

    switch (resolution) {
      case ScanResolved(:final product):
        logInfo('Trip scan resolved: ${product.name}');
        unawaited(_handleScannedProduct(product, tripId));
      case ScanFailed(:final message) when message == 'PRODUCT_NOT_FOUND':
        logInfo('Trip scan — product not found, opening manual entry');
        ref.read(scannerCameraProvider.notifier).clearResolution();
        unawaited(_openManualAdd(tripId));
      case ScanFailed(:final message):
        logWarning('Trip scan failed: $message');
        final l10n = AppLocalizations.of(context)!;
        SnackbarHelper.showError(context, l10n.scanFailed);
        ref.read(scannerCameraProvider.notifier).clearResolution();
      case ScanResolving():
        break;
    }
  }

  Future<void> _handleScannedProduct(Product product, int tripId) async {
    final db = ref.read(databaseProvider);
    final affected = await db.markShoppingItemsByBarcode(
      product.barcode,
      inventoryId: tripId,
    );
    if (affected == 0) {
      await ref
          .read(shoppingListServiceProvider)
          .addShoppingItem(
            ShoppingItem(
              name: product.name != 'Unknown' ? product.name : product.barcode,
              barcode: product.barcode,
              inventoryId: tripId,
            ),
            activeInventoryId: tripId,
          );
      invalidateShoppingListForInventory(ref, tripId);
      if (!mounted) return;
      await _offerEstimate(product, tripId);
    } else {
      invalidateShoppingListForInventory(ref, tripId);
    }

    ref.read(scannerCameraProvider.notifier).clearResolution();
    if (mounted) {
      unawaited(HapticFeedback.lightImpact());
    }
  }

  /// Prompts the user to confirm or update the estimated price for [product]
  /// when a tracked price exists and the item has no entered price.
  Future<void> _offerEstimate(Product product, int tripId) async {
    final l10n = AppLocalizations.of(context)!;
    if (product.barcode.isEmpty) return;
    final priceTrackingEnabled =
        ref.read(settingsProvider).value?.priceTrackingEnabled ?? false;
    if (!priceTrackingEnabled) return;

    final tracked = await ref.read(
      latestPriceProvider((product.barcode, tripId)).future,
    );
    if (tracked == null) return;

    final repo = ref.read(priceRepositoryProvider);
    final formatted = repo.formatPrice(tracked.price, tracked.currency);

    if (!mounted) return;
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text(
                l10n.confirmEstimateTitle,
                style: Theme.of(ctx).textTheme.titleMedium,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(
                l10n.confirmEstimateBody(product.name, formatted),
                textAlign: TextAlign.center,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.check_circle_outline),
              title: Text(l10n.useEstimate),
              onTap: () => Navigator.pop(ctx, 'use'),
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: Text(l10n.enterPrice),
              onTap: () => Navigator.pop(ctx, 'enter'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;

    final item = await _findItemForBarcode(product.barcode, tripId);
    if (item == null || !mounted) return;

    if (action == 'use') {
      await ref
          .read(shoppingListServiceProvider)
          .updateShoppingItemPrice(
            item.id!,
            priceAmount: tracked.price,
            priceCurrency: tracked.currency,
            priceStore: tracked.store,
          );
      invalidateShoppingListForInventory(ref, tripId);
    } else if (action == 'enter') {
      if (!mounted) return;
      final price = await PriceEntrySheet.show(
        context,
        barcode: product.barcode,
        existingAmount: tracked.price,
        existingCurrency: tracked.currency,
        existingStore: tracked.store,
      );
      if (price == null) return;
      await ref
          .read(shoppingListServiceProvider)
          .updateShoppingItemPrice(
            item.id!,
            priceAmount: price.price,
            priceCurrency: price.currency,
            priceStore: price.store,
          );
      invalidateShoppingListForInventory(ref, tripId);
    }
  }

  Future<ShoppingItem?> _findItemForBarcode(String barcode, int tripId) async {
    final items = await ref
        .read(databaseProvider)
        .getShoppingList(
          inventoryId: tripId,
        );
    for (final item in items) {
      if (item.barcode == barcode && !item.isPurchased) return item;
    }
    return null;
  }

  Future<void> _openManualAdd(int tripId) async {
    final item = await AddToShoppingListSheet.show(context);
    if (item == null || !mounted) return;
    await ref
        .read(shoppingListServiceProvider)
        .addShoppingItem(
          item.copyWith(inventoryId: tripId),
          activeInventoryId: tripId,
        );
    invalidateShoppingListForInventory(ref, tripId);
  }

  Future<void> _finish() async {
    final tripId = _tripInventoryId;
    if (tripId == null) return;

    final l10n = AppLocalizations.of(context)!;
    var finish = false;
    while (mounted && !finish) {
      if (!mounted) return;
      final action = await BottomSheetHelper.show<String>(
        context: context,
        builder: (ctx) => Padding(
          padding: EdgeInsets.only(bottom: BottomSheetHelper.bottomInset(ctx)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.eco_outlined),
                title: Text(l10n.addProduce),
                subtitle: Text(l10n.produceSearchHint),
                onTap: () => Navigator.pop(ctx, 'produce'),
              ),
              ListTile(
                leading: const Icon(Icons.done_all),
                title: Text(l10n.noProduceFinish),
                onTap: () => Navigator.pop(ctx, 'finish'),
              ),
            ],
          ),
        ),
      );

      if (!mounted) return;
      if (action == 'produce') {
        await _addProduce(tripId);
      } else if (action == 'finish') {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l10n.finishTrip),
            content: Text(l10n.finishTripConfirm),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l10n.finishTrip),
              ),
            ],
          ),
        );
        if (confirm == true) {
          await _doFinish(tripId);
          finish = true;
        }
      } else {
        finish = true;
      }
    }
  }

  Future<void> _addProduce(int tripId) async {
    final product = await ProduceSearchSheet.show(context);
    if (product == null || !mounted) return;

    // Cache the product first so the "plu-" barcode survives insertion and
    // the item can later be moved to inventory by barcode lookup.
    try {
      await ref.read(productRepositoryProvider).cacheProduct(product);
    } on Exception catch (e) {
      logWarning('Failed to cache produce ${product.name}: $e');
    }

    await ref
        .read(shoppingListServiceProvider)
        .addShoppingItem(
          ShoppingItem(
            name: product.name,
            barcode: product.barcode,
            inventoryId: tripId,
          ),
          activeInventoryId: tripId,
        );
    invalidateShoppingListForInventory(ref, tripId);
    if (mounted) {
      final l10n = AppLocalizations.of(context)!;
      SnackbarHelper.showInfo(
        context,
        l10n.productAddedToShoppingList(product.name),
      );
    }
  }

  Future<void> _doFinish(int tripId) async {
    final l10n = AppLocalizations.of(context)!;
    final service = ref.read(shoppingListServiceProvider);
    try {
      final result = await service.finishShoppingTrip(inventoryId: tripId);
      invalidateShoppingListForInventory(ref, tripId);
      ref.invalidate(pantryProvider);
      if (!mounted) return;
      SnackbarHelper.showInfo(
        context,
        l10n.tripSummary(result.movedCount, result.cleanedCount),
      );
      Navigator.of(context).pop();
    } on Exception catch (e) {
      logError('Finish trip failed: $e');
      if (!mounted) return;
      SnackbarHelper.showError(context, l10n.couldNotCreateInventory);
    }
  }

  Widget _buildTotal(BuildContext context, List<ShoppingItem> items) {
    final l10n = AppLocalizations.of(context)!;
    final tripId = _tripInventoryId;
    if (tripId == null) return const SizedBox.shrink();

    final priceTrackingEnabled =
        ref.watch(settingsProvider).value?.priceTrackingEnabled ?? false;

    final prices = <ShoppingPrice>[];
    for (final item in items) {
      if (item.priceAmount != null && item.priceAmount! > 0) {
        prices.add(
          ShoppingPrice(
            amount: item.priceAmount!,
            currency: item.priceCurrency ?? 'USD',
            isEstimate: false,
          ),
        );
        continue;
      }
      if (!priceTrackingEnabled || item.barcode == null) continue;
      final tracked = ref
          .watch(latestPriceProvider((item.barcode!, tripId)))
          .asData
          ?.value;
      if (tracked == null) continue;
      prices.add(
        ShoppingPrice(
          amount: tracked.price,
          currency: tracked.currency,
          isEstimate: true,
        ),
      );
    }

    if (prices.isEmpty) return const SizedBox.shrink();

    final total = groupShoppingPrices(prices);
    final parts = total.byCurrency.entries.map((e) {
      final symbol = currencySymbolFor(e.key);
      return '$symbol${e.value.toStringAsFixed(2)}';
    });
    final totalText = parts.join(' + ');
    final label = total.estimatedAmount > 0
        ? l10n.totalWithEstimated(
            totalText,
            '${currencySymbolFor(total.byCurrency.keys.first)}'
            '${total.estimatedAmount.toStringAsFixed(2)}',
          )
        : l10n.shoppingTotal(totalText);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tripId = _tripInventoryId;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.marketTripTitle),
        actions: [
          if (tripId != null)
            TextButton(
              onPressed: () => unawaited(_finish()),
              child: Text(l10n.finishTrip),
            ),
        ],
      ),
      body: tripId == null
          ? Center(child: ProgressIndicatorHelper.build())
          : _TripBody(
              inventoryId: tripId,
              onScanStateChanged: _onScanStateChanged,
              onManualAdd: () => unawaited(_openManualAdd(tripId)),
              buildTotal: _buildTotal,
            ),
    );
  }
}

/// The trip body: embedded camera, item list, and running total.
class _TripBody extends ConsumerWidget {
  const _TripBody({
    required this.inventoryId,
    required this.onScanStateChanged,
    required this.onManualAdd,
    required this.buildTotal,
  });

  final int inventoryId;
  final void Function(ScannerCameraState?, ScannerCameraState)
  onScanStateChanged;
  final VoidCallback onManualAdd;
  final Widget Function(BuildContext, List<ShoppingItem>) buildTotal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    ref.listen(scannerCameraProvider, onScanStateChanged);

    final itemsAsync = ref.watch(shoppingListByInventoryProvider(inventoryId));
    final items = itemsAsync.asData?.value ?? <ShoppingItem>[];

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: ScannerCameraView(
              onSwitchToManual: onManualAdd,
              onSwitchToPlu: onManualAdd,
              embedded: true,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.scanNextItem,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: l10n.addItem,
                onPressed: onManualAdd,
              ),
            ],
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? Center(
                  child: Text(
                    l10n.emptyShoppingListSub,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    return ShoppingItemTile(item: items[index]);
                  },
                ),
        ),
        buildTotal(context, items),
      ],
    );
  }
}
