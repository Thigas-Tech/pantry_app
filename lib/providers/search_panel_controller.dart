import 'dart:async';

import 'package:pantry_app/models/inventory_with_product.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/models/product_type.dart';
import 'package:pantry_app/models/search_filter.dart';
import 'package:pantry_app/models/search_result.dart';
import 'package:pantry_app/providers/active_inventory_provider.dart';
import 'package:pantry_app/providers/api_service_provider.dart';
import 'package:pantry_app/providers/connectivity_provider.dart';
import 'package:pantry_app/providers/database_provider.dart';
import 'package:pantry_app/providers/product_repository_provider.dart';
import 'package:pantry_app/providers/usda_provider.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:pantry_app/utils/search_utils.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'search_panel_controller.g.dart';

/// Immutable state for [SearchPanelController].
///
/// Holds everything the search UI needs to render: the current [query], the
/// resolved [results], the loading and searched flags, the active
/// [SearchSource], the in-pantry filter, and a one-shot offline warning flag.
class SearchPanelState {
  /// All fields default to their zero/empty values.
  const SearchPanelState({
    this.query = '',
    this.results = const <SearchResult>[],
    this.isSearching = false,
    this.hasSearched = false,
    this.activeSource = SearchSource.off,
    this.filterInPantryOnly = false,
    this.showOfflineWarning = false,
  });

  /// The raw text currently in the search bar.
  final String query;

  /// The enriched search results.
  final List<SearchResult> results;

  /// Whether a search request is currently in flight.
  final bool isSearching;

  /// Whether at least one search has completed (including empty results).
  final bool hasSearched;

  /// The currently selected [SearchSource].
  final SearchSource activeSource;

  /// When true, only results already in the pantry are shown.
  final bool filterInPantryOnly;

  /// One-shot flag that asks the UI to show the offline warning snackbar.
  ///
  /// Set by the controller when a search path is skipped because the device
  /// is offline, and consumed by the widget via
  /// [SearchPanelController.consumeOfflineWarning] after the snackbar is
  /// shown.
  final bool showOfflineWarning;

  /// [results] filtered by [filterInPantryOnly].
  List<SearchResult> get displayResults {
    if (!filterInPantryOnly) return results;
    return results.where((r) => r.isInPantry).toList();
  }

  /// Returns a copy with the given fields replaced.
  SearchPanelState copyWith({
    String? query,
    List<SearchResult>? results,
    bool? isSearching,
    bool? hasSearched,
    SearchSource? activeSource,
    bool? filterInPantryOnly,
    bool? showOfflineWarning,
  }) {
    return SearchPanelState(
      query: query ?? this.query,
      results: results ?? this.results,
      isSearching: isSearching ?? this.isSearching,
      hasSearched: hasSearched ?? this.hasSearched,
      activeSource: activeSource ?? this.activeSource,
      filterInPantryOnly: filterInPantryOnly ?? this.filterInPantryOnly,
      showOfflineWarning: showOfflineWarning ?? this.showOfflineWarning,
    );
  }
}

/// Notifier that owns all search state and execution for the search panel.
///
/// This is an auto-dispose provider family keyed by the search debounce
/// duration, so state lives exactly as long as the hosting search panel
/// widget and each panel instance is isolated.
///
/// The notifier handles query changes (debounced and on-submit), source
/// switching, the stale-response race guard, pantry enrichment, and all three
/// search implementations (OFF, USDA, and inventory). UI concerns such as
/// navigation, snackbars, and the long-press menu live in the widget layer.
@riverpod
class SearchPanelController extends _$SearchPanelController {
  int _requestId = 0;
  Timer? _debounce;
  Timer? _graceTimer;

  @override
  SearchPanelState build(Duration searchDebounceDuration) {
    ref.onDispose(() {
      _debounce?.cancel();
      _graceTimer?.cancel();
    });
    return const SearchPanelState();
  }

  /// Called on every query change (keystroke).
  ///
  /// Searches are debounced by [searchDebounceDuration]. An empty query
  /// resets the panel to its idle state without triggering a search.
  void onQueryChanged(String value, {required String languageCode}) {
    _debounce?.cancel();
    _graceTimer?.cancel();
    final query = value.trim();
    if (query.isEmpty) {
      _resetToIdle();
      return;
    }
    _requestId++;
    state = state.copyWith(query: value, filterInPantryOnly: false);
    _debounce = Timer(searchDebounceDuration, () {
      unawaited(_search(query, languageCode));
    });
  }

