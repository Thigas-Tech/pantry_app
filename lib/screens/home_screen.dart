import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:pantry_app/l10n/app_localizations.dart';
import 'package:pantry_app/models/inventory_with_product.dart';
import 'package:pantry_app/providers/active_inventory_provider.dart';
import 'package:pantry_app/providers/inventory_provider.dart';
import 'package:pantry_app/providers/product_repository_provider.dart';
import 'package:pantry_app/providers/settings_provider.dart';
import 'package:pantry_app/screens/manage_inventories_screen.dart';
import 'package:pantry_app/screens/product_detail_screen.dart';
import 'package:pantry_app/screens/scanner_screen.dart';
import 'package:pantry_app/utils/date_helpers.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:pantry_app/utils/string_helpers.dart';
import 'package:pantry_app/widgets/empty_pantry.dart';
import 'package:pantry_app/widgets/error_view.dart';
import 'package:pantry_app/widgets/inventory_card.dart';
import 'package:pantry_app/widgets/inventory_switcher_card.dart';

/// The main pantry inventory screen.
class HomeScreen extends ConsumerStatefulWidget {
  /// Creates a [HomeScreen].
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with AutomaticKeepAliveClientMixin {
  bool _selectionMode = false;
  final Set<int> _selectedIds = {};
  bool _hasCheckedOverdue = false;
  String _searchQuery = '';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshIfOverdue());
  }

  Future<void> _refreshIfOverdue() async {
    if (_hasCheckedOverdue || !mounted) return;
    _hasCheckedOverdue = true;
    try {
      final repo = ref.read(productRepositoryProvider);
      final online = await InternetConnectionChecker.instance.hasConnection;
      if (!online) return;
      if (!await repo.isCacheOverdue()) return;
      final activeId = ref.read(activeInventoryProvider);
      repo.refreshInventoryProductsBackground(activeId);
      await repo.setLastRefreshTime();
    } on Exception catch (e) {
      logWarning('Overdue cache check failed: $e');
    }
  }

  void _onLongPressItem(int id) {
    if (!_selectionMode) {
      setState(() {
        _selectionMode = true;
        _selectedIds.add(id);
      });
    }
  }

  Future<void> _scanBarcode(BuildContext context, WidgetRef ref) async {
    final navigator = Navigator.of(context);
    final barcode = await navigator.push<String>(
      MaterialPageRoute(builder: (_) => const ScannerScreen()),
    );
    if (barcode == null || !mounted) return;
    final repo = ref.read(productRepositoryProvider);
    try {
      final product = await repo.getProduct(barcode);
      if (mounted) {
        await navigator.push<void>(
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(product: product),
          ),
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.invalidate(inventoryWithProductProvider);
        });
      }
    } on Exception catch (e) {
      logWarning('Scan failed for $barcode: $e');
    }
  }

  Widget _buildSearchAnchor(
    AppLocalizations l10n,
    List<InventoryWithProduct> items,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: SearchAnchor(
        builder: (context, controller) {
          return SearchBar(
            controller: controller,
            hintText: l10n.searchHint,
            leading: const Padding(
              padding: EdgeInsets.only(left: 12),
              child: Icon(Icons.search),
            ),
            trailing: [
              if (_searchQuery.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    controller.clear();
                    setState(() => _searchQuery = '');
                  },
                ),
            ],
            onChanged: (v) => setState(() => _searchQuery = v),
          );
        },
        suggestionsBuilder: (context, controller) {
          final query = controller.text;
          if (query.isEmpty) return [];

          final q = removeDiacritics(query.trim().toLowerCase());
          final matched = <InventoryWithProduct>{};
          for (final item in items) {
            final name = item.productName ?? item.barcode;
            if (removeDiacritics(name.toLowerCase()).contains(q) ||
                removeDiacritics(item.barcode).contains(q)) {
              matched.add(item);
            }
          }
          return matched.take(20).map((item) {
            return ListTile(
              title: Text(item.productName ?? item.barcode),
              subtitle: Text(item.barcode),
              onTap: () {
                controller.closeView(item.productName ?? item.barcode);
                setState(() => _searchQuery = item.productName ?? item.barcode);
              },
            );
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context)!;
    final inventoryAsync = ref.watch(inventoryWithProductProvider);
    final settings = ref.watch(settingsProvider);

    final inventories = ref.watch(inventoryListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myPantry),
        actions: [
          if (inventories.asData?.value != null) ...[
            InventorySwitcherCard(
              name:
                  inventories.asData!.value
                          .cast<Map<String, dynamic>>()
                          .firstWhere(
                            (inv) =>
                                inv['id'] == ref.read(activeInventoryProvider),
                            orElse: () => <String, dynamic>{
                              'name': l10n.myPantry,
                            },
                          )['name']
                      as String?,
              nutriscoreGrade: inventoryAsync.asData?.value.isNotEmpty == true
                  ? null
                  : null,
              onTap: () async {
                final result = await Navigator.of(context).push<Object>(
                  MaterialPageRoute(
                    builder: (_) => const ManageInventoriesScreen(),
                  ),
                );
                if (result == true && context.mounted) {
                  ref.invalidate(inventoryWithProductProvider);
                }
              },
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          _buildSearchAnchor(l10n, inventoryAsync.asData?.value ?? []),
          Expanded(
            child: inventoryAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => ErrorView(
                message: l10n.inventoryLoadFailed,
                onRetry: () => ref.invalidate(inventoryWithProductProvider),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return EmptyPantry(onScan: () => _scanBarcode(context, ref));
                }
                return _InventoryList(
                  items: items,
                  onScan: () => _scanBarcode(context, ref),
                  expiringSoonDays: settings.expiringSoonDays,
                  selectionMode: _selectionMode,
                  selectedIds: _selectedIds,
                  searchQuery: _searchQuery,
                  onToggleSelection: (id) => setState(() {
                    if (_selectedIds.contains(id)) {
                      _selectedIds.remove(id);
                    } else {
                      _selectedIds.add(id);
                    }
                  }),
                  onLongPressItem: _onLongPressItem,
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _selectionMode
          ? null
          : FloatingActionButton(
              onPressed: () => _scanBarcode(context, ref),
              child: const Icon(Icons.qr_code_scanner),
            ),
    );
  }
}

class _InventoryList extends ConsumerStatefulWidget {
  const _InventoryList({
    required this.items,
    required this.onScan,
    required this.expiringSoonDays,
    required this.searchQuery,
    this.selectionMode = false,
    this.selectedIds = const {},
    this.onToggleSelection,
    this.onLongPressItem,
  });

  final List<InventoryWithProduct> items;
  final VoidCallback onScan;
  final int expiringSoonDays;
  final bool selectionMode;
  final Set<int> selectedIds;
  final void Function(int itemId)? onToggleSelection;
  final void Function(int itemId)? onLongPressItem;
  final String searchQuery;

  @override
  ConsumerState<_InventoryList> createState() => _InventoryListState();
}

class _InventoryListState extends ConsumerState<_InventoryList> {
  List<InventoryWithProduct> get _filtered {
    if (widget.searchQuery.isEmpty) return widget.items;
    final q = removeDiacritics(widget.searchQuery.trim().toLowerCase());
    return widget.items.where((item) {
      final name = item.productName ?? item.barcode;
      return removeDiacritics(name.toLowerCase()).contains(q) ||
          removeDiacritics(item.barcode).contains(q);
    }).toList();
  }

  List<InventoryWithProduct> get _expired =>
      _filtered.where((i) => isExpired(i.expiryDate)).toList();

  List<InventoryWithProduct> get _expiringSoon => _filtered
      .where(
        (i) => isExpiringSoon(i.expiryDate, widget.expiringSoonDays),
      )
      .toList();

  List<InventoryWithProduct> get _good {
    final threshold = DateTime.now().add(
      Duration(days: widget.expiringSoonDays),
    );
    return _filtered.where((i) {
      if (i.expiryDate == null) return true;
      final date = parseExpiryDate(i.expiryDate);
      if (date == null) return true;
      return !date.isBefore(threshold);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final weekAgo = now
        .subtract(const Duration(days: 7))
        .millisecondsSinceEpoch;
    final addedThisWeek = widget.items.where((i) {
      if (i.dateAdded == null) return false;
      return i.dateAdded! >= weekAgo;
    }).length;

    return RefreshIndicator(
      onRefresh: () async {
        final repo = ref.read(productRepositoryProvider);
        final activeId = ref.read(activeInventoryProvider);
        repo.refreshInventoryProductsBackground(activeId);
        await repo.setLastRefreshTime();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.invalidate(inventoryWithProductProvider);
        });
      },
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          SizedBox(
            height: 32,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _countChip(
                    l10n.totalItemsCount(widget.items.length),
                    Icons.inventory_2_outlined,
                  ),
                  const SizedBox(width: 8),
                  _countChip(
                    l10n.expiringSoonCount(_expiringSoon.length),
                    Icons.warning_amber_outlined,
                  ),
                  const SizedBox(width: 8),
                  _countChip(
                    l10n.addedThisWeek(addedThisWeek),
                    Icons.add_circle_outline,
                  ),
                ],
              ),
            ),
          ),
          if (_expired.isNotEmpty) ...[
            _sectionHeader(l10n.expired, Icons.error_outline),
            ..._expired.map(_buildCard),
          ],
          if (_expiringSoon.isNotEmpty) ...[
            _sectionHeader(l10n.expiringSoon, Icons.warning_amber),
            ..._expiringSoon.map(_buildCard),
          ],
          if (_good.isNotEmpty) ...[
            _sectionHeader(l10n.good, Icons.check_circle_outline),
            ..._good.map(_buildCard),
          ],
          if (_filtered.isEmpty && widget.searchQuery.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(child: Text(l10n.noItemsMatch)),
            ),
        ],
      ),
    );
  }

  Widget _countChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withAlpha(25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withAlpha(76),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(InventoryWithProduct item) {
    return RepaintBoundary(
      child: InventoryCard(
        key: ValueKey(item.id),
        item: item,
        showCheckbox: widget.selectionMode,
        isSelected: widget.selectedIds.contains(item.id),
        onToggleSelection: () => widget.onToggleSelection?.call(item.id!),
        onLongPress: () => widget.onLongPressItem?.call(item.id!),
      ),
    );
  }
}
