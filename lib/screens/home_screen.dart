import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/models/inventory_with_product.dart';
import 'package:pantry_app/providers/inventory_provider.dart';
import 'package:pantry_app/providers/product_repository_provider.dart';
import 'package:pantry_app/screens/product_detail_screen.dart';
import 'package:pantry_app/screens/scanner_screen.dart';
import 'package:pantry_app/services/exceptions.dart';

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
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(inventoryWithProductProvider),
          ),
        ],
      ),
      body: inventoryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
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

  Future<void> _scanBarcode(BuildContext context, WidgetRef ref) async {
    final barcode = await Navigator.of(
      context,
    ).push<String>(MaterialPageRoute(builder: (_) => const ScannerScreen()));
    if (barcode == null || !context.mounted) return;

    try {
      final repo = ref.read(productRepositoryProvider);
      final product = await repo.getProduct(barcode);
      if (context.mounted) {
        unawaited(
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ProductDetailScreen(product: product),
            ),
          ),
        );
        ref.invalidate(
          inventoryWithProductProvider,
        ); // refresh list when we come back
      }
    } on ProductNotFoundException {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Product not found')));
      }
    } on FetchFailedException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }
}

// ---------- Empty state ----------
class _EmptyPantry extends StatelessWidget {
  const _EmptyPantry({required this.onScan});
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

// ---------- List with expiry grouping & search ----------
class _InventoryList extends ConsumerStatefulWidget {
  const _InventoryList({required this.items, required this.onScan});
  final List<InventoryWithProduct> items;
  final VoidCallback onScan;

  @override
  ConsumerState<_InventoryList> createState() => _InventoryListState();
}

class _InventoryListState extends ConsumerState<_InventoryList> {
  String _searchQuery = '';

  List<InventoryWithProduct> get _filtered {
    if (_searchQuery.isEmpty) return widget.items;
    final q = _searchQuery.toLowerCase();
    return widget.items.where((item) {
      return (item.productName?.toLowerCase().contains(q) ?? false) ||
          item.barcode.toLowerCase().contains(q);
    }).toList();
  }

  // Group by expiry
  List<InventoryWithProduct> get _expired => _filtered
      .where(
        (i) =>
            i.expiryDate != null &&
            DateTime.tryParse(i.expiryDate!)?.isBefore(DateTime.now()) == true,
      )
      .toList();

  List<InventoryWithProduct> get _expiringSoon => _filtered.where((i) {
    if (i.expiryDate == null) return false;
    final date = DateTime.tryParse(i.expiryDate!);
    if (date == null) return false;
    final diff = date.difference(DateTime.now()).inDays;
    return diff >= 0 && diff <= 3;
  }).toList();

  List<InventoryWithProduct> get _good => _filtered.where((i) {
    if (i.expiryDate == null) return true; // no expiry → good
    final date = DateTime.tryParse(i.expiryDate!);
    if (date == null) return true;
    final diff = date.difference(DateTime.now()).inDays;
    return diff > 3;
  }).toList();

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
        // Grouped list
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

class _InventoryCard extends StatelessWidget {
  const _InventoryCard({required this.item});
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
          // Navigate to product detail via barcode (we can fetch product there)
          final repo = ProviderScope.containerOf(
            context,
          ).read(productRepositoryProvider);
          try {
            final product = await repo.getProduct(item.barcode);
            if (context.mounted) {
              unawaited(
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ProductDetailScreen(product: product),
                  ),
                ),
              );
            }
          } catch (_) {
            // ignore
          }
        },
      ),
    );
  }
}
