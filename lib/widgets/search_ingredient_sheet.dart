import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/l10n/app_localizations.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/models/product_type.dart';
import 'package:pantry_app/providers/api_service_provider.dart';
import 'package:pantry_app/providers/connectivity_provider.dart';
import 'package:pantry_app/providers/database_provider.dart';
import 'package:pantry_app/utils/bottom_sheet_helper.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:pantry_app/utils/progress_indicator_helper.dart';
import 'package:pantry_app/utils/search_utils.dart';

/// A bottom sheet that lets the user search for products by name or barcode.
///
/// Searches the local database and the Open Food Facts API. Tapping a result
/// pops the sheet with the selected [Product], or null if cancelled.
///
/// Example:
/// ```dart
/// final product = await SearchIngredientSheet.show(context);
/// if (product != null) {
///   addIngredient(name: product.name, barcode: product.barcode);
/// }
/// ```
class SearchIngredientSheet extends ConsumerStatefulWidget {
  const SearchIngredientSheet._();

  /// Shows the search sheet and returns the selected [Product], or null.
  static Future<Product?> show(BuildContext context) {
    return BottomSheetHelper.show<Product>(
      context: context,
      builder: (_) => const SearchIngredientSheet._(),
    );
  }

  @override
  ConsumerState<SearchIngredientSheet> createState() =>
      _SearchIngredientSheetState();
}

class _SearchIngredientSheetState extends ConsumerState<SearchIngredientSheet> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  List<Product> _results = [];
  bool _isSearching = false;
  bool _hasSearched = false;
  int _requestId = 0;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
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
    _debounce = Timer(
      const Duration(milliseconds: 500),
      () => _search(query),
    );
  }

  Future<void> _search(String query) async {
    final capturedRequestId = _requestId;
    setState(() => _isSearching = true);

    final normalizedQuery = normalizeForSearch(query);
    final locale = Localizations.localeOf(context).languageCode;

    try {
      final db = ref.read(databaseProvider);
      final local = await db.searchProducts(normalizedQuery);
      if (capturedRequestId != _requestId || !mounted) return;

      final hasConnection = await ref.read(hasConnectionProvider.future);
      var apiResults = <Product>[];
      if (hasConnection && query.length >= 2) {
        final api = ref.read(apiServiceProvider);
        apiResults = await api.searchProducts(
          query,
          languageCode: locale,
        );
        if (capturedRequestId != _requestId || !mounted) return;

        // Dedup against local results
        final existingBarcodes = local.map((p) => p.barcode).toSet();
        apiResults = apiResults
            .where((p) => !existingBarcodes.contains(p.barcode))
            .toList();
      }

      setState(() {
        _results = [...local, ...apiResults];
        _isSearching = false;
        _hasSearched = true;
      });
    } on Exception catch (e) {
      logError('Search failed: $e');
      if (!mounted) return;
      setState(() {
        _isSearching = false;
        _hasSearched = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: EdgeInsets.only(
        bottom: BottomSheetHelper.bottomInset(context),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SearchBar(
              controller: _searchController,
              hintText: l10n.productSearchHint,
              autoFocus: true,
              onChanged: _onSearchChanged,
            ),
          ),
          if (_isSearching)
            Padding(
              padding: const EdgeInsets.all(16),
              child: ProgressIndicatorHelper.build(),
            )
          else if (_results.isNotEmpty)
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _results.length,
                itemBuilder: (context, index) {
                  final product = _results[index];
                  return ListTile(
                    title: Text(
                      product.name != 'Unknown'
                          ? product.name
                          : product.barcode,
                    ),
                    subtitle: Text(product.barcode),
                    leading: Icon(
                      product.productType == ProductType.produce
                          ? Icons.eco
                          : Icons.inventory_2,
                    ),
                    onTap: () => Navigator.pop(context, product),
                  );
                },
              ),
            )
          else if (_hasSearched)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                l10n.noProductsFound,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                l10n.productSearchHint,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
