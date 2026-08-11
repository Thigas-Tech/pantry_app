import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/database/product_dao.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/models/product_nutrient.dart';
import 'package:pantry_app/models/product_type.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late DatabaseHelper dbHelper;
  late ProductDao dao;

  setUp(() async {
    dbHelper = DatabaseHelper.withPath(inMemoryDatabasePath);
    await dbHelper.database;
    dao = const ProductDao();
  });

  tearDown(() async {
    final db = await dbHelper.database;
    await db.close();
  });

  group('ProductDao basic CRUD', () {
    const product = Product(
      barcode: '1234567890123',
      name: 'Test Product',
      brand: 'Test Brand',
      imageUrl: 'https://example.com/image.jpg',
      category: 'Test Category',
      ingredients: 'Ingredient 1, Ingredient 2',
      servingSize: '100g',
      energyKcal: 100,
      proteinG: 10,
      carbsG: 20,
      fatG: 5,
      fiberG: 2,
      saltG: 0.1,
      lastSynced: 123456789,
      nutriscoreGrade: 'a',
      nutritionImagePath: '/path/to/nutr.jpg',
      ingredientsImagePath: '/path/to/ingr.jpg',
      productImagePath: '/path/to/prod.jpg',
      offNutritionImageUrl: 'https://off.org/nutr',
      offIngredientsImageUrl: 'https://off.org/ingr',
      offProductImageUrl: 'https://off.org/prod',
      categoriesHierarchy: ['Root', 'Level1', 'Level2'],
    );

    test('insert and get', () async {
      final db = await dbHelper.database;
      await dao.insert(db, product);
      final fetched = await dao.get(db, product.barcode);
      expect(fetched, isNotNull);
      expect(fetched!.name, product.name);
      expect(fetched.categoriesHierarchy, product.categoriesHierarchy);
    });

    test('upsert replaces existing', () async {
      final db = await dbHelper.database;
      await dao.insert(db, product);
      final updated = product.copyWith(name: 'Updated Name');
      await dao.insert(db, updated);
      final fetched = await dao.get(db, product.barcode);
      expect(fetched!.name, 'Updated Name');
    });

    test('get returns null for missing barcode', () async {
      final db = await dbHelper.database;
      final result = await dao.get(db, 'nonexistent');
      expect(result, isNull);
    });

    test('count and all', () async {
      final db = await dbHelper.database;
      await dao.insert(db, product);
      await dao.insert(db, product.copyWith(barcode: '456', name: 'Prod 2'));
      expect(await dao.count(db), 2);
      expect((await dao.all(db)).length, 2);
    });

    test('clear removes all', () async {
      final db = await dbHelper.database;
      await dao.insert(db, product);
      await dao.clear(db);
      expect(await dao.count(db), 0);
    });

    test('insert and get round-trips packaging quantity fields', () async {
      final db = await dbHelper.database;
      const packaged = Product(
        barcode: '777',
        name: 'Eggs',
        quantity: '12 x 1',
        productQuantity: 12,
      );
      await dao.insert(db, packaged);
      final fetched = await dao.get(db, '777');
      expect(fetched, isNotNull);
      expect(fetched!.quantity, '12 x 1');
      expect(fetched.productQuantity, 12);
    });
  });

  group('ProductDao search', () {
    setUp(() async {
      final db = await dbHelper.database;
      await dao.insert(db, const Product(barcode: '1', name: 'Café au Lait'));
      await dao.insert(db, const Product(barcode: '2', name: 'Apple'));
      await dao.insert(db, const Product(barcode: '3', name: 'Banana'));
    });

    test('search finds by name case-insensitively', () async {
      final db = await dbHelper.database;
      final results = await dao.search(db, 'cafe');
      expect(results.any((p) => p.name == 'Café au Lait'), isTrue);
    });

    test('search finds by name accent-insensitively', () async {
      final db = await dbHelper.database;
      final results = await dao.search(db, 'cafe'); // 'cafe' matches 'Café'
      expect(results.any((p) => p.name == 'Café au Lait'), isTrue);
    });

    test('search finds by barcode', () async {
      final db = await dbHelper.database;
      final results = await dao.search(db, '1');
      expect(results.any((p) => p.barcode == '1'), isTrue);
    });

    test('search returns empty for no match', () async {
      final db = await dbHelper.database;
      final results = await dao.search(db, 'Zebra');
      expect(results, isEmpty);
    });
  });

  group('ProductDao source filtering', () {
    setUp(() async {
      final db = await dbHelper.database;
      await dao.insert(
        db,
        const Product(barcode: 'api1', name: 'API 1'),
      );
      await dao.insert(
        db,
        const Product(
          barcode: 'man1',
          name: 'Man 1',
          source: 'manual',
        ),
      );
    });

    test('getBySource filters correctly', () async {
      final db = await dbHelper.database;
      final apiProds = await dao.getBySource(db, 'api');
      final manProds = await dao.getBySource(db, 'manual');
      expect(apiProds.length, 1);
      expect(apiProds.first.barcode, 'api1');
      expect(manProds.length, 1);
      expect(manProds.first.barcode, 'man1');
    });

    test('deleteBySource removes only target source', () async {
      final db = await dbHelper.database;
      await dao.deleteBySource(db, 'api');
      expect(await dao.count(db), 1);
      expect(await dao.get(db, 'api1'), isNull);
      expect(await dao.get(db, 'man1'), isNotNull);
    });
  });

  group('ProductDao distributions', () {
    setUp(() async {
      final db = await dbHelper.database;
      await dao.insert(
        db,
        const Product(
          barcode: '1',
          name: 'P1',
          nutriscoreGrade: 'a',
        ),
      );
      await dao.insert(
        db,
        const Product(
          barcode: '2',
          name: 'P2',
          nutriscoreGrade: 'a',
        ),
      );
      await dao.insert(
        db,
        const Product(
          barcode: '3',
          name: 'P3',
          nutriscoreGrade: 'b',
        ),
      );
      await dao.insert(
        db,
        const Product(
          barcode: '4',
          name: 'P4',
          nutriscoreGrade: 'c',
          source: 'manual',
        ),
      );
    });

    test('nutriscoreDistribution counts correctly', () async {
      final db = await dbHelper.database;
      final dist = await dao.nutriscoreDistribution(db);
      expect(dist['a'], 2);
      expect(dist['b'], 1);
      expect(dist['c'], isNull); // Manual product should be excluded
    });

    test('categoryDistribution counts correctly', () async {
      final db = await dbHelper.database;
      await dao.insert(
        db,
        const Product(barcode: '5', name: 'P5', category: 'Fruit'),
      );
      await dao.insert(
        db,
        const Product(barcode: '6', name: 'P6', category: 'Fruit'),
      );
      await dao.insert(
        db,
        const Product(barcode: '7', name: 'P7', category: 'Dairy'),
      );

      final dist = await dao.categoryDistribution(db);
      expect(dist.firstWhere((e) => e['category'] == 'Fruit')['cnt'], 2);
      expect(dist.firstWhere((e) => e['category'] == 'Dairy')['cnt'], 1);
    });

    test('sourceDistribution counts correctly', () async {
      final db = await dbHelper.database;
      final dist = await dao.sourceDistribution(db);
      expect(dist['api'], 3);
      expect(dist['manual'], 1);
    });
  });

  group('ProductDao photo completeness', () {
    setUp(() async {
      final db = await dbHelper.database;
      await dao.insert(
        db,
        const Product(
          barcode: '1',
          name: 'P1',
          nutritionImagePath: 'n1',
          productImagePath: 'p1',
          offNutritionImageUrl: 'off_n1',
          offProductImageUrl: 'off_p1',
        ),
      );
      await dao.insert(
        db,
        const Product(
          barcode: '2',
          name: 'P2',
          ingredientsImagePath: 'i2',
          offIngredientsImageUrl: 'off_i2',
        ),
      );
    });

    test('photoCompleteness counts correctly', () async {
      final db = await dbHelper.database;
      final res = await dao.photoCompleteness(db);
      expect(res['total'], 2);
      expect(res['nutrition'], 1);
      expect(res['ingredients'], 1);
      expect(res['product'], 1);
    });

    test('offPhotoCompleteness counts correctly', () async {
      final db = await dbHelper.database;
      final res = await dao.offPhotoCompleteness(db);
      expect(res['total'], 2);
      expect(res['nutrition'], 1);
      expect(res['ingredients'], 1);
      expect(res['product'], 1);
    });
  });

  group('ProductDao additional nutrients', () {
    const product = Product(
      barcode: '1234567890123',
      name: 'Test Product',
      additionalNutrients: [
        ProductNutrient(offTag: 'vitamin-c', value: 20, unit: 'mg'),
        ProductNutrient(offTag: 'sodium', value: 0.5, unit: 'g'),
      ],
    );

    test('insert and get round-trips additional nutrients', () async {
      final db = await dbHelper.database;
      await dao.insert(db, product);
      final fetched = await dao.get(db, product.barcode);
      expect(fetched, isNotNull);
      expect(fetched!.additionalNutrients, product.additionalNutrients);
    });

    test('decodeAdditionalNutrients returns empty for null or blank', () {
      expect(ProductDao.decodeAdditionalNutrients(null), isEmpty);
      expect(ProductDao.decodeAdditionalNutrients(''), isEmpty);
    });

    test('decodeAdditionalNutrients returns empty for corrupt JSON', () {
      expect(ProductDao.decodeAdditionalNutrients('not json'), isEmpty);
      expect(ProductDao.decodeAdditionalNutrients('{"a":1}'), isEmpty);
      expect(
        ProductDao.decodeAdditionalNutrients('[{"offTag":5}]'),
        isEmpty,
      );
    });
  });

  group('ProductDao pluCode and productType', () {
    const produceProduct = Product(
      barcode: 'produce-banana-4011',
      name: 'Banana',
      productType: ProductType.produce,
      pluCode: '4011',
    );

    test('insert and get produce product with pluCode', () async {
      final db = await dbHelper.database;
      await dao.insert(db, produceProduct);
      final fetched = await dao.get(db, produceProduct.barcode);
      expect(fetched, isNotNull);
      expect(fetched!.pluCode, '4011');
      expect(fetched.productType, ProductType.produce);
    });

    test('default productType is barcoded', () async {
      final db = await dbHelper.database;
      await dao.insert(
        db,
        const Product(barcode: 'basic', name: 'Basic'),
      );
      final fetched = await dao.get(db, 'basic');
      expect(fetched, isNotNull);
      expect(fetched!.productType, ProductType.barcoded);
      expect(fetched.pluCode, isNull);
    });
  });
}
