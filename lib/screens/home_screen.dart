import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/l10n/app_localizations.dart';
import 'package:pantry_app/l10n/l10n_extensions.dart';
import 'package:pantry_app/models/inventory_with_product.dart';
import 'package:pantry_app/providers/active_inventory_provider.dart';
import 'package:pantry_app/providers/home_screen_controller.dart';
import 'package:pantry_app/providers/inventory_provider.dart';
import 'package:pantry_app/providers/pantry_provider.dart';
import 'package:pantry_app/providers/product_repository_provider.dart';
import 'package:pantry_app/providers/quick_add_provider.dart';
import 'package:pantry_app/providers/settings_provider.dart';
import 'package:pantry_app/screens/manage_inventories_screen.dart';
import 'package:pantry_app/screens/product_detail_screen.dart';
import 'package:pantry_app/screens/recipe_list_screen.dart';
import 'package:pantry_app/screens/scanner_screen.dart';
import 'package:pantry_app/screens/search_screen.dart';
import 'package:pantry_app/utils/date_helpers.dart';
import 'package:pantry_app/utils/progress_indicator_helper.dart';
import 'package:pantry_app/utils/snackbar_helper.dart';
import 'package:pantry_app/widgets/empty_pantry.dart';
import 'package:pantry_app/widgets/error_view.dart';
import 'package:pantry_app/widgets/inventory_card.dart';
import 'package:pantry_app/widgets/inventory_switcher_card.dart';
import 'package:pantry_app/widgets/price_visibility_toggle.dart';
import 'package:pantry_app/widgets/quick_add_produce.dart';

