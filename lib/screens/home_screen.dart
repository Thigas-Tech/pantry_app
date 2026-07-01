import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/models/inventory_with_product.dart';
import 'package:pantry_app/providers/active_inventory_provider.dart';
import 'package:pantry_app/providers/inventory_provider.dart';
import 'package:pantry_app/providers/product_repository_provider.dart';
import 'package:pantry_app/screens/product_detail_screen.dart';
import 'package:pantry_app/screens/scanner_screen.dart';
import 'package:pantry_app/screens/settings_screen.dart';
import 'package:pantry_app/services/exceptions.dart';
import 'package:pantry_app/services/product_repository.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:pantry_app/utils/snackbar_helper.dart';
import 'package:pantry_app/widgets/empty_pantry.dart';
import 'package:pantry_app/widgets/inventory_card.dart';
import 'package:url_launcher/url_launcher.dart';

/// The main dashboard of the app (Android).
///
/// [HomeScreen] shows the user's pantry inventory grouped by expiry status
/// (expired / expiring soon / good) for the currently selected inventory.
/// It also contains the barcode scanner trigger (FAB), an inventory switcher,
/// and navigation to the [SettingsScreen].
///
/// ## Loading states
///
/// While the inventory is being fetched from the database,
/// a [CircularProgressIndicator] is displayed to give a sense of progress.
/// On error, a simple error text is shown and an error snackbar appears.
///
/// ## Empty state
///
/// When the inventory list is empty (no items added yet), the [EmptyPantry]
/// illustration is shown with a prompt to scan the first product.
///
/// ## Scanning flow
///
/// Tapping the FAB (or the empty‑state button) opens the [ScannerScreen].
/// The returned barcode is then resolved via [ProductRepository]:
/// - **Product found** (in cache or from Open Food Facts): navigates to the
///   [ProductDetailScreen] where the user can add it to inventory.
/// - **Product not found**: the user is directed to the Open Food Facts
///   Play Store page so they can install the OFF app and contribute the
///   missing product.
///
/// ## Automatic refresh
///
/// The inventory list is automatically refreshed every time it could have
/// changed – after adding/editing/deleting an item in the detail screen,
/// after importing/exporting data in the stats screen, or after a product
/// scan that leads to a new inventory entry. A manual refresh button is
/// therefore unnecessary and has been removed.
class HomeScreen extends ConsumerWidget {
  /// Creates a [HomeScreen] widget.
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventoryAsync = ref.watch(inventoryWithProductProvider);
    final inventoriesAsync = ref.watch(inventoryListProvider);

    // Build the inventory switcher dropdown.
    Widget? switcher;
    inventoriesAsync.whenData((list) {
      if (list.length > 1) {
        switcher = PopupMenuButton<int>(
          icon: const Icon(Icons.swap_horiz),
          tooltip: 'Switch pantry',
          onSelected: (id) {
            logInfo('Switched to inventory $id');
            ref.read(activeInventoryProvider.notifier).value = id;
          },
          itemBuilder: (_) => list
              .map(
                (inv) => PopupMenuItem<int>(
                  value: inv['id'] as int,
                  child: Text(inv['name'] as String),
                ),
              )
              .toList(),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Pantry'),
        centerTitle: true,
        actions: [
          if (switcher != null) switcher!,

          /// Opens the [SettingsScreen] where the user can adjust theme,
          /// notifications, and data retention.
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () async {
              logInfo('Settings button pressed');
              await Navigator.of(context).push<void>(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
              ref.invalidate(inventoryWithProductProvider);
            },
          ),
        ],
      ),
      body: inventoryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) {
          logError('Failed to load inventory: $err');
          if (context.mounted) {
            SnackbarHelper.showError(context, 'Failed to load inventory.');
          }
          return Center(child: Text('Error: $err'));
        },
        data: (items) {
          if (items.isEmpty) {
            return EmptyPantry(onScan: () => _scanBarcode(context, ref));
          }
          return _InventoryList(
            items: items,
            onScan: () => _scanBarcode(context, ref),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _scanBarcode(context, ref),
        child: const Icon(Icons.qr_code_scanner),
      ),
    );
  }

  /// Initiates the barcode scanning flow and handles the result.
  ///
  /// Steps:
  /// 1. Opens the [ScannerScreen] and waits for a barcode string.
  /// 2. Uses [ProductRepository.getProduct] to resolve the barcode.
  /// 3. On success – navigates to [ProductDetailScreen].
  /// 4. On [ProductNotFoundException] – opens the Play Store link.
  Future<void> _scanBarcode(BuildContext context, WidgetRef ref) async {
    final barcode = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const ScannerScreen()),
    );
    logInfo('Barcode scanned: $barcode');
    if (barcode == null || !context.mounted) return;

