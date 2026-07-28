import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/l10n/app_localizations.dart';
import 'package:pantry_app/models/inventory_item.dart';
import 'package:pantry_app/models/inventory_with_product.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/models/product_type.dart';
import 'package:pantry_app/models/search_filter.dart';
import 'package:pantry_app/models/shopping_item.dart';
import 'package:pantry_app/providers/active_inventory_provider.dart';
import 'package:pantry_app/providers/api_service_provider.dart';
import 'package:pantry_app/providers/connectivity_provider.dart';
import 'package:pantry_app/providers/database_provider.dart';
import 'package:pantry_app/providers/pantry_provider.dart';
import 'package:pantry_app/providers/product_repository_provider.dart';
import 'package:pantry_app/providers/shopping_list_provider.dart';
import 'package:pantry_app/providers/usda_provider.dart';
import 'package:pantry_app/screens/add_product_screen.dart';
import 'package:pantry_app/screens/product_detail_screen.dart';
import 'package:pantry_app/screens/product_picker_screen.dart';
import 'package:pantry_app/screens/scanner_screen.dart';
import 'package:pantry_app/screens/search_screen.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:pantry_app/utils/progress_indicator_helper.dart';
import 'package:pantry_app/utils/search_utils.dart';
import 'package:pantry_app/utils/snackbar_helper.dart';
import 'package:pantry_app/widgets/not_found_flow.dart';

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
class SearchPanel extends ConsumerStatefulWidget {
  /// Creates a [SearchPanel].
  const SearchPanel({
    super.key,
    this.onProductSelected,
    this.selectMode = false,
    this.autoFocus = false,
    this.showBackButton = false,
    this.onBack,
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

  @override
  ConsumerState<SearchPanel> createState() => _SearchPanelState();
}

class _SearchPanelState extends ConsumerState<SearchPanel> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  List<_SearchResult> _results = [];
  bool _isSearching = false;
  bool _hasSearched = false;
  int _requestId = 0;
  Timer? _graceTimer;
  SearchSource _activeSource = SearchSource.off;
  bool _filterInPantryOnly = false;
  final _notFoundFlowKey = GlobalKey<NotFoundFlowState>();

  @override
  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    _graceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _graceTimer?.cancel();
    final query = value.trim();
    if (query.isEmpty) {
      setState(() {
        _results = [];
        _isSearching = false;
        _hasSearched = false;
      });
      return;
    }
    _requestId++;
    _filterInPantryOnly = false;
    _debounce = Timer(const Duration(milliseconds: 500), () => _search(query));
  }

  Future<void> _search(String query) async {
    if (!mounted) return;
    final capturedRequestId = _requestId;
    setState(() => _isSearching = true);

    try {
      List<_SearchResult> results;
      bool apiHadResults;

      switch (_activeSource) {
        case SearchSource.off:
          final r = await _searchOff(query, capturedRequestId);
          results = r.results;
          apiHadResults = r.apiHadResults;
        case SearchSource.usda:
          final r = await _searchUsda(query, capturedRequestId);
          results = r;
          apiHadResults = r.isNotEmpty;
        case SearchSource.inventory:
          final r = await _searchInventory(query, capturedRequestId);
          results = r;
          apiHadResults = r.isNotEmpty;
      }

      if (capturedRequestId != _requestId || !mounted) return;

      final enriched = await _enrichWithPantryStatus(results);
      if (capturedRequestId != _requestId || !mounted) return;

      if (!mounted) return;
      _graceTimer?.cancel();
      if (enriched.isEmpty && !apiHadResults) {
        _graceTimer = Timer(const Duration(seconds: 1), () {
          if (!mounted) return;
          setState(() {
            _results = enriched;
            _isSearching = false;
            _hasSearched = true;
          });
        });
        setState(() => _results = []);
      } else {
        setState(() {
          _results = enriched;
          _isSearching = false;
          _hasSearched = true;
        });
      }
    } on Exception catch (e) {
      logError('Search failed: $e');
      if (!mounted) return;
      setState(() {
        _results = [];
        _isSearching = false;
        _hasSearched = true;
      });
    }
  }

