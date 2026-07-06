import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:pantry_app/l10n/app_localizations.dart';
import 'package:pantry_app/models/inventory_item.dart';
import 'package:pantry_app/models/inventory_with_product.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/providers/active_inventory_provider.dart';
import 'package:pantry_app/providers/connectivity_provider.dart';
import 'package:pantry_app/providers/inventory_provider.dart';
import 'package:pantry_app/providers/product_repository_provider.dart';
import 'package:pantry_app/providers/settings_provider.dart';
import 'package:pantry_app/screens/add_product_screen.dart';
import 'package:pantry_app/screens/manage_inventories_screen.dart';
import 'package:pantry_app/screens/product_detail_screen.dart';
import 'package:pantry_app/screens/scanner_screen.dart';
import 'package:pantry_app/services/exceptions.dart';
import 'package:pantry_app/utils/date_helpers.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:pantry_app/utils/snackbar_helper.dart';
import 'package:pantry_app/utils/string_helpers.dart';
import 'package:pantry_app/widgets/empty_pantry.dart';
import 'package:pantry_app/widgets/error_view.dart';
import 'package:pantry_app/widgets/inventory_card.dart';
import 'package:pantry_app/widgets/nutriscore_badge.dart';
import 'package:url_launcher/url_launcher.dart';

