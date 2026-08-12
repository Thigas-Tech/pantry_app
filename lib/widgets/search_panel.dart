import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/l10n/app_localizations.dart';
import 'package:pantry_app/models/inventory_item.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/models/search_filter.dart';
import 'package:pantry_app/models/shopping_item.dart';
import 'package:pantry_app/providers/active_inventory_provider.dart';
import 'package:pantry_app/providers/connectivity_provider.dart';
import 'package:pantry_app/providers/pantry_provider.dart';
import 'package:pantry_app/providers/product_repository_provider.dart';
import 'package:pantry_app/providers/search_panel_controller.dart';
import 'package:pantry_app/providers/shopping_list_provider.dart';
import 'package:pantry_app/providers/shopping_list_service_provider.dart';
import 'package:pantry_app/screens/add_product_screen.dart';
import 'package:pantry_app/screens/product_detail_screen.dart';
import 'package:pantry_app/screens/product_picker_screen.dart';
import 'package:pantry_app/screens/scanner_screen.dart';
import 'package:pantry_app/screens/search_screen.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:pantry_app/utils/progress_indicator_helper.dart';
import 'package:pantry_app/utils/snackbar_helper.dart';
import 'package:pantry_app/widgets/not_found_flow.dart';
import 'package:pantry_app/widgets/search_query_bar.dart';
import 'package:pantry_app/widgets/search_results_list.dart';
import 'package:pantry_app/widgets/search_source_selector.dart';

/// A reusable search panel with search bar, source filter, category filter,
/// and results list.
///
/// Can be used in three modes:
///   * **Standalone** (default) — pushes [ProductDetailScreen] on result tap.
///     Used by [SearchScreen].
///   * **Inline** — set [onProductSelected] so the host handles navigation.
///     Set [showBackButton] to show a back arrow in the search bar leading.
///     Used by the home screen.
///   * **Picker** — set [selectMode] to pop the current route with the
///     selected [Product]. Used by [ProductPickerScreen] for recipe
///     ingredient selection.
///
/// The search bar, source dropdown, and results list are extracted into
/// [SearchQueryBar], [SearchSourceSelector], and [SearchResultsList]. All
/// search state and execution lives in [SearchPanelController]; this widget
/// wires them together and renders the surrounding states (loading, idle,
/// empty, and not-found).
class SearchPanel extends ConsumerStatefulWidget {
  /// Creates a [SearchPanel].
  ///
  /// [searchDebounceDuration] controls how long to wait after the last
  /// keystroke before triggering a search. Defaults to 2 seconds. Pressing
  /// Enter in the search bar bypasses this delay.
  const SearchPanel({
    super.key,
    this.onProductSelected,
    this.selectMode = false,
    this.autoFocus = false,
    this.showBackButton = false,
    this.onBack,
    this.searchDebounceDuration = const Duration(milliseconds: 2000),
  });

  /// Called when a product result is tapped, instead of pushing
  /// [ProductDetailScreen].
  final void Function(Product product)? onProductSelected;

  /// When true, tapping a result calls [Navigator.pop] with the
  /// selected [Product] instead of navigating to a detail screen.
  final bool selectMode;

  /// Whether to auto-focus the search bar on first build.
  final bool autoFocus;

  /// When true, replaces the search icon leading with a back arrow.
  final bool showBackButton;

  /// Called when the back arrow is tapped (only when [showBackButton] is
  /// true).
  final VoidCallback? onBack;

  /// How long to wait after the last keystroke before triggering a search.
  /// Pressing Enter bypasses this delay.
  final Duration searchDebounceDuration;

  @override
  ConsumerState<SearchPanel> createState() => _SearchPanelState();
}

class _SearchPanelState extends ConsumerState<SearchPanel> {
  final _notFoundFlowKey = GlobalKey<NotFoundFlowState>();

  SearchPanelController get _controller => ref.read(
    searchPanelControllerProvider(widget.searchDebounceDuration).notifier,
  );

  void _showOfflineWarning() {
    final l10n = AppLocalizations.of(context)!;
    SnackbarHelper.showWarning(context, l10n.offlineWarning);
    _controller.consumeOfflineWarning();
  }

  void _onResultTapped(Product product) {
    if (widget.selectMode) {
      Navigator.pop(context, product);
      return;
    }
    final callback = widget.onProductSelected;
    if (callback != null) {
      callback(product);
      return;
    }
    logInfo(
      'Search result tapped: ${product.barcode} — ${product.name}',
    );
    unawaited(
      Navigator.of(context)
          .push<void>(
            MaterialPageRoute(
              builder: (_) => ProductDetailScreen(product: product),
            ),
          )
          .then((_) {
            if (!context.mounted) return;
            ref.invalidate(pantryProvider);
          }),
    );
  }

  void _onNotFoundScanBarcode() {
    unawaited(
      Navigator.of(context).push<void>(
        MaterialPageRoute(builder: (_) => const ScannerScreen()),
      ),
    );
  }

  Future<void> _onNotFoundBarcodeSubmitted(String barcode) async {
    final repo = ref.read(productRepositoryProvider);
    try {
      final hasConnection = await ref.read(hasConnectionProvider.future);
      if (!hasConnection) {
        if (mounted) {
          SnackbarHelper.showWarning(
            context,
            AppLocalizations.of(context)!.offlineWarning,
          );
        }
        return;
      }
      final product = await repo.getProduct(barcode);
      if (!mounted) return;
      _onResultTapped(product);
    } on Exception {
      if (!mounted) return;
      _notFoundFlowKey.currentState?.showBarcodeNotFound(barcode);
    }
  }

