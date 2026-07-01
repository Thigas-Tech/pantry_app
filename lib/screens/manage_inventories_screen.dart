import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/providers/active_inventory_provider.dart';
import 'package:pantry_app/providers/inventory_provider.dart';
import 'package:pantry_app/providers/product_repository_provider.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:pantry_app/utils/snackbar_helper.dart';

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
    final inventoriesAsync = ref.watch(inventoryListProvider);
    final activeId = ref.watch<int>(activeInventoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Inventories')),
      body: inventoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (list) {
          if (list.isEmpty) {
            return const Center(child: Text('No inventories.'));
          }

          return ListView(
            children: [
              for (final inv in list)
                ListTile(
                  title: Text(inv['name'] as String),
                  subtitle: Text('Items: ${inv['item_count'] ?? '…'}'),
                  trailing: (inv['id'] as int) == activeId
                      ? const Icon(Icons.check, color: Colors.teal)
                      : null,
                  onTap: () {
                    ref.read(activeInventoryProvider.notifier).value =
                        inv['id'] as int;
                    // Go back immediately so the user sees the updated home.
                    Navigator.of(context).pop();
                  },
                  onLongPress: () => _showRenameDialog(
                    context,
                    ref,
                    inv['id'] as int,
                    inv['name'] as String,
                  ),
                ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.add),
                title: const Text('Create new pantry'),
                onTap: () => _showCreateDialog(context, ref),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showCreateDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New pantry'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (name != null && name.isNotEmpty && context.mounted) {
      final repo = ref.read(productRepositoryProvider);
      try {
        await repo.createInventory(name);
        logInfo('Created inventory "$name"');
        ref.invalidate(inventoryListProvider);
        if (context.mounted) {
          SnackbarHelper.showInfo(context, '"$name" created.');
        }
      } on Exception catch (e) {
        logError('Failed to create inventory: $e');
        if (context.mounted) {
          SnackbarHelper.showError(context, 'Could not create inventory.');
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
    final controller = TextEditingController(text: currentName);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename pantry'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Rename'),
          ),
          TextButton(
            onPressed: () async {
              // Delete option
              Navigator.pop(ctx);
              await _confirmDelete(context, ref, id, currentName);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && context.mounted) {
      final repo = ref.read(productRepositoryProvider);
      try {
        await repo.renameInventory(id, newName);
        logInfo('Renamed inventory $id to "$newName"');
        ref.invalidate(inventoryListProvider);
        if (context.mounted) {
          SnackbarHelper.showInfo(context, 'Renamed to "$newName".');
        }
      } on Exception catch (e) {
        logError('Failed to rename inventory: $e');
        if (context.mounted) {
          SnackbarHelper.showError(context, 'Could not rename inventory.');
        }
      }
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    int id,
    String name,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete pantry?'),
        content: Text('All items in "$name" will be permanently deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final repo = ref.read(productRepositoryProvider);
      try {
        await repo.deleteInventory(id);
        logInfo('Deleted inventory $id ("$name")');
        ref.invalidate(inventoryListProvider);

        // If the deleted inventory was the active one,
        // switch to the first remaining.
        final activeId = ref.read<int>(activeInventoryProvider);
        if (activeId == id) {
          final inventories = await ref.read(inventoryListProvider.future);
          if (inventories.isNotEmpty) {
            ref.read(activeInventoryProvider.notifier).value =
                inventories.first['id'] as int;
          }
        }
        if (context.mounted) {
          SnackbarHelper.showInfo(context, '"$name" deleted.');
        }
      } on Exception catch (e) {
        logError('Failed to delete inventory: $e');
        if (context.mounted) {
          SnackbarHelper.showError(context, 'Could not delete inventory.');
        }
      }
    }
  }
}
