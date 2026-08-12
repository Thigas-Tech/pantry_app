import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/l10n/app_localizations.dart';
import 'package:pantry_app/l10n/l10n_extensions.dart';
import 'package:pantry_app/providers/active_inventory_provider.dart';
import 'package:pantry_app/providers/inventory_provider.dart';
import 'package:pantry_app/providers/product_repository_provider.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:pantry_app/utils/progress_indicator_helper.dart';
import 'package:pantry_app/utils/snackbar_helper.dart';
import 'package:pantry_app/widgets/error_view.dart';

/// A screen that lists all inventories and allows the user to create,
/// rename, or delete them.
///
/// The active inventory is shown with a trailing check icon. Tapping
/// an inventory makes it the active one.
class ManageInventoriesScreen extends ConsumerWidget {
  /// Creates a [ManageInventoriesScreen] widget.
  const ManageInventoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final inventoriesAsync = ref.watch(inventoryListProvider);
    final activeId = ref.watch<int>(activeInventoryProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.manageInventories)),
      body: inventoriesAsync.when(
        loading: () => Center(child: ProgressIndicatorHelper.build()),
        error: (err, _) => ErrorView(
          message: l10n.inventoryLoadFailed,
          onRetry: () => WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.invalidate(inventoryListProvider);
          }),
        ),
        data: (list) {
          if (list.isEmpty) {
            return Center(child: Text(l10n.noInventories));
          }

          return ListView.builder(
            itemCount: list.length + 2,
            itemBuilder: (context, index) {
              if (index < list.length) {
                final inv = list[index];
                return Dismissible(
                  key: ValueKey('manage-inv-${inv.id}'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    color: Colors.red,
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  confirmDismiss: (_) => _confirmDelete(
                    context,
                    ref,
                    inv.id,
                    inv.name,
                  ),
                  child: ListTile(
                    title: Text(
                      l10n.displayInventoryName(inv.name),
                    ),
                    subtitle: Text(
                      l10n.itemsCount(inv.itemCount),
                    ),
                    trailing: inv.id == activeId
                        ? const Icon(Icons.check, color: Colors.teal)
                        : null,
                    onTap: () {
                      ref
                          .read(activeInventoryProvider.notifier)
                          .setActiveInventory(inv.id);
                      Navigator.of(context).pop();
                    },
                    onLongPress: () => _showRenameDialog(
                      context,
                      ref,
                      inv.id,
                      inv.name,
                    ),
                  ),
                );
              }
              if (index == list.length) {
                return const Divider();
              }
              return ListTile(
                leading: const Icon(Icons.add),
                title: Text(l10n.createNewPantry),
                onTap: () => _showCreateDialog(context, ref),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showCreateDialog(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.newPantry),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(labelText: l10n.nameLabel),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(l10n.create),
          ),
        ],
      ),
    );

    if (name != null && name.isNotEmpty && context.mounted) {
      final repo = ref.read(productRepositoryProvider);
      try {
        await repo.createInventory(name);
        logInfo('Created inventory "$name"');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.invalidate(inventoryListProvider);
        });
        if (context.mounted) {
          SnackbarHelper.showInfo(context, l10n.inventoryCreated(name));
        }
      } on Exception catch (e) {
        logError('Failed to create inventory: $e');
        if (context.mounted) {
          SnackbarHelper.showError(context, l10n.couldNotCreateInventory);
        }
      }
    }
  }

  Future<void> _showRenameDialog(
    BuildContext context,
    WidgetRef ref,
    int id,
    String currentName,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: currentName);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.renamePantry),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(labelText: l10n.nameLabel),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(l10n.rename),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _confirmDelete(context, ref, id, currentName);
            },
            child: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && context.mounted) {
      final repo = ref.read(productRepositoryProvider);
      try {
        await repo.renameInventory(id, newName);
        logInfo('Renamed inventory $id to "$newName"');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.invalidate(inventoryListProvider);
        });
        if (context.mounted) {
          SnackbarHelper.showInfo(context, l10n.inventoryRenamed(newName));
        }
      } on Exception catch (e) {
        logError('Failed to rename inventory: $e');
        if (context.mounted) {
          SnackbarHelper.showError(context, l10n.couldNotRenameInventory);
        }
      }
    }
  }

  Future<bool> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    int id,
    String name,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deletePantry),
        content: Text(l10n.deletePantryContent(name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final repo = ref.read(productRepositoryProvider);
      try {
        await repo.deleteInventory(id);
        logInfo('Deleted inventory $id ("$name")');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.invalidate(inventoryListProvider);
        });

        // If the deleted inventory was the active one,
        // switch to the first remaining.
        final activeId = ref.read<int>(activeInventoryProvider);
        if (activeId == id) {
          final inventories = await ref.read(inventoryListProvider.future);
          if (inventories.isNotEmpty) {
            ref
                .read(activeInventoryProvider.notifier)
                .setActiveInventory(inventories.first.id);
          }
        }
        if (context.mounted) {
          SnackbarHelper.showInfo(context, l10n.inventoryDeleted(name));
        }
        return true;
      } on Exception catch (e) {
        logError('Failed to delete inventory: $e');
        if (context.mounted) {
          SnackbarHelper.showError(context, l10n.couldNotDeleteInventory);
        }
        return false;
      }
    }
    return false;
  }
}