/// The main dashboard of the app.
///
/// Shows inventory grouped by expiry status and provides barcode scanning.
class HomeScreen extends ConsumerStatefulWidget {
  /// Creates a [HomeScreen] widget.
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with AutomaticKeepAliveClientMixin {
  bool _selectionMode = false;
  final Set<int> _selectedIds = {};
  bool _hasCheckedOverdue = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshIfOverdue());
  }

  /// Fires a background refresh when the cached product data is older than
  /// `cacheOverdueDays` (5 days). Runs at most once per widget lifecycle.
  Future<void> _refreshIfOverdue() async {
    if (_hasCheckedOverdue || !mounted) return;
    _hasCheckedOverdue = true;
    try {
      final repo = ref.read(productRepositoryProvider);
      final online = await InternetConnectionChecker.instance.hasConnection;
      if (!online) return;
      if (!await repo.isCacheOverdue()) return;
      logInfo('Cache overdue — scheduling background refresh');
      final activeId = ref.read(activeInventoryProvider);
      repo.refreshInventoryProductsBackground(activeId);
      await repo.setLastRefreshTime();
    } on Exception catch (e) {
      logWarning('Overdue cache check failed: $e');
    }
  }

  void _toggleSelectionMode() {
    setState(() {
      _selectionMode = !_selectionMode;
      if (!_selectionMode) _selectedIds.clear();
    });
  }

  void _onLongPressItem(int id) {
    if (!_selectionMode) {
      setState(() {
        _selectionMode = true;
        _selectedIds.add(id);
      });
    }
  }

  Future<void> _deleteSelected(List<InventoryWithProduct> allItems) async {
    final l10n = AppLocalizations.of(context)!;
    final count = _selectedIds.length;
    if (count == 0) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteInventoryItem),
        content: Text(l10n.deleteCountSub(count)),
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

    final ids = Set<int>.from(_selectedIds);
    final repo = ref.read(productRepositoryProvider);
    final deletedItems = allItems
        .where((item) => ids.contains(item.id))
        .toList();
    try {
      for (final id in ids) {
        await repo.deleteInventoryItem(id);
      }
    } on Exception catch (e) {
      logError('Batch delete failed: $e');
      if (mounted) {
        SnackbarHelper.showError(context, l10n.deleteFailed);
      }
      return;
    }

    setState(() {
      _selectedIds.clear();
      _selectionMode = false;
    });
    ref.invalidate(inventoryWithProductProvider);

    if (mounted) {
      SnackbarHelper.showUndo(
        context,
        l10n.itemsDeleted(deletedItems.length),
        () async {
          for (final item in deletedItems) {
            final inventoryItem = InventoryItem(
              barcode: item.barcode,
              quantity: item.quantity,
              unit: item.unit,
              location: item.location,
              expiryDate: item.expiryDate,
              notes: item.notes,
              dateAdded: item.dateAdded,
              inventoryId: item.inventoryId,
            );
            await repo.addInventoryItem(inventoryItem);
          }
          ref.invalidate(inventoryWithProductProvider);
          if (mounted) {
            SnackbarHelper.showInfo(context, l10n.itemsRestored);
          }
        },
      );
    }
  }

  Future<void> _moveSelected(
    List<InventoryWithProduct> allItems,
    List<Map<String, dynamic>> inventories,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final count = _selectedIds.length;
    if (count == 0) return;

    final ids = Set<int>.from(_selectedIds);
    final itemsToMove = allItems
        .where((item) => ids.contains(item.id))
        .toList();

    final activeId = ref.read(activeInventoryProvider);
    final targetInventories = inventories
        .where((inv) => (inv['id'] as int) != activeId)
        .toList();

    if (targetInventories.isEmpty) return;

    final targetInv = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l10n.moveToPantry),
        children: [
          for (final inv in targetInventories)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, inv),
              child: ListTile(
                leading: const Icon(Icons.kitchen),
                title: Text(inv['name'] as String),
                subtitle: Text(
                  '${inv['item_count'] ?? 0} '
                  '${l10n.inventoryItems.toLowerCase()}',
                ),
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
        ],
      ),
    );

    if (targetInv == null || !mounted) return;

    final targetId = targetInv['id'] as int;
    final targetName = targetInv['name'] as String;
    final repo = ref.read(productRepositoryProvider);

    try {
      await repo.moveItemsToInventory(ids.toList(), targetId);
    } on Exception catch (e) {
      logError('Batch move failed: $e');
      if (mounted) {
        SnackbarHelper.showError(context, l10n.moveFailed);
      }
      return;
    }

    setState(() {
      _selectedIds.clear();
      _selectionMode = false;
    });
    ref.invalidate(inventoryWithProductProvider);

    if (mounted) {
      SnackbarHelper.showUndo(
        context,
        '${itemsToMove.length} moved to $targetName',
        () async {
          await repo.moveItemsToInventory(ids.toList(), activeId);
          ref.invalidate(inventoryWithProductProvider);
          if (mounted) {
            SnackbarHelper.showInfo(context, l10n.itemsRestored);
          }
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context)!;
    final inventoryAsync = ref.watch(inventoryWithProductProvider);
    final inventoriesAsync = ref.watch(inventoryListProvider);
    final activeId = ref.watch<int>(activeInventoryProvider);
    final settings = ref.watch(settingsProvider);
    final averageNutriscore = ref.watch(averageNutriscoreProvider);

    var appBarTitle = l10n.myPantry;
    inventoriesAsync.whenData((list) {
      for (final inv in list) {
        if (inv['id'] == activeId) {
          appBarTitle = inv['name'] as String;
          break;
        }
      }
    });

    // Always show the inventory switcher with "Create" at the bottom.
    final switcher = inventoriesAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (error, stackTrace) => const SizedBox.shrink(),
      data: (list) => PopupMenuButton<String>(
        icon: const Icon(Icons.swap_horiz),
        tooltip: l10n.switchPantry,
        onSelected: (value) {
          if (value == '__manage__') {
            unawaited(
              Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (_) => const ManageInventoriesScreen(),
                ),
              ),
            );
          } else if (value == '__create__') {
            unawaited(_showCreatePantryDialog(context, ref));
          } else {
            final id = int.tryParse(value);
            if (id != null) {
              logInfo('Switched to inventory $id');
              ref.read(activeInventoryProvider.notifier).value = id;
            }
          }
        },
        itemBuilder: (_) => [
          for (final inv in list)
            PopupMenuItem<String>(
              value: '${inv['id']}',
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      inv['name'] as String,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if ((inv['id'] as int) == activeId)
                    const Icon(Icons.check, size: 18, color: Colors.teal),
                ],
              ),
            ),
          const PopupMenuDivider(),
          PopupMenuItem<String>(
            value: '__create__',
            child: Row(
              children: [
                const Icon(Icons.add, size: 18),
                const SizedBox(width: 8),
                Flexible(child: Text(l10n.createNewPantry)),
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: '__manage__',
            child: Row(
              children: [
                const Icon(Icons.folder, size: 18),
                const SizedBox(width: 8),
                Flexible(child: Text(l10n.manageInventories)),
              ],
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(child: Text(appBarTitle, overflow: TextOverflow.ellipsis)),
            if (averageNutriscore.value != null) ...[
              const SizedBox(width: 8),
              NutriScoreBadge(
                grade: averageNutriscore.value,
                size: 24,
              ),
            ],
          ],
        ),
        centerTitle: true,
        actions: _selectionMode
            ? [
                IconButton(
                  icon: const Icon(Icons.delete),
                  tooltip: l10n.delete,
                  onPressed: () => unawaited(
                    _deleteSelected(
                      inventoryAsync.value ?? [],
                    ),
                  ),
                ),
                if (inventoriesAsync.value != null &&
                    inventoriesAsync.value!.length > 1)
                  IconButton(
                    icon: const Icon(Icons.move_up),
                    tooltip: l10n.moveToPantry,
                    onPressed: () => unawaited(
                      _moveSelected(
                        inventoryAsync.value ?? [],
                        inventoriesAsync.value!,
                      ),
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: l10n.cancel,
                  onPressed: _toggleSelectionMode,
                ),
              ]
            : [
                switcher,
                IconButton(
                  icon: const Icon(Icons.checklist),
                  tooltip: l10n.selectItems,
                  onPressed: _toggleSelectionMode,
                ),
              ],
      ),
      body: inventoryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) {
          logError('Failed to load inventory: $err');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              SnackbarHelper.showError(context, l10n.inventoryLoadFailed);
            }
          });
          return ErrorView(
            message: l10n.inventoryLoadFailed,
            onRetry: () => ref.invalidate(inventoryWithProductProvider),
          );
        },
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
      floatingActionButton: _selectionMode
          ? null
          : FloatingActionButton(
              onPressed: () => _scanBarcode(context, ref),
              child: const Icon(Icons.qr_code_scanner),
            ),
    );
  }

  Future<void> _showCreatePantryDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
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
        ref.invalidate(inventoryListProvider);
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

  Future<void> _scanBarcode(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final barcode = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const ScannerScreen()),
    );
    logInfo('Barcode scanned: $barcode');
    if (barcode == null || !context.mounted) return;

    // If offline, skip API and go directly to manual entry.
    final isOnline = ref.read(connectivityProvider).value;
    if (isOnline == false) {
      logWarning('Offline — skipping API lookup for $barcode');
      if (context.mounted) {
        SnackbarHelper.showWarning(context, l10n.offlineWarning);
        final result = await Navigator.of(context).push<Product>(
          MaterialPageRoute(
            builder: (_) => AddProductScreen(barcode: barcode),
          ),
        );
        if (result != null && context.mounted) {
          final repo = ref.read(productRepositoryProvider);
          await repo.cacheProduct(result);
          if (context.mounted) {
            await Navigator.of(context).push<void>(
              MaterialPageRoute(
                builder: (_) => ProductDetailScreen(product: result),
              ),
            );
          }
          ref.invalidate(inventoryWithProductProvider);
        }
      }
      return;
    }

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
      logWarning('Product not found for $barcode');
      if (context.mounted) {
        _showProductNotFoundSheet(context, ref, barcode);
      }
    } on FetchFailedException {
      logWarning('Network error fetching $barcode');
      if (context.mounted) {
        SnackbarHelper.showError(context, l10n.networkError);
      }
    }
  }

  void _showProductNotFoundSheet(
    BuildContext context,
    WidgetRef ref,
    String barcode,
  ) {
    final l10n = AppLocalizations.of(context)!;
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        builder: (ctx) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.productNotFound,
                style: Theme.of(ctx).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              Text(l10n.productNotFoundHint, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(ctx);
                  if (context.mounted) {
                    final result = await Navigator.of(context).push<Product>(
                      MaterialPageRoute(
                        builder: (_) => AddProductScreen(barcode: barcode),
                      ),
                    );
                    if (result != null && context.mounted) {
                      final repo = ref.read(productRepositoryProvider);
                      await repo.cacheProduct(result);
                      if (context.mounted) {
                        await Navigator.of(context).push<void>(
                          MaterialPageRoute(
                            builder: (_) =>
                                ProductDetailScreen(product: result),
                          ),
                        );
                        ref.invalidate(inventoryWithProductProvider);
                      }
                    }
                  }
                },
                icon: const Icon(Icons.add),
                label: Text(l10n.addManually),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  if (context.mounted) {
                    const storeUrl =
                        'https://play.google.com/store/apps/details?id=org.openfoodfacts.scanner&hl=en&pli=1';
                    final uri = Uri.parse(storeUrl);
                    final canLaunch = await canLaunchUrl(uri);
                    if (canLaunch && context.mounted) {
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    } else if (context.mounted) {
                      SnackbarHelper.showError(
                        context,
                        l10n.couldNotOpenPlayStore,
                      );
                    }
                  }
                },
                child: Text(l10n.contributeToOpenFoodFacts),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InventoryList extends ConsumerStatefulWidget {
  const _InventoryList({
    required this.items,
    required this.onScan,
    required this.expiringSoonDays,
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

  @override
  ConsumerState<_InventoryList> createState() => _InventoryListState();
}

class _InventoryListState extends ConsumerState<_InventoryList> {
  String _searchQuery = '';
  String? _selectedCategory;
  List<InventoryWithProduct>? _cachedFiltered;
  List<InventoryWithProduct>? _cachedExpired;
  List<InventoryWithProduct>? _cachedExpiringSoon;
  List<InventoryWithProduct>? _cachedGood;
  int? _cachedItemHash;
  String? _cachedSearchQuery;
  String? _cachedSelectedCategory;
  int? _cachedThreshold;
  Map<String, List<InventoryWithProduct>> _normalizedNameMap = {};
  List<_SectionedItem>? _cachedSectionedItems;

  /// A flat list of section headers interleaved with inventory items,
  /// ready for [ListView.builder].
  List<_SectionedItem> get _sectionedItems {
    if (_cacheValid && _cachedSectionedItems != null) {
      return _cachedSectionedItems!;
    }
    final items = <_SectionedItem>[];
    if (_expired.isNotEmpty) {
      items
        ..add(
          const _SectionHeaderItem(
            titleKey: 'expired',
            color: Colors.red,
            icon: Icons.error_outline,
          ),
        )
        ..addAll(_expired.map(_ProductItem.new));
    }
    if (_expiringSoon.isNotEmpty) {
      items
        ..add(
          const _SectionHeaderItem(
            titleKey: 'expiringSoon',
            color: Colors.orange,
            icon: Icons.warning_amber,
          ),
        )
        ..addAll(_expiringSoon.map(_ProductItem.new));
    }
    if (_good.isNotEmpty) {
      items
        ..add(
          const _SectionHeaderItem(
            titleKey: 'good',
            color: Colors.green,
            icon: Icons.check_circle_outline,
          ),
        )
        ..addAll(_good.map(_ProductItem.new));
    }
    _cachedSectionedItems = items;
    return items;
  }

  void _rebuildNameMap() {
    final map = <String, List<InventoryWithProduct>>{};
    for (final item in widget.items) {
      if (item.productName != null && item.productName!.isNotEmpty) {
        final key = removeDiacritics(item.productName!);
        map.putIfAbsent(key, () => []).add(item);
      }
    }
    _normalizedNameMap = map;
  }

  void _invalidateCache() {
    _cachedFiltered = null;
    _cachedExpired = null;
    _cachedExpiringSoon = null;
    _cachedGood = null;
    _cachedItemHash = null;
    _cachedSearchQuery = null;
    _cachedSelectedCategory = null;
    _cachedThreshold = null;
    _cachedSectionedItems = null;
  }

  bool get _cacheValid =>
      _cachedItemHash != null &&
      _cachedItemHash == widget.items.hashCode &&
      _cachedSearchQuery == _searchQuery &&
      _cachedSelectedCategory == _selectedCategory &&
      _cachedThreshold == widget.expiringSoonDays;

  Set<String> get _uniqueCategories {
    final cats = <String>{};
    for (final item in widget.items) {
      if (item.productCategory != null && item.productCategory!.isNotEmpty) {
        cats.add(item.productCategory!);
      }
    }
    return cats;
  }

  List<InventoryWithProduct> get _filtered {
    if (_cacheValid && _cachedFiltered != null) return _cachedFiltered!;

    var items = widget.items;

    // Apply search filter (case- and accent-insensitive).
    if (_searchQuery.isNotEmpty) {
      final q = removeDiacritics(_searchQuery);
      items = items.where((item) {
        return (item.productName != null &&
                removeDiacritics(item.productName!).contains(q)) ||
            removeDiacritics(item.barcode).contains(q);
      }).toList();
    }

    // Apply category filter.
    if (_selectedCategory != null) {
      items = items.where((item) {
        return item.productCategory == _selectedCategory;
      }).toList();
    }

    _cachedFiltered = items;
    _cachedItemHash = widget.items.hashCode;
    _cachedSearchQuery = _searchQuery;
    _cachedSelectedCategory = _selectedCategory;
    _cachedThreshold = widget.expiringSoonDays;
    _cachedExpired = null;
    _cachedExpiringSoon = null;
    _cachedGood = null;
    _cachedSectionedItems = null;
    return _cachedFiltered!;
  }

  List<InventoryWithProduct> get _expired {
    if (_cacheValid && _cachedExpired != null) return _cachedExpired!;
    _cachedExpired = _filtered.where((i) => isExpired(i.expiryDate)).toList();
    return _cachedExpired!;
  }

  List<InventoryWithProduct> get _expiringSoon {
    if (_cacheValid && _cachedExpiringSoon != null) {
      return _cachedExpiringSoon!;
    }
    _cachedExpiringSoon = _filtered
        .where((i) => isExpiringSoon(i.expiryDate, widget.expiringSoonDays))
        .toList();
    return _cachedExpiringSoon!;
  }

  List<InventoryWithProduct> get _good {
    if (_cacheValid && _cachedGood != null) return _cachedGood!;
    _cachedGood = _filtered.where((i) {
      if (i.expiryDate == null) return true;
      final date = parseExpiryDate(i.expiryDate);
      if (date == null) return true;
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      final threshold = todayStart.add(Duration(days: widget.expiringSoonDays));
      return !date.isBefore(threshold);
    }).toList();
    return _cachedGood!;
  }

  /// Converts an OFF taxonomy code (e.g. `'en:spreads'`) into a
  /// human‑readable display name (e.g. `'Spreads'`).
  String _displayCategory(String category) {
    final parts = category.split(':');
    final name = parts.length > 1 ? parts.sublist(1).join(':') : parts[0];
    return name
        .replaceAll(RegExp('[_-]'), ' ')
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  int get _addedThisWeekCount {
    final now = DateTime.now();
    final weekAgo = now
        .subtract(const Duration(days: 7))
        .millisecondsSinceEpoch;
    return widget.items.where((i) {
      if (i.dateAdded == null) return false;
      return i.dateAdded! >= weekAgo;
    }).length;
  }

  @override
  void didUpdateWidget(covariant _InventoryList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items ||
        oldWidget.expiringSoonDays != widget.expiringSoonDays) {
      _rebuildNameMap();
      _invalidateCache();
    }
  }

  @override
  void initState() {
    super.initState();
    _rebuildNameMap();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final categories = _uniqueCategories;

    return Column(
      children: [
        // Stock count badge row.
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: SizedBox(
            height: 32,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _countChip(
                  label: l10n.totalItemsCount(widget.items.length),
                  icon: Icons.inventory_2_outlined,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                _countChip(
                  label: l10n.expiringSoonCount(_expiringSoon.length),
                  icon: Icons.warning_amber_outlined,
                  color: Colors.orange,
                ),
                const SizedBox(width: 8),
                _countChip(
                  label: l10n.addedThisWeek(_addedThisWeekCount),
                  icon: Icons.add_circle_outline,
                  color: theme.colorScheme.tertiary,
                ),
              ],
            ),
          ),
        ),
        // Search field (with autocomplete suggestions).
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: Autocomplete<InventoryWithProduct>(
            displayStringForOption: (item) => item.productName ?? item.barcode,
            optionsBuilder: (textEditingValue) {
              if (textEditingValue.text.isEmpty) return [];

              // Lazily populate the name map if it wasn't built in initState
              // (e.g. when items were not yet available).
              if (_normalizedNameMap.isEmpty && widget.items.isNotEmpty) {
                _rebuildNameMap();
              }

              final q = removeDiacritics(textEditingValue.text);

              // Match by normalized product name.
              final matched = <InventoryWithProduct>{};
              for (final entry in _normalizedNameMap.entries) {
                if (entry.key.contains(q)) {
                  matched.addAll(entry.value);
                }
              }

              // Match by barcode (full item list iteration is cheap for
              // typical pantry sizes; barcodes are ASCII-only).
              for (final item in widget.items) {
                if (removeDiacritics(item.barcode).contains(q)) {
                  matched.add(item);
                }
              }

              // Scope to the active category filter if one is set.
              if (_selectedCategory != null) {
                matched.removeWhere(
                  (item) => item.productCategory != _selectedCategory,
                );
              }

              return matched.take(20);
            },
            onSelected: (selection) {
              setState(() {
                _searchQuery = selection.productName ?? selection.barcode;
              });
            },
            fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
              return TextField(
                controller: controller,
                focusNode: focusNode,
                decoration: InputDecoration(
                  hintText: l10n.searchHint,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            controller.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
                onSubmitted: (_) => onSubmitted(),
              );
            },
            optionsViewBuilder: (context, onSelected, options) {
              final items = options.toList();
              return Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(12),
                clipBehavior: Clip.antiAlias,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 280),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: items.length,
                    itemBuilder: (context, index) => _suggestionTile(
                      item: items[index],
                      onTap: () => onSelected(items[index]),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        // Category filter chips.
        if (categories.length >= 2)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
            child: SizedBox(
              height: 36,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 1 + categories.length,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return FilterChip(
                      label: Text(l10n.filterAll),
                      selected: _selectedCategory == null,
                      onSelected: (_) =>
                          setState(() => _selectedCategory = null),
                    );
                  }
                  final cat = categories.elementAt(index - 1);
                  return Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: FilterChip(
                      label: Text(_displayCategory(cat)),
                      selected: _selectedCategory == cat,
                      onSelected: (selected) => setState(
                        () => _selectedCategory = selected ? cat : null,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                  );
                },
              ),
            ),
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              final repo = ref.read(productRepositoryProvider);
              final lastRefresh = await repo.getLastRefreshTime();

              final cooldownExpired =
                  lastRefresh == null ||
                  DateTime.now().difference(lastRefresh).inMinutes >= 1;
              if (!cooldownExpired) {
                logInfo('Refresh skipped — cooldown active');
                ref.invalidate(inventoryWithProductProvider);
                return;
              }

              final online =
                  await InternetConnectionChecker.instance.hasConnection;
              if (online && context.mounted) {
                final activeId = ref.read(activeInventoryProvider);
                repo.refreshInventoryProductsBackground(activeId);
                await repo.setLastRefreshTime();
              }
              ref.invalidate(inventoryWithProductProvider);
            },
            child: _sectionedItems.isEmpty
                ? ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Center(
                          child: Text(
                            _selectedCategory != null
                                ? '${l10n.noItemsMatch} '
                                      '(${l10n.filterByCategory}: '
                                      '${_displayCategory(_selectedCategory!)})'
                                : l10n.noItemsMatch,
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _sectionedItems.length,
                    itemBuilder: (context, index) {
                      final element = _sectionedItems[index];
                      if (element is _SectionHeaderItem) {
                        final title = switch (element.titleKey) {
                          'expired' => l10n.expired,
                          'expiringSoon' => l10n.expiringSoon,
                          'good' => l10n.good,
                          _ => '',
                        };
                        return _sectionHeader(
                          title,
                          element.color,
                          element.icon,
                        );
                      }
                      final item = (element as _ProductItem).item;
                      return RepaintBoundary(
                        child: InventoryCard(
                          key: ValueKey(item.id),
                          item: item,
                          showCheckbox: widget.selectionMode,
                          isSelected: widget.selectedIds.contains(item.id),
                          onToggleSelection: () =>
                              widget.onToggleSelection?.call(item.id!),
                          onLongPress: () =>
                              widget.onLongPressItem?.call(item.id!),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _countChip({
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(76)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: color),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, Color color, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _suggestionTile({
    required InventoryWithProduct item,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: item.productImageUrl != null
          ? ClipOval(
              child: Image.network(
                item.productImageUrl!,
                width: 32,
                height: 32,
                cacheWidth: (32 * MediaQuery.devicePixelRatioOf(context))
                    .round(),
                cacheHeight: (32 * MediaQuery.devicePixelRatioOf(context))
                    .round(),
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const SizedBox(width: 32, height: 32);
                },
                errorBuilder: (context, error, stackTrace) =>
                    _barcodeAvatar(item.barcode),
              ),
            )
          : _barcodeAvatar(item.barcode),
      title: Text(item.productName ?? item.barcode),
      subtitle: Text(item.barcode),
      onTap: onTap,
    );
  }

  Widget _barcodeAvatar(String barcode) {
    return CircleAvatar(
      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
      radius: 16,
      child: Text(
        barcode.length >= 3
            ? barcode.substring(0, 3)
            : barcode.padRight(3, '0'),
        style: TextStyle(
          fontSize: 10,
          color: Theme.of(context).colorScheme.onSecondaryContainer,
        ),
      ),
    );
  }
}

sealed class _SectionedItem {
  const _SectionedItem();
}

class _SectionHeaderItem extends _SectionedItem {
  const _SectionHeaderItem({
    required this.titleKey,
    required this.color,
    required this.icon,
  });

  final String titleKey;

  final Color color;

  final IconData icon;
}

class _ProductItem extends _SectionedItem {
  const _ProductItem(this.item);

  final InventoryWithProduct item;
}