  void _onNotFoundContributeToOff(String barcode) {
    unawaited(
      Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => AddProductScreen(barcode: barcode, submitToOff: true),
        ),
      ),
    );
  }

  void _onNotFoundSaveLocally(String barcode) {
    unawaited(
      Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => AddProductScreen(barcode: barcode),
        ),
      ),
    );
  }

  Future<void> _addToInventory(Product product) async {
    final repo = ref.read(productRepositoryProvider);
    final l10n = AppLocalizations.of(context)!;
    final activeId = await ref.read(activeInventoryProvider.future);

    final item = InventoryItem(
      barcode: product.barcode,
      inventoryId: activeId,
    );

    try {
      await repo.cacheProduct(product);
      final newId = await repo.addOrMergeInventoryItem(item);
      if (!mounted) return;
      ref.invalidate(pantryProvider);
      if (!mounted) return;
      SnackbarHelper.showUndo(
        context,
        l10n.addToPantry,
        () async {
          await repo.deleteInventoryItem(newId);
          if (!mounted) return;
          ref.invalidate(pantryProvider);
          if (mounted) {
            SnackbarHelper.showInfo(context, l10n.removedFromPantry);
          }
        },
      );
    } on Exception catch (e) {
      logError('Failed to add item from search: $e');
      if (mounted) {
        SnackbarHelper.showError(context, l10n.couldNotCreateInventory);
      }
    }
  }

  void _showLongPressMenu(Product product) {
    final l10n = AppLocalizations.of(context)!;

    unawaited(
      showModalBottomSheet<void>(
        context: context,
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.add),
                title: Text(l10n.addToInventory),
                onTap: () {
                  Navigator.pop(ctx);
                  unawaited(_addToInventory(product));
                },
              ),
              ListTile(
                leading: const Icon(Icons.copy),
                title: Text(l10n.copyBarcode),
                onTap: () {
                  Navigator.pop(ctx);
                  unawaited(
                    Clipboard.setData(ClipboardData(text: product.barcode)),
                  );
                  SnackbarHelper.showInfo(context, l10n.barcodeCopied);
                },
              ),
              ListTile(
                leading: const Icon(Icons.shopping_cart_outlined),
                title: Text(l10n.addToShoppingList),
                onTap: () {
                  Navigator.pop(ctx);
                  final item = ShoppingItem(
                    name: product.name,
                    barcode: product.barcode,
                  );
                  unawaited(
                    ref
                        .read(productRepositoryProvider)
                        .cacheProduct(product)
                        .then(
                          (_) async {
                            final activeId = await ref.read(
                              activeInventoryProvider.future,
                            );
                            await ref
                                .read(shoppingListServiceProvider)
                                .addShoppingItem(
                                  item,
                                  activeInventoryId: activeId,
                                );
                            invalidateShoppingList(ref);
                          },
                        ),
                  );
                  SnackbarHelper.showInfo(context, l10n.addToShoppingList);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;
    final provider = searchPanelControllerProvider(
      widget.searchDebounceDuration,
    );
    final state = ref.watch(provider);

    ref.listen<SearchPanelState>(provider, (previous, next) {
      if (next.showOfflineWarning && !(previous?.showOfflineWarning ?? false)) {
        _showOfflineWarning();
      }
    });

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: SearchQueryBar(
            searchHint: l10n.searchHint,
            autoFocus: widget.autoFocus,
            showBackButton: widget.showBackButton,
            onBack: widget.onBack,
            onChanged: (value) =>
                _controller.onQueryChanged(value, languageCode: languageCode),
            onSubmitted: (value) =>
                _controller.onQuerySubmitted(value, languageCode: languageCode),
            onClear: _controller.clear,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: SearchSourceSelector(
            label: l10n.searchSourceLabel,
            value: state.activeSource,
            onChanged: (source) => _controller.setActiveSource(
              source,
              languageCode: languageCode,
            ),
            offLabel: l10n.searchSourceOff,
            usdaLabel: l10n.searchSourceUsda,
            inventoryLabel: l10n.searchSourceInventory,
          ),
        ),
        if (state.results.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FilterChip(
                label: Text(l10n.inPantryFilter),
                selected: state.filterInPantryOnly,
                onSelected: (value) =>
                    _controller.setFilterInPantryOnly(value: value),
              ),
            ),
          ),
        Expanded(child: _buildResults(state, l10n, theme)),
      ],
    );
  }

  Widget _buildResults(
    SearchPanelState state,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    if (state.isSearching) {
      return Center(child: ProgressIndicatorHelper.build());
    }

    if (!state.hasSearched) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search, size: 64, color: theme.colorScheme.outline),
              const SizedBox(height: 16),
              Text(
                l10n.searchProductsHint,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final displayResults = state.displayResults;

    if (displayResults.isEmpty) {
      if (state.filterInPantryOnly) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.kitchen,
                  size: 64,
                  color: theme.colorScheme.outline,
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.inPantryEmpty,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      if (state.results.isEmpty &&
          state.activeSource == SearchSource.off &&
          state.hasSearched) {
        return NotFoundFlow(
          key: _notFoundFlowKey,
          onScanBarcode: _onNotFoundScanBarcode,
          onBarcodeSubmitted: _onNotFoundBarcodeSubmitted,
          onContributeToOff: _onNotFoundContributeToOff,
          onSaveLocally: _onNotFoundSaveLocally,
        );
      }
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.search_off,
                size: 64,
                color: theme.colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.noSearchResults,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SearchResultsList(
      results: displayResults,
      inPantrySwipeLabel: l10n.inPantrySwipeLabel,
      addToInventoryLabel: l10n.addToInventory,
      inPantryIndicatorLabel: l10n.inPantryIndicator,
      onResultTapped: _onResultTapped,
      onResultLongPressed: _showLongPressMenu,
      onResultDismissed: (result) {
        _controller.removeResult(result.product);
        unawaited(_addToInventory(result.product));
      },
    );
  }
}
