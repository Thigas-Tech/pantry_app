import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/l10n/app_localizations.dart';
import 'package:pantry_app/l10n/l10n_extensions.dart';
import 'package:pantry_app/models/shopping_item.dart';
import 'package:pantry_app/providers/active_inventory_provider.dart';
import 'package:pantry_app/providers/database_provider.dart';
import 'package:pantry_app/providers/price_provider.dart';
import 'package:pantry_app/providers/settings_provider.dart';
import 'package:pantry_app/providers/shopping_list_provider.dart';
import 'package:pantry_app/providers/shopping_list_service_provider.dart';
import 'package:pantry_app/services/currency_service.dart';
import 'package:pantry_app/utils/progress_indicator_helper.dart';
import 'package:pantry_app/utils/shopping_price.dart';
import 'package:pantry_app/utils/snackbar_helper.dart';
import 'package:pantry_app/utils/unit_conversion.dart';
import 'package:pantry_app/utils/unit_resolver.dart';
import 'package:pantry_app/widgets/add_to_shopping_list_sheet.dart';
import 'package:pantry_app/widgets/shopping_item_tile.dart';
import 'package:share_plus/share_plus.dart';

/// The main shopping list screen with price tracking and move-to-inventory.
class ShoppingListScreen extends ConsumerStatefulWidget {
  /// Creates a [ShoppingListScreen] widget.
  const ShoppingListScreen({super.key});

  @override
  ConsumerState<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends ConsumerState<ShoppingListScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.shoppingList),
        actions: [
          _MoveToInventoryButton(),
          _ClearPurchasedButton(),
          _ShareButton(),
        ],
      ),
      body: _ShoppingListBody(),
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        onPressed: () => unawaited(_showAddSheet(context)),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showAddSheet(BuildContext context) async {
    final item = await AddToShoppingListSheet.show(context);
    if (item != null && context.mounted) {
      await ref
          .read(shoppingListServiceProvider)
          .addShoppingItem(
            item,
            activeInventoryId: await ref.read(activeInventoryProvider.future),
          );
      invalidateShoppingList(ref);
    }
  }
}

/// Button that moves purchased items (with barcodes) to the active inventory
/// and removes leftover purchased items that could not be moved.
class _MoveToInventoryButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final purchasedAsync = ref.watch(purchasedShoppingListProvider);
    final purchased = purchasedAsync.asData?.value ?? [];

    final movableItems = purchased.where(
      (i) => i.barcode != null && i.barcode!.isNotEmpty,
    );
    if (movableItems.isEmpty) return const SizedBox.shrink();

    final barcodeCount = movableItems.length;
    final skipped = purchased.length - barcodeCount;

    return IconButton(
      icon: const Icon(Icons.move_to_inbox),
      tooltip: l10n.addToInventoryFromList,
      onPressed: () async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l10n.addToInventoryFromList),
            content: Text(
              l10n.addToInventoryConfirm(barcodeCount, skipped),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l10n.addToInventoryFromList),
              ),
            ],
          ),
        );
        if (confirm != true) return;

        final inventoryId = await ref.read(activeInventoryProvider.future);
        final cleanedBefore = await ref
            .read(databaseProvider)
            .getPurchasedShoppingItems(inventoryId: inventoryId);

        try {
          final result = await ref
              .read(shoppingListServiceProvider)
              .finishShoppingTrip(inventoryId: inventoryId);
          invalidateShoppingList(ref);
          if (!context.mounted) return;
          SnackbarHelper.showUndo(
            context,
            l10n.itemsMovedToInventory(result.movedCount),
            () async {
              for (final item in cleanedBefore) {
                await ref
                    .read(shoppingListServiceProvider)
                    .addShoppingItem(
                      item.copyWith(isPurchased: false),
                      activeInventoryId: inventoryId,
                    );
              }
              invalidateShoppingList(ref);
            },
          );
          if (result.cleanedCount > 0) {
            SnackbarHelper.showInfo(
              context,
              l10n.itemsSkippedNoBarcode(result.cleanedCount),
            );
          }
        } on Exception {
          if (context.mounted) {
            SnackbarHelper.showError(
              context,
              l10n.couldNotCreateInventory,
            );
          }
        }
      },
    );
  }
}

class _ClearPurchasedButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final purchasedAsync = ref.watch(purchasedShoppingListProvider);

    final hasPurchased = purchasedAsync.asData?.value.isNotEmpty ?? false;

    if (!hasPurchased) return const SizedBox.shrink();

    return IconButton(
      icon: const Icon(Icons.clear_all),
      tooltip: l10n.clearPurchased,
      onPressed: () async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l10n.clearPurchased),
            content: Text(l10n.clearPurchasedConfirm),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l10n.clearPurchased),
              ),
            ],
          ),
        );
        if (confirm != true) return;
        final db = ref.read(databaseProvider);
        final inventoryId = await ref.read(activeInventoryProvider.future);
        final purchasedItems = await db.getPurchasedShoppingItems(
          inventoryId: inventoryId,
        );
        final deleted = await ref
            .read(shoppingListServiceProvider)
            .clearPurchasedShoppingItems(
              inventoryId: await ref.read(activeInventoryProvider.future),
            );
        invalidateShoppingList(ref);
        if (!context.mounted) return;
        if (deleted > 0) {
          SnackbarHelper.showUndo(
            context,
            l10n.undoClearPurchased,
            () async {
              for (final item in purchasedItems) {
                await ref
                    .read(shoppingListServiceProvider)
                    .addShoppingItem(
                      item.copyWith(isPurchased: false),
                      activeInventoryId: await ref.read(
                        activeInventoryProvider.future,
                      ),
                    );
              }
              invalidateShoppingList(ref);
            },
          );
        }
      },
    );
  }
}