  Future<({List<_SearchResult> results, bool apiHadResults})> _searchOff(
    String query,
    int capturedRequestId,
  ) async {
    final normalizedQuery = normalizeForSearch(query.trim());
    final db = ref.read(databaseProvider);
    final localResults = await db.searchProducts(normalizedQuery);
    if (capturedRequestId != _requestId || !mounted) {
      return (results: <_SearchResult>[], apiHadResults: false);
    }

    final results = <_SearchResult>[
      for (final p in localResults)
        _SearchResult(product: p, source: _ResultSource.local),
    ];

    final isBarcodeQuery =
        normalizedQuery.length >= 8 &&
        RegExp(r'^\d+$').hasMatch(normalizedQuery);

    var apiHadResults = false;
    if (isBarcodeQuery) {
      try {
        final hasConnection = await ref.read(hasConnectionProvider.future);
        if (!hasConnection) {
          if (mounted) {
            SnackbarHelper.showWarning(
              context,
              AppLocalizations.of(context)!.offlineWarning,
            );
          }
        } else {
          final repo = ref.read(productRepositoryProvider);
          final product = await repo.getProduct(normalizedQuery);
          if (capturedRequestId != _requestId || !mounted) {
            return (results: <_SearchResult>[], apiHadResults: false);
          }
          apiHadResults = true;
          final existingBarcodes = results
              .map((r) => r.product.barcode)
              .toSet();
          if (!existingBarcodes.contains(product.barcode)) {
            results.add(
              _SearchResult(product: product, source: _ResultSource.api),
            );
          }
        }
      } on Exception catch (e) {
        logWarning('Barcode lookup failed: $e');
      }
    } else if (query.length >= 2) {
      final appLocale = Localizations.localeOf(context).languageCode;
      final hasConnection = await ref.read(hasConnectionProvider.future);
      if (!hasConnection) {
        if (mounted) {
          SnackbarHelper.showWarning(
            context,
            AppLocalizations.of(context)!.offlineWarning,
          );
        }
      } else {
        try {
          final api = ref.read(apiServiceProvider);
          var apiResults = await api.searchProducts(
            normalizedQuery,
            languageCode: appLocale,
          );
          if (capturedRequestId != _requestId || !mounted) {
            return (results: <_SearchResult>[], apiHadResults: false);
          }

          if (apiResults.isEmpty && normalizedQuery != query) {
            apiResults = await api.searchProducts(
              query,
              languageCode: appLocale,
            );
            if (capturedRequestId != _requestId || !mounted) {
              return (results: <_SearchResult>[], apiHadResults: false);
            }
          }

          apiHadResults = apiResults.isNotEmpty;
          final existingBarcodes = results
              .map((r) => r.product.barcode)
              .toSet();
          for (final p in apiResults) {
            if (!existingBarcodes.contains(p.barcode)) {
              results.add(
                _SearchResult(product: p, source: _ResultSource.api),
              );
            }
          }
        } on Exception catch (e) {
          logWarning('API search failed: $e');
        }
      }
    }

    return (results: results, apiHadResults: apiHadResults);
  }

  Future<List<_SearchResult>> _searchUsda(
    String query,
    int capturedRequestId,
  ) async {
    if (query.length < 2) return [];

    final normalizedQuery = normalizeForSearch(query.trim());
    final hasConnection = await ref.read(hasConnectionProvider.future);
    if (!hasConnection) {
      if (mounted) {
        SnackbarHelper.showWarning(
          context,
          AppLocalizations.of(context)!.offlineWarning,
        );
      }
      return [];
    }

    try {
      final usda = ref.read(usdaApiClientProvider);
      final products = await usda.searchFood(normalizedQuery);
      if (capturedRequestId != _requestId || !mounted) return [];

      return [
        for (final p in products)
          _SearchResult(product: p, source: _ResultSource.api),
      ];
    } on Exception catch (e) {
      logWarning('USDA search failed: $e');
      return [];
    }
  }

