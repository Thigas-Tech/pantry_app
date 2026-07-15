import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:pantry_app/l10n/app_localizations.dart';
import 'package:pantry_app/l10n/l10n_extensions.dart';
import 'package:pantry_app/models/inventory_with_product.dart';
import 'package:pantry_app/models/product_type.dart';
import 'package:pantry_app/providers/active_inventory_provider.dart';
import 'package:pantry_app/providers/api_service_provider.dart';
import 'package:pantry_app/providers/database_provider.dart';
import 'package:pantry_app/providers/inventory_provider.dart';
import 'package:pantry_app/providers/product_repository_provider.dart';
import 'package:pantry_app/providers/settings_provider.dart';
import 'package:pantry_app/screens/manage_inventories_screen.dart';
import 'package:pantry_app/screens/product_detail_screen.dart';
import 'package:pantry_app/screens/scanner_screen.dart';
import 'package:pantry_app/screens/search_screen.dart';
import 'package:pantry_app/services/exceptions.dart';
import 'package:pantry_app/services/produce_purchase_tracker.dart';
import 'package:pantry_app/services/scan_result.dart';
import 'package:pantry_app/utils/date_helpers.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:pantry_app/utils/search_utils.dart';
import 'package:pantry_app/utils/snackbar_helper.dart';
import 'package:pantry_app/widgets/empty_pantry.dart';
import 'package:pantry_app/widgets/error_view.dart';
import 'package:pantry_app/widgets/inventory_card.dart';
import 'package:pantry_app/widgets/inventory_switcher_card.dart';
import 'package:pantry_app/widgets/price_visibility_toggle.dart';
import 'package:pantry_app/widgets/quick_add_produce.dart';

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
  List<String> _quickAddItems = [];
  final Set<String> _loadingProduce = {};

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_refreshIfOverdue());
      unawaited(_loadQuickAddItems());
    });
  }

  Future<void> _loadQuickAddItems() async {
    try {
      final tracker = ProducePurchaseTracker();
      final items = await tracker.getTopPurchases();
      if (mounted) setState(() => _quickAddItems = items);
    } on Exception catch (e) {
      logWarning('Failed to load quick-add items: $e');
      if (mounted) {
        setState(
          () => _quickAddItems = ProducePurchaseTracker.getDefaultList(),
        );
      }
    }
  }

  Future<void> _handleQuickProduceAdd(String produceName) async {
    if (_loadingProduce.contains(produceName)) return;
    setState(() => _loadingProduce.add(produceName));

    final repo = ref.read(productRepositoryProvider);
    final l10n = AppLocalizations.of(context)!;

    try {
      final product = await repo.resolveProduceProduct(produceName);
      if (!mounted) return;
      setState(() => _loadingProduce.remove(produceName));

      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => ProductDetailScreen(product: product),
        ),
      );

      if (!mounted) return;
      ref.invalidate(inventoryWithProductProvider);
      await ProducePurchaseTracker().recordPurchase(produceName);
    } on Exception catch (e) {
      logError('Failed to resolve produce product: $e');
      if (mounted) {
        setState(() => _loadingProduce.remove(produceName));
        SnackbarHelper.showError(context, l10n.couldNotCreateInventory);
      }
    }
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

  void _exitSelectionMode() {
    setState(() {
      _selectionMode = false;
      _selectedIds.clear();
    });
  }

  Future<void> _deleteSelected() async {
    if (_selectedIds.isEmpty) return;
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteItemTitle),
        content: Text(l10n.deleteCountSub(_selectedIds.length)),
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
    if (confirmed != true || !mounted) return;

    final db = ref.read(databaseProvider);
    for (final id in _selectedIds) {
      await db.deleteInventoryItem(id);
    }
    ref.invalidate(inventoryWithProductProvider);
    _exitSelectionMode();
  }

  Future<void> _moveSelected() async {
    if (_selectedIds.isEmpty) return;
    final inventories = ref.read(inventoryListProvider).asData?.value ?? [];
    final activeId = ref.read(activeInventoryProvider);
    final targetInventories = inventories
        .where((inv) => inv['id'] != activeId)
        .toList();

    final l10n = AppLocalizations.of(context)!;
    if (targetInventories.isEmpty) {
      SnackbarHelper.showInfo(context, l10n.noOtherInventories);
      return;
    }

    final targetId = await showModalBottomSheet<int>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                l10n.moveToPantry,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            ...targetInventories.map(
              (inv) => ListTile(
                leading: const Icon(Icons.inventory_2),
                title: Text(l10n.displayInventoryName(inv['name'] as String)),
                onTap: () => Navigator.pop(ctx, inv['id'] as int),
              ),
            ),
          ],
        ),
      ),
    );

    if (targetId == null || !mounted) return;

    final db = ref.read(databaseProvider);
    await db.moveItemsToInventory(_selectedIds.toList(), targetId);
    ref.invalidate(inventoryWithProductProvider);
    _exitSelectionMode();
  }

  Future<void> _scanBarcode(BuildContext context, WidgetRef ref) async {
    final navigator = Navigator.of(context);
    final result = await navigator.push<ScanResult>(
      MaterialPageRoute(builder: (_) => const ScannerScreen()),
    );
    if (result == null) return;
    // Capture context before async gap.
    if (!context.mounted) return;

    switch (result) {
      case BarcodeResult(:final barcode):
        await _handleBarcodeResult(context, ref, barcode);
      case PluResult(:final pluCode, :final produceName):
        await _handlePluResult(context, ref, pluCode, produceName);
    }
  }

  Future<void> _handleBarcodeResult(
    BuildContext context,
    WidgetRef ref,
    String barcode,
  ) async {
    final navigator = Navigator.of(context);
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
      if (!context.mounted) return;
      final l10n = AppLocalizations.of(context)!;
      if (e is ProductNotFoundException) {
        SnackbarHelper.showWarning(context, l10n.productNotFound);
      } else {
        SnackbarHelper.showError(context, l10n.scanFailed);
      }
    }
  }

  Future<void> _handlePluResult(
    BuildContext context,
    WidgetRef ref,
    String pluCode,
    String produceName,
  ) async {
    logInfo('PLU result: $pluCode — $produceName');
    final navigator = Navigator.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;

    // Search OFF API for the produce name to get nutrition data.
    try {
      final api = ref.read(apiServiceProvider);
      final results = await api.searchProducts(
        produceName,
        languageCode: languageCode,
      );
      if (results.isNotEmpty) {
        final best = results.firstWhere(
          (p) => p.name.toLowerCase().contains(produceName.toLowerCase()),
          orElse: () => results.first,
        );
        final enriched = best.copyWith(
          productType: ProductType.produce,
          pluCode: pluCode,
        );
        if (mounted) {
          await navigator.push<void>(
            MaterialPageRoute(
              builder: (_) => ProductDetailScreen(product: enriched),
            ),
          );
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.invalidate(inventoryWithProductProvider);
          });
        }
        return;
      }
    } on Exception catch (e) {
      logWarning('OFF search failed for $produceName: $e');
    }

    // Fallback: navigate to SearchScreen with the produce name pre-entered.
    if (mounted) {
      await navigator.push<void>(
        MaterialPageRoute(
          builder: (_) => const SearchScreen(),
        ),
      );
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

          final q = normalizeForSearch(query);
          final matched = <InventoryWithProduct>{};
          for (final item in items) {
            final searchText =
                item.productSearchText ??
                normalizeForSearch(
                  [
                    item.productName,
                    item.barcode,
                    item.productCategory,
                  ].whereType<String>().join(' '),
                );
            if (searchText.contains(q)) {
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
    final priceTrackingEnabled = ref.watch(
      settingsProvider.select((s) => s.priceTrackingEnabled),
    );
    final expiringSoonDays = ref.watch(
      settingsProvider.select((s) => s.expiringSoonDays),
    );

    final inventories = ref.watch(inventoryListProvider);

    return Scaffold(
      appBar: AppBar(
        leading: _selectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _exitSelectionMode,
              )
            : null,
        title: _selectionMode
            ? Text(l10n.selectedCount(_selectedIds.length))
            : Text(l10n.myPantry),
        actions: [
          if (_selectionMode) ...[
            if (_selectedIds.isNotEmpty) ...[
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: _deleteSelected,
                tooltip: l10n.delete,
              ),
              IconButton(
                icon: const Icon(Icons.drive_file_move_outline),
                onPressed: _moveSelected,
                tooltip: l10n.moveToPantry,
              ),
            ],
          ] else ...[
            if (priceTrackingEnabled) const PriceVisibilityToggle(),
            if (inventories.asData?.value != null) ...[
              InventorySwitcherCard(
                name: l10n.displayInventoryName(
                  (inventories.asData!.value
                              .cast<Map<String, dynamic>>()
                              .firstWhere(
                                (inv) =>
                                    inv['id'] ==
                                    ref.read(activeInventoryProvider),
                                orElse: () => <String, dynamic>{
                                  'name': l10n.myPantry,
                                },
                              )['name']
                          as String?) ??
                      l10n.myPantry,
                ),
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
        ],
      ),
      body: Column(
        children: [
          if (!_selectionMode)
            _buildSearchAnchor(l10n, inventoryAsync.asData?.value ?? []),
          if (!_selectionMode && _quickAddItems.isNotEmpty)
            QuickAddProduce(
              items: _quickAddItems,
              loadingItems: _loadingProduce,
              onProduceSelected: _handleQuickProduceAdd,
            ),
          Expanded(
            child: inventoryAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => ErrorView(
                message: l10n.inventoryLoadFailed,
                onRetry: () => ref.invalidate(inventoryWithProductProvider),
              ),
              data: (items) {
                if (items.isEmpty && !_selectionMode) {
                  return EmptyPantry(onScan: () => _scanBarcode(context, ref));
                }
                return _InventoryList(
                  items: items,
                  onScan: () => _scanBarcode(context, ref),
                  expiringSoonDays: expiringSoonDays,
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
              heroTag: null,
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
    final q = normalizeForSearch(widget.searchQuery);
    return widget.items.where((item) {
      final searchText =
          item.productSearchText ??
          normalizeForSearch(
            [
              item.productName,
              item.barcode,
              item.productCategory,
            ].whereType<String>().join(' '),
          );
      return searchText.contains(q);
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
