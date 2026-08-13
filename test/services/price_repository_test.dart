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

    test('inventoryPriceSummary derives all aggregates from one pass',
        () async {
      final db = await statsDb.database;
      const inventoryDao = InventoryDao();
      final p1Rows = await inventoryDao.listByBarcode(db, 'p1', inventoryId: 1);
      await inventoryDao.update(db, p1Rows.first.copyWith(quantity: 3));

      // Latest prices p1=10 (x3), p2=20 (x1).
      final summary = await statsRepo.inventoryPriceSummary(1);

      expect(summary.total, 50.0);
      expect(summary.average, 12.5);
      expect(summary.count, 2);
    });

    test('inventoryPriceSummary returns nulls when no prices exist',
        () async {
      final db = await statsDb.database;
      await db.delete('prices');

      final summary = await statsRepo.inventoryPriceSummary(1);

      expect(summary.total, isNull);
      expect(summary.average, isNull);
      expect(summary.count, 0);
    });
  });
}