class _ShareButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final allAsync = ref.watch(shoppingListProvider);

    final items = allAsync.asData?.value ?? [];
    if (items.isEmpty) return const SizedBox.shrink();

    return IconButton(
      icon: const Icon(Icons.share),
      tooltip: l10n.shareShoppingList,
      onPressed: () {
        final pending = items.where((i) => !i.isPurchased).toList();
        final purchased = items.where((i) => i.isPurchased).toList();

        final buffer = StringBuffer()
          ..writeln(l10n.shoppingList)
          ..writeln();

        if (pending.isNotEmpty) {
          final settings =
              ref.watch(settingsProvider).value ?? const Settings();
          final shoppingSystem = UnitResolver.systemFor(
            settings: settings,
            context: UnitContext.inventory,
          );
          buffer.writeln('${l10n.pendingItems}:');
          for (final item in pending) {
            final display = UnitConverter.displayUnit(
              item.quantity,
              item.unit,
              shoppingSystem,
              weightPref: settings.preferredWeightUnit,
              volumePref: settings.preferredVolumeUnit,
            );
            final formatted = l10n.formatQuantityUnit(
              display.quantity,
              l10n.localizeUnit(display.unit),
            );
            buffer.writeln('- ${item.name} ($formatted)');
          }
          buffer.writeln();
        }

        if (purchased.isNotEmpty) {
          buffer.writeln('${l10n.purchasedItems}:');
          for (final item in purchased) {
            buffer.writeln('- ${item.name}');
          }
        }

        final text = buffer.toString();
        if (text.trim().isNotEmpty) {
          unawaited(SharePlus.instance.share(ShareParams(text: text)));
        }
      },
    );
  }
}

class _ShoppingListBody extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final pendingAsync = ref.watch(pendingShoppingListProvider);
    final purchasedAsync = ref.watch(purchasedShoppingListProvider);

    final isLoading = pendingAsync.isLoading || purchasedAsync.isLoading;
    if (isLoading) {
      return Center(child: ProgressIndicatorHelper.build());
    }

    final pending = pendingAsync.asData?.value ?? [];
    final purchased = purchasedAsync.asData?.value ?? [];

    if (pending.isEmpty && purchased.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.emptyShoppingList,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.emptyShoppingListSub,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.only(bottom: 80),
          sliver: SliverList.list(
            children: [
              if (pending.isNotEmpty)
                _SectionHeader(
                  title: l10n.pendingItems,
                  itemCount: pending.length,
                  totalText: _buildTotalText(context, ref, pending),
                ),
            ],
          ),
        ),
        if (pending.isNotEmpty)
          SliverReorderableList(
            itemCount: pending.length,
            onReorderItem: (oldIndex, newIndex) {
              if (oldIndex == newIndex) return;
              final reordered = [...pending];
              final moved = reordered.removeAt(oldIndex);
              reordered.insert(newIndex, moved);
              unawaited(
                ref
                    .read(shoppingListServiceProvider)
                    .reorderShoppingItems(reordered.map((i) => i.id!).toList())
                    .then((_) => invalidateShoppingList(ref)),
              );
            },
            itemBuilder: (context, index) {
              return ShoppingItemTile(
                key: ValueKey(pending[index].id),
                item: pending[index],
                reorderIndex: index,
              );
            },
          ),
        if (purchased.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.only(bottom: 80),
            sliver: SliverList.list(
              children: [
                _SectionHeader(
                  title: l10n.purchasedItems,
                  itemCount: purchased.length,
                  totalText: _buildTotalText(context, ref, purchased),
                ),
                ...purchased.map((item) => ShoppingItemTile(item: item)),
              ],
            ),
          ),
      ],
    );
  }

  String? _buildTotalText(
    BuildContext context,
    WidgetRef ref,
    List<ShoppingItem> items,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final priceTrackingEnabled =
        ref.watch(settingsProvider).value?.priceTrackingEnabled ?? false;
    final activeId = ref.watch(activeInventoryProvider).value ?? 1;

    final prices = <ShoppingPrice>[];
    for (final item in items) {
      if (item.priceAmount != null && item.priceAmount! > 0) {
        prices.add(
          ShoppingPrice(
            amount: item.priceAmount!,
            currency: item.priceCurrency ?? 'USD',
            isEstimate: false,
            store: item.priceStore,
          ),
        );
        continue;
      }
      if (!priceTrackingEnabled || item.barcode == null) continue;
      final tracked = ref
          .watch(latestPriceProvider((item.barcode!, activeId)))
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

    if (prices.isEmpty) return null;

    final total = groupShoppingPrices(prices);
    final parts = total.byCurrency.entries.map((e) {
      final symbol = currencySymbolFor(e.key);
      return '$symbol${e.value.toStringAsFixed(2)}';
    });
    final totalText = parts.join(' + ');
    if (total.estimatedAmount > 0) {
      final estimateSymbol = currencySymbolFor(total.byCurrency.keys.first);
      final estimated =
          '$estimateSymbol${total.estimatedAmount.toStringAsFixed(2)}';
      return l10n.totalWithEstimated(totalText, estimated);
    }
    return l10n.shoppingTotal(totalText);
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.itemCount,
    this.totalText,
  });

  final String title;
  final int itemCount;
  final String? totalText;

  @override
  Widget build(BuildContext context) {
    final label = totalText != null
        ? '$title ($itemCount) — $totalText'
        : '$title ($itemCount)';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
