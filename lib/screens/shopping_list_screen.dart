import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/l10n/app_localizations.dart';
import 'package:pantry_app/l10n/l10n_extensions.dart';
import 'package:pantry_app/models/shopping_item.dart';
import 'package:pantry_app/providers/active_inventory_provider.dart';
import 'package:pantry_app/providers/database_provider.dart';
import 'package:pantry_app/providers/settings_provider.dart';
import 'package:pantry_app/providers/shopping_list_provider.dart';
import 'package:pantry_app/providers/shopping_list_service_provider.dart';
import 'package:pantry_app/services/currency_service.dart';
import 'package:pantry_app/utils/progress_indicator_helper.dart';
import 'package:pantry_app/utils/snackbar_helper.dart';
import 'package:pantry_app/utils/unit_conversion.dart';
import 'package:pantry_app/utils/unit_resolver.dart';
import 'package:pantry_app/widgets/add_to_shopping_list_sheet.dart';
import 'package:pantry_app/widgets/price_entry_sheet.dart';
import 'package:pantry_app/widgets/shopping_item_edit_sheet.dart';
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

/// Button that moves purchased items (with barcodes) to the active inventory.
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

        try {
          final result = await ref
              .read(shoppingListServiceProvider)
              .movePurchasedToInventory(
                inventoryId: await ref.read(activeInventoryProvider.future),
              );
          invalidateShoppingList(ref);
          if (!context.mounted) return;
          SnackbarHelper.showUndo(
            context,
            l10n.itemsMovedToInventory(result.movedCount),
            () {},
          );
          if (result.skippedCount > 0) {
            SnackbarHelper.showInfo(
              context,
              l10n.itemsSkippedNoBarcode(result.skippedCount),
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
                  totalText: _buildTotalText(context, pending),
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
              return _ShoppingItemTile(
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
                  totalText: _buildTotalText(context, purchased),
                ),
                ...purchased.map((item) => _ShoppingItemTile(item: item)),
              ],
            ),
          ),
      ],
    );
  }

  String? _buildTotalText(BuildContext context, List<ShoppingItem> items) {
    final l10n = AppLocalizations.of(context)!;
    final priced = items
        .where(
          (i) =>
              i.priceAmount != null &&
              i.priceAmount! > 0 &&
              i.priceCurrency != null,
        )
        .toList();

    if (priced.isEmpty) return null;
    if (priced.length == 1) {
      final item = priced.first;
      final symbol = currencySymbolFor(item.priceCurrency!);
      return l10n.shoppingTotal(
        '$symbol${item.priceAmount!.toStringAsFixed(2)}',
      );
    }

    final groups = <String, double>{};
    for (final item in priced) {
      groups.update(
        item.priceCurrency!,
        (v) => v + item.priceAmount!,
        ifAbsent: () => item.priceAmount!,
      );
    }

    if (groups.length == 1) {
      final entry = groups.entries.first;
      final symbol = currencySymbolFor(entry.key);
      return l10n.shoppingTotal(
        '$symbol${entry.value.toStringAsFixed(2)}',
      );
    }

    final parts = groups.entries.map((e) {
      final symbol = currencySymbolFor(e.key);
      return '$symbol${e.value.toStringAsFixed(2)}';
    });
    return l10n.shoppingMixedCurrency(parts.join(' + '));
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

class _ShoppingItemTile extends ConsumerWidget {
  const _ShoppingItemTile({
    required this.item,
    this.reorderIndex,
    super.key,
  });

  final ShoppingItem item;

  /// The item's index within the reorderable pending list, or null when the
  /// tile is not reorderable (e.g. purchased items).
  final int? reorderIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Dismissible(
      key: ValueKey('dismiss-${item.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red.shade700,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        unawaited(
          ref
              .read(shoppingListServiceProvider)
              .deleteShoppingItem(item.id!)
              .then((_) {
                if (!context.mounted) return;
                invalidateShoppingList(ref);
                SnackbarHelper.showUndo(
                  context,
                  l10n.undoDeleteShoppingItem,
                  () async {
                    await ref
                        .read(shoppingListServiceProvider)
                        .addShoppingItem(
                          item,
                          activeInventoryId: await ref.read(
                            activeInventoryProvider.future,
                          ),
                        );
                    invalidateShoppingList(ref);
                  },
                );
              }),
        );
      },
      child: Material(
        type: MaterialType.transparency,
        child: ListTile(
          onLongPress: item.isPurchased
              ? null
              : () => _showEditSheet(context, ref),
          leading: Checkbox(
            value: item.isPurchased,
            onChanged: (_) {
              unawaited(
                ref
                    .read(shoppingListServiceProvider)
                    .toggleShoppingItem(item.id!)
                    .then((_) => invalidateShoppingList(ref)),
              );
            },
          ),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: item.isPurchased
                      ? TextStyle(
                          decoration: TextDecoration.lineThrough,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        )
                      : null,
                ),
              ),
              if (!item.isPurchased) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, size: 20),
                  visualDensity: VisualDensity.compact,
                  tooltip: l10n.editQuantity,
                  onPressed: () =>
                      _changeQuantity(context, ref, item.quantity - 1),
                ),
                GestureDetector(
                  onTap: () => _showEditSheet(context, ref),
                  child: Text(
                    _quantityText(context, ref),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, size: 20),
                  visualDensity: VisualDensity.compact,
                  tooltip: l10n.editQuantity,
                  onPressed: () =>
                      _changeQuantity(context, ref, item.quantity + 1),
                ),
              ],
            ],
          ),
          subtitle: _buildSubtitle(context, l10n, ref),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!item.isPurchased)
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  tooltip: l10n.editItem,
                  onPressed: () => _showEditSheet(context, ref),
                ),
              if (!item.isPurchased)
                IconButton(
                  icon: Icon(
                    item.priceAmount != null
                        ? Icons.attach_money
                        : Icons.attach_money_outlined,
                    size: 20,
                  ),
                  tooltip: item.priceAmount != null
                      ? l10n.removePrice
                      : l10n.addPrice,
                  onPressed: () => _showPriceEntry(context, ref),
                ),
              if (item.isPurchased)
                TextButton.icon(
                  icon: const Icon(Icons.add_shopping_cart, size: 18),
                  label: Text(l10n.addAgain),
                  onPressed: () async {
                    await ref
                        .read(shoppingListServiceProvider)
                        .toggleShoppingItem(item.id!);
                    invalidateShoppingList(ref);
                  },
                ),
              IconButton(
                icon: const Icon(Icons.delete, size: 20),
                onPressed: () {
                  unawaited(
                    ref
                        .read(shoppingListServiceProvider)
                        .deleteShoppingItem(item.id!)
                        .then((_) {
                          if (!context.mounted) return;
                          invalidateShoppingList(ref);
                          SnackbarHelper.showUndo(
                            context,
                            l10n.undoDeleteShoppingItem,
                            () async {
                              await ref
                                  .read(shoppingListServiceProvider)
                                  .addShoppingItem(
                                    item,
                                    activeInventoryId: await ref.read(
                                      activeInventoryProvider.future,
                                    ),
                                  );
                              invalidateShoppingList(ref);
                            },
                          );
                        }),
                  );
                },
                tooltip: l10n.deleteItem,
              ),
              if (reorderIndex != null)
                ReorderableDragStartListener(
                  index: reorderIndex!,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(Icons.drag_handle),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _changeQuantity(
    BuildContext context,
    WidgetRef ref,
    double newQuantity,
  ) {
    if (newQuantity <= 0) {
      unawaited(
        ref.read(shoppingListServiceProvider).deleteShoppingItem(item.id!).then(
          (_) {
            if (!context.mounted) return;
            invalidateShoppingList(ref);
            SnackbarHelper.showUndo(
              context,
              AppLocalizations.of(context)!.undoDeleteShoppingItem,
              () async {
                await ref
                    .read(shoppingListServiceProvider)
                    .addShoppingItem(
                      item,
                      activeInventoryId: await ref.read(
                        activeInventoryProvider.future,
                      ),
                    );
                invalidateShoppingList(ref);
              },
            );
          },
        ),
      );
      return;
    }
    unawaited(
      ref
          .read(shoppingListServiceProvider)
          .updateShoppingItem(item.copyWith(quantity: newQuantity))
          .then((_) => invalidateShoppingList(ref)),
    );
  }

  String _quantityText(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(settingsProvider).value ?? const Settings();
    final shoppingSystem = UnitResolver.systemFor(
      settings: settings,
      context: UnitContext.inventory,
    );
    final display = UnitConverter.displayUnit(
      item.quantity,
      item.unit,
      shoppingSystem,
      weightPref: settings.preferredWeightUnit,
      volumePref: settings.preferredVolumeUnit,
    );
    return l10n.formatQuantityUnit(
      display.quantity,
      l10n.localizeUnit(display.unit),
    );
  }

  Future<void> _showEditSheet(BuildContext context, WidgetRef ref) async {
    final result = await ShoppingItemEditSheet.show(
      context,
      item: item,
    );
    if (result == null || !context.mounted) return;
    await ref
        .read(shoppingListServiceProvider)
        .updateShoppingItem(
          item.copyWith(
            name: result.name,
            quantity: result.quantity,
            unit: result.unit,
          ),
        );
    invalidateShoppingList(ref);
  }

  Widget _buildSubtitle(
    BuildContext context,
    AppLocalizations l10n,
    WidgetRef ref,
  ) {
    final settings = ref.watch(settingsProvider).value ?? const Settings();
    final shoppingSystem = UnitResolver.systemFor(
      settings: settings,
      context: UnitContext.inventory,
    );
    final display = UnitConverter.displayUnit(
      item.quantity,
      item.unit,
      shoppingSystem,
      weightPref: settings.preferredWeightUnit,
      volumePref: settings.preferredVolumeUnit,
    );
    final quantityText = l10n.formatQuantityUnit(
      display.quantity,
      l10n.localizeUnit(display.unit),
    );

    if (item.priceAmount != null) {
      final symbol = currencySymbolFor(item.priceCurrency ?? 'USD');
      final priceText = '$symbol${item.priceAmount!.toStringAsFixed(2)}';
      final store = item.priceStore;
      final priceStr = store != null ? '$priceText — $store' : priceText;
      return Text(
        item.isPurchased ? '$quantityText — $priceStr' : priceStr,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
    }

    if (item.isPurchased) {
      return Text(
        quantityText,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Future<void> _showPriceEntry(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final l10n = AppLocalizations.of(context)!;

    if (item.priceAmount != null) {
      final action = await showModalBottomSheet<String>(
        context: context,
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: Text(l10n.addPrice),
                onTap: () => Navigator.pop(ctx, 'edit'),
              ),
              ListTile(
                leading: const Icon(
                  Icons.remove_circle_outline,
                  color: Colors.red,
                ),
                title: Text(l10n.removePrice),
                onTap: () => Navigator.pop(ctx, 'remove'),
              ),
            ],
          ),
        ),
      );

      if (action == 'remove') {
        await ref
            .read(shoppingListServiceProvider)
            .updateShoppingItemPrice(item.id!);
        invalidateShoppingList(ref);
        if (context.mounted) {
          SnackbarHelper.showInfo(context, l10n.removePrice);
        }
        return;
      }
      if (action != 'edit') return;
    }

    if (!context.mounted) return;

    final price = await PriceEntrySheet.show(
      context,
      barcode: item.barcode ?? '',
      existingAmount: item.priceAmount,
      existingCurrency: item.priceCurrency,
      existingStore: item.priceStore,
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
    invalidateShoppingList(ref);

    if (context.mounted) {
      SnackbarHelper.showInfo(context, l10n.addPrice);
    }
  }
}
