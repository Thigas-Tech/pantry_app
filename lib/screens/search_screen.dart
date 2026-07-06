import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/l10n/app_localizations.dart';
import 'package:pantry_app/models/inventory_item.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/providers/active_inventory_provider.dart';
import 'package:pantry_app/providers/api_service_provider.dart';
import 'package:pantry_app/providers/database_provider.dart';
import 'package:pantry_app/providers/product_repository_provider.dart';
import 'package:pantry_app/screens/product_detail_screen.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:pantry_app/utils/snackbar_helper.dart';

/// A search‑focused tab that lets the user find products by name or
/// barcode, querying both the local cache and the Open Food Facts API.
///
/// Results are shown in a scrollable list; tapping a result navigates to
/// [ProductDetailScreen]. The search input is debounced (300 ms) to avoid
/// excessive API calls.
class SearchScreen extends ConsumerStatefulWidget {
  /// Creates a [SearchScreen] widget.
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen>
    with AutomaticKeepAliveClientMixin {
  final _searchController = TextEditingController();
  Timer? _debounce;
  List<_SearchResult> _results = [];
  bool _isSearching = false;
  bool _hasSearched = false;
  int _requestId = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _results = [];
        _isSearching = false;
        _hasSearched = false;
      });
      return;
    }
    _requestId++;
    _debounce = Timer(const Duration(milliseconds: 300), () => _search(query));
  }

  Future<void> _search(String query) async {
    if (!mounted) return;
    final capturedRequestId = _requestId;
    setState(() => _isSearching = true);

    try {
      final db = ref.read(databaseProvider);
      final localResults = await db.searchProducts(query);
      if (capturedRequestId != _requestId || !mounted) return;

      final results = <_SearchResult>[
        for (final p in localResults)
          _SearchResult(product: p, source: _ResultSource.local),
      ];

      // Search the API only for queries with at least 2 characters.
      if (query.length >= 2) {
        try {
          final api = ref.read(apiServiceProvider);
          final apiResults = await api.searchProducts(query);
          if (capturedRequestId != _requestId || !mounted) return;
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

      if (!mounted) return;
      setState(() {
        _results = results;
        _isSearching = false;
        _hasSearched = true;
      });
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

  Future<void> _addToInventory(Product product) async {
    final repo = ref.read(productRepositoryProvider);
    final activeId = ref.read(activeInventoryProvider);
    final l10n = AppLocalizations.of(context)!;

    final item = InventoryItem(
      barcode: product.barcode,
      inventoryId: activeId,
    );

    try {
      final newId = await repo.addInventoryItem(item);
      if (!mounted) return;
      SnackbarHelper.showUndo(
        context,
        l10n.addToPantry,
        () async {
          await repo.deleteInventoryItem(newId);
          if (mounted) {
            SnackbarHelper.showInfo(context, l10n.removedFromPantry);
          }
        },
      );
    } on Exception catch (e) {
      logError('Failed to add item from search: $e');
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
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.searchTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: l10n.searchHint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _results = [];
                            _hasSearched = false;
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Expanded(child: _buildResults(l10n, theme)),
        ],
      ),
    );
  }

  Widget _buildResults(AppLocalizations l10n, ThemeData theme) {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
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

    if (_results.isEmpty) {
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
      itemCount: _results.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final result = _results[index];
        final product = result.product;
        return Dismissible(
          key: ValueKey('search-result-${product.barcode}'),
          direction: DismissDirection.startToEnd,
          background: Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 20),
            color: Colors.green,
            child: const Icon(Icons.add, color: Colors.white),
          ),
          onDismissed: (_) {
            setState(() {
              _results.removeAt(index);
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
              ].join(' — '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: result.source == _ResultSource.api
                ? Icon(
                    Icons.cloud_outlined,
                    size: 16,
                    color: theme.colorScheme.outline,
                  )
                : null,
            onTap: () {
              logInfo(
                'Search result tapped: ${product.barcode} — ${product.name}',
              );
              unawaited(
                Navigator.of(context).push<void>(
                  MaterialPageRoute(
                    builder: (_) => ProductDetailScreen(product: product),
                  ),
                ),
              );
            },
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
            return _barcodeAvatar(product.barcode, theme);
          },
          errorBuilder: (_, _, _) => _barcodeAvatar(product.barcode, theme),
        ),
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
  });

  final Product product;
  final _ResultSource source;
}
