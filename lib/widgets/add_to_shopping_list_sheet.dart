import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/l10n/app_localizations.dart';
import 'package:pantry_app/models/inventory_product_option.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/models/product_type.dart';
import 'package:pantry_app/models/shopping_item.dart';
import 'package:pantry_app/providers/api_service_provider.dart';
import 'package:pantry_app/providers/connectivity_provider.dart';
import 'package:pantry_app/providers/database_provider.dart';
import 'package:pantry_app/providers/product_repository_provider.dart';
import 'package:pantry_app/providers/shopping_list_provider.dart';
import 'package:pantry_app/utils/bottom_sheet_helper.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:pantry_app/utils/progress_indicator_helper.dart';
import 'package:pantry_app/utils/search_utils.dart';

/// A bottom sheet for adding items to the shopping list.
///
/// The primary flow lets the user search cached products by name. Matching
/// products are shown in a scrollable list; tapping one returns a
/// [ShoppingItem] linked to that product's barcode.
///
/// When the product is not in cache, a "search online" hint appears and
/// OFF API results are appended as they arrive.
///
/// A fallback "Add custom item" button switches to a free-text form
/// (name + quantity + unit) for items that are not in any product database.
///
/// Opens via [showModalBottomSheet]. Returns a [ShoppingItem] or null if
/// cancelled.
///
/// Example:
/// Example:
///
///     final item = await AddToShoppingListSheet.show(context);
///     if (item != null) await addShoppingItem(ref, item);
class AddToShoppingListSheet extends ConsumerStatefulWidget {
  const AddToShoppingListSheet._({
    this.searchDebounceDuration = const Duration(milliseconds: 2000),
  });

  /// How long to wait after the last keystroke before triggering a search.
  /// Pressing Enter bypasses this delay.
  final Duration searchDebounceDuration;

  /// Shows the add-to-shopping-list bottom sheet and returns a
  /// [ShoppingItem], or null if cancelled.
  static Future<ShoppingItem?> show(
    BuildContext context, {
    Duration debounceDuration = const Duration(milliseconds: 2000),
  }) {
    return BottomSheetHelper.show<ShoppingItem>(
      context: context,
      builder: (_) => AddToShoppingListSheet._(
        searchDebounceDuration: debounceDuration,
      ),
    );
  }

  @override
  ConsumerState<AddToShoppingListSheet> createState() =>
      _AddToShoppingListSheetState();
}

