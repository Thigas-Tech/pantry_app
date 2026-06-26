import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/models/inventory_item.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/providers/product_repository_provider.dart';
import 'package:pantry_app/screens/add_to_inventory_screen.dart';
import 'package:pantry_app/services/notification_service.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  const ProductDetailScreen({required this.product, super.key});
  final Product product;

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  // A counter that we increment after inventory changes to force a rebuild
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
            // Product info
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

            // Inventory section
            Text(
              'Your inventory',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            FutureBuilder<List<InventoryItem>>(
              key: ValueKey(_inventoryVersion), // rebuild when version changes
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

  Future<void> _openAddEditScreen({InventoryItem? existing}) async {
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
        await repo.updateInventoryItem(result);
        await NotificationService.cancelReminders(existing.id!);
      } else {
        await repo.addInventoryItem(result);
      }
      await NotificationService.scheduleExpiryReminders(result);
      setState(() => _inventoryVersion++); // trigger refresh
    }
  }

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
      setState(() => _inventoryVersion++);
    }
  }
}

class _InventoryTile extends StatelessWidget {
  const _InventoryTile({
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });
  final InventoryItem item;
  final VoidCallback onEdit;
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