    final repo = ref.read(productRepositoryProvider);

    try {
      final product = await repo.getProduct(barcode);
      logInfo('Product found: ${product.name}');
      if (context.mounted) {
        await Navigator.of(context).push<void>(
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(product: product),
          ),
        );
        ref.invalidate(inventoryWithProductProvider);
      }
    } on ProductNotFoundException {
      logWarning('Product not found for $barcode – redirecting to Play Store');
      if (context.mounted) {
        const storeUrl =
            'https://play.google.com/store/apps/details?id=org.openfoodfacts.scanner&hl=en&pli=1';
        final uri = Uri.parse(storeUrl);
        final canLaunch = await canLaunchUrl(uri);
        if (canLaunch && context.mounted) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else if (context.mounted) {
          SnackbarHelper.showError(context, 'Could not open the Play Store.');
        }
      }
    }
  }
}

// ---------- Inventory list with expiry grouping & search ----------

/// Displays the full inventory list with search and expiry grouping.
///
/// The list is divided into three sections:
/// - **Expired** (red) – items whose expiry date is strictly before today.
/// - **Expiring soon** (orange) – items expiring between today (inclusive)
///   and 3 days from now.
/// - **Good** (green) – items expiring more than 3 days in the future, or
///   items without an expiry date.
///
/// A search bar at the top filters items by product name or barcode.
/// The filtering is case‑insensitive and updates as the user types.
class _InventoryList extends ConsumerStatefulWidget {
  const _InventoryList({required this.items, required this.onScan});

  /// The full, unfiltered list of inventory items with product metadata.
  final List<InventoryWithProduct> items;

  /// Unused in this widget, but required for consistency with the parent.
  final VoidCallback onScan;

  @override
  ConsumerState<_InventoryList> createState() => _InventoryListState();
}

class _InventoryListState extends ConsumerState<_InventoryList> {
  /// The current search string; an empty string means "show all".
  String _searchQuery = '';

  /// Returns [_InventoryList] filtered by [_searchQuery].
  List<InventoryWithProduct> get _filtered {
    if (_searchQuery.isEmpty) return widget.items;
    final q = _searchQuery.toLowerCase();
    return widget.items.where((item) {
      return (item.productName?.toLowerCase().contains(q) ?? false) ||
          item.barcode.toLowerCase().contains(q);
    }).toList();
  }

  /// Items with an expiry date strictly before today (local time).
  List<InventoryWithProduct> get _expired {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    return _filtered.where((i) {
      if (i.expiryDate == null) return false;
      final date = DateTime.tryParse(i.expiryDate!);
      if (date == null) return false;
      return date.isBefore(todayStart);
    }).toList();
  }

  /// Items expiring between today (inclusive) and 3 days from now.
  List<InventoryWithProduct> get _expiringSoon {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final threeDaysLater = todayStart.add(const Duration(days: 3));
    return _filtered.where((i) {
      if (i.expiryDate == null) return false;
      final date = DateTime.tryParse(i.expiryDate!);
      if (date == null) return false;
      return !date.isBefore(todayStart) && date.isBefore(threeDaysLater);
    }).toList();
  }

  /// Items expiring more than 3 days in the future, or without an expiry date.
  List<InventoryWithProduct> get _good {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final threeDaysLater = todayStart.add(const Duration(days: 3));
    return _filtered.where((i) {
      if (i.expiryDate == null) return true;
      final date = DateTime.tryParse(i.expiryDate!);
      if (date == null) return true;
      return !date.isBefore(threeDaysLater);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search by name or barcode',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _searchQuery = ''),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
        ),
        // Expiry‑grouped inventory list
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              if (_expired.isNotEmpty) ...[
                _sectionHeader('Expired', Colors.red),
                ..._expired.map((item) => InventoryCard(item: item)),
              ],
              if (_expiringSoon.isNotEmpty) ...[
                _sectionHeader('Expiring soon', Colors.orange),
                ..._expiringSoon.map((item) => InventoryCard(item: item)),
              ],
              if (_good.isNotEmpty) ...[
                _sectionHeader('Good', Colors.green),
                ..._good.map((item) => InventoryCard(item: item)),
              ],
              if (_filtered.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('No items match your search')),
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// Builds a section header for an expiry group.
  Widget _sectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Text(
        title,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }
}
