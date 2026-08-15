/// Unit tests for [SearchPanelState] and [SearchPanelController].
library;

import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/models/search_filter.dart';
import 'package:pantry_app/models/search_result.dart';
import 'package:pantry_app/providers/api_service_provider.dart';
import 'package:pantry_app/providers/connectivity_provider.dart';
import 'package:pantry_app/providers/database_provider.dart';
import 'package:pantry_app/providers/product_repository_provider.dart';
import 'package:pantry_app/providers/search_panel_controller.dart';
import 'package:pantry_app/providers/usda_provider.dart';
import 'package:pantry_app/services/off_adapter.dart';
import 'package:pantry_app/services/usda_api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/pump_app.dart';

class _MockDatabaseHelper extends Mock implements DatabaseHelper {
  _MockDatabaseHelper() {
    when(
      () => getBarcodesInInventory(
        any(),
        inventoryId: any(named: 'inventoryId'),
      ),
    ).thenAnswer((_) async => <String>{});
  }
}

class _MockOffAdapter extends Mock implements OffAdapter {}

class _MockUsdaApiClient extends Mock implements UsdaApiClient {}

void main() {
  const debounce = Duration(milliseconds: 50);
  final panelProvider = searchPanelControllerProvider(debounce);

  late _MockDatabaseHelper mockDb;
  late _MockOffAdapter mockApi;
  late _MockUsdaApiClient mockUsda;
  late MockProductRepository mockRepo;

  const localProduct = Product(
    barcode: '001',
    name: 'Local Milk',
    brand: 'Brand A',
  );
  const apiProduct = Product(
    barcode: '002',
    name: 'API Bread',
    brand: 'Brand B',
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockDb = _MockDatabaseHelper();
    mockApi = _MockOffAdapter();
    mockUsda = _MockUsdaApiClient();
    mockRepo = createMockProductRepository();

    when(() => mockDb.searchProducts(any())).thenAnswer((_) async => []);
    when(
      () => mockDb.getInventories(),
    ).thenAnswer(
      (_) async => <Map<String, dynamic>>[
        {'id': 1},
      ],
    );
    when(
      () => mockApi.searchProducts(
        any(),
        pageSize: any(named: 'pageSize'),
      ),
    ).thenAnswer((_) async => []);
    when(() => mockUsda.searchFood(any())).thenAnswer((_) async => []);
    when(
      () => mockDb.getInventoryWithProduct(
        inventoryId: any(named: 'inventoryId'),
      ),
    ).thenAnswer((_) async => []);
  });

  ProviderContainer makeContainer({bool connected = true}) {
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(mockDb),
        apiServiceProvider.overrideWithValue(mockApi),
        usdaApiClientProvider.overrideWithValue(mockUsda),
        productRepositoryProvider.overrideWithValue(mockRepo),
        hasConnectionProvider.overrideWith((ref) => Future.value(connected)),
      ],
    );
    // Keep the autoDispose provider alive for the whole test.
    final sub = container.listen<SearchPanelState>(panelProvider, (_, _) {});
    addTearDown(() {
      sub.close();
      container.dispose();
    });
    return container;
  }

  SearchPanelController notifierOf(ProviderContainer container) {
    return container.read(panelProvider.notifier);
  }

  SearchPanelState stateOf(ProviderContainer container) {
    return container.read(panelProvider);
  }

  group('SearchPanelState', () {
    test('initial state has empty defaults', () {
      const state = SearchPanelState();
      expect(state.query, '');
      expect(state.results, isEmpty);
      expect(state.isSearching, isFalse);
      expect(state.hasSearched, isFalse);
      expect(state.activeSource, SearchSource.off);
      expect(state.filterInPantryOnly, isFalse);
      expect(state.showOfflineWarning, isFalse);
    });

    test('displayResults returns all when filter is off', () {
      const state = SearchPanelState(
        results: [
          SearchResult(
            product: localProduct,
            source: ResultSource.local,
            isInPantry: true,
          ),
          SearchResult(
            product: apiProduct,
            source: ResultSource.api,
          ),
        ],
      );
      expect(state.displayResults, hasLength(2));
    });

    test('displayResults filters to pantry items when filter is on', () {
      const state = SearchPanelState(
        filterInPantryOnly: true,
        results: [
          SearchResult(
            product: localProduct,
            source: ResultSource.local,
            isInPantry: true,
          ),
          SearchResult(product: apiProduct, source: ResultSource.api),
        ],
      );
      expect(state.displayResults, hasLength(1));
      expect(state.displayResults.single.product.barcode, '001');
    });

    test('copyWith preserves unset fields', () {
      const state = SearchPanelState(isSearching: true, hasSearched: true);
      final copy = state.copyWith(isSearching: false);
      expect(copy.isSearching, isFalse);
      expect(copy.hasSearched, isTrue);
      expect(copy.activeSource, SearchSource.off);
    });
  });

  group('SearchPanelController', () {
    test('initial state is idle', () {
      final container = makeContainer();
      expect(stateOf(container).query, '');
      expect(stateOf(container).results, isEmpty);
      expect(stateOf(container).isSearching, isFalse);
      expect(stateOf(container).hasSearched, isFalse);
    });

    test('onQuerySubmitted runs the search immediately', () async {
      final container = makeContainer();
      when(
        () => mockDb.searchProducts('milk'),
      ).thenAnswer((_) async => [localProduct]);
      when(
        () => mockApi.searchProducts(
          'milk',
          pageSize: any(named: 'pageSize'),
        ),
      ).thenAnswer((_) async => []);

      notifierOf(container).onQuerySubmitted('milk', languageCode: 'en');
      await pumpEventQueue();

      final state = stateOf(container);
      expect(state.hasSearched, isTrue);
      expect(state.isSearching, isFalse);
      expect(state.results, hasLength(1));
      expect(state.results.single.product.barcode, '001');
    });

    test('onQuerySubmitted with empty query does nothing', () async {
      final container = makeContainer();
      notifierOf(container).onQuerySubmitted('   ', languageCode: 'en');
      await pumpEventQueue();
      expect(stateOf(container).hasSearched, isFalse);
      expect(stateOf(container).isSearching, isFalse);
    });

    test('onQueryChanged debounces the search', () {
      fakeAsync((async) {
        final container = makeContainer();
        final notifier = notifierOf(container);
        when(
          () => mockDb.searchProducts('milk'),
        ).thenAnswer((_) async => [localProduct]);

        notifier.onQueryChanged('milk', languageCode: 'en');
        async.elapse(const Duration(milliseconds: 40));
        expect(stateOf(container).results, isEmpty);

        async
          ..elapse(const Duration(milliseconds: 20))
          ..flushMicrotasks();
        expect(stateOf(container).results, hasLength(1));
      });
    });

    test('onQueryChanged empty query resets to idle', () async {
      final container = makeContainer();
      when(
        () => mockDb.searchProducts('milk'),
      ).thenAnswer((_) async => [localProduct]);
      notifierOf(container).onQuerySubmitted('milk', languageCode: 'en');
      await pumpEventQueue();
      expect(stateOf(container).hasSearched, isTrue);

      notifierOf(container).onQueryChanged('', languageCode: 'en');
      await pumpEventQueue();
      final state = stateOf(container);
      expect(state.results, isEmpty);
      expect(state.isSearching, isFalse);
      expect(state.hasSearched, isFalse);
    });

    test('clear preserves source and filter but resets results', () async {
      final container = makeContainer();
      when(
        () => mockDb.searchProducts('milk'),
      ).thenAnswer((_) async => [localProduct]);
      final notifier = notifierOf(container)
        ..onQuerySubmitted('milk', languageCode: 'en');
      await pumpEventQueue();
      notifier
        ..setFilterInPantryOnly(value: true)
        ..clear();

      final state = stateOf(container);
      expect(state.results, isEmpty);
      expect(state.isSearching, isFalse);
      expect(state.hasSearched, isFalse);
      expect(state.activeSource, SearchSource.off);
      expect(state.filterInPantryOnly, isTrue);
    });

    test(
      'setActiveSource re-runs the active query on the new source',
      () async {
        final container = makeContainer();
        when(
          () => mockDb.searchProducts('milk'),
        ).thenAnswer((_) async => []);
        when(() => mockUsda.searchFood('milk')).thenAnswer(
          (_) async => [apiProduct],
        );

        final notifier = notifierOf(container)
          ..onQuerySubmitted('milk', languageCode: 'en');
        await pumpEventQueue();

        notifier.setActiveSource(SearchSource.usda, languageCode: 'en');
        await pumpEventQueue();

        verify(() => mockUsda.searchFood('milk')).called(1);
        final state = stateOf(container);
        expect(state.activeSource, SearchSource.usda);
        expect(state.results.single.product.barcode, '002');
      },
    );

    test('setActiveSource with empty query does not search', () async {
      final container = makeContainer();
      notifierOf(container).setActiveSource(
        SearchSource.usda,
        languageCode: 'en',
      );
      await pumpEventQueue();
      verifyNever(() => mockUsda.searchFood(any()));
      expect(stateOf(container).activeSource, SearchSource.usda);
    });

    test('setActiveSource with same source is a no-op', () {
      final container = makeContainer();
      notifierOf(container).setActiveSource(
        SearchSource.off,
        languageCode: 'en',
      );
      expect(stateOf(container).activeSource, SearchSource.off);
      verifyNever(() => mockDb.searchProducts(any()));
    });

    test('setFilterInPantryOnly filters displayResults', () async {
      final container = makeContainer();
      when(
        () => mockDb.searchProducts('milk'),
      ).thenAnswer((_) async => [localProduct]);
      when(
        () => mockDb.getBarcodesInInventory(
          any(),
          inventoryId: any(named: 'inventoryId'),
        ),
      ).thenAnswer((_) async => {'001'});

      final notifier = notifierOf(container)
        ..onQuerySubmitted('milk', languageCode: 'en');
      await pumpEventQueue();
      expect(stateOf(container).displayResults, hasLength(1));

      notifier.setFilterInPantryOnly(value: true);
      expect(stateOf(container).filterInPantryOnly, isTrue);
      expect(stateOf(container).displayResults, hasLength(1));
    });

    test('removeResult removes the dismissed product', () async {
      final container = makeContainer();
      when(
        () => mockDb.searchProducts('milk'),
      ).thenAnswer((_) async => [localProduct, apiProduct]);

      final notifier = notifierOf(container)
        ..onQuerySubmitted('milk', languageCode: 'en');
      await pumpEventQueue();
      expect(stateOf(container).results, hasLength(2));

      notifier.removeResult(localProduct);
      expect(stateOf(container).results, hasLength(1));
      expect(stateOf(container).results.single.product.barcode, '002');
    });

    test('stale responses are discarded by the request guard', () async {
      final container = makeContainer();
      final slowMilk = Completer<List<Product>>();
      when(
        () => mockDb.searchProducts('milk'),
      ).thenAnswer((_) => slowMilk.future);
      when(
        () => mockDb.searchProducts('bread'),
      ).thenAnswer((_) async => [apiProduct]);

      notifierOf(container)
        ..onQuerySubmitted('milk', languageCode: 'en')
        ..onQuerySubmitted('bread', languageCode: 'en');
      await pumpEventQueue();
      expect(stateOf(container).results.single.product.barcode, '002');

      slowMilk.complete([localProduct]);
      await pumpEventQueue();
      expect(stateOf(container).results.single.product.barcode, '002');
    });

    test('notifyOffline and consumeOfflineWarning are one-shot', () {
      final container = makeContainer();
      final notifier = notifierOf(container);
      expect(stateOf(container).showOfflineWarning, isFalse);

      notifier.notifyOffline();
      expect(stateOf(container).showOfflineWarning, isTrue);

      // A second notify is a no-op while the flag is set.
      notifier.notifyOffline();
      expect(stateOf(container).showOfflineWarning, isTrue);

      notifier.consumeOfflineWarning();
      expect(stateOf(container).showOfflineWarning, isFalse);

      // Consuming again is a no-op.
      notifier.consumeOfflineWarning();
      expect(stateOf(container).showOfflineWarning, isFalse);
    });

    test('enrichment marks results already in the pantry', () async {
      final container = makeContainer();
      when(
        () => mockDb.searchProducts('milk'),
      ).thenAnswer((_) async => [localProduct, apiProduct]);
      when(
        () => mockDb.getBarcodesInInventory(
          any(),
          inventoryId: any(named: 'inventoryId'),
        ),
      ).thenAnswer((_) async => {'001'});

      notifierOf(container).onQuerySubmitted('milk', languageCode: 'en');
      await pumpEventQueue();

      final results = stateOf(container).results;
      expect(
        results.firstWhere((r) => r.product.barcode == '001').isInPantry,
        isTrue,
      );
      expect(
        results.firstWhere((r) => r.product.barcode == '002').isInPantry,
        isFalse,
      );
    });

    test('inventory source marks every result as in pantry', () async {
      final container = makeContainer();
      when(
        () => mockDb.getInventoryWithProduct(
          inventoryId: any(named: 'inventoryId'),
        ),
      ).thenAnswer(
        (_) async => [
          {
            'id': 1,
            'barcode': '001',
            'quantity': 1,
            'unit': 'pcs',
            'location': 'pantry',
            'inventory_id': 1,
            'product_name': 'Milk',
            'product_type': null,
          },
        ],
      );

      notifierOf(container)
        ..setActiveSource(SearchSource.inventory, languageCode: 'en')
        ..onQuerySubmitted('milk', languageCode: 'en');
      await pumpEventQueue();

      final results = stateOf(container).results;
      expect(results, hasLength(1));
      expect(results.single.product.name, 'Milk');
      expect(results.single.isInPantry, isTrue);
    });

    test('OFF results are deduplicated by barcode', () async {
      final container = makeContainer();
      when(
        () => mockDb.searchProducts('milk'),
      ).thenAnswer((_) async => [localProduct]);
      when(
        () => mockApi.searchProducts(
          'milk',
          pageSize: any(named: 'pageSize'),
        ),
      ).thenAnswer((_) async => [localProduct]);

      notifierOf(container).onQuerySubmitted('milk', languageCode: 'en');
      await pumpEventQueue();

      expect(stateOf(container).results, hasLength(1));
      expect(stateOf(container).results.single.source, ResultSource.local);
    });

    test('single-character query never hits the API', () {
      fakeAsync((async) {
        final container = makeContainer();
        notifierOf(container).onQuerySubmitted('a', languageCode: 'en');
        async
          ..flushMicrotasks()
          ..elapse(const Duration(seconds: 1));

        verifyNever(
          () => mockApi.searchProducts(
            any(),
            languageCode: any(named: 'languageCode'),
          ),
        );
        expect(stateOf(container).results, isEmpty);
        expect(stateOf(container).hasSearched, isTrue);
      });
    });

    test('numeric barcode query fetches via the repository', () async {
      const barcode = '5012345678900';
      const barcodeProduct = Product(barcode: barcode, name: 'Cereal');
      final container = makeContainer();
      when(
        () => mockDb.searchProducts(barcode),
      ).thenAnswer((_) async => []);
      when(
        () => mockRepo.getProduct(
          barcode,
          languageCode: any(named: 'languageCode'),
        ),
      ).thenAnswer((_) async => barcodeProduct);

      notifierOf(container).onQuerySubmitted(barcode, languageCode: 'en');
      await pumpEventQueue();

      verify(
        () => mockRepo.getProduct(
          barcode,
          languageCode: 'en',
        ),
      ).called(1);
      final results = stateOf(container).results;
      expect(results, hasLength(1));
      expect(results.single.product.barcode, barcode);
      expect(results.single.source, ResultSource.api);
    });

    test('USDA returns no results for queries shorter than 2 chars', () async {
      final container = makeContainer();
      notifierOf(container)
        ..setActiveSource(SearchSource.usda, languageCode: 'en')
        ..onQuerySubmitted('m', languageCode: 'en');
      await pumpEventQueue();

      verifyNever(() => mockUsda.searchFood(any()));
      expect(stateOf(container).results, isEmpty);
    });

    test(
      'offline search returns local results and sets offline flag',
      () async {
        final container = makeContainer(connected: false);
        when(
          () => mockDb.searchProducts('milk'),
        ).thenAnswer((_) async => [localProduct]);

        notifierOf(container).onQuerySubmitted('milk', languageCode: 'en');
        await pumpEventQueue();

        verifyNever(
          () => mockApi.searchProducts(
            any(),
            languageCode: any(named: 'languageCode'),
          ),
        );
        final state = stateOf(container);
        expect(state.results.single.product.barcode, '001');
        expect(state.showOfflineWarning, isTrue);
      },
    );

    test('search failure clears results and marks hasSearched', () async {
      final container = makeContainer();
      when(
        () => mockDb.searchProducts('milk'),
      ).thenThrow(Exception('boom'));

      notifierOf(container).onQuerySubmitted('milk', languageCode: 'en');
      await pumpEventQueue();

      final state = stateOf(container);
      expect(state.results, isEmpty);
      expect(state.isSearching, isFalse);
      expect(state.hasSearched, isTrue);
    });
  });
}