  Future<List<_SearchResult>> _searchInventory(
    String query,
    int capturedRequestId,
  ) async {
    final normalizedQuery = normalizeForSearch(query.trim());
    final activeId = ref.read(activeInventoryProvider);
    final db = ref.read(databaseProvider);
    final items = await db.getInventoryWithProduct(inventoryId: activeId);
    if (capturedRequestId != _requestId || !mounted) return [];

    final inventoryItems = items.map(InventoryWithProduct.fromMap).toList();

    if (normalizedQuery.isEmpty) {
      return [
        for (final item in inventoryItems)
          _SearchResult(
            product: Product(
              barcode: item.barcode,
              name: item.productName ?? item.barcode,
              productType: item.productType ?? ProductType.custom,
            ),
            source: _ResultSource.local,
          ),
      ];
    }

    final matching = inventoryItems.where((item) {
      final searchText =
          item.productSearchText ?? '${item.productName ?? ''} ${item.barcode}';
      return normalizeForSearch(searchText).contains(normalizedQuery);
    }).toList();

    return [
      for (final item in matching)
        _SearchResult(
          product: Product(
            barcode: item.barcode,
            name: item.productName ?? item.barcode,
            productType: item.productType ?? ProductType.custom,
          ),
          source: _ResultSource.local,
        ),
    ];
  }

