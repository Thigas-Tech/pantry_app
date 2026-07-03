import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/l10n/app_localizations.dart';
import 'package:pantry_app/models/inventory_item.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/providers/active_inventory_provider.dart';
import 'package:pantry_app/providers/image_cache_provider.dart';
import 'package:pantry_app/providers/inventory_provider.dart';
import 'package:pantry_app/providers/product_repository_provider.dart';
import 'package:pantry_app/screens/add_to_inventory_screen.dart';
import 'package:pantry_app/services/notification_service.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:pantry_app/utils/snackbar_helper.dart';
import 'package:url_launcher/url_launcher.dart';

/// Displays full product details and the associated inventory entries
/// for the currently active pantry.
///
/// This screen is reached after scanning a known barcode or tapping an
/// inventory card on the home screen. It shows:
/// - Product image (if available), animated with a [Hero] transition.
/// - All nutritional information (per 100 g / 100 ml) presented in a styled
///   [Table] with alternating row colours.
/// - The ingredients list, collapsed by default.
/// - A list of existing inventory items for this product, scoped to the
///   active pantry (managed via [activeInventoryProvider]).
/// - An "Add to Inventory" button that opens the [AddToInventoryScreen]
///   and creates the item inside the active pantry.
/// - A button in the app bar that opens the product’s page on Open Food Facts.
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
/// After an item is created or updated,
/// [NotificationService.scheduleExpiryReminders] is called. When an item is
/// deleted, the corresponding reminders are cancelled.
class ProductDetailScreen extends ConsumerStatefulWidget {
  /// Creates a [ProductDetailScreen] for the given [product].
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
    final l10n = AppLocalizations.of(context)!;
    final activeId = ref.watch<int>(activeInventoryProvider);
    final repo = ref.watch(productRepositoryProvider);
    final inventoryFuture = repo.getInventoryForBarcode(
      widget.product.barcode,
      inventoryId: activeId,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_browser),
            tooltip: l10n.viewOnOpenFoodFacts,
            onPressed: () async {
              final url = Uri.parse(
                'https://world.openfoodfacts.org/product/${widget.product.barcode}',
              );
              logInfo('Opening OFF page for ${widget.product.barcode}');
              if (await canLaunchUrl(url) && context.mounted) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
                logInfo('OFF page opened successfully');
              } else if (context.mounted) {
                logWarning('Failed to launch OFF page');
                SnackbarHelper.showError(context, l10n.couldNotOpenLink);
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            // Product image wrapped in Hero, loaded from cache when possible.
            if (widget.product.imageUrl != null)
              Hero(
                tag: widget.product.barcode,
                child: Consumer(
                  builder: (context, ref, _) {
                    final imageCache = ref.watch(imageCacheProvider);
                    return FutureBuilder<String?>(
                      future: imageCache.cacheImage(
                        widget.product.imageUrl,
                        widget.product.barcode,
                      ),
                      builder: (context, snapshot) {
                        if (snapshot.hasData && snapshot.data != null) {
                          return Image.file(
                            File(snapshot.data!),
                            height: 200,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.broken_image, size: 48),
                          );
                        }
                        return Image.network(
                          widget.product.imageUrl!,
                          height: 200,
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value:
                                    loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.broken_image, size: 48),
                        );
                      },
                    );
                  },
                ),
              ),
            _infoRow(l10n.barcodeLabel, widget.product.barcode),
            if (widget.product.brand != null)
              _infoRow(l10n.brandLabel, widget.product.brand!),
            if (widget.product.category != null)
              _infoRow(l10n.categoryLabel, widget.product.category!),
            const Divider(),
            _infoRow(l10n.servingSize, widget.product.servingSize ?? 'N/A'),

            // Nutrition table
            _NutritionTable(product: widget.product),

            const Divider(),
            if (widget.product.ingredients != null)
              ExpansionTile(
                title: Text(l10n.ingredients),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Text(widget.product.ingredients!),
                  ),
                ],
              ),
            const SizedBox(height: 24),

            // Inventory section header
            Text(
              l10n.yourInventory,
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
                if (snapshot.hasError) {
                  logError('Error fetching inventory: ${snapshot.error}');
                  return Center(
                    child: Text(l10n.failedToLoadInventoryItems),
                  );
                }
                final items = snapshot.data ?? [];
                if (items.isEmpty) {
                  return Text(l10n.noItemsInPantry);
                }
                return Column(
                  children: items.map(_buildInventoryTile).toList(),
                );
              },
            ),
            const SizedBox(height: 16),

            // Add to Inventory button
            ElevatedButton.icon(
              onPressed: _openAddEditScreen,
              icon: const Icon(Icons.add),
              label: Text(l10n.addToInventory),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds an [_InventoryTile] for the given [item].
  _InventoryTile _buildInventoryTile(InventoryItem item) {
    return _InventoryTile(
      item: item,
      onEdit: () => _openAddEditScreen(existing: item),
      onDelete: () => _deleteItem(item),
    );
  }

  /// Builds a simple label‑value row used for non‑nutrition product information
  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
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
  Future<void> _openAddEditScreen({InventoryItem? existing}) async {
    final activeId = ref.read<int>(activeInventoryProvider);

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
          inventoryId: activeId,
        ),
      ),
    );

    if (result != null && mounted) {
      final l10n = AppLocalizations.of(context)!;
      final repo = ref.read(productRepositoryProvider);
      try {
        if (existing != null) {
          logInfo(
            '''Updated inventory item ${existing.id} (${widget.product.barcode}) — qty: ${result.quantity} ${result.unit}, loc: ${result.location}''',
          );
          await repo.updateInventoryItem(result);
          await NotificationService.cancelReminders(existing.id!);
          if (mounted) {
            SnackbarHelper.showInfo(context, l10n.itemUpdated);
          }
        } else {
          logInfo(
            '''Added inventory item (${widget.product.barcode}) — qty: ${result.quantity} ${result.unit}, loc: ${result.location}''',
          );
          await repo.addInventoryItem(result);
          if (mounted) {
            SnackbarHelper.showInfo(context, l10n.itemAdded);
          }
        }
        await NotificationService.scheduleExpiryReminders(result);
        setState(() => _inventoryVersion++);
        ref.invalidate(inventoryWithProductProvider);
      } on Exception catch (e) {
        logError('Inventory operation failed: $e');
        if (mounted) {
          SnackbarHelper.showError(context, l10n.saveFailed);
        }
      }
    }
  }

  /// Asks for confirmation and then deletes the given inventory [item].
  Future<void> _deleteItem(InventoryItem item) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteItemTitle),
        content: Text(l10n.deleteItemContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      final repo = ref.read(productRepositoryProvider);
      try {
        await repo.deleteInventoryItem(item.id!);
        await NotificationService.cancelReminders(item.id!);
        logInfo(
          'Deleted inventory item ${item.id} (${widget.product.barcode})',
        );
        if (mounted) {
          SnackbarHelper.showInfo(context, l10n.itemRemoved);
        }
        setState(() => _inventoryVersion++);
        ref.invalidate(inventoryWithProductProvider);
      } on Exception catch (e) {
        logError('Failed to delete item: $e');
        if (mounted) {
          SnackbarHelper.showError(context, l10n.deleteFailed);
        }
      }
    }
  }
}

