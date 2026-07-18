import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/models/produce_cache_entry.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/models/product_type.dart';

/// Tests for [ProduceCacheEntry] and [ProduceCacheEntryConversions].
void main() {
  group('ProduceCacheEntry', () {
    group('JSON serialization', () {
      test('fromJson deserializes valid map', () {
        final json = <String, dynamic>{
          'fdcId': 1750339,
          'name': 'apple',
          'localizedNames': {'pt': 'Maca'},
          'nutrition': {'energyKcal': 52.0, 'proteinG': 0.26},
          'pluCodes': ['4011'],
          'category': 'Fruits',
          'schemaVersion': 1,
          'createdAt': 1700000000000,
          'lastRefreshedAt': 1700000000000,
          'nextRefreshAt': 1708754400000,
        };
        final entry = ProduceCacheEntry.fromJson(json);
        expect(entry.fdcId, 1750339);
        expect(entry.name, 'apple');
        expect(entry.localizedNames, {'pt': 'Maca'});
        expect(entry.nutrition, {'energyKcal': 52.0, 'proteinG': 0.26});
        expect(entry.pluCodes, ['4011']);
        expect(entry.category, 'Fruits');
        expect(entry.schemaVersion, 1);
        expect(entry.createdAt, 1700000000000);
        expect(entry.lastRefreshedAt, 1700000000000);
        expect(entry.nextRefreshAt, 1708754400000);
        expect(entry.servingSizeG, isNull);
      });

      test('toJson serializes to expected map', () {
        const entry = ProduceCacheEntry(
          fdcId: 1750339,
          name: 'apple',
          nutrition: {'energyKcal': 52.0, 'proteinG': 0.26},
          createdAt: 1700000000000,
          lastRefreshedAt: 1700000000000,
          nextRefreshAt: 1708754400000,
          localizedNames: {'pt': 'Maca'},
          pluCodes: ['4011'],
          category: 'Fruits',
        );
        final json = entry.toJson();
        expect(json['fdcId'], 1750339);
        expect(json['name'], 'apple');
        expect(json['localizedNames'], {'pt': 'Maca'});
        expect(json['nutrition'], {'energyKcal': 52.0, 'proteinG': 0.26});
        expect(json['pluCodes'], ['4011']);
        expect(json['category'], 'Fruits');
        expect(json['createdAt'], 1700000000000);
        expect(json['lastRefreshedAt'], 1700000000000);
        expect(json['nextRefreshAt'], 1708754400000);
      });

      test('toJson omits null fields', () {
        const entry = ProduceCacheEntry(
          fdcId: 0,
          name: 'apple',
          nutrition: <String, double>{},
          createdAt: 1700000000000,
          lastRefreshedAt: 1700000000000,
          nextRefreshAt: 1708754400000,
        );
        final json = entry.toJson();
        expect(json.containsKey('servingSizeG'), false);
        expect(json.containsKey('category'), false);
      });

      test('fromJson handles missing optional fields with defaults', () {
        final json = <String, dynamic>{
          'fdcId': 1750339,
          'name': 'apple',
          'nutrition': <String, double>{},
          'createdAt': 1700000000000,
          'lastRefreshedAt': 1700000000000,
          'nextRefreshAt': 1708754400000,
        };
        final entry = ProduceCacheEntry.fromJson(json);
        expect(entry.schemaVersion, 1);
        expect(entry.localizedNames, <String, String>{});
        expect(entry.pluCodes, <String>[]);
        expect(entry.servingSizeG, isNull);
        expect(entry.category, isNull);
      });

      test('round-trip produces equal object', () {
        const original = ProduceCacheEntry(
          fdcId: 1750339,
          name: 'apple',
          nutrition: {'energyKcal': 52.0},
          createdAt: 1700000000000,
          lastRefreshedAt: 1700000000000,
          nextRefreshAt: 1708754400000,
        );
        final json = original.toJson();
        final restored = ProduceCacheEntry.fromJson(json);
        expect(restored, original);
      });
    });

    group('fromProduct', () {
      test('creates entry with 180-day nextRefreshAt window', () {
        const product = Product(
          barcode: 'produce-Apple',
          name: 'Apple',
          productType: ProductType.produce,
        );
        final before = DateTime.now().millisecondsSinceEpoch;
        final entry = ProduceCacheEntryConversions.fromProduct(
          product,
          1750339,
          englishName: 'apple',
        );
        final after = DateTime.now().millisecondsSinceEpoch;
        expect(
          entry.nextRefreshAt - entry.lastRefreshedAt,
          closeTo(180 * 24 * 60 * 60 * 1000, 100),
        );
        expect(entry.lastRefreshedAt, greaterThanOrEqualTo(before));
        expect(entry.lastRefreshedAt, lessThanOrEqualTo(after));
      });

      test(
        'creates entry with createdAt == lastRefreshedAt when not provided',
        () {
          const product = Product(
            barcode: 'produce-Apple',
            name: 'Apple',
            productType: ProductType.produce,
          );
          final entry = ProduceCacheEntryConversions.fromProduct(
            product,
            1750339,
            englishName: 'apple',
          );
          expect(
            (entry.createdAt - entry.lastRefreshedAt).abs(),
            lessThan(100),
          );
        },
      );

      test('preserves provided createdAt', () {
        const product = Product(
          barcode: 'produce-Apple',
          name: 'Apple',
          productType: ProductType.produce,
        );
        final entry = ProduceCacheEntryConversions.fromProduct(
          product,
          1750339,
          englishName: 'apple',
          createdAt: 1000000000000,
        );
        expect(entry.createdAt, 1000000000000);
      });

      test('only maps non-null nutrition fields', () {
        const product = Product(
          barcode: 'produce-Apple',
          name: 'Apple',
          productType: ProductType.produce,
          energyKcal: 52,
        );
        final entry = ProduceCacheEntryConversions.fromProduct(
          product,
          1750339,
          englishName: 'apple',
        );
        expect(entry.nutrition, {'energyKcal': 52});
      });

      test('handles all-null nutrition gracefully', () {
        const product = Product(
          barcode: 'produce-Apple',
          name: 'Apple',
          productType: ProductType.produce,
        );
        final entry = ProduceCacheEntryConversions.fromProduct(
          product,
          1750339,
          englishName: 'apple',
        );
        expect(entry.nutrition, <String, double>{});
      });

      test('copies category from product', () {
        const product = Product(
          barcode: 'produce-Apple',
          name: 'Apple',
          productType: ProductType.produce,
          category: 'Fruits',
        );
        final entry = ProduceCacheEntryConversions.fromProduct(
          product,
          1750339,
          englishName: 'apple',
        );
        expect(entry.category, 'Fruits');
      });

      test('sets fdcId, englishName, and default pluCodes', () {
        const product = Product(
          barcode: 'produce-Apple',
          name: 'Apple',
          productType: ProductType.produce,
        );
        final entry = ProduceCacheEntryConversions.fromProduct(
          product,
          1750339,
          englishName: 'apple',
        );
        expect(entry.fdcId, 1750339);
        expect(entry.name, 'apple');
        expect(entry.pluCodes, <String>[]);
        expect(entry.localizedNames, <String, String>{});
        expect(entry.servingSizeG, isNull);
      });
    });

    group('toProduct', () {
      test('creates valid Product with correct barcode and type', () {
        const entry = ProduceCacheEntry(
          fdcId: 1750339,
          name: 'apple',
          nutrition: {'energyKcal': 52},
          createdAt: 1700000000000,
          lastRefreshedAt: 1700000000000,
          nextRefreshAt: 1708754400000,
        );
        final product = entry.toProduct(barcode: 'produce-Apple');
        expect(product.barcode, 'produce-Apple');
        expect(product.name, 'apple');
        expect(product.productType, ProductType.produce);
        expect(product.source, 'manual');
        expect(product.energyKcal, 52);
      });

      test('returns null nutrition fields when map is empty', () {
        const entry = ProduceCacheEntry(
          fdcId: 1750339,
          name: 'apple',
          nutrition: <String, double>{},
          createdAt: 1700000000000,
          lastRefreshedAt: 1700000000000,
          nextRefreshAt: 1708754400000,
        );
        final product = entry.toProduct(barcode: 'produce-Apple');
        expect(product.energyKcal, isNull);
        expect(product.proteinG, isNull);
        expect(product.carbsG, isNull);
        expect(product.fatG, isNull);
        expect(product.fiberG, isNull);
      });

      test('sets lastSynced to current timestamp', () {
        const entry = ProduceCacheEntry(
          fdcId: 1750339,
          name: 'apple',
          nutrition: <String, double>{},
          createdAt: 1700000000000,
          lastRefreshedAt: 1700000000000,
          nextRefreshAt: 1708754400000,
        );
        final before = DateTime.now().millisecondsSinceEpoch;
        final product = entry.toProduct(barcode: 'produce-Apple');
        final after = DateTime.now().millisecondsSinceEpoch;
        expect(product.lastSynced, greaterThanOrEqualTo(before));
        expect(product.lastSynced, lessThanOrEqualTo(after));
      });
    });

    group('withRefreshedData', () {
      test('preserves createdAt from original entry', () {
        const original = ProduceCacheEntry(
          fdcId: 1750339,
          name: 'apple',
          nutrition: {'energyKcal': 52},
          createdAt: 1000000000000,
          lastRefreshedAt: 1000000000000,
          nextRefreshAt: 1000000000000 + 180 * 24 * 60 * 60 * 1000,
        );
        const freshEntry = ProduceCacheEntry(
          fdcId: 1750339,
          name: 'apple',
          nutrition: {'energyKcal': 55},
          createdAt: 2000000000000,
          lastRefreshedAt: 2000000000000,
          nextRefreshAt: 2000000000000 + 180 * 24 * 60 * 60 * 1000,
        );
        final result = original.withRefreshedData(freshEntry);
        expect(result.createdAt, 1000000000000);
        expect(result.lastRefreshedAt, 2000000000000);
        expect(result.nutrition['energyKcal'], 55);
      });
    });
  });
}
