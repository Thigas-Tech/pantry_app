import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/models/price.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/models/recipe_ingredient.dart';
import 'package:pantry_app/services/currency_service.dart';
import 'package:pantry_app/services/recipe_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _MockCurrencyService extends Mock implements CurrencyService {}

/// Integration tests for the price-math parts of [RecipeService].
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    registerFallbackValue(0.0);
    registerFallbackValue('');
  });

  late DatabaseHelper db;
  late _MockCurrencyService currency;
  late RecipeService service;

  setUp(() async {
    db = DatabaseHelper.withPath(inMemoryDatabasePath);
    await db.database;
    currency = _MockCurrencyService();
    when(() => currency.convert(any(), any(), any())).thenAnswer(
      (invocation) async => invocation.positionalArguments[0] as double,
    );
    service = RecipeService(db, currency);
  });

  tearDown(() async {
    final database = await db.database;
    await database.close();
  });

  Future<void> seedProduct({
    required String barcode,
    String? quantity,
    double? productQuantity,
  }) async {
    await db.insertProduct(
      Product(
        barcode: barcode,
        name: 'Product $barcode',
        quantity: quantity,
        productQuantity: productQuantity,
      ),
    );
  }

  Future<void> seedPrice(
    String barcode, {
    required double price,
    int? datePurchased,
    double? packageQuantity,
    String? packageUnit,
  }) async {
    await db.insertPrice(
      Price(
        barcode: barcode,
        price: price,
        datePurchased: datePurchased,
        packageQuantity: packageQuantity,
        packageUnit: packageUnit,
      ),
    );
  }

  group('calculateIngredientCost multi-pack scaling', () {
    test(
      'charges 300 g of a 3 x 150 g pack by the total package size',
      () async {
        await seedProduct(barcode: 'yog', quantity: '3 x 150 g');
        await seedPrice('yog', price: 4.5, datePurchased: 1000);
        final database = await db.database;

        final cost = await service.calculateIngredientCost(
          database,
          [
            const RecipeIngredient(
              recipeId: 1,
              name: 'Yogurt',
              barcode: 'yog',
              quantity: 300,
              unit: 'g',
            ),
          ],
          inventoryId: 1,
          baseCurrency: 'USD',
          currencyService: currency,
        );

        // 300 / (3 x 150) of 4.50 = 3.00.
        expect(cost, 3.00);
      },
    );

    test('charges 130 g of a bonus pack by the summed package size', () async {
      await seedProduct(barcode: 'crack', quantity: '2 x 300 g + 1 x 50 g');
      await seedPrice('crack', price: 6.5, datePurchased: 1000);
      final database = await db.database;

      final cost = await service.calculateIngredientCost(
        database,
        [
          const RecipeIngredient(
            recipeId: 1,
            name: 'Crackers',
            barcode: 'crack',
            quantity: 130,
            unit: 'g',
          ),
        ],
        inventoryId: 1,
        baseCurrency: 'USD',
        currencyService: currency,
      );

      // 130 / 650 of 6.50 = 1.30.
      expect(cost, 1.30);
    });

    test('uses the most recently recorded same-day price', () async {
      await seedProduct(barcode: 'yog', quantity: '3 x 150 g');
      final sameDay = DateTime(2026, 6, 15).millisecondsSinceEpoch;
      await seedPrice('yog', price: 4.5, datePurchased: sameDay);
      await seedPrice('yog', price: 6, datePurchased: sameDay);
      final database = await db.database;

      final cost = await service.calculateIngredientCost(
        database,
        [
          const RecipeIngredient(
            recipeId: 1,
            name: 'Yogurt',
            barcode: 'yog',
            quantity: 300,
            unit: 'g',
          ),
        ],
        inventoryId: 1,
        baseCurrency: 'USD',
        currencyService: currency,
      );

      // Latest (id desc) is 6.00: 300 / 450 of 6.00 = 4.00.
      expect(cost, 4.00);
    });

    test(
      'charges the full price when no package size can be resolved',
      () async {
        await seedProduct(barcode: 'mystery');
        await seedPrice('mystery', price: 5, datePurchased: 1000);
        final database = await db.database;

        final cost = await service.calculateIngredientCost(
          database,
          [
            const RecipeIngredient(
              recipeId: 1,
              name: 'Mystery',
              barcode: 'mystery',
              quantity: 2,
            ),
          ],
          inventoryId: 1,
          baseCurrency: 'USD',
          currencyService: currency,
        );

        expect(cost, 5.00);
      },
    );

    test(
      'prefers the price row package size over the product packaging',
      () async {
        await seedProduct(barcode: 'yog', quantity: '3 x 150 g');
        await seedPrice(
          'yog',
          price: 4.50,
          datePurchased: 1000,
          packageQuantity: 900,
          packageUnit: 'g',
        );
        final database = await db.database;

        final cost = await service.calculateIngredientCost(
          database,
          [
            const RecipeIngredient(
              recipeId: 1,
              name: 'Yogurt',
              barcode: 'yog',
              quantity: 300,
              unit: 'g',
            ),
          ],
          inventoryId: 1,
          baseCurrency: 'USD',
          currencyService: currency,
        );

        // 300 / 900 of 4.50 = 1.50.
        expect(cost, 1.50);
      },
    );
  });

  group('ingredientCosts', () {
    test('returns the scaled cost per ingredient keyed by barcode', () async {
      await seedProduct(barcode: 'yog', quantity: '3 x 150 g');
      await seedProduct(barcode: 'egg', quantity: '12 pieces');
      await seedPrice('yog', price: 4.5, datePurchased: 1000);
      await seedPrice('egg', price: 3.5, datePurchased: 2000);

      final costs = await service.ingredientCosts(
        [
          const RecipeIngredient(
            recipeId: 1,
            name: 'Yogurt',
            barcode: 'yog',
            quantity: 300,
            unit: 'g',
          ),
          const RecipeIngredient(
            recipeId: 1,
            name: 'Eggs',
            barcode: 'egg',
            quantity: 2,
          ),
        ],
        inventoryId: 1,
        baseCurrency: 'USD',
      );

      expect(costs['yog'], 3.00);
      // 2 / 12 of 3.50 = 0.58.
      expect(costs['egg'], 0.58);
    });

    test('groups duplicate barcodes by summed quantity', () async {
      await seedProduct(barcode: 'yog', quantity: '3 x 150 g');
      await seedPrice('yog', price: 4.5, datePurchased: 1000);

      final costs = await service.ingredientCosts(
        [
          const RecipeIngredient(
            recipeId: 1,
            name: 'Yogurt',
            barcode: 'yog',
            quantity: 200,
            unit: 'g',
          ),
          const RecipeIngredient(
            recipeId: 1,
            name: 'Yogurt',
            barcode: 'yog',
            quantity: 100,
            unit: 'g',
          ),
        ],
        inventoryId: 1,
        baseCurrency: 'USD',
      );

      // 300 / 450 of 4.50 = 3.00 for the merged group.
      expect(costs, hasLength(1));
      expect(costs['yog'], 3.00);
    });

    test('skips ingredients without a barcode', () async {
      final costs = await service.ingredientCosts(
        [
          const RecipeIngredient(recipeId: 1, name: 'Salt'),
        ],
        inventoryId: 1,
        baseCurrency: 'USD',
      );

      expect(costs, isEmpty);
    });

    test('omits ingredients with no recorded price', () async {
      await seedProduct(barcode: 'yog', quantity: '3 x 150 g');

      final costs = await service.ingredientCosts(
        [
          const RecipeIngredient(
            recipeId: 1,
            name: 'Yogurt',
            barcode: 'yog',
            quantity: 300,
            unit: 'g',
          ),
        ],
        inventoryId: 1,
        baseCurrency: 'USD',
      );

      expect(costs, isEmpty);
    });
  });
}
