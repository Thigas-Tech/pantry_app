import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/l10n/app_localizations.dart';
import 'package:pantry_app/l10n/l10n_extensions.dart';
import 'package:pantry_app/models/inventory_summary.dart';
import 'package:pantry_app/models/inventory_with_product.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/providers/active_inventory_provider.dart';
import 'package:pantry_app/providers/home_screen_controller.dart';
import 'package:pantry_app/providers/inventory_provider.dart';
import 'package:pantry_app/providers/onboarding_provider.dart';
import 'package:pantry_app/providers/pantry_provider.dart';
import 'package:pantry_app/providers/settings_provider.dart';
import 'package:pantry_app/screens/manage_inventories_screen.dart';
import 'package:pantry_app/screens/market_trip_screen.dart';
import 'package:pantry_app/screens/product_detail_screen.dart';
import 'package:pantry_app/screens/recipe_list_screen.dart';
import 'package:pantry_app/screens/scanner_screen.dart';
import 'package:pantry_app/screens/search_screen.dart';
import 'package:pantry_app/utils/deferred_refresh.dart';
import 'package:pantry_app/utils/inventory_grouping.dart';
import 'package:pantry_app/utils/progress_indicator_helper.dart';
import 'package:pantry_app/utils/snackbar_helper.dart';
import 'package:pantry_app/widgets/empty_pantry.dart';
import 'package:pantry_app/widgets/error_view.dart';
import 'package:pantry_app/widgets/inventory_card.dart';
import 'package:pantry_app/widgets/inventory_switcher_card.dart';
import 'package:pantry_app/widgets/onboarding_flow.dart';
import 'package:pantry_app/widgets/price_visibility_toggle.dart';
import 'package:pantry_app/widgets/search_panel.dart';
import 'package:pantry_app/widgets/section_header.dart';

/// The main pantry screen showing inventory items grouped by expiry.
///
/// Displays a search bar, inventory switcher, and a scrollable list of
/// inventory cards grouped by expiry status.
class HomeScreen extends ConsumerStatefulWidget {
  /// Creates a [HomeScreen].
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with AutomaticKeepAliveClientMixin {
  bool _isSearchActive = false;

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

  Widget _buildSearchBar(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: SearchBar(
        hintText: l10n.searchHint,
        leading: const Padding(
          padding: EdgeInsets.only(left: 12),
          child: Icon(Icons.search),
        ),
        onTap: () => setState(() => _isSearchActive = true),
      ),
    );
  }

  void _exitSearchMode() {
    setState(() => _isSearchActive = false);
  }