/// A single row in the inventory list.
///
/// Displays an icon that varies by storage location (coloured red if expired,
/// orange otherwise), the quantity/unit/location, the expiry date, and edit /
/// delete buttons.
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
    final l10n = AppLocalizations.of(context)!;
    final isExpired =
        item.expiryDate != null &&
        DateTime.tryParse(item.expiryDate!)?.isBefore(DateTime.now()) == true;
    return ListTile(
      leading: Icon(
        _iconForLocation(item.location),
        color: isExpired ? Colors.red : Colors.orange,
      ),
      title: Text(
        '${item.quantity} ${item.unit} ${l10n.inLocation} ${item.location}',
      ),
      subtitle: Text(item.expiryDate ?? l10n.noExpiry),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(icon: const Icon(Icons.edit), onPressed: onEdit),
          IconButton(icon: const Icon(Icons.delete), onPressed: onDelete),
        ],
      ),
    );
  }

  /// Returns an appropriate icon for the given storage [location].
  IconData _iconForLocation(String location) {
    switch (location.toLowerCase()) {
      case 'pantry':
        return Icons.kitchen;
      case 'fridge':
        return Icons.local_drink;
      case 'freezer':
        return Icons.ac_unit;
      default:
        return Icons.help_outline;
    }
  }
}

/// A styled table that displays the nutritional values of a [Product].
///
/// Each row shows a nutrient name and its amount per 100 g / 100 ml.
/// The header uses the theme’s primary container colour, and data rows
/// alternate between transparent and a very subtle primary overlay for
/// readability in both light and dark themes.
class _NutritionTable extends StatelessWidget {
  const _NutritionTable({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final rows = <_NutrientRow>[
      _NutrientRow(l10n.energy, '${product.energyKcal ?? '-'} kcal'),
      _NutrientRow(l10n.protein, '${product.proteinG ?? '-'} g'),
      _NutrientRow(l10n.carbs, '${product.carbsG ?? '-'} g'),
      _NutrientRow(l10n.fat, '${product.fatG ?? '-'} g'),
      _NutrientRow(l10n.fiber, '${product.fiberG ?? '-'} g'),
      _NutrientRow(l10n.salt, '${product.saltG ?? '-'} g'),
    ];

    return Table(
      border: TableBorder.all(
        color: theme.colorScheme.outlineVariant,
        width: 0.5,
      ),
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(),
      },
      children: [
        // Header row
        TableRow(
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                l10n.nutrient,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                l10n.per100g,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
        // Data rows with alternating subtle backgrounds
        for (var i = 0; i < rows.length; i++)
          TableRow(
            decoration: BoxDecoration(
              color: i.isEven
                  ? Colors.transparent
                  : theme.colorScheme.primary.withValues(alpha: 0.05),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(rows[i].name),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(rows[i].value),
              ),
            ],
          ),
      ],
    );
  }
}

/// A single row of nutritional data.
class _NutrientRow {
  const _NutrientRow(this.name, this.value);
  final String name;
  final String value;
}
