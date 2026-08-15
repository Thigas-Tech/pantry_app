import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/l10n/app_localizations.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/providers/connectivity_provider.dart';
import 'package:pantry_app/providers/usda_provider.dart';
import 'package:pantry_app/utils/bottom_sheet_helper.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:pantry_app/utils/search_utils.dart';

/// A bottom sheet for finding non-barcoded produce by name.
///
/// Queries the USDA FoodData Central API ([usdaApiClientProvider]) with a
/// debounced search and returns the selected [Product] (a produce item with
/// a synthetic "plu-" barcode), or null if the user cancels.
class ProduceSearchSheet extends ConsumerStatefulWidget {
  const ProduceSearchSheet._({this.searchDebounceDuration});

  /// How long to wait after the last keystroke before searching.
  final Duration? searchDebounceDuration;

  /// Shows the sheet and returns the selected produce [Product], or null.
  static Future<Product?> show(
    BuildContext context, {
    Duration? searchDebounceDuration,
  }) {
    return BottomSheetHelper.show<Product>(
      context: context,
      builder: (_) => ProduceSearchSheet._(
        searchDebounceDuration: searchDebounceDuration,
      ),
    );
  }

  @override
  ConsumerState<ProduceSearchSheet> createState() => _ProduceSearchSheetState();
}

class _ProduceSearchSheetState extends ConsumerState<ProduceSearchSheet> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  List<Product> _results = [];
  bool _isSearching = false;
  bool _searchFailed = false;
  bool _searched = false;

  Duration get _debounceDuration =>
      widget.searchDebounceDuration ?? const Duration(milliseconds: 700);

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(_debounceDuration, () => _search(query.trim()));
  }

  Future<void> _search(String query) async {
    if (query.isEmpty) {
      setState(() {
        _results = [];
        _searched = false;
        _searchFailed = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _searchFailed = false;
      _searched = true;
    });

    final hasConnection = await ref.read(hasConnectionProvider.future);
    if (!mounted) return;
    if (!hasConnection) {
      logWarning('Produce search skipped — offline');
      setState(() {
        _isSearching = false;
        _searchFailed = true;
      });
      return;
    }

    try {
      final usda = ref.read(usdaApiClientProvider);
      final normalized = normalizeForSearch(query);
      final results = await usda.searchFood(normalized);
      if (!mounted) return;
      setState(() {
        _results = results;
        _isSearching = false;
      });
      logInfo('Produce search — query="$query" results=${results.length}');
    } on Exception catch (e) {
      logWarning('Produce search failed: $e');
      if (!mounted) return;
      setState(() {
        _isSearching = false;
        _searchFailed = true;
      });
    }
  }

  void _select(Product product) {
    Navigator.of(context).pop(product);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: BottomSheetHelper.bottomInset(context)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: SearchBar(
              controller: _searchController,
              hintText: l10n.produceSearchHint,
              leading: const Padding(
                padding: EdgeInsets.only(left: 12),
                child: Icon(Icons.eco_outlined),
              ),
              onChanged: _onQueryChanged,
              trailing: [
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _debounce?.cancel();
                      _searchController.clear();
                      _onQueryChanged('');
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _buildBody(l10n, theme),
        ],
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n, ThemeData theme) {
    if (_isSearching) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_searchFailed) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            l10n.searchFailed,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ),
      );
    }

    if (_searched && _results.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(child: Text(l10n.produceNotFound)),
      );
    }

    if (_results.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            l10n.searchHint,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return Flexible(
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: _results.length,
        itemBuilder: (context, index) {
          final product = _results[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.green.shade100,
              child: Icon(Icons.eco_outlined, color: Colors.green.shade600),
            ),
            title: Text(product.name),
            onTap: () => _select(product),
          );
        },
      ),
    );
  }
}
