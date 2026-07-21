import 'package:flutter_test/flutter_test.dart';
import 'package:openfoodfacts/openfoodfacts.dart' as off;
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/models/product_type.dart';

/// Tests for the [Product] model.
///
/// Covers JSON deserialization from the Open Food Facts v3 API format,
/// handling of missing optional fields, immutability via copyWith, and
/// safe API merge semantics via Product.mergeFromApi.
void main() {
  group('ProductType', () {
    test('enum values exist for barcoded, produce, custom', () {
      expect(ProductType.values, hasLength(3));
      expect(ProductType.values, contains(ProductType.barcoded));
      expect(ProductType.values, contains(ProductType.produce));
      expect(ProductType.values, contains(ProductType.custom));
    });
  });

  group('Product', () {
    test('productType defaults to barcoded for new products', () {
      const product = Product(barcode: '123', name: 'Test');
      expect(product.productType, ProductType.barcoded);
    });

    test('productType can be set to produce', () {
      const product = Product(
        barcode: '123',
        name: 'Test',
        productType: ProductType.produce,
      );
      expect(product.productType, ProductType.produce);
    });

    test('pluCode is nullable and defaults to null', () {
      const product = Product(barcode: '123', name: 'Test');
      expect(product.pluCode, isNull);
    });

    test('pluCode can be set for produce products', () {
      const product = Product(
        barcode: '123',
        name: 'Banana',
        productType: ProductType.produce,
        pluCode: '4011',
      );
      expect(product.pluCode, '4011');
    });

    test('copyWith preserves new fields', () {
      const product = Product(
        barcode: '123',
        name: 'Banana',
        productType: ProductType.produce,
        pluCode: '4011',
      );
      final updated = product.copyWith(pluCode: '94011');
      expect(updated.pluCode, '94011');
      expect(updated.productType, ProductType.produce);
      expect(updated.name, 'Banana');
    });

    test(
      'fromOffProduct creates barcoded product type with null pluCode',
      () {
        final offProduct = off.Product(
          barcode: '123',
          productName: 'Test Product',
        );
        final product = Product.fromOffProduct(offProduct);
        expect(product.productType, ProductType.barcoded);
        expect(product.pluCode, isNull);
      },
    );

    test(
      'fromOffProduct creates a valid Product from a complete off.Product',
      () {
        final offProduct = off.Product(
          barcode: '123',
          productName: 'Test Product',
          brands: 'Test Brand',
          imageFrontUrl: 'http://example.com/image.jpg',
          categories: 'Test Category',
          ingredientsText: 'sugar, water',
          servingSize: '100 g',
          nutriments: off.Nutriments.empty()
            ..setValue(
              off.Nutrient.energyKCal,
              off.PerSize.oneHundredGrams,
              100,
            )
            ..setValue(off.Nutrient.proteins, off.PerSize.oneHundredGrams, 5.5)
            ..setValue(
              off.Nutrient.carbohydrates,
              off.PerSize.oneHundredGrams,
              20,
            )
            ..setValue(off.Nutrient.fat, off.PerSize.oneHundredGrams, 2)
            ..setValue(off.Nutrient.fiber, off.PerSize.oneHundredGrams, 1)
            ..setValue(off.Nutrient.salt, off.PerSize.oneHundredGrams, 0.5),
          nutriscore: 'a',
        );
        final product = Product.fromOffProduct(offProduct);
        expect(product.barcode, '123');
        expect(product.name, 'Test Product');
        expect(product.brand, 'Test Brand');
        expect(product.imageUrl, 'http://example.com/image.jpg');
        expect(product.category, 'Test Category');
        expect(product.ingredients, 'sugar, water');
        expect(product.servingSize, '100 g');
        expect(product.energyKcal, 100);
        expect(product.proteinG, 5.5);
        expect(product.carbsG, 20.0);
        expect(product.fatG, 2.0);
        expect(product.fiberG, 1.0);
        expect(product.saltG, 0.5);
        expect(product.nutriscoreGrade, 'a');
        expect(product.lastSynced, isNotNull);
      },
    );

    test('fromOffProduct handles missing optional fields', () {
      /// Only the required fields are present; all optional fields become
      /// null.
      final offProduct = off.Product(
        barcode: '456',
        productName: 'Minimal',
      );
      final product = Product.fromOffProduct(offProduct);
      expect(product.barcode, '456');
      expect(product.name, 'Minimal');
      expect(product.brand, isNull);
      expect(product.imageUrl, isNull);
      expect(product.category, isNull);
      expect(product.ingredients, isNull);
      expect(product.servingSize, isNull);
      expect(product.energyKcal, isNull);
      expect(product.proteinG, isNull);
      expect(product.carbsG, isNull);
      expect(product.fatG, isNull);
      expect(product.fiberG, isNull);
      expect(product.saltG, isNull);
      expect(product.lastSynced, isNotNull);
    });

    test('copyWith creates a modified copy', () {
      /// The original product remains unchanged; only the specified fields
      /// are updated.
      const product = Product(barcode: '789', name: 'Original');
      final updated = product.copyWith(name: 'Updated', brand: 'Brand');
      expect(updated.name, 'Updated');
      expect(updated.brand, 'Brand');
      expect(updated.barcode, '789'); // unchanged
    });

    group('mergeFromApi', () {
      test('API non-null overwrites cached value', () {
        const cached = Product(barcode: '1', name: 'Old Name', brand: 'Old');
        const api = Product(barcode: '1', name: 'New Name', brand: 'New');
        final merged = cached.mergeFromApi(api);
        expect(merged.name, 'New Name');
        expect(merged.brand, 'New');
      });

      test('API null preserves cached value', () {
        const cached = Product(
          barcode: '1',
          name: 'Old Name',
          brand: 'Old Brand',
          category: 'Old Cat',
          nutriscoreGrade: 'a',
          energyKcal: 100,
          lastSynced: 1000,
        );
        // API returns only barcode + name; everything else is null/default.
        const api = Product(barcode: '1', name: 'New Name');
        final merged = cached.mergeFromApi(api);
        // Name updated, everything else preserved.
        expect(merged.name, 'New Name');
        expect(merged.brand, 'Old Brand');
        expect(merged.category, 'Old Cat');
        expect(merged.nutriscoreGrade, 'a');
        expect(merged.energyKcal, 100);
        expect(merged.lastSynced, 1000);
      });

      test('API empty string does not overwrite cached string value', () {
        const cached = Product(
          barcode: '1',
          name: 'Real Name',
          brand: 'Real Brand',
          nutriscoreGrade: 'a',
        );
        // API returns empty strings for optional fields.
        const api = Product(
          barcode: '1',
          name: 'Real Name',
          brand: '',
          nutriscoreGrade: '',
        );
        final merged = cached.mergeFromApi(api);
        expect(merged.brand, 'Real Brand');
        expect(merged.nutriscoreGrade, 'a');
      });

      test('API name sentinel Unknown does not overwrite cached name', () {
        const cached = Product(barcode: '1', name: 'Real Name');
        const api = Product(barcode: '1', name: 'Unknown');
        final merged = cached.mergeFromApi(api);
        expect(merged.name, 'Real Name');
      });

      test('local-only fields are never overwritten by API', () {
        const cached = Product(
          barcode: '1',
          name: 'P',
          source: 'manual',
          submissionStatus: productSubmissionSubmitted,
          nutritionImagePath: '/a.jpg',
        );
        final api = Product.fromOffProduct(
          off.Product(barcode: '1', productName: 'P'),
        );
        // API product has default source='api' and
        // submissionStatus='not_submitted'.
        final merged = cached.mergeFromApi(api);
        expect(merged.source, 'manual');
        expect(merged.submissionStatus, productSubmissionSubmitted);
        expect(merged.nutritionImagePath, '/a.jpg');
      });

      test('full API response updates all nutrition fields', () {
        const cached = Product(barcode: '1', name: 'Old');
        const api = Product(
          barcode: '1',
          name: 'New',
          energyKcal: 200,
          proteinG: 10,
          carbsG: 30,
          fatG: 5,
          fiberG: 3,
          saltG: 1.5,
          nutriscoreGrade: 'b',
          servingSize: '50 g',
        );
        final merged = cached.mergeFromApi(api);
        expect(merged.energyKcal, 200);
        expect(merged.proteinG, 10);
        expect(merged.carbsG, 30);
        expect(merged.fatG, 5);
        expect(merged.fiberG, 3);
        expect(merged.saltG, 1.5);
        expect(merged.nutriscoreGrade, 'b');
        expect(merged.servingSize, '50 g');
      });
    });
  });
}
