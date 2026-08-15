import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/l10n/app_localizations.dart';
import 'package:pantry_app/l10n/l10n_extensions.dart';
import 'package:pantry_app/models/shopping_item.dart';
import 'package:pantry_app/providers/active_inventory_provider.dart';
import 'package:pantry_app/providers/price_provider.dart';
import 'package:pantry_app/providers/price_repository_provider.dart';
import 'package:pantry_app/providers/settings_provider.dart';
import 'package:pantry_app/providers/shopping_list_provider.dart';
import 'package:pantry_app/providers/shopping_list_service_provider.dart';
import 'package:pantry_app/services/currency_service.dart';
import 'package:pantry_app/utils/snackbar_helper.dart';
import 'package:pantry_app/utils/unit_conversion.dart';
import 'package:pantry_app/utils/unit_resolver.dart';
import 'package:pantry_app/widgets/price_entry_sheet.dart';
import 'package:pantry_app/widgets/price_mask.dart';
import 'package:pantry_app/widgets/shopping_item_edit_sheet.dart';

/// A single row in a shopping list.
///
/// Shows the item name, quantity steppers, price (entered or estimated from
/// the latest tracked price), purchased state, and edit/delete actions.
///
/// When the item has no entered price but a tracked price exists for its
/// barcode (and price tracking is enabled), an estimate prefixed with
/// "Est." is shown instead. An entered price always wins over the estimate.
///
/// The tile is shared between the shopping list tab and the market trip
/// screen. [reorderIndex] enables the drag handle when used inside a
/// reorderable pending list.
class ShoppingItemTile extends ConsumerWidget {
  /// Creates a [ShoppingItemTile].
  const ShoppingItemTile({
    required this.item,
    this.reorderIndex,
    super.key,
  });

  /// The shopping item to display.
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

    final estimate = _estimatePrice(context, ref);
    if (estimate != null) {
      return Text.rich(
        TextSpan(
          children: [
            if (item.isPurchased) TextSpan(text: '$quantityText — '),
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: estimate,
            ),
          ],
        ),
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

  /// Returns the "Est. price" widget for the item when an estimate is
  /// available, or null.
  ///
  /// An estimate is shown only when the item has no entered price, has a
  /// barcode, price tracking is enabled, and a tracked price exists for the
  /// barcode in the active inventory.
  Widget? _estimatePrice(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    if (item.priceAmount != null || item.barcode == null) return null;

    final priceTrackingEnabled =
        ref.watch(settingsProvider).value?.priceTrackingEnabled ?? false;
    if (!priceTrackingEnabled) return null;

    final activeId = ref.watch(activeInventoryProvider).value ?? 1;
    final priceAsync = ref.watch(
      latestPriceProvider((item.barcode!, activeId)),
    );
    final price = priceAsync.asData?.value;
    if (price == null) return null;

    final repo = ref.read(priceRepositoryProvider);
    final formatted = repo.formatPrice(price.price, price.currency);
    return PriceMask(
      formattedPrice: formatted,
      child: Text(
        l10n.estimatedPrice(formatted),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
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