  /// Called when the user submits the search (Enter key).
  ///
  /// Runs the search immediately, bypassing the debounce delay.
  void onQuerySubmitted(String value, {required String languageCode}) {
    _debounce?.cancel();
    _graceTimer?.cancel();
    final query = value.trim();
    if (query.isEmpty) return;
    _requestId++;
    state = state.copyWith(query: value, filterInPantryOnly: false);
    unawaited(_search(query, languageCode));
  }

  /// Clears the query and resets the results.
  ///
  /// The active [SearchSource] and the in-pantry filter are preserved.
  void clear() {
    _debounce?.cancel();
    _graceTimer?.cancel();
    _resetToIdle();
  }

  /// Switches the active [SearchSource].
  ///
  /// When a non-empty query is present, the search is re-run against the new
  /// source. Selecting the already-active source is a no-op.
  void setActiveSource(SearchSource source, {required String languageCode}) {
    if (source == state.activeSource) return;
    final query = state.query.trim();
    state = state.copyWith(activeSource: source);
    if (query.isNotEmpty) {
      _requestId++;
      _debounce?.cancel();
      _graceTimer?.cancel();
      unawaited(_search(query, languageCode));
    }
  }

  /// Sets whether only in-pantry results are displayed.
  void setFilterInPantryOnly({required bool value}) {
    state = state.copyWith(filterInPantryOnly: value);
  }

  /// Removes the result with the same barcode as [product] from the list.
  ///
  /// Used when a result is dismissed via swipe-to-add.
  void removeResult(Product product) {
    state = state.copyWith(
      results: state.results
          .where((r) => r.product.barcode != product.barcode)
          .toList(),
    );
  }

  /// Requests the offline warning snackbar to be shown.
  ///
  /// Only sets the flag when it is not already set, so a single search
  /// produces at most one warning.
  void notifyOffline() {
    if (state.showOfflineWarning) return;
    state = state.copyWith(showOfflineWarning: true);
  }

  /// Clears the one-shot offline warning flag.
  void consumeOfflineWarning() {
    if (!state.showOfflineWarning) return;
    state = state.copyWith(showOfflineWarning: false);
  }

  void _resetToIdle() {
    state = state.copyWith(
      query: '',
      results: const <SearchResult>[],
      isSearching: false,
      hasSearched: false,
    );
  }

