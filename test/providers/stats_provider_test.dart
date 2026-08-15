/// @file Stats provider unit tests.
///
/// Tests for pure functions and provider logic in
/// [package:pantry_app/providers/stats_provider.dart].  The [parentCategory]
/// function is tested independently; [statsProvider] is tested with an
/// in-memory database seeded with controlled data.
library;

import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/models/inventory_item.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/providers/active_inventory_provider.dart';
import 'package:pantry_app/providers/database_provider.dart';
import 'package:pantry_app/providers/price_repository_provider.dart';
import 'package:pantry_app/providers/settings_provider.dart';
import 'package:pantry_app/providers/stats_provider.dart';
import 'package:pantry_app/services/currency_service.dart';
import 'package:pantry_app/services/price_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// An [http.Client] that always throws, so [CurrencyService] falls back
/// to empty cache (returning empty rates, which makes price queries safe).
class _FailingHttpClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    throw Exception('FailingHttpClient: no network in test');
  }
}

class _MockPriceRepository extends Mock implements PriceRepository {}

class _TestSettingsNotifier extends SettingsNotifier {
  _TestSettingsNotifier(this._settings);

  factory _TestSettingsNotifier.defaults() =>
      _TestSettingsNotifier(const Settings());

  factory _TestSettingsNotifier.days5() =>
      _TestSettingsNotifier(const Settings(expiringSoonDays: 5));

  final Settings _settings;

  @override
  Future<Settings> build() async => _settings;
}

