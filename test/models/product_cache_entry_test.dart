import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/models/product_cache_entry.dart';

/// Tests for [ProductCacheEntry] and [ProductCacheEntryConversions].
void main() {
  group('ProductCacheEntry', () {
    group('JSON serialization', () {
      test('fromJson deserializes valid map', () {
        final json = <String, dynamic>{
          'barcode': '7622210449283',
          'name': 'Nutella',
          'brand': 'Ferrero',
          'category': 'Spreads',
          'categoriesHierarchy': ['en:spreads', 'en:sweet-spreads'],
          'ingredients': 'Sugar, palm oil, hazelnuts',
          'servingSize': '15 g',
          'energyKcal': 539,
          'proteinG': 6.3,
          'carbsG': 57.5,
          'fatG': 31.5,
          'fiberG': 1.3,
          'saltG': 0.1,
          'nutriscoreGrade': 'e',
          'imageUrl': 'https://images.openfoodfacts.org/1.jpg',
          'offNutritionImageUrl': 'https://images.openfoodfacts.org/nutri.jpg',
          'offIngredientsImageUrl': 'https://images.openfoodfacts.org/ing.jpg',
          'offProductImageUrl': 'https://images.openfoodfacts.org/prod.jpg',
          'languageCode': 'en',
          'schemaVersion': 1,
          'createdAt': 1700000000000,
          'lastRefreshedAt': 1700000000000,
          'nextRefreshAt': 1708754400000,
        };
        final entry = ProductCacheEntry.fromJson(json);
        expect(entry.barcode, '7622210449283');
        expect(entry.name, 'Nutella');
        expect(entry.brand, 'Ferrero');
        expect(entry.category, 'Spreads');
        expect(
          entry.categoriesHierarchy,
          ['en:spreads', 'en:sweet-spreads'],
        );
        expect(entry.ingredients, 'Sugar, palm oil, hazelnuts');
        expect(entry.servingSize, '15 g');
        expect(entry.energyKcal, 539);
        expect(entry.proteinG, 6.3);
        expect(entry.carbsG, 57.5);
        expect(entry.fatG, 31.5);
        expect(entry.fiberG, 1.3);
        expect(entry.saltG, 0.1);
        expect(entry.nutriscoreGrade, 'e');
        expect(entry.imageUrl, 'https://images.openfoodfacts.org/1.jpg');
        expect(
          entry.offNutritionImageUrl,
          'https://images.openfoodfacts.org/nutri.jpg',
        );
        expect(
          entry.offIngredientsImageUrl,
          'https://images.openfoodfacts.org/ing.jpg',
        );
        expect(
          entry.offProductImageUrl,
          'https://images.openfoodfacts.org/prod.jpg',
        );
        expect(entry.schemaVersion, 1);
        expect(entry.languageCode, 'en');
      });

      test('toJson serializes to expected map', () {
        const entry = ProductCacheEntry(
          barcode: '7622210449283',
          name: 'Nutella',
          createdAt: 1700000000000,
          lastRefreshedAt: 1700000000000,
          nextRefreshAt: 1708754400000,
          brand: 'Ferrero',
          category: 'Spreads',
          ingredients: 'Sugar',
          energyKcal: 539,
        );
        final json = entry.toJson();
        expect(json['barcode'], '7622210449283');
        expect(json['name'], 'Nutella');
        expect(json['brand'], 'Ferrero');
        expect(json['category'], 'Spreads');
        expect(json['ingredients'], 'Sugar');
        expect(json['energyKcal'], 539);
        expect(json['createdAt'], 1700000000000);
        expect(json['lastRefreshedAt'], 1700000000000);
        expect(json['nextRefreshAt'], 1708754400000);
      });

      test('toJson omits null fields', () {
        const entry = ProductCacheEntry(
          barcode: '7622210449283',
          name: 'Minimal',
          createdAt: 1700000000000,
          lastRefreshedAt: 1700000000000,
          nextRefreshAt: 1708754400000,
        );
        final json = entry.toJson();
        expect(json.containsKey('brand'), false);
        expect(json.containsKey('category'), false);
        expect(json.containsKey('ingredients'), false);
        expect(json.containsKey('servingSize'), false);
        expect(json.containsKey('energyKcal'), false);
        expect(json.containsKey('proteinG'), false);
        expect(json.containsKey('carbsG'), false);
        expect(json.containsKey('fatG'), false);
        expect(json.containsKey('fiberG'), false);
        expect(json.containsKey('saltG'), false);
        expect(json.containsKey('nutriscoreGrade'), false);
        expect(json.containsKey('imageUrl'), false);
        expect(json.containsKey('offNutritionImageUrl'), false);
        expect(json.containsKey('offIngredientsImageUrl'), false);
        expect(json.containsKey('offProductImageUrl'), false);
        expect(json.containsKey('categoriesHierarchy'), false);
        expect(json['schemaVersion'], 1);
        expect(json['languageCode'], 'en');
      });

      test('fromJson handles missing optional fields with defaults', () {
        final json = <String, dynamic>{
          'barcode': '7622210449283',
          'name': 'Nutella',
          'createdAt': 1700000000000,
          'lastRefreshedAt': 1700000000000,
          'nextRefreshAt': 1708754400000,
        };
        final entry = ProductCacheEntry.fromJson(json);
        expect(entry.schemaVersion, 1);
        expect(entry.languageCode, 'en');
        expect(entry.brand, isNull);
        expect(entry.category, isNull);
        expect(entry.energyKcal, isNull);
        expect(entry.categoriesHierarchy, isNull);
      });

      test('round-trip produces equal object', () {
        const original = ProductCacheEntry(
          barcode: '7622210449283',
          name: 'Nutella',
          createdAt: 1700000000000,
          lastRefreshedAt: 1700000000000,
          nextRefreshAt: 1708754400000,
          brand: 'Ferrero',
          energyKcal: 539,
        );
        final json = original.toJson();
        final restored = ProductCacheEntry.fromJson(json);
        expect(restored, original);
      });
    });

    group('fromProduct', () {
      test('creates entry with 180-day nextRefreshAt window', () {
        const product = Product(
          barcode: '7622210449283',
          name: 'Nutella',
        );
        final before = DateTime.now().millisecondsSinceEpoch;
        final entry = ProductCacheEntryConversions.fromProduct(product);
        final after = DateTime.now().millisecondsSinceEpoch;
        expect(
          entry.nextRefreshAt - entry.lastRefreshedAt,
          closeTo(180 * 24 * 60 * 60 * 1000, 100),
        );
        expect(entry.lastRefreshedAt, greaterThanOrEqualTo(before));
        expect(entry.lastRefreshedAt, lessThanOrEqualTo(after));
      });

      test('copies nutrition fields from Product', () {
        const product = Product(
          barcode: '7622210449283',
          name: 'Nutella',
          energyKcal: 539,
          proteinG: 6.3,
          carbsG: 57.5,
          fatG: 31.5,
          fiberG: 1.3,
          saltG: 0.1,
        );
        final entry = ProductCacheEntryConversions.fromProduct(product);
        expect(entry.energyKcal, 539);
        expect(entry.proteinG, 6.3);
        expect(entry.carbsG, 57.5);
        expect(entry.fatG, 31.5);
        expect(entry.fiberG, 1.3);
        expect(entry.saltG, 0.1);
      });

      test('handles null nutrition gracefully', () {
        const product = Product(
          barcode: '7622210449283',
          name: 'Minimal',
        );
        final entry = ProductCacheEntryConversions.fromProduct(product);
        expect(entry.energyKcal, isNull);
        expect(entry.proteinG, isNull);
        expect(entry.carbsG, isNull);
        expect(entry.fatG, isNull);
        expect(entry.fiberG, isNull);
        expect(entry.saltG, isNull);
      });

      test('copies OFF-sourced fields from Product', () {
        const product = Product(
          barcode: '7622210449283',
          name: 'Nutella',
          brand: 'Ferrero',
          category: 'Spreads',
          categoriesHierarchy: ['en:spreads'],
          ingredients: 'Sugar, palm oil',
          servingSize: '15 g',
          nutriscoreGrade: 'e',
          imageUrl: 'https://images.openfoodfacts.org/1.jpg',
          offNutritionImageUrl: 'https://images.openfoodfacts.org/nutri.jpg',
          offIngredientsImageUrl: 'https://images.openfoodfacts.org/ing.jpg',
          offProductImageUrl: 'https://images.openfoodfacts.org/prod.jpg',
          languageCode: 'fr',
        );
        final entry = ProductCacheEntryConversions.fromProduct(product);
        expect(entry.barcode, '7622210449283');
        expect(entry.name, 'Nutella');
        expect(entry.brand, 'Ferrero');
        expect(entry.category, 'Spreads');
        expect(entry.categoriesHierarchy, ['en:spreads']);
        expect(entry.ingredients, 'Sugar, palm oil');
        expect(entry.servingSize, '15 g');
        expect(entry.nutriscoreGrade, 'e');
        expect(entry.imageUrl, 'https://images.openfoodfacts.org/1.jpg');
        expect(
          entry.offNutritionImageUrl,
          'https://images.openfoodfacts.org/nutri.jpg',
        );
        expect(
          entry.offIngredientsImageUrl,
          'https://images.openfoodfacts.org/ing.jpg',
        );
        expect(
          entry.offProductImageUrl,
          'https://images.openfoodfacts.org/prod.jpg',
        );
        expect(entry.languageCode, 'fr');
      });

      test('preserves provided createdAt', () {
        const product = Product(
          barcode: '7622210449283',
          name: 'Nutella',
        );
        final entry = ProductCacheEntryConversions.fromProduct(
          product,
          createdAt: 1000000000000,
        );
        expect(entry.createdAt, 1000000000000);
      });
    });

    group('toProduct', () {
      test('creates valid Product with correct fields', () {
        const entry = ProductCacheEntry(
          barcode: '7622210449283',
          name: 'Nutella',
          createdAt: 1700000000000,
          lastRefreshedAt: 1700000000000,
          nextRefreshAt: 1708754400000,
          brand: 'Ferrero',
          energyKcal: 539,
        );
        final product = entry.toProduct();
        expect(product.barcode, '7622210449283');
        expect(product.name, 'Nutella');
        expect(product.brand, 'Ferrero');
        expect(product.energyKcal, 539);
      });

      test('sets lastSynced to current timestamp', () {
        const entry = ProductCacheEntry(
          barcode: '7622210449283',
          name: 'Nutella',
          createdAt: 1700000000000,
          lastRefreshedAt: 1700000000000,
          nextRefreshAt: 1708754400000,
        );
        final before = DateTime.now().millisecondsSinceEpoch;
        final product = entry.toProduct();
        final after = DateTime.now().millisecondsSinceEpoch;
        expect(product.lastSynced, greaterThanOrEqualTo(before));
        expect(product.lastSynced, lessThanOrEqualTo(after));
      });

      test('handles null image URLs', () {
        const entry = ProductCacheEntry(
          barcode: '7622210449283',
          name: 'Nutella',
          createdAt: 1700000000000,
          lastRefreshedAt: 1700000000000,
          nextRefreshAt: 1708754400000,
        );
        final product = entry.toProduct();
        expect(product.imageUrl, isNull);
        expect(product.offNutritionImageUrl, isNull);
        expect(product.offIngredientsImageUrl, isNull);
        expect(product.offProductImageUrl, isNull);
      });

      test('handles null categoriesHierarchy', () {
        const entry = ProductCacheEntry(
          barcode: '7622210449283',
          name: 'Nutella',
          createdAt: 1700000000000,
          lastRefreshedAt: 1700000000000,
          nextRefreshAt: 1708754400000,
        );
        final product = entry.toProduct();
        expect(product.categoriesHierarchy, isNull);
      });
    });

    group('withRefreshedData', () {
      test('preserves createdAt from original entry', () {
        const original = ProductCacheEntry(
          barcode: '7622210449283',
          name: 'Nutella',
          createdAt: 1000000000000,
          lastRefreshedAt: 1000000000000,
          nextRefreshAt: 1000000000000 + 180 * 24 * 60 * 60 * 1000,
          brand: 'Ferrero',
        );
        const freshEntry = ProductCacheEntry(
          barcode: '7622210449283',
          name: 'Nutella',
          createdAt: 2000000000000,
          lastRefreshedAt: 2000000000000,
          nextRefreshAt: 2000000000000 + 180 * 24 * 60 * 60 * 1000,
          brand: 'Ferrero',
          energyKcal: 550,
        );
        final result = original.withRefreshedData(freshEntry);
        expect(result.createdAt, 1000000000000);
        expect(result.lastRefreshedAt, 2000000000000);
        expect(result.energyKcal, 550);
      });
    });
  });
}