/// The main pantry screen showing inventory items grouped by expiry.
///
/// Displays a search bar, produce quick-add carousel, inventory switcher,
/// and a scrollable list of inventory cards grouped by expiry status.
class HomeScreen extends ConsumerStatefulWidget {
  /// Creates a [HomeScreen].
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(
        ref.read(homeScreenControllerProvider.notifier).refreshIfOverdue(),
      );
    });
  }

  Future<void> _handleQuickProduceAdd(String produceName) async {
    final notifier = ref.read(homeScreenControllerProvider.notifier);
    final l10n = AppLocalizations.of(context)!;

    final product = await notifier.handleQuickProduceAdd(produceName);

    if (product != null && mounted) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => ProductDetailScreen(product: product),
        ),
      );
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref
            ..invalidate(pantryProvider)
            ..invalidate(quickAddItemsProvider);
        });
      }
    } else if (mounted) {
      SnackbarHelper.showError(context, l10n.couldNotResolveProduct);
    }
  }

  List<Widget> _buildProduceCarousel(
    AppLocalizations l10n,
    List<String> items,
  ) {
    final controller = ref.watch(homeScreenControllerProvider);
    final localizedItems = items
        .map((e) => l10n.localizeProduceName(e))
        .toList();

    String resolveCallbackName(String displayName) {
      for (var i = 0; i < localizedItems.length; i++) {
        if (localizedItems[i] == displayName) return items[i];
      }
      return displayName;
    }

    return [
      QuickAddProduce(
        items: localizedItems,
        loadingItems: controller.loadingProduce,
        onProduceSelected: (localizedName) =>
            _handleQuickProduceAdd(resolveCallbackName(localizedName)),
      ),
    ];
  }

  Widget _buildSearchAnchor(
    AppLocalizations l10n,
    List<InventoryWithProduct> items,
  ) {
    final controller = ref.watch(homeScreenControllerProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: SearchAnchor(
        builder: (context, searchController) {
          return SearchBar(
            controller: searchController,
            hintText: l10n.searchHint,
            leading: const Padding(
              padding: EdgeInsets.only(left: 12),
              child: Icon(Icons.search),
            ),
            trailing: [
              if (controller.searchQuery.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    searchController.clear();
                    ref
                        .read(homeScreenControllerProvider.notifier)
                        .setSearchQuery('');
                  },
                ),
            ],
            onChanged: (v) => ref
                .read(homeScreenControllerProvider.notifier)
                .setSearchQuery(v),
          );
        },
        suggestionsBuilder: (context, searchController) {
          final query = searchController.text;
          if (query.isEmpty) return [];

          final q = query.toLowerCase();
          final matched = <InventoryWithProduct>{};
          for (final item in items) {
            final searchText =
                item.productSearchText ??
                '${item.productName ?? ''} ${item.barcode}';
            if (searchText.toLowerCase().contains(q)) {
              matched.add(item);
            }
          }
          return matched.take(20).map((item) {
            return ListTile(
              title: Text(item.productName ?? item.barcode),
              subtitle: Text(item.barcode),
              onTap: () {
                searchController.closeView(item.productName ?? item.barcode);
                ref
                    .read(homeScreenControllerProvider.notifier)
                    .setSearchQuery(item.productName ?? item.barcode);
              },
            );
          });
        },
      ),
    );
  }

  void _showActionSheet() {
    final l10n = AppLocalizations.of(context)!;
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.search),
                title: Text(l10n.addProduct),
                subtitle: Text(l10n.addProductSubtitle),
                onTap: () {
                  Navigator.pop(ctx);
                  unawaited(
                    Navigator.of(context).push<void>(
                      MaterialPageRoute(
                        builder: (_) => const SearchScreen(),
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.restaurant),
                title: Text(l10n.registerRecipe),
                subtitle: Text(l10n.registerRecipeSubtitle),
                onTap: () {
                  Navigator.pop(ctx);
                  unawaited(
                    Navigator.of(context).push<void>(
                      MaterialPageRoute(
                        builder: (_) => const RecipeListScreen(),
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.qr_code_scanner),
                title: Text(l10n.scanBarcode),
                subtitle: Text(l10n.scanBarcodeSubtitle),
                onTap: () {
                  Navigator.pop(ctx);
                  unawaited(_scanBarcode(context, ref));
                },
              ),
              ListTile(
                leading: const Icon(Icons.shopping_cart),
                title: Text(l10n.marketTrip),
                subtitle: Text(l10n.marketTripSubtitle),
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.comingSoon)),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _scanBarcode(BuildContext context, WidgetRef ref) async {
    final navigator = Navigator.of(context);
    await navigator.push<void>(
      MaterialPageRoute(builder: (_) => const ScannerScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context)!;
    final pantryAsync = ref.watch(pantryProvider);
    final controller = ref.watch(homeScreenControllerProvider);
    final priceTrackingEnabled = ref.watch(
      settingsProvider.select((s) => s.priceTrackingEnabled),
    );
    final expiringSoonDays = ref.watch(
      settingsProvider.select((s) => s.expiringSoonDays),
    );

    final inventories = ref.watch(inventoryListProvider);
    final averageNutriscore = ref.watch(averageNutriscoreProvider).value;
    final quickAddItemsAsync = ref.watch(quickAddItemsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: controller.selectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => ref
                    .read(
                      homeScreenControllerProvider.notifier,
                    )
                    .exitSelectionMode(),
              )
            : null,
        title: controller.selectionMode
            ? Text(l10n.selectedCount(controller.selectedIds.length))
            : Text(l10n.myPantry),
        actions: [
          if (controller.selectionMode) ...[
            if (controller.selectedIds.isNotEmpty) ...[
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => ref
                    .read(
                      homeScreenControllerProvider.notifier,
                    )
                    .deleteSelected(),
                tooltip: l10n.delete,
              ),
              IconButton(
                icon: const Icon(Icons.drive_file_move_outline),
                onPressed: () => _moveSelected(
                  ref.read(homeScreenControllerProvider.notifier),
                ),
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
                nutriscoreGrade: averageNutriscore,
                onTap: () async {
                  final result = await Navigator.of(context).push<Object>(
                    MaterialPageRoute(
                      builder: (_) => const ManageInventoriesScreen(),
                    ),
                  );
                  if (result == true && context.mounted) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      ref.invalidate(pantryProvider);
                    });
                  }
                },
              ),
            ],
          ],
        ],
      ),
      body: Column(
        children: [
          if (!controller.selectionMode)
            _buildSearchAnchor(l10n, pantryAsync.asData?.value ?? []),
          if (!controller.selectionMode)
            ..._buildProduceCarousel(
              l10n,
              quickAddItemsAsync.asData?.value ?? [],
            ),
          Expanded(
            child: pantryAsync.when(
              loading: () => Center(child: ProgressIndicatorHelper.build()),
              error: (err, _) => ErrorView(
                message: l10n.inventoryLoadFailed,
                onRetry: () =>
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      ref.invalidate(pantryProvider);
                    }),
              ),
              data: (items) {
                if (items.isEmpty && !controller.selectionMode) {
                  return EmptyPantry(onScan: _showActionSheet);
                }
                return _InventoryList(
                  items: items,
                  onScan: _showActionSheet,
                  expiringSoonDays: expiringSoonDays,
                  selectionMode: controller.selectionMode,
                  selectedIds: controller.selectedIds,
                  searchQuery: controller.searchQuery,
                  onToggleSelection: (id) => ref
                      .read(
                        homeScreenControllerProvider.notifier,
                      )
                      .toggleSelection(id),
                  onLongPressItem: (id) => ref
                      .read(
                        homeScreenControllerProvider.notifier,
                      )
                      .enterSelectionMode(id),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: controller.selectionMode
          ? null
          : FloatingActionButton(
              heroTag: null,
              onPressed: _showActionSheet,
              child: const Icon(Icons.add),
            ),
    );
  }

  Future<void> _moveSelected(
    HomeScreenController notifier,
  ) async {
    final controller = ref.watch(homeScreenControllerProvider);
    if (controller.selectedIds.isEmpty) return;
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
    await notifier.moveSelected(targetId);
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
    final q = widget.searchQuery.toLowerCase();
    return widget.items.where((item) {
      final searchText =
          item.productSearchText ?? '${item.productName ?? ''} ${item.barcode}';
      return searchText.toLowerCase().contains(q);
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
        final activeId = ref.read(activeInventoryProvider);
        final repo = ref.read(productRepositoryProvider);
        await repo.refreshInventoryProducts(activeId);
        await repo.setLastRefreshTime();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.invalidate(pantryProvider);
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
