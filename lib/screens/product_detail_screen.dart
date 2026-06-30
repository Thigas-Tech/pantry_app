import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/models/inventory_item.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/providers/product_repository_provider.dart';
import 'package:pantry_app/screens/add_to_inventory_screen.dart';
import 'package:pantry_app/services/notification_service.dart';
import 'package:pantry_app/utils/logger.dart';

/// Displays full product details and the associated inventory entries.
///
/// This screen is reached after scanning a known barcode or tapping an
/// inventory card on the home screen. It shows:
/// - Product image (if available).
/// - All nutritional information (per 100 g / 100 ml).
/// - The ingredients list.
/// - A list of existing inventory items for this product, each with edit and
///   delete actions.
/// - An "Add to Inventory" button that opens the [AddToInventoryScreen].
///
/// ## State
///
/// The screen is a [ConsumerStatefulWidget] because it needs to rebuild the
/// inventory list after adding, editing, or deleting an item. A simple
/// counter `_inventoryVersion` is incremented after every mutation; it is
/// used as the [ValueKey] of the [FutureBuilder] so that the future is
/// re‑evaluated and the list refreshes.
///
/// ## Expiry suggestions
///
/// When adding a new item, the screen looks at the product’s [Product.category]
/// and suggests a default expiry date:
/// - **Dairy** → today + 7 days.
/// - **Bread** → today + 3 days.
/// - Other categories → no suggestion (user picks manually).
///
/// ## Notifications
///
// ignore: lines_longer_than_80_chars
/// After an item is created or updated, [NotificationService.scheduleExpiryReminders]
/// is called. When an item is deleted,
/// the corresponding reminders are cancelled.
class ProductDetailScreen extends ConsumerStatefulWidget {
  const ProductDetailScreen({required this.product, super.key});

  /// The product to display details for.
  final Product product;

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  /// Incremented after every inventory mutation to force the [FutureBuilder]
  /// to re‑fetch the inventory list.
  int _inventoryVersion = 0;

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(productRepositoryProvider);
    final inventoryFuture = repo.getInventoryForBarcode(widget.product.barcode);