  Future<List<_SearchResult>> _enrichWithPantryStatus(
    List<_SearchResult> results,
  ) async {
    if (results.isEmpty || _activeSource == SearchSource.inventory) {
      return results
          .map(
            (r) => _SearchResult(
              product: r.product,
              source: r.source,
              isInPantry: _activeSource == SearchSource.inventory,
            ),
          )
          .toList();
    }

    final barcodes = results.map((r) => r.product.barcode).toSet();
    final activeId = ref.read(activeInventoryProvider);
    final db = ref.read(databaseProvider);
    final inPantryBarcodes = await db.getBarcodesInInventory(
      barcodes,
      inventoryId: activeId,
    );

    return results
        .map(
          (r) => _SearchResult(
            product: r.product,
            source: r.source,
            isInPantry: inPantryBarcodes.contains(r.product.barcode),
          ),
        )
        .toList();
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
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ref.invalidate(pantryProvider);
            });
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

  void _onNotFoundContributeToOff() {
    final l10n = AppLocalizations.of(context)!;
    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.contributeToOffComingSoonTitle),
          content: Text(l10n.contributeToOffComingSoonBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.iUnderstand),
            ),
          ],
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
    final activeId = ref.read(activeInventoryProvider);
    final l10n = AppLocalizations.of(context)!;

    final item = InventoryItem(
      barcode: product.barcode,
      inventoryId: activeId,
    );

    try {
      await repo.cacheProduct(product);
      final newId = await repo.addInventoryItem(item);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.invalidate(pantryProvider);
      });
      if (!mounted) return;
      SnackbarHelper.showUndo(
        context,
        l10n.addToPantry,
        () async {
          await repo.deleteInventoryItem(newId);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.invalidate(pantryProvider);
          });
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
                          (_) => addShoppingItem(ref, item),
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

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: SearchBar(
            controller: _searchController,
            hintText: l10n.searchHint,
            leading: widget.showBackButton && widget.onBack != null
                ? IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: widget.onBack,
                  )
                : const Padding(
                    padding: EdgeInsets.only(left: 12),
                    child: Icon(Icons.search),
                  ),
            trailing: [
              if (_searchController.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _debounce?.cancel();
                    _graceTimer?.cancel();
                    _searchController.clear();
                    setState(() {
                      _results = [];
                      _hasSearched = false;
                      _isSearching = false;
                    });
                  },
                ),
            ],
            onChanged: _onSearchChanged,
            textInputAction: TextInputAction.search,
            autoFocus: widget.autoFocus,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Text(
                '${l10n.searchSourceLabel}: ',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              DropdownButton<SearchSource>(
                value: _activeSource,
                underline: const SizedBox(),
                isDense: true,
                items: [
                  DropdownMenuItem(
                    value: SearchSource.off,
                    child: Text(l10n.searchSourceOff),
                  ),
                  DropdownMenuItem(
                    value: SearchSource.usda,
                    child: Text(l10n.searchSourceUsda),
                  ),
                  DropdownMenuItem(
                    value: SearchSource.inventory,
                    child: Text(l10n.searchSourceInventory),
                  ),
                ],
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _activeSource = v);
                  if (_searchController.text.trim().isNotEmpty) {
                    _requestId++;
                    _debounce?.cancel();
                    _graceTimer?.cancel();
                    unawaited(
                      _search(_searchController.text.trim()),
                    );
                  }
                },
              ),
            ],
          ),
        ),
        if (_results.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FilterChip(
                label: Text(l10n.inPantryFilter),
                selected: _filterInPantryOnly,
                onSelected: (v) => setState(() => _filterInPantryOnly = v),
              ),
            ),
          ),
        Expanded(child: _buildResults(l10n, theme)),
      ],
    );
  }

  Widget _buildResults(AppLocalizations l10n, ThemeData theme) {
    if (_isSearching) {
      return Center(child: ProgressIndicatorHelper.build());
    }

    if (!_hasSearched) {
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

    final displayResults = _filterInPantryOnly
        ? _results.where((r) => r.isInPantry).toList()
        : _results;

    if (displayResults.isEmpty) {
      if (_filterInPantryOnly) {
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

      if (_results.isEmpty &&
          _activeSource == SearchSource.off &&
          _hasSearched) {
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

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      itemCount: displayResults.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final result = displayResults[index];
        final product = result.product;
        return Dismissible(
          key: ValueKey('search-result-${product.barcode}'),
          direction: DismissDirection.startToEnd,
          background: Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 20),
            color: result.isInPantry ? Colors.blue.shade200 : Colors.green,
            child: Text(
              result.isInPantry ? l10n.inPantrySwipeLabel : l10n.addToInventory,
              style: const TextStyle(color: Colors.white),
            ),
          ),
          onDismissed: (_) {
            setState(() {
              _results.removeWhere(
                (r) => r.product.barcode == product.barcode,
              );
            });
            unawaited(_addToInventory(product));
          },
          child: ListTile(
            leading: _searchResultAvatar(product, theme, context),
            title: Text(
              product.name != 'Unknown' ? product.name : product.barcode,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              [
                if (product.brand != null && product.brand!.isNotEmpty)
                  product.brand,
                product.barcode,
              ].join(' \u2014 '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (result.isInPantry)
                  Semantics(
                    label: l10n.inPantryIndicator,
                    child: Icon(
                      Icons.kitchen,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                if (result.isInPantry) const SizedBox(width: 4),
                if (product.productType == ProductType.produce)
                  Icon(
                    Icons.eco_outlined,
                    size: 16,
                    color: Colors.green.shade600,
                  )
                else if (result.source == _ResultSource.api)
                  Icon(
                    Icons.cloud_outlined,
                    size: 16,
                    color: theme.colorScheme.outline,
                  ),
              ],
            ),
            onTap: () => _onResultTapped(product),
            onLongPress: () => _showLongPressMenu(product),
          ),
        );
      },
    );
  }

  Widget _searchResultAvatar(
    Product product,
    ThemeData theme,
    BuildContext context,
  ) {
    if (product.imageUrl != null) {
      final ratio = MediaQuery.devicePixelRatioOf(context);
      return ClipOval(
        child: Image.network(
          product.imageUrl!,
          width: 40,
          height: 40,
          cacheWidth: (40 * ratio).round(),
          cacheHeight: (40 * ratio).round(),
          fit: BoxFit.cover,
          loadingBuilder: (_, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return _produceOrBarcodeAvatar(product, theme);
          },
          errorBuilder: (_, _, _) => _produceOrBarcodeAvatar(product, theme),
        ),
      );
    }
    return _produceOrBarcodeAvatar(product, theme);
  }

  Widget _produceOrBarcodeAvatar(Product product, ThemeData theme) {
    if (product.productType == ProductType.produce) {
      return CircleAvatar(
        backgroundColor: Colors.green.shade100,
        child: Icon(Icons.eco_outlined, color: Colors.green.shade600, size: 18),
      );
    }
    return _barcodeAvatar(product.barcode, theme);
  }

  Widget _barcodeAvatar(String barcode, ThemeData theme) {
    return CircleAvatar(
      backgroundColor: theme.colorScheme.secondaryContainer,
      child: Text(
        barcode.length >= 3
            ? barcode.substring(0, 3)
            : barcode.padRight(3, '0'),
        style: TextStyle(
          color: theme.colorScheme.onSecondaryContainer,
          fontSize: 11,
        ),
      ),
    );
  }
}

enum _ResultSource { local, api }

class _SearchResult {
  const _SearchResult({
    required this.product,
    required this.source,
    this.isInPantry = false,
  });

  final Product product;
  final _ResultSource source;
  final bool isInPantry;
}