class _AddToShoppingListSheetState
    extends ConsumerState<AddToShoppingListSheet> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  List<Product> _localResults = [];
  List<Product> _apiResults = [];
  bool _isSearching = false;
  int _requestId = 0;
  bool _showCustomForm = false;
  bool _apiSearchFailed = false;

  final _nameController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    _nameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    final query = value.trim();
    if (query.isEmpty) {
      setState(() {
        _localResults = [];
        _apiResults = [];
        _isSearching = false;
        _apiSearchFailed = false;
      });
      return;
    }
    _requestId++;
    final locale = Localizations.localeOf(context).languageCode;
    logInfo('Search queued — query="$query" locale=$locale');
    _debounce = Timer(
      widget.searchDebounceDuration,
      () => _search(query, locale),
    );
  }

  void _onSearchSubmitted(String value) {
    _debounce?.cancel();
    final query = value.trim();
    if (query.isEmpty) return;
    _requestId++;
    final locale = Localizations.localeOf(context).languageCode;
    unawaited(_search(query, locale));
  }

  Future<void> _search(String query, String locale) async {
    if (!mounted) return;
    final capturedRequestId = _requestId;
    setState(() => _isSearching = true);

    final normalizedQuery = normalizeForSearch(query);

    try {
      final db = ref.read(databaseProvider);
      final local = await db.searchProducts(normalizedQuery);
      if (capturedRequestId != _requestId || !mounted) {
        logInfo('Search stale — request $capturedRequestId superseded');
        return;
      }
      setState(() => _localResults = local);
      logInfo('Local search — query="$query" results=${local.length}');

      final hasConnection = await ref.read(hasConnectionProvider.future);
      if (!hasConnection) {
        logWarning('Offline — skipping API search for "$query"');
        if (mounted) {
          setState(() => _isSearching = false);
        }
        return;
      }

      if (query.length >= 2) {
        final api = ref.read(apiServiceProvider);
        final apiProducts = await api.searchProducts(
          query,
          languageCode: locale,
        );
        if (capturedRequestId != _requestId || !mounted) return;

        final existingBarcodes = _localResults.map((p) => p.barcode).toSet();
        final deduped = apiProducts
            .where((p) => !existingBarcodes.contains(p.barcode))
            .toList();
        setState(() {
          _apiResults = deduped;
          _isSearching = false;
        });
        logInfo(
          'API search — query="$query" results=${apiProducts.length} '
          'dedup=${deduped.length}',
        );
      } else {
        setState(() => _isSearching = false);
      }
    } on Exception catch (e) {
      logError('Search failed — query="$query" error=$e');
      if (!mounted) return;
      setState(() {
        _isSearching = false;
        _apiSearchFailed = true;
      });
    }
  }

  ShoppingItem _productToItem(Product product) {
    return ShoppingItem(
      name: product.name != 'Unknown' ? product.name : product.barcode,
      barcode: product.barcode,
    );
  }

  ShoppingItem _inventoryEntryToItem(
    InventoryProductOption entry,
  ) {
    final name = entry.name ?? entry.barcode;
    return ShoppingItem(
      name: name,
      barcode: entry.barcode,
    );
  }

  void _addFromProduct(Product product, {bool isApi = false}) {
    logInfo(
      'Add from product — barcode=${product.barcode} name=${product.name} '
      'isApi=$isApi',
    );
    if (isApi) {
      unawaited(
        ref.read(productRepositoryProvider).cacheProduct(product),
      );
    }
    Navigator.of(context).pop(_productToItem(product));
  }

  Future<void> _addFromInventory(InventoryProductOption entry) async {
    final barcode = entry.barcode;
    logInfo(
      'Add from inventory — barcode=$barcode name=${entry.name}',
    );
    if (barcode.isNotEmpty) {
      final existing = await ref
          .read(productRepositoryProvider)
          .getProductFromCache(barcode);
      if (existing == null) {
        logWarning(
          'Product $barcode missing from cache, but shown in inventory '
          'suggestions — fetching before pop',
        );
        try {
          final fetched = await ref
              .read(productRepositoryProvider)
              .getProduct(barcode);
          await ref.read(productRepositoryProvider).cacheProduct(fetched);
        } on Exception catch (e) {
          logWarning(
            'Could not fetch product $barcode for inventory suggestion: $e',
          );
        }
      }
    }
    if (!mounted) return;
    Navigator.of(context).pop(_inventoryEntryToItem(entry));
  }

  Widget _buildPantryEntryAvatar(
    InventoryProductOption entry,
    ThemeData theme,
  ) {
    final imageUrl = entry.imageUrl;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      final ratio = MediaQuery.devicePixelRatioOf(context);
      return ClipOval(
        child: Image.network(
          imageUrl,
          width: 40,
          height: 40,
          cacheWidth: (40 * ratio).round(),
          cacheHeight: (40 * ratio).round(),
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _fallbackPantryAvatar(entry, theme),
          loadingBuilder: (_, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return _fallbackPantryAvatar(entry, theme);
          },
        ),
      );
    }
    return _fallbackPantryAvatar(entry, theme);
  }

  Widget _fallbackPantryAvatar(
    InventoryProductOption entry,
    ThemeData theme,
  ) {
    final productType = entry.productType;
    if (productType == 'produce') {
      return CircleAvatar(
        backgroundColor: Colors.green.shade100,
        child: Icon(Icons.eco_outlined, color: Colors.green.shade600, size: 18),
      );
    }
    return CircleAvatar(
      backgroundColor: theme.colorScheme.tertiaryContainer,
      child: Icon(
        Icons.kitchen_outlined,
        size: 20,
        color: theme.colorScheme.onTertiaryContainer,
      ),
    );
  }

  void _addCustomItem() {
    if (!_formKey.currentState!.validate()) return;
    final name = _nameController.text.trim();
    final qty = double.tryParse(_quantityController.text.trim()) ?? 1;
    logInfo('Add custom item — name="$name" qty=$qty');
    final item = ShoppingItem(name: name, quantity: qty);
    Navigator.of(context).pop(item);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final bottomPad = BottomSheetHelper.bottomInset(context);

    return Padding(
      padding: EdgeInsets.only(bottom: bottomPad),
      child: _showCustomForm
          ? _buildCustomForm(l10n)
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildSearchBar(l10n),
                  _buildSearchBody(l10n, theme),
                  _buildAddCustomItemButton(l10n),
                ],
              ),
            ),
    );
  }

  Widget _buildSearchBar(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: SearchBar(
        controller: _searchController,
        hintText: l10n.productSearchHint,
        leading: const Padding(
          padding: EdgeInsets.only(left: 12),
          child: Icon(Icons.search),
        ),
        trailing: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _debounce?.cancel();
                _searchController.clear();
                setState(() {
                  _localResults = [];
                  _apiResults = [];
                  _isSearching = false;
                });
              },
            ),
        ],
        onChanged: _onSearchChanged,
        onSubmitted: _onSearchSubmitted,
        textInputAction: TextInputAction.search,
        autoFocus: true,
      ),
    );
  }

  Widget _buildSearchBody(AppLocalizations l10n, ThemeData theme) {
    final allResults = [..._localResults, ..._apiResults];
    final inventoryProducts = ref.watch(inventoryProductsProvider);

    if (_isSearching) {
      return Center(child: ProgressIndicatorHelper.build());
    }
    if (_searchController.text.trim().isEmpty) {
      return _buildInitialState(l10n, theme, inventoryProducts);
    }
    if (allResults.isEmpty && !_apiSearchFailed) {
      return _buildNoResults(l10n, theme);
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_apiSearchFailed)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
            child: MaterialBanner(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              content: Text(
                l10n.apiSearchWarning,
                style: theme.textTheme.bodySmall,
              ),
              leading: Icon(
                Icons.warning_amber_rounded,
                size: 20,
                color: theme.colorScheme.error,
              ),
              actions: [
                TextButton(
                  onPressed: () => setState(() => _apiSearchFailed = false),
                  child: Text(l10n.dismiss),
                ),
              ],
            ),
          ),
        if (allResults.isEmpty && _apiSearchFailed)
          _buildNoResults(l10n, theme)
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: allResults.length,
            itemBuilder: (ctx, index) {
              final product = allResults[index];
              final isApi = index >= _localResults.length;
              return _ProductResultTile(
                product: product,
                isApi: isApi,
                onTap: () => _addFromProduct(product, isApi: isApi),
              );
            },
          ),
      ],
    );
  }

  Widget _buildAddCustomItemButton(AppLocalizations l10n) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => setState(() => _showCustomForm = true),
              icon: const Icon(Icons.edit_note, size: 20),
              label: Text(l10n.addCustomItem),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInitialState(
    AppLocalizations l10n,
    ThemeData theme,
    AsyncValue<List<InventoryProductOption>> inventoryProducts,
  ) {
    return inventoryProducts.when(
      data: (products) {
        if (products.isEmpty) {
          logInfo('Inventory products empty — showing search hint');
          return _buildEmptyHint(l10n, theme);
        }
        logInfo('Inventory products loaded — count=${products.length}');
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: products.length + 1,
          itemBuilder: (ctx, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(4, 16, 0, 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.kitchen_outlined,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.fromYourPantry,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              );
            }
            final entry = products[index - 1];
            final name = entry.name ?? entry.barcode;
            return ListTile(
              leading: _buildPantryEntryAvatar(entry, theme),
              title: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(l10n.inYourPantry),
              onTap: () => _addFromInventory(entry),
            );
          },
        );
      },
      loading: () => _buildEmptyHint(l10n, theme),
      error: (e, _) {
        logError('Failed to load inventory products: $e');
        return _buildEmptyHint(l10n, theme);
      },
    );
  }

  Widget _buildEmptyHint(AppLocalizations l10n, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.productSearchHint,
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

  Widget _buildNoResults(AppLocalizations l10n, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 64, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              l10n.noProductsFound,
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

  Widget _buildCustomForm(
    AppLocalizations l10n,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.addCustomItem,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: l10n.quickAddHint,
                  labelText: l10n.itemName,
                ),
                autofocus: true,
                validator: (v) =>
                    (v?.trim().isEmpty ?? true) ? l10n.requiredField : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _quantityController,
                decoration: InputDecoration(labelText: l10n.quantity),
                keyboardType: TextInputType.number,
                validator: (v) {
                  final qty = double.tryParse(v ?? '');
                  if (qty == null || qty < 1) return l10n.requiredField;
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _showCustomForm = false),
                      child: Text(l10n.backToSearch),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _addCustomItem,
                      child: Text(l10n.add),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A single product result tile shown in the search results.
class _ProductResultTile extends StatelessWidget {
  const _ProductResultTile({
    required this.product,
    required this.isApi,
    required this.onTap,
  });

  final Product product;
  final bool isApi;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: _buildAvatar(theme, context),
      title: Text(
        product.name != 'Unknown' ? product.name : product.barcode,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        [
          if (product.brand != null && product.brand!.isNotEmpty) product.brand,
          product.barcode,
        ].join(' — '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: product.productType == ProductType.produce
          ? Icon(Icons.eco_outlined, size: 16, color: Colors.green.shade600)
          : isApi
          ? Icon(
              Icons.cloud_outlined,
              size: 16,
              color: theme.colorScheme.outline,
            )
          : null,
      onTap: onTap,
    );
  }

  Widget _buildAvatar(ThemeData theme, BuildContext context) {
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