    return Scaffold(
      appBar: AppBar(title: Text(widget.product.name)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Product image (from Open Food Facts CDN)
            if (widget.product.imageUrl != null)
              Image.network(widget.product.imageUrl!, height: 200),
            _infoRow('Barcode', widget.product.barcode),
            if (widget.product.brand != null)
              _infoRow('Brand', widget.product.brand!),
            if (widget.product.category != null)
              _infoRow('Category', widget.product.category!),
            const Divider(),
            _infoRow('Serving size', widget.product.servingSize ?? 'N/A'),
            _infoRow('Energy', '${widget.product.energyKcal ?? '-'} kcal/100g'),
            _infoRow('Protein', '${widget.product.proteinG ?? '-'} g'),
            _infoRow('Carbs', '${widget.product.carbsG ?? '-'} g'),
            _infoRow('Fat', '${widget.product.fatG ?? '-'} g'),
            _infoRow('Fiber', '${widget.product.fiberG ?? '-'} g'),
            _infoRow('Salt', '${widget.product.saltG ?? '-'} g'),
            const Divider(),
            if (widget.product.ingredients != null)
              Text('Ingredients: ${widget.product.ingredients}'),
            const SizedBox(height: 24),

            // Inventory section header
            Text(
              'Your inventory',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),

            // Inventory list (rebuilds when _inventoryVersion changes)
            FutureBuilder<List<InventoryItem>>(
              key: ValueKey(_inventoryVersion),
              future: inventoryFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final items = snapshot.data ?? [];
                if (items.isEmpty) {
                  return const Text('No items in pantry yet.');
                }
                return Column(
                  children: items
                      .map(
                        (item) => _InventoryTile(
                          item: item,
                          onEdit: () => _openAddEditScreen(existing: item),
                          onDelete: () => _deleteItem(item),
                        ),
                      )
                      .toList(),
                );
              },
            ),
            const SizedBox(height: 16),

            // Add to Inventory button
            ElevatedButton.icon(
              onPressed: () => _openAddEditScreen(),
              icon: const Icon(Icons.add),
              label: const Text('Add to Inventory'),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a simple label‑value row used for product information.
  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text('$label:')),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  /// Opens the [AddToInventoryScreen] for creating or editing an item.
  ///
  /// If [existing] is provided, the screen is pre‑filled with the current
  /// values for editing. Otherwise a new item form is shown.
  ///
  /// After the user saves, the inventory item is persisted via the repository
  /// and expiry notifications are scheduled (or rescheduled for edits). The
  /// screen then rebuilds the inventory list by incrementing
  /// `_inventoryVersion`.
  Future<void> _openAddEditScreen({InventoryItem? existing}) async {
    // Suggest an expiry date based on the product category.
    String? suggested;
    if (existing == null && widget.product.category != null) {
      final cat = widget.product.category!.toLowerCase();
      if (cat.contains('dairy')) {
        suggested = DateTime.now()
            .add(const Duration(days: 7))
            .toIso8601String()
            .substring(0, 10);
      } else if (cat.contains('bread')) {
        suggested = DateTime.now()
            .add(const Duration(days: 3))
            .toIso8601String()
            .substring(0, 10);
      }
    }

    final result = await Navigator.of(context).push<InventoryItem>(
      MaterialPageRoute(
        builder: (_) => AddToInventoryScreen(
          barcode: widget.product.barcode,
          existingItem: existing,
          suggestedExpiry: suggested,
        ),
      ),
    );

    if (result != null && mounted) {
      final repo = ref.read(productRepositoryProvider);
      if (existing != null) {
        logInfo(
          // ignore: lines_longer_than_80_chars
          'Updated inventory item ${existing.id} (${widget.product.barcode}) — qty: ${result.quantity} ${result.unit}, loc: ${result.location}',
        );
        // Edit mode: update existing item and reschedule notifications.
        await repo.updateInventoryItem(result);
        await NotificationService.cancelReminders(existing.id!);
      } else {
        // Create mode: insert new item.
        logInfo(
          // ignore: lines_longer_than_80_chars
          'Added inventory item (${widget.product.barcode}) — qty: ${result.quantity} ${result.unit}, loc: ${result.location}',
        );
        await repo.addInventoryItem(result);
      }
      await NotificationService.scheduleExpiryReminders(result);
      setState(() => _inventoryVersion++);
    }
  }

  /// Asks for confirmation and then deletes the given inventory [item].
  ///
  /// Cancels any scheduled notifications for the item before removing it
  /// from the database. Triggers a refresh of the inventory list.
  Future<void> _deleteItem(InventoryItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete item?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      final repo = ref.read(productRepositoryProvider);
      await repo.deleteInventoryItem(item.id!);
      await NotificationService.cancelReminders(item.id!);
      logInfo('Deleted inventory item ${item.id} (${widget.product.barcode})');
      setState(() => _inventoryVersion++);
    }
  }
}

/// A single row in the inventory list.
///
/// Displays an icon (coloured red if expired, orange otherwise), the
/// quantity/unit/location, the expiry date, and edit / delete buttons.
class _InventoryTile extends StatelessWidget {
  const _InventoryTile({
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  /// The inventory item to display.
  final InventoryItem item;

  /// Called when the user taps the edit button.
  final VoidCallback onEdit;

  /// Called when the user taps the delete button.
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isExpired =
        item.expiryDate != null &&
        DateTime.tryParse(item.expiryDate!)?.isBefore(DateTime.now()) == true;
    return ListTile(
      leading: Icon(
        Icons.kitchen,
        color: isExpired ? Colors.red : Colors.orange,
      ),
      title: Text('${item.quantity} ${item.unit} in ${item.location}'),
      subtitle: Text(item.expiryDate ?? 'No expiry'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(icon: const Icon(Icons.edit), onPressed: onEdit),
          IconButton(icon: const Icon(Icons.delete), onPressed: onDelete),
        ],
      ),
    );
  }
}