class _TestActiveInventoryNotifier extends ActiveInventoryNotifier {
  @override
  Future<int> build() async => 1;
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    SharedPreferences.setMockInitialValues({});
    dotenv.loadFromString(isOptional: true, mergeWith: {});
  });

  group('parentCategory', () {
    /// Verifies that [parentCategory] returns the 3rd-level English entry
    /// when a full OFF hierarchy is provided.
    test('returns parent from hierarchy (4 entries)', () {
      final hierarchy = jsonEncode([
        'en:products',
        'en:eggs-and-their-products',
        'en:eggs',
        'en:chicken-eggs',
      ]);
      final result = parentCategory(null, hierarchy, 'en');
      expect(result, 'Eggs');
    });

    /// Verifies the 2nd-to-last is picked (3-level hierarchy).
    test('returns parent from hierarchy (3 entries)', () {
      final hierarchy = jsonEncode([
        'en:beverages',
        'en:hot-beverages',
        'en:coffee',
      ]);
      final result = parentCategory(null, hierarchy, 'en');
      expect(result, 'Hot beverages');
    });

    /// Verifies fallback to the raw category when hierarchy is null.
    test('falls back to raw category without language prefix', () {
      final result = parentCategory('Dairy', null, 'en');
      expect(result, 'Dairy');
    });

    /// Verifies a comma-separated raw category with language tags is
    /// stripped to the first untagged part.
    test('strips language-tagged parts from raw category', () {
      final result = parentCategory('en:dairy, Dairy', null, 'en');
      expect(result, 'Dairy');
    });

    /// Verifies a raw category that is entirely language-tagged
    /// returns null.
    test('returns null when raw category has no untagged part', () {
      final result = parentCategory('en:dairy, fr:produit-laitier', null, 'en');
      expect(result, null);
    });

    /// Verifies both inputs null returns null.
    test('returns null when both inputs are null', () {
      final result = parentCategory(null, null, 'en');
      expect(result, null);
    });

    /// Verifies empty hierarchy JSON uses raw category.
    test('empty hierarchy falls back to raw category', () {
      final result = parentCategory('Snacks', '[]', 'en');
      expect(result, 'Snacks');
    });

    /// Verifies hierarchy without English entries uses raw category.
    test('hierarchy without en: entries falls back to raw category', () {
      final hierarchy = jsonEncode([
        'fr:produits',
        'fr:boissons',
      ]);
      final result = parentCategory('Beverages', hierarchy, 'en');
      expect(result, 'Beverages');
    });

    /// Verifies invalid JSON falls back gracefully.
    test('invalid JSON falls back to raw category', () {
      final result = parentCategory('Bread', 'not-valid-json', 'en');
      expect(result, 'Bread');
    });

    /// Verifies empty string inputs.
    test('returns null for empty string inputs', () {
      final result = parentCategory('', '', 'en');
      expect(result, null);
    });

    /// Verifies single en: entry in hierarchy uses it as parent.
    test('single en: entry in hierarchy', () {
      final hierarchy = jsonEncode(['en:fruits']);
      final result = parentCategory(null, hierarchy, 'en');
      expect(result, 'Fruits');
    });

    /// Verifies replacing hyphens with spaces in hierarchy names.
    test('replaces hyphens with spaces in hierarchy name', () {
      final hierarchy = jsonEncode([
        'en:products',
        'en:sweet-spreads',
        'en:hazelnut-cocoa-spreads',
      ]);
      final result = parentCategory(null, hierarchy, 'en');
      expect(result, 'Sweet spreads');
    });

    /// Verifies that pt: tags are preferred over en: tags.
    test('prefers pt: tags over en: tags', () {
      final hierarchy = jsonEncode([
        'en:products',
        'en:dairy',
        'en:milk',
        'en:whole-milk',
        'pt:produtos',
        'pt:laticinios',
        'pt:leite',
        'pt:leite-integral',
      ]);
      final result = parentCategory(null, hierarchy, 'pt');
      expect(result, 'Leite');
    });

    /// Verifies pt: tags work without any en: tags present.
    test('uses pt: tags when no en: tags exist', () {
      final hierarchy = jsonEncode([
        'fr:produits',
        'pt:laticinios',
        'pt:leites',
        'pt:leite-gordo',
      ]);
      final result = parentCategory('Milk', hierarchy, 'pt');
      expect(result, 'Leites');
    });

    /// Verifies fallback to en: when no pt: tags exist.
    test('falls back to en: when no pt: tags', () {
      final hierarchy = jsonEncode([
        'en:products',
        'en:dairy',
        'en:cheeses',
        'en:cheddar',
      ]);
      final result = parentCategory(null, hierarchy, 'pt');
      expect(result, 'Cheeses');
    });

    /// Verifies pt: tags with hyphens are converted correctly.
    test('handles pt: tags with hyphens', () {
      final hierarchy = jsonEncode([
        'en:products',
        'en:snacks',
        'pt:produtos',
        'pt:salgadinhos',
        'pt:batata-frita',
      ]);
      final result = parentCategory(null, hierarchy, 'pt');
      expect(result, 'Salgadinhos');
    });

    /// Verifies fr: tags are preferred when the locale is French.
    test('prefers fr: tags for a French locale', () {
      final hierarchy = jsonEncode([
        'en:products',
        'en:dairy',
        'en:milk',
        'en:whole-milk',
        'fr:produits',
        'fr:produits-laitiers',
        'fr:lait',
        'fr:lait-entier',
      ]);
      final result = parentCategory(null, hierarchy, 'fr');
      expect(result, 'Lait');
    });

    /// Verifies fallback to en: when the requested language is absent.
    test('falls back to en: when the requested language has no tags', () {
      final hierarchy = jsonEncode([
        'en:products',
        'en:dairy',
        'en:cheeses',
        'en:cheddar',
        'fr:produits',
        'fr:fromages',
      ]);
      final result = parentCategory(null, hierarchy, 'de');
      expect(result, 'Cheeses');
    });

    /// Verifies en: tags are used directly for an English locale.
    test('uses en: tags for an English locale', () {
      final hierarchy = jsonEncode([
        'pt:produtos',
        'pt:laticinios',
        'pt:queijos',
        'pt:queijo-cheddar',
        'en:products',
        'en:dairy',
        'en:cheeses',
        'en:cheddar',
      ]);
      final result = parentCategory(null, hierarchy, 'en');
      expect(result, 'Cheeses');
    });
  });

  group('statsProvider', () {
    late DatabaseHelper dbHelper;

    setUp(() async {
      dbHelper = DatabaseHelper.withPath(inMemoryDatabasePath);
      await dbHelper.database;
    });

    tearDown(() async {
      final db = await dbHelper.database;
      await db.close();
    });

    /// Verifies [statsProvider] returns default/zero stats when the
    /// database is empty.
    test('returns zero stats on empty database', () async {
      final priceRepo = PriceRepository(
        dbHelper,
        CurrencyService(httpClient: _FailingHttpClient()),
      );
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(dbHelper),
          activeInventoryProvider.overrideWith(
            _TestActiveInventoryNotifier.new,
          ),
          settingsProvider.overrideWith(
            _TestSettingsNotifier.defaults,
          ),
          priceRepositoryProvider.overrideWithValue(priceRepo),
        ],
      );
      addTearDown(container.dispose);

      final stats = await container.read(statsProvider.future);

      expect(stats.totalProducts, 0);
      expect(stats.totalItems, 0);
      expect(stats.averageNutriscoreNumeric, 0.0);
      expect(stats.expiredCount, 0);
      expect(stats.expiringSoonCount, 0);
      expect(stats.goodCount, 0);
      expect(stats.addedThisWeek, 0);
      expect(stats.itemsByLocation, isEmpty);
      expect(stats.categoriesTop, isEmpty);
      expect(stats.nutriscoreDistribution, isEmpty);
    });

    /// Verifies [statsProvider] computes correct totals and
    /// distributions for a single product with inventory.
    test('computes stats for seeded data', () async {
      final db = await dbHelper.database;

      const product = Product(
        barcode: '001',
        name: 'Milk',
        category: 'Dairy',
        nutriscoreGrade: 'a',
        categoriesHierarchy: ['en:dairy', 'en:milk'],
      );
      await dbHelper.productDao.insert(db, product);

      await dbHelper.inventoryDao.insert(
        db,
        InventoryItem(
          barcode: '001',
          quantity: 3,
          unit: 'kg',
          location: 'fridge',
          expiryDate: DateTime.now()
              .add(const Duration(days: 10))
              .toIso8601String(),
          dateAdded: DateTime.now().millisecondsSinceEpoch,
        ),
      );

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(dbHelper),
          activeInventoryProvider.overrideWith(
            _TestActiveInventoryNotifier.new,
          ),
          settingsProvider.overrideWith(
            _TestSettingsNotifier.days5,
          ),
        ],
      );
      addTearDown(container.dispose);

      final stats = await container.read(statsProvider.future);

      expect(stats.totalProducts, 1);
      expect(stats.totalItems, 1);
      expect(stats.expiredCount, 0);
      expect(stats.goodCount, 1);
      expect(stats.addedThisWeek, 1);
      expect(stats.itemsByLocation, {'fridge': 1});
      expect(stats.categoriesTop.length, 1);
      expect(stats.categoriesTop.first.category, 'Dairy');
      expect(stats.categoriesTop.first.count, 1);
      expect(stats.nutriscoreDistribution, {'a': 1});
      expect(stats.itemsBySource, {'api': 1});
      expect(stats.localPhotos.total, 1);
      expect(stats.offPhotos.total, 1);
      expect(stats.offPhotos.withProduct, 0);
    });

    test('derives price aggregates from a single latest-price pass', () async {
      final mockPriceRepo = _MockPriceRepository();
      when(
        () => mockPriceRepo.inventoryPriceSummary(1, baseCurrency: 'EUR'),
      ).thenAnswer((_) async => (total: 42.5, average: 7.5, count: 3));

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(dbHelper),
          activeInventoryProvider.overrideWith(
            _TestActiveInventoryNotifier.new,
          ),
          settingsProvider.overrideWith(
            () => _TestSettingsNotifier(
              const Settings(baseCurrency: 'EUR'),
            ),
          ),
          priceRepositoryProvider.overrideWithValue(mockPriceRepo),
        ],
      );
      addTearDown(container.dispose);

      final stats = await container.read(statsProvider.future);

      expect(stats.totalValue, 42.5);
      expect(stats.averagePrice, 7.5);
      expect(stats.pricedItemCount, 3);
      verify(
        () => mockPriceRepo.inventoryPriceSummary(1, baseCurrency: 'EUR'),
      ).called(1);
      verifyNever(
        () => mockPriceRepo.totalInventoryValue(
          any(),
          baseCurrency: any(named: 'baseCurrency'),
        ),
      );
      verifyNever(
        () => mockPriceRepo.averageItemPrice(
          any(),
          baseCurrency: any(named: 'baseCurrency'),
        ),
      );
      verifyNever(() => mockPriceRepo.pricedItemCount(any()));
    });

    /// Verifies [statsProvider] handles product with null category
    /// without crashing.
    test('handles product with null category gracefully', () async {
      final db = await dbHelper.database;

      const product = Product(
        barcode: '001',
        name: 'Item',
        nutriscoreGrade: 'b',
      );
      await dbHelper.productDao.insert(db, product);

      await dbHelper.inventoryDao.insert(
        db,
        InventoryItem(
          barcode: '001',
          unit: 'pcs',
          dateAdded: DateTime.now().millisecondsSinceEpoch,
        ),
      );

      final priceRepo = PriceRepository(
        dbHelper,
        CurrencyService(httpClient: _FailingHttpClient()),
      );
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(dbHelper),
          activeInventoryProvider.overrideWith(
            _TestActiveInventoryNotifier.new,
          ),
          settingsProvider.overrideWith(
            _TestSettingsNotifier.defaults,
          ),
          priceRepositoryProvider.overrideWithValue(priceRepo),
        ],
      );
      addTearDown(container.dispose);

      final stats = await container.read(statsProvider.future);

      expect(stats.totalProducts, 1);
      expect(stats.totalItems, 1);
      expect(stats.categoriesTop, isEmpty);
    });

    /// Verifies [statsProvider] handles an expired inventory item
    /// correctly in the expiry distribution.
    test('counts expired items correctly', () async {
      final db = await dbHelper.database;

      const product = Product(
        barcode: '001',
        name: 'Expired Milk',
        category: 'Dairy',
      );
      await dbHelper.productDao.insert(db, product);

      await dbHelper.inventoryDao.insert(
        db,
        InventoryItem(
          barcode: '001',
          unit: 'pcs',
          expiryDate: DateTime.now()
              .subtract(const Duration(days: 10))
              .toIso8601String(),
          dateAdded: DateTime.now().millisecondsSinceEpoch,
        ),
      );

      final priceRepo = PriceRepository(
        dbHelper,
        CurrencyService(httpClient: _FailingHttpClient()),
      );
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(dbHelper),
          activeInventoryProvider.overrideWith(
            _TestActiveInventoryNotifier.new,
          ),
          settingsProvider.overrideWith(
            _TestSettingsNotifier.days5,
          ),
          priceRepositoryProvider.overrideWithValue(priceRepo),
        ],
      );
      addTearDown(container.dispose);

      final stats = await container.read(statsProvider.future);

      expect(stats.expiredCount, 1);
      expect(stats.expiringSoonCount, 0);
      expect(stats.goodCount, 0);
    });
  });
}
