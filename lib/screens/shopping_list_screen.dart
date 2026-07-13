import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/l10n/app_localizations.dart';
import 'package:pantry_app/l10n/l10n_extensions.dart';
import 'package:pantry_app/models/shopping_item.dart';
import 'package:pantry_app/providers/database_provider.dart';
import 'package:pantry_app/providers/shopping_list_provider.dart';
import 'package:pantry_app/utils/snackbar_helper.dart';
import 'package:share_plus/share_plus.dart';

/// Displays the user's shopping list with pending and purchased sections.
///
/// Items can be toggled as purchased, deleted, or cleared in bulk.
/// Formats a [quantity] for display, showing decimals only when needed.
String _formatQuantity(double quantity) {
  return quantity == quantity.toInt()
      ? quantity.toInt().toString()
      : quantity.toString();
}

/// The main shopping list screen.
///
/// Displays pending and purchased shopping items. A FAB opens the
/// quick-add dialog. The share button exports the list as text to
/// other apps.
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
          _ClearPurchasedButton(),
          _ShareButton(),
        ],
      ),
      body: _ShoppingListBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, l10n),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showAddDialog(BuildContext context, AppLocalizations l10n) {
    final nameController = TextEditingController();
    final quantityController = TextEditingController(text: '1');
    final formKey = GlobalKey<FormState>();

    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.addShoppingItem),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                  hintText: l10n.quickAddHint,
                  labelText: l10n.itemName,
                ),
                autofocus: true,
                validator: (v) =>
                    (v?.trim().isEmpty ?? true) ? l10n.requiredField : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: quantityController,
                decoration: InputDecoration(
                  labelText: l10n.quantity,
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  final qty = double.tryParse(v ?? '');
                  if (qty == null || qty < 1) return l10n.requiredField;
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final item = ShoppingItem(
                name: nameController.text.trim(),
                quantity: double.parse(quantityController.text.trim()),
              );
              await addShoppingItem(ref, item);
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
            },
            child: Text(l10n.add),
          ),
        ],
      ),
    );
  }
}

/// Button that clears all purchased items with an undo snackbar.
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
        final purchasedItems = await db.getPurchasedShoppingItems();
        final deleted = await clearPurchasedShoppingItems(ref);
        if (!context.mounted) return;
        if (deleted > 0) {
          SnackbarHelper.showUndo(
            context,
            l10n.undoClearPurchased,
            () async {
              for (final item in purchasedItems) {
                await addShoppingItem(
                  ref,
                  item.copyWith(isPurchased: false),
                );
              }
            },
          );
        }
      },
    );
  }
}

/// Button that shares the shopping list as plain text via share_plus.
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
          buffer.writeln('${l10n.pendingItems}:');
          for (final item in pending) {
            buffer.writeln(
              '- ${item.name} (${_formatQuantity(item.quantity)} '
              '${l10n.localizeUnit(item.unit)})',
            );
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

/// The main body of the shopping list screen.
///
/// Shows pending items first, then purchased items. Both sections are
/// wrapped with headers. An empty state is shown when the list has no items.
class _ShoppingListBody extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final pendingAsync = ref.watch(pendingShoppingListProvider);
    final purchasedAsync = ref.watch(purchasedShoppingListProvider);

    final isLoading = pendingAsync.isLoading || purchasedAsync.isLoading;
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
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

    return ListView(
      padding: const EdgeInsets.only(bottom: 80),
      children: [
        if (pending.isNotEmpty) ...[
          _SectionHeader(title: l10n.pendingItems, itemCount: pending.length),
          ...pending.map((item) => _ShoppingItemTile(item: item)),
        ],
        if (purchased.isNotEmpty) ...[
          _SectionHeader(
            title: l10n.purchasedItems,
            itemCount: purchased.length,
          ),
          ...purchased.map((item) => _ShoppingItemTile(item: item)),
        ],
      ],
    );
  }
}

/// Header label for a section (pending / purchased).
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.itemCount});

  final String title;
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        '$title ($itemCount)',
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

/// A single shopping list item row with checkbox, name, quantity, and
/// swipe-to-delete.
class _ShoppingItemTile extends ConsumerWidget {
  const _ShoppingItemTile({required this.item});

  final ShoppingItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red.shade700,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        unawaited(
          deleteShoppingItem(ref, item.id!).then((_) {
            if (!context.mounted) return;
            SnackbarHelper.showUndo(
              context,
              l10n.undoDeleteShoppingItem,
              () async {
                await addShoppingItem(ref, item);
              },
            );
          }),
        );
      },
      child: ListTile(
        leading: Checkbox(
          value: item.isPurchased,
          onChanged: (_) {
            unawaited(toggleShoppingItem(ref, item.id!));
          },
        ),
        title: Text(
          item.name,
          style: item.isPurchased
              ? TextStyle(
                  decoration: TextDecoration.lineThrough,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                )
              : null,
        ),
        subtitle: Text(
          '${_formatQuantity(item.quantity)} ${l10n.localizeUnit(item.unit)}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (item.isPurchased)
              TextButton.icon(
                icon: const Icon(Icons.add_shopping_cart, size: 18),
                label: Text(l10n.addAgain),
                onPressed: () async {
                  await toggleShoppingItem(ref, item.id!);
                },
              ),
            IconButton(
              icon: const Icon(Icons.delete, size: 20),
              onPressed: () {
                unawaited(
                  deleteShoppingItem(ref, item.id!).then((_) {
                    if (!context.mounted) return;
                    SnackbarHelper.showUndo(
                      context,
                      l10n.undoDeleteShoppingItem,
                      () async {
                        await addShoppingItem(ref, item);
                      },
                    );
                  }),
                );
              },
              tooltip: l10n.deleteItem,
            ),
          ],
        ),
      ),
    );
  }
}
