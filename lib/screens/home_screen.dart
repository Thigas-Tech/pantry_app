import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/models/inventory_with_product.dart';
import 'package:pantry_app/providers/inventory_provider.dart';
import 'package:pantry_app/providers/product_repository_provider.dart';
import 'package:pantry_app/screens/product_detail_screen.dart';
import 'package:pantry_app/screens/scanner_screen.dart';
import 'package:pantry_app/screens/stats_screen.dart';
import 'package:pantry_app/services/exceptions.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

/// The main dashboard of the app (Android).
///
/// [HomeScreen] shows the user’s pantry inventory grouped by expiry status
/// (expired / expiring soon / good). It also contains the barcode scanner
/// trigger (FAB) and navigation to the [StatsScreen].
///
/// ## Loading states
///
/// While the inventory is being fetched from the database,
/// a [Shimmer] placeholder is displayed to give a sense of progress.
/// On error, a simple error text is shown.
///
/// ## Empty state
///
/// When the inventory list is empty (no items added yet), the [_EmptyPantry]
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
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventoryAsync = ref.watch(inventoryWithProductProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Pantry'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const StatsScreen()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(inventoryWithProductProvider),
          ),
        ],
      ),
      body: inventoryAsync.when(
        loading: () => const _InventoryShimmer(),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (items) {
          if (items.isEmpty) {
            return _EmptyPantry(onScan: () => _scanBarcode(context, ref));
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
  /// 4. On [ProductNotFoundException] – opens the appropriate Open Food Facts
  ///    link for the current platform (Play Store, App Store, or website).
  Future<void> _scanBarcode(BuildContext context, WidgetRef ref) async {
    final barcode = await Navigator.of(
      context,
    ).push<String>(MaterialPageRoute(builder: (_) => const ScannerScreen()));
    logInfo('Barcode scanned: $barcode');
    if (barcode == null || !context.mounted) return;

    final repo = ref.read(productRepositoryProvider);

    try {
      // 1. Try to fetch from OFF or local cache
      final product = await repo.getProduct(barcode);
      logInfo('Product found: ${product.name}');
      if (context.mounted) {
        await Navigator.of(context).push(
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open the Play Store.')),
          );
        }
      }
    }
  }
}

// ---------- Empty state ----------

/// Shown when the user has not added any items yet.
///
/// Displays a large kitchen icon, a title, a subtitle, and a button that
/// triggers the same scanning flow as the FAB.
class _EmptyPantry extends StatelessWidget {
  const _EmptyPantry({required this.onScan});

  /// Callback invoked when the user presses the scan button.
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.kitchen, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 24),
            Text(
              'Your pantry is empty',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text('Tap the button below to scan your first product'),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onScan,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Scan a barcode'),
            ),
          ],
        ),
      ),
    );
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
  /// The current search string; an empty string means “show all”.
  String _searchQuery = '';

  /// Returns [items] filtered by [searchQuery].
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
          padding: const EdgeInsets.all(12.0),
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
                ..._expired.map((item) => _InventoryCard(item: item)),
              ],
              if (_expiringSoon.isNotEmpty) ...[
                _sectionHeader('Expiring soon', Colors.orange),
                ..._expiringSoon.map((item) => _InventoryCard(item: item)),
              ],
              if (_good.isNotEmpty) ...[
                _sectionHeader('Good', Colors.green),
                ..._good.map((item) => _InventoryCard(item: item)),
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

// ---------- Individual inventory card ----------

/// A tappable card representing one inventory item.
///
/// Displays the product image (or a placeholder icon), the product name, and
/// a subtitle with quantity, location, and expiry date. A small coloured dot
/// on the right indicates whether the item is expired.
///
/// Tapping the card navigates to the [ProductDetailScreen] for that barcode,
/// fetching the product from the repository (which checks the local cache
/// first).
class _InventoryCard extends StatelessWidget {
  const _InventoryCard({required this.item});

  /// The inventory item to display.
  final InventoryWithProduct item;

  @override
  Widget build(BuildContext context) {
    final isExpired =
        item.expiryDate != null &&
        DateTime.tryParse(item.expiryDate!)?.isBefore(DateTime.now()) == true;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: item.productImageUrl != null
              ? NetworkImage(item.productImageUrl!)
              : null,
          child: item.productImageUrl == null
              ? const Icon(Icons.fastfood)
              : null,
        ),
        title: Text(item.productName ?? item.barcode),
        subtitle: Text(
          // ignore: lines_longer_than_80_chars
          '${item.quantity} ${item.unit} · ${item.location}${item.expiryDate != null ? " · Exp: ${item.expiryDate}" : ""}',
        ),
        trailing: Icon(
          Icons.circle,
          color: isExpired ? Colors.red : Colors.grey.shade300,
          size: 12,
        ),
        onTap: () async {
          // Obtain the repository from the nearest ProviderScope.
          final repo = ProviderScope.containerOf(
            context,
          ).read(productRepositoryProvider);
          try {
            final product = await repo.getProduct(item.barcode);
            if (!context.mounted) return;
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ProductDetailScreen(product: product),
              ),
            );
          } catch (_) {
            // Silently ignore errors – the product might have been removed
            // or the network is unavailable.
          }
        },
      ),
    );
  }
}

// ---------- Shimmer loading placeholder ----------

/// A shimmer effect shown while the inventory is loading.
///
/// Mimics the layout of a list of inventory cards, providing visual feedback
/// that content is being loaded.
class _InventoryShimmer extends StatelessWidget {
  const _InventoryShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: 6,
        itemBuilder: (_, _) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              const CircleAvatar(backgroundColor: Colors.white),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 14, color: Colors.white),
                    const SizedBox(height: 8),
                    Container(height: 10, width: 150, color: Colors.white),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
