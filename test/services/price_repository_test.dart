import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/database/inventory_dao.dart';
import 'package:pantry_app/database/price_dao.dart';
import 'package:pantry_app/database/product_dao.dart';
import 'package:pantry_app/models/inventory_item.dart';
import 'package:pantry_app/models/price.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/services/currency_service.dart';
import 'package:pantry_app/services/open_prices_api_client.dart';
import 'package:pantry_app/services/open_prices_service.dart';
import 'package:pantry_app/services/price_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late PriceRepository repo;

  setUp(() {
    repo = PriceRepository(
      DatabaseHelper.withPath('/tmp/price_repo_unused.db'),
      CurrencyService(),
      OpenPricesService(
        databaseHelper: DatabaseHelper.withPath('/tmp/price_repo_unused.db'),
        apiClient: OpenPricesApiClient(
          client: http.Client(),
          baseUrl: 'https://test.prices.api/v1',
          token: 'test-token',
          contactEmail: 'test@example.com',
        ),
      ),
    );
  });

  group('unitPriceLabel', () {
    const perPiece = '/unit';
    const perHundredGrams = '/100 g';
    const perKilogram = '/kg';
    const perLiter = '/L';
    const perHundredMilliliters = '/100 ml';

    String? labelFor(Price price) => repo.unitPriceLabel(
      price,
      perPiece: perPiece,
      perHundredGrams: perHundredGrams,
      perKilogram: perKilogram,
      perLiter: perLiter,
      perHundredMilliliters: perHundredMilliliters,
    );

    test('formats per-piece for a piece package', () {
      final label = labelFor(
        const Price(
          barcode: '1',
          price: 9.99,
          packageQuantity: 12,
          packageUnit: 'pieces',
        ),
      );
      expect(label, isNotNull);
      expect(label, contains('0.83'));
      expect(label, endsWith(perPiece));
    });

    test('formats per-kilogram when the package is at least one kg', () {
      final label = labelFor(
        const Price(
          barcode: '1',
          price: 8,
          packageQuantity: 1,
          packageUnit: 'kg',
        ),
      );
      expect(label, contains('8'));
      expect(label, endsWith(perKilogram));
    });

    test('formats per-hundred-grams for smaller weight packages', () {
      final label = labelFor(
        const Price(
          barcode: '1',
          price: 15,
          packageQuantity: 500,
          packageUnit: 'g',
        ),
      );
      expect(label, contains('3'));
      expect(label, endsWith(perHundredGrams));
    });

    test('formats per-liter when the package is at least one liter', () {
      final label = labelFor(
        const Price(
          barcode: '1',
          price: 5,
          packageQuantity: 1,
          packageUnit: 'L',
        ),
      );
      expect(label, contains('5'));
      expect(label, endsWith(perLiter));
    });

    test('formats per-hundred-milliliters for smaller volume packages', () {
      final label = labelFor(
        const Price(
          barcode: '1',
          price: 5,
          packageQuantity: 250,
          packageUnit: 'ml',
        ),
      );
      expect(label, contains('2'));
      expect(label, endsWith(perHundredMilliliters));
    });

    test('returns null when the price has no package size', () {
      final label = labelFor(
        const Price(barcode: '1', price: 9.99),
      );
      expect(label, isNull);
    });

    test('returns null when the package quantity is invalid', () {
      final label = labelFor(
        const Price(
          barcode: '1',
          price: 9.99,
          packageQuantity: 0,
          packageUnit: 'pieces',
        ),
      );
      expect(label, isNull);
    });
  });

  group('quantity-weighted aggregations', () {
    setUpAll(() {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    });

    late DatabaseHelper statsDb;
    late PriceRepository statsRepo;

    setUp(() async {
      statsDb = DatabaseHelper.withPath(inMemoryDatabasePath);
      final db = await statsDb.database;

      const productDao = ProductDao();
      await productDao.insert(
        db,
        const Product(barcode: 'p1', name: 'Product 1'),
      );
      await productDao.insert(
        db,
        const Product(barcode: 'p2', name: 'Product 2'),
      );

      const inventoryDao = InventoryDao();
      await inventoryDao.insert(db, const InventoryItem(barcode: 'p1'));
      await inventoryDao.insert(db, const InventoryItem(barcode: 'p2'));

      const priceDao = PriceDao();
      await priceDao.insert(
        db,
        const Price(barcode: 'p1', price: 8, datePurchased: 100),
      );
      await priceDao.insert(
        db,
        const Price(barcode: 'p1', price: 10, datePurchased: 200),
      );
      await priceDao.insert(
        db,
        const Price(barcode: 'p2', price: 15, datePurchased: 100),
      );
      await priceDao.insert(
        db,
        const Price(barcode: 'p2', price: 20, datePurchased: 200),
      );

      statsRepo = PriceRepository(
        statsDb,
        CurrencyService(),
        OpenPricesService(
          databaseHelper: statsDb,
          apiClient: OpenPricesApiClient(
            client: http.Client(),
            baseUrl: 'https://test.prices.api/v1',
            token: 'test-token',
            contactEmail: 'test@example.com',
          ),
        ),
      );
    });

    tearDown(() async {
      final db = await statsDb.database;
      await db.close();
    });

    test('totalInventoryValue scales by inventory quantity', () async {
      final db = await statsDb.database;
      const inventoryDao = InventoryDao();
      final p1Rows = await inventoryDao.listByBarcode(db, 'p1', inventoryId: 1);
      await inventoryDao.update(db, p1Rows.first.copyWith(quantity: 3));

      // Latest prices p1=10, p2=20; p1 held 3 units => 10*3 + 20*1.
      expect(await statsRepo.totalInventoryValue(1), 50.0);
    });

    test('averageItemPrice is weighted by inventory quantity', () async {
      final db = await statsDb.database;
      const inventoryDao = InventoryDao();
      final p1Rows = await inventoryDao.listByBarcode(db, 'p1', inventoryId: 1);
      await inventoryDao.update(db, p1Rows.first.copyWith(quantity: 3));

      // Quantity-weighted average (10*3 + 20*1) / (3 + 1).
      expect(await statsRepo.averageItemPrice(1), 12.5);
    });

    test('aggregations return null when no prices exist', () async {
      final db = await statsDb.database;
      await db.delete('prices');
      expect(await statsRepo.totalInventoryValue(1), isNull);
      expect(await statsRepo.averageItemPrice(1), isNull);
    });

    test(
      'inventoryPriceSummary derives all aggregates from one pass',
      () async {
        final db = await statsDb.database;
        const inventoryDao = InventoryDao();
        final p1Rows = await inventoryDao.listByBarcode(
          db,
          'p1',
          inventoryId: 1,
        );
        await inventoryDao.update(db, p1Rows.first.copyWith(quantity: 3));

        // Latest prices p1=10 (x3), p2=20 (x1).
        final summary = await statsRepo.inventoryPriceSummary(1);

        expect(summary.total, 50.0);
        expect(summary.average, 12.5);
        expect(summary.count, 2);
      },
    );

    test('inventoryPriceSummary returns nulls when no prices exist', () async {
      final db = await statsDb.database;
      await db.delete('prices');

      final summary = await statsRepo.inventoryPriceSummary(1);

      expect(summary.total, isNull);
      expect(summary.average, isNull);
      expect(summary.count, 0);
    });
  });

  group('package-aware aggregations', () {
    setUpAll(() {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    });

    late DatabaseHelper packageDb;
    late PriceRepository packageRepo;

    setUp(() async {
      packageDb = DatabaseHelper.withPath(inMemoryDatabasePath);
      final db = await packageDb.database;

      const productDao = ProductDao();
      await productDao.insert(
        db,
        const Product(barcode: 'pk1', name: 'Dozen eggs'),
      );
      await productDao.insert(
        db,
        const Product(barcode: 'pk2', name: 'Milk'),
      );

      const inventoryDao = InventoryDao();
      // pk1: a dozen eggs held as 12 pieces at $4 for the 12-pack.
      await inventoryDao.insert(
        db,
        const InventoryItem(barcode: 'pk1', quantity: 12),
      );
      // pk2: no package size, held 6 units at $2 each.
      await inventoryDao.insert(
        db,
        const InventoryItem(barcode: 'pk2', quantity: 6),
      );

      const priceDao = PriceDao();
      await priceDao.insert(
        db,
        const Price(
          barcode: 'pk1',
          price: 4,
          datePurchased: 100,
          packageQuantity: 12,
          packageUnit: 'pieces',
        ),
      );
      await priceDao.insert(
        db,
        const Price(barcode: 'pk2', price: 2, datePurchased: 100),
      );

      packageRepo = PriceRepository(
        packageDb,
        CurrencyService(),
        OpenPricesService(
          databaseHelper: packageDb,
          apiClient: OpenPricesApiClient(
            client: http.Client(),
            baseUrl: 'https://test.prices.api/v1',
            token: 'test-token',
            contactEmail: 'test@example.com',
          ),
        ),
      );
    });

    tearDown(() async {
      final db = await packageDb.database;
      await db.close();
    });

    test('totalInventoryValue scales latest price by package size', () async {
      // pk1: 4 * 12 / 12 = 4; pk2: 2 * 6 = 12. Total 16.
      expect(await packageRepo.totalInventoryValue(1), 16.0);
    });

    test('averageItemPrice is weighted and package-aware', () async {
      // (4*12/12 + 2*6) / (12 + 6) = 16/18, rounded to cents.
      expect(await packageRepo.averageItemPrice(1), 0.89);
    });

    test('inventoryPriceSummary is package-aware', () async {
      final summary = await packageRepo.inventoryPriceSummary(1);
      expect(summary.total, 16.0);
      expect(summary.average, 0.89);
      expect(summary.count, 2);
    });
  });

  group('priceHistoryPoints', () {
    setUpAll(() {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    });

    late DatabaseHelper historyDb;
    late PriceRepository historyRepo;

    setUp(() async {
      historyDb = DatabaseHelper.withPath(inMemoryDatabasePath);
      final db = await historyDb.database;

      const productDao = ProductDao();
      await productDao.insert(
        db,
        const Product(barcode: 'h1', name: 'History product'),
      );

      const priceDao = PriceDao();
      await priceDao.insert(
        db,
        Price(
          barcode: 'h1',
          price: 10,
          datePurchased: DateTime(2026, 6, 15).millisecondsSinceEpoch,
          store: 'Corner Shop',
        ),
      );
      await priceDao.insert(
        db,
        Price(
          barcode: 'h1',
          price: 5,
          datePurchased: DateTime(2026, 6, 10).millisecondsSinceEpoch,
        ),
      );

      historyRepo = PriceRepository(
        historyDb,
        CurrencyService(),
        OpenPricesService(
          databaseHelper: historyDb,
          apiClient: OpenPricesApiClient(
            client: http.Client(),
            baseUrl: 'https://test.prices.api/v1',
            token: 'test-token',
            contactEmail: 'test@example.com',
          ),
        ),
      );
    });

    tearDown(() async {
      final db = await historyDb.database;
      await db.close();
    });

    test('converts history into date-sorted points', () async {
      final points = await historyRepo.priceHistoryPoints(
        'h1',
        inventoryId: 1,
        baseCurrency: 'USD',
      );

      expect(points, hasLength(2));
      // Oldest first for a left-to-right time axis.
      expect(points.first.amount, 5);
      expect(points.first.date, DateTime(2026, 6, 10));
      expect(points.last.amount, 10);
      expect(points.last.store, 'Corner Shop');
    });

    test('returns an empty list for a barcode without prices', () async {
      final points = await historyRepo.priceHistoryPoints(
        'unknown',
        inventoryId: 1,
        baseCurrency: 'USD',
      );

      expect(points, isEmpty);
    });
  });
}