  Future<void> _search(String query, String languageCode) async {
    if (!ref.mounted) return;
    final capturedRequestId = _requestId;
    state = state.copyWith(isSearching: true);

    try {
      List<SearchResult> results;
      bool apiHadResults;

      switch (state.activeSource) {
        case SearchSource.off:
          final r = await _searchOff(query, languageCode, capturedRequestId);
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

      if (capturedRequestId != _requestId || !ref.mounted) return;

      final enriched = await _enrichWithPantryStatus(results);
      if (capturedRequestId != _requestId || !ref.mounted) return;

      _graceTimer?.cancel();
      if (enriched.isEmpty && !apiHadResults) {
        _graceTimer = Timer(const Duration(seconds: 1), () {
          if (!ref.mounted) return;
          state = state.copyWith(
            results: enriched,
            isSearching: false,
            hasSearched: true,
          );
        });
        state = state.copyWith(results: const <SearchResult>[]);
      } else {
        state = state.copyWith(
          results: enriched,
          isSearching: false,
          hasSearched: true,
        );
      }
    } on Exception catch (e) {
      logError('Search failed: $e');
      if (!ref.mounted) return;
      state = state.copyWith(
        results: const <SearchResult>[],
        isSearching: false,
        hasSearched: true,
      );
    }
  }

  Future<({List<SearchResult> results, bool apiHadResults})> _searchOff(
    String query,
    String languageCode,
    int capturedRequestId,
  ) async {
    final normalizedQuery = normalizeForSearch(query.trim());
    final db = ref.read(databaseProvider);
    final localResults = await db.searchProducts(normalizedQuery);
    if (capturedRequestId != _requestId || !ref.mounted) {
      return (results: const <SearchResult>[], apiHadResults: false);
    }

    final results = <SearchResult>[
      for (final p in localResults)
        SearchResult(product: p, source: ResultSource.local),
    ];

    final isBarcodeQuery =
        normalizedQuery.length >= 8 &&
        RegExp(r'^\d+$').hasMatch(normalizedQuery);

    var apiHadResults = false;
    if (isBarcodeQuery) {
      try {
        final hasConnection = await ref.read(hasConnectionProvider.future);
        if (!ref.mounted) {
          return (results: const <SearchResult>[], apiHadResults: false);
        }
        if (!hasConnection) {
          notifyOffline();
        } else {
          final repo = ref.read(productRepositoryProvider);
          final product = await repo.getProduct(
            normalizedQuery,
            languageCode: languageCode,
          );
          if (capturedRequestId != _requestId || !ref.mounted) {
            return (results: const <SearchResult>[], apiHadResults: false);
          }
          apiHadResults = true;
          final existingBarcodes = results
              .map((r) => r.product.barcode)
              .toSet();
          if (!existingBarcodes.contains(product.barcode)) {
            results.add(
              SearchResult(product: product, source: ResultSource.api),
            );
          }
        }
      } on Exception catch (e) {
        logWarning('Barcode lookup failed: $e');
      }
    } else if (query.length >= 2) {
      final hasConnection = await ref.read(hasConnectionProvider.future);
      if (!ref.mounted) {
        return (results: const <SearchResult>[], apiHadResults: false);
      }
      if (!hasConnection) {
        notifyOffline();
      } else {
        try {
          final api = ref.read(apiServiceProvider);
          var apiResults = await api.searchProducts(
            normalizedQuery,
            languageCode: languageCode,
          );
          if (capturedRequestId != _requestId || !ref.mounted) {
            return (results: const <SearchResult>[], apiHadResults: false);
          }

          if (apiResults.isEmpty && normalizedQuery != query) {
            apiResults = await api.searchProducts(
              query,
              languageCode: languageCode,
            );
            if (capturedRequestId != _requestId || !ref.mounted) {
              return (results: const <SearchResult>[], apiHadResults: false);
            }
          }

          apiHadResults = apiResults.isNotEmpty;
          final existingBarcodes = results
              .map((r) => r.product.barcode)
              .toSet();
          for (final p in apiResults) {
            if (!existingBarcodes.contains(p.barcode)) {
              results.add(
                SearchResult(product: p, source: ResultSource.api),
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

  Future<List<SearchResult>> _searchUsda(
    String query,
    int capturedRequestId,
  ) async {
    if (query.length < 2) return const <SearchResult>[];

    final normalizedQuery = normalizeForSearch(query.trim());
    final hasConnection = await ref.read(hasConnectionProvider.future);
    if (!ref.mounted) return const <SearchResult>[];
    if (!hasConnection) {
      notifyOffline();
      return const <SearchResult>[];
    }

    try {
      final usda = ref.read(usdaApiClientProvider);
      final products = await usda.searchFood(normalizedQuery);
      if (capturedRequestId != _requestId || !ref.mounted) {
        return const <SearchResult>[];
      }

      return [
        for (final p in products)
          SearchResult(product: p, source: ResultSource.api),
      ];
    } on Exception catch (e) {
      logWarning('USDA search failed: $e');
      return const <SearchResult>[];
    }
  }

  Future<List<SearchResult>> _searchInventory(
    String query,
    int capturedRequestId,
  ) async {
    final normalizedQuery = normalizeForSearch(query.trim());
    final activeId = await ref.read(activeInventoryProvider.future);
    final db = ref.read(databaseProvider);
    final items = await db.getInventoryWithProduct(inventoryId: activeId);
    if (capturedRequestId != _requestId || !ref.mounted) {
      return const <SearchResult>[];
    }

    final inventoryItems = items.map(InventoryWithProduct.fromMap).toList();

    if (normalizedQuery.isEmpty) {
      return [
        for (final item in inventoryItems)
          SearchResult(
            product: Product(
              barcode: item.barcode,
              name: item.productName ?? item.barcode,
              productType: item.productType ?? ProductType.custom,
            ),
            source: ResultSource.local,
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
        SearchResult(
          product: Product(
            barcode: item.barcode,
            name: item.productName ?? item.barcode,
            productType: item.productType ?? ProductType.custom,
          ),
          source: ResultSource.local,
        ),
    ];
  }

  Future<List<SearchResult>> _enrichWithPantryStatus(
    List<SearchResult> results,
  ) async {
    if (results.isEmpty || state.activeSource == SearchSource.inventory) {
      return results
          .map(
            (r) => SearchResult(
              product: r.product,
              source: r.source,
              isInPantry: state.activeSource == SearchSource.inventory,
            ),
          )
          .toList();
    }

    final barcodes = results.map((r) => r.product.barcode).toSet();
    final activeId = await ref.read(activeInventoryProvider.future);
    final db = ref.read(databaseProvider);
    final inPantryBarcodes = await db.getBarcodesInInventory(
      barcodes,
      inventoryId: activeId,
    );

    return results
        .map(
          (r) => SearchResult(
            product: r.product,
            source: r.source,
            isInPantry: inPantryBarcodes.contains(r.product.barcode),
          ),
        )
        .toList();
  }
}