  Future<void> _onHomeProductSelected(Product product) async {
    if (!_isSearchActive) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(product: product),
      ),
    );
    if (mounted) {
      afterFrame(() {
        if (mounted) ref.invalidate(pantryProvider);
      });
    }
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
                  unawaited(
                    Navigator.of(context).push<void>(
                      MaterialPageRoute(
                        builder: (_) => const MarketTripScreen(),
                      ),
                    ),
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

  /// Returns the display name for the inventory with [activeId] from
  /// [inventories], falling back to [fallback] when not found.
  String _inventoryName(
    List<InventorySummary> inventories,
    int activeId,
    String fallback,
  ) {
    for (final inv in inventories) {
      if (inv.id == activeId) return inv.name;
    }
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context)!;
    final pantryAsync = ref.watch(pantryProvider);
    final controller = ref.watch(homeScreenControllerProvider);
    final priceTrackingEnabled =
        ref.watch(settingsProvider).value?.priceTrackingEnabled ?? false;
    final expiringSoonDays =
        ref.watch(settingsProvider).value?.expiringSoonDays ?? 3;

    final inventories = ref.watch(inventoryListProvider);
    final averageNutriscore = ref.watch(averageNutriscoreProvider).value;
    final onboardingComplete = ref.watch(onboardingProvider).value ?? false;

    ref.listen(totalInventoryCountProvider, (prev, next) {
      final prevValue = prev?.asData?.value ?? 0;
      final nextValue = next.asData?.value ?? 0;
      if (prevValue == 0 && nextValue > 0) {
        unawaited(ref.read(onboardingProvider.notifier).markComplete());
      }
    });

    return PopScope(
      canPop: !_isSearchActive,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _isSearchActive) {
          _exitSearchMode();
        }
      },
      child: Scaffold(
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
                    _inventoryName(
                      inventories.asData?.value ?? const [],
                      ref.read(activeInventoryProvider).value ?? 1,
                      l10n.myPantry,
                    ),
                  ),
                  nutriscoreGrade: averageNutriscore,
                  onTap: () async {
                    final result = await Navigator.of(context).push<Object>(
                      MaterialPageRoute(
                        builder: (_) => const ManageInventoriesScreen(),
                      ),
                    );
                    if (result == true && context.mounted) {
                      afterFrame(() {
                        if (context.mounted) ref.invalidate(pantryProvider);
                      });
                    }
                  },
                ),
              ],
            ],
          ],
        ),
        body: _isSearchActive
            ? SearchPanel(
                onProductSelected: _onHomeProductSelected,
                showBackButton: true,
                onBack: _exitSearchMode,
              )
            : Column(
                children: [
                  if (!controller.selectionMode) _buildSearchBar(l10n),
                  Expanded(
                    child: pantryAsync.when(
                      loading: () => Center(
                        child: ProgressIndicatorHelper.build(),
                      ),
                      error: (err, _) => ErrorView(
                        message: l10n.inventoryLoadFailed,
                        onRetry: () => ref.invalidate(pantryProvider),
                      ),
                      data: (items) {
                        if (items.isEmpty && !controller.selectionMode) {
                          if (!onboardingComplete) {
                            return OnboardingFlow(
                              onScanBarcode: () =>
                                  unawaited(_scanBarcode(context, ref)),
                              onSearchProduct: () => unawaited(
                                Navigator.of(context).push<void>(
                                  MaterialPageRoute(
                                    builder: (_) => const SearchScreen(),
                                  ),
                                ),
                              ),
                              onAddProduce: () => unawaited(
                                Navigator.of(context).push<void>(
                                  MaterialPageRoute(
                                    builder: (_) => const SearchScreen(),
                                  ),
                                ),
                              ),
                              onGetStarted: () => ref
                                  .read(onboardingProvider.notifier)
                                  .markComplete(),
                            );
                          }
                          return EmptyPantry(onScan: _showActionSheet);
                        }
                        return _InventoryList(
                          items: items,
                          onScan: _showActionSheet,
                          expiringSoonDays: expiringSoonDays,
                          selectionMode: controller.selectionMode,
                          selectedIds: controller.selectedIds,
                          onToggleSelection: (id) => ref
                              .read(homeScreenControllerProvider.notifier)
                              .toggleSelection(id),
                          onLongPressItem: (id) => ref
                              .read(homeScreenControllerProvider.notifier)
                              .enterSelectionMode(id),
                        );
                      },
                    ),
                  ),
                ],
              ),
        floatingActionButton: (controller.selectionMode || !onboardingComplete)
            ? null
            : FloatingActionButton(
                heroTag: null,
                onPressed: _showActionSheet,
                child: const Icon(Icons.add),
              ),
      ),
    );
  }

  Future<void> _moveSelected(
    HomeScreenController notifier,
  ) async {
    final controller = ref.watch(homeScreenControllerProvider);
    if (controller.selectedIds.isEmpty) return;
    final inventories = ref.read(inventoryListProvider).asData?.value ?? [];
    final activeId = await ref.read(activeInventoryProvider.future);
    if (!mounted) return;
    final targetInventories = inventories
        .where((inv) => inv.id != activeId)
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
                title: Text(l10n.displayInventoryName(inv.name)),
                onTap: () => Navigator.pop(ctx, inv.id),
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
  InventoryGrouping? _grouping;
  Object? _groupingKey;

  /// Returns the memoized [InventoryGrouping], recomputed only when the
  /// items, the expiring-soon window, or the calendar day change.
  InventoryGrouping _groupingFor() {
    final today = DateTime.now();
    final dayKey = DateTime(today.year, today.month, today.day);
    final key = (widget.items, widget.expiringSoonDays, dayKey);
    if (_grouping == null || _groupingKey != key) {
      _grouping = InventoryGrouping.partition(
        widget.items,
        widget.expiringSoonDays,
        now: today,
      );
      _groupingKey = key;
    }
    return _grouping!;
  }

  String _sectionTitle(AppLocalizations l10n, InventorySection section) {
    return switch (section) {
      InventorySection.expired => l10n.expired,
      InventorySection.expiringSoon => l10n.expiringSoon,
      InventorySection.good => l10n.good,
    };
  }

  IconData _sectionIcon(InventorySection section) {
    return switch (section) {
      InventorySection.expired => Icons.error_outline,
      InventorySection.expiringSoon => Icons.warning_amber,
      InventorySection.good => Icons.check_circle_outline,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final grouping = _groupingFor();
    final entries = grouping.entries;

    return RefreshIndicator(
      onRefresh: () => ref.read(pantryProvider.notifier).refresh(),
      child: entries.isEmpty
          ? ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(child: Text(l10n.noItemsMatch)),
                ),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: entries.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return SizedBox(
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
                            l10n.expiringSoonCount(
                              grouping.expiringSoon.length,
                            ),
                            Icons.warning_amber_outlined,
                          ),
                          const SizedBox(width: 8),
                          _countChip(
                            l10n.addedThisWeek(grouping.addedThisWeek),
                            Icons.add_circle_outline,
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return switch (entries[index - 1]) {
                  InventorySectionEntry(:final section) => SectionHeader(
                    key: ValueKey('section-${section.name}'),
                    title: _sectionTitle(l10n, section),
                    icon: _sectionIcon(section),
                  ),
                  InventoryItemEntry(:final item) => _buildCard(item),
                };
              },
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
