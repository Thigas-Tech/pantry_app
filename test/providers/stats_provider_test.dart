/// @file Stats provider unit tests.
///
/// Tests for pure functions and provider logic in
/// [package:pantry_app/providers/stats_provider.dart].  The [parentCategory]
/// function is tested independently; [statsProvider] is tested with an
/// in-memory database seeded with controlled data.
library;

/// AGENTS.md rule 7 requires explicit `source: 'api'` on Product() calls.
/// The freezed `@Default('api')` triggers `avoid_redundant_argument_values`,
/// so suppress that specific lint in this test file.
// ignore_for_file: avoid_redundant_argument_values

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
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

class _TestSettingsNotifier extends SettingsNotifier {
  _TestSettingsNotifier(this._settings);

  factory _TestSettingsNotifier.defaults() =>
      _TestSettingsNotifier(const Settings());

  factory _TestSettingsNotifier.days5() =>
      _TestSettingsNotifier(const Settings(expiringSoonDays: 5));

  final Settings _settings;

  @override
  Settings build() => _settings;
}

class _TestActiveInventoryNotifier extends ActiveInventoryNotifier {
  @override
  int build() => 1;
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    SharedPreferences.setMockInitialValues({});
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
      final result = parentCategory(null, hierarchy);
      expect(result, 'Eggs');
    });

    /// Verifies the 2nd-to-last is picked (3-level hierarchy).
    test('returns parent from hierarchy (3 entries)', () {
      final hierarchy = jsonEncode([
        'en:beverages',
        'en:hot-beverages',
        'en:coffee',
      ]);
      final result = parentCategory(null, hierarchy);
      expect(result, 'Hot beverages');
    });

    /// Verifies fallback to the raw category when hierarchy is null.
    test('falls back to raw category without language prefix', () {
      final result = parentCategory('Dairy', null);
      expect(result, 'Dairy');
    });

    /// Verifies a comma-separated raw category with language tags is
    /// stripped to the first untagged part.
    test('strips language-tagged parts from raw category', () {
      final result = parentCategory('en:dairy, Dairy', null);
      expect(result, 'Dairy');
    });

    /// Verifies a raw category that is entirely language-tagged
    /// returns null.
    test('returns null when raw category has no untagged part', () {
      final result = parentCategory('en:dairy, fr:produit-laitier', null);
      expect(result, null);
    });

    /// Verifies both inputs null returns null.
    test('returns null when both inputs are null', () {
      final result = parentCategory(null, null);
      expect(result, null);
    });

    /// Verifies empty hierarchy JSON uses raw category.
    test('empty hierarchy falls back to raw category', () {
      final result = parentCategory('Snacks', '[]');
      expect(result, 'Snacks');
    });

    /// Verifies hierarchy without English entries uses raw category.
    test('hierarchy without en: entries falls back to raw category', () {
      final hierarchy = jsonEncode([
        'fr:produits',
        'fr:boissons',
      ]);
      final result = parentCategory('Beverages', hierarchy);
      expect(result, 'Beverages');
    });

    /// Verifies invalid JSON falls back gracefully.
    test('invalid JSON falls back to raw category', () {
      final result = parentCategory('Bread', 'not-valid-json');
      expect(result, 'Bread');
    });

    /// Verifies empty string inputs.
    test('returns null for empty string inputs', () {
      final result = parentCategory('', '');
      expect(result, null);
    });

    /// Verifies single en: entry in hierarchy uses it as parent.
    test('single en: entry in hierarchy', () {
      final hierarchy = jsonEncode(['en:fruits']);
      final result = parentCategory(null, hierarchy);
      expect(result, 'Fruits');
    });

    /// Verifies replacing hyphens with spaces in hierarchy names.
    test('replaces hyphens with spaces in hierarchy name', () {
      final hierarchy = jsonEncode([
        'en:products',
        'en:sweet-spreads',
        'en:hazelnut-cocoa-spreads',
      ]);
      final result = parentCategory(null, hierarchy);
      expect(result, 'Sweet spreads');
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
        source: 'api',
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
          inventoryId: 1,
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

    /// Verifies [statsProvider] handles product with null category
    /// without crashing.
    test('handles product with null category gracefully', () async {
      final db = await dbHelper.database;

      const product = Product(
        barcode: '001',
        name: 'Item',
        nutriscoreGrade: 'b',
        source: 'api',
      );
      await dbHelper.productDao.insert(db, product);

      await dbHelper.inventoryDao.insert(
        db,
        InventoryItem(
          barcode: '001',
          quantity: 1,
          unit: 'pcs',
          inventoryId: 1,
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
        source: 'api',
      );
      await dbHelper.productDao.insert(db, product);

      await dbHelper.inventoryDao.insert(
        db,
        InventoryItem(
          barcode: '001',
          quantity: 1,
          unit: 'pcs',
          expiryDate: DateTime.now()
              .subtract(const Duration(days: 10))
              .toIso8601String(),
          inventoryId: 1,
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
