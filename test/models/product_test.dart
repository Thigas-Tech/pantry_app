import 'package:flutter_test/flutter_test.dart';
import 'package:openfoodfacts/openfoodfacts.dart' as off;
import 'package:pantry_app/models/product.dart';

/// Tests for the [Product] model.
///
/// Covers JSON deserialization from the Open Food Facts v3 API format,
/// handling of missing optional fields, immutability via copyWith, and
/// safe API merge semantics via Product.mergeFromApi.
void main() {
  group('Product', () {
    test('copyWith preserves new fields', () {
      const product = Product(barcode: '123', name: 'Banana');
      final updated = product.copyWith(barcode: '456');
      expect(updated.barcode, '456');
      expect(updated.name, 'Banana');
    });

    test('fromOffProduct creates a valid product', () {
      final offProduct = off.Product(
        barcode: '123',
        productName: 'Test Product',
      );
      final product = Product.fromOffProduct(offProduct);
      expect(product.barcode, '123');
      expect(product.name, 'Test Product');
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

      test('API languageCode overwrites cached value', () {
        const cached = Product(
          barcode: '1',
          name: 'Milk',
        );
        const api = Product(
          barcode: '1',
          name: 'Leite',
          languageCode: 'pt',
        );
        final merged = cached.mergeFromApi(api);
        expect(merged.languageCode, 'pt');
      });

      group('mergeLanguageOnly', () {
        test('updates languageCode and preserves user-entered fields', () {
          const cached = Product(
            barcode: '1',
            name: 'My Note',
            brand: 'My Brand',
            ingredients: 'user ingredients',
            source: 'manual',
          );
          const api = Product(
            barcode: '1',
            name: 'API Name',
            brand: 'API Brand',
            ingredients: 'api ingredients',
            languageCode: 'fr',
          );
          final merged = cached.mergeLanguageOnly(api);
          expect(merged.languageCode, 'fr');
          expect(merged.name, 'My Note');
          expect(merged.brand, 'My Brand');
          expect(merged.ingredients, 'user ingredients');
          expect(merged.source, 'manual');
        });
      });

      group('toOffProduct', () {
        test('maps nutrition values per 100g', () {
          const product = Product(
            barcode: '123',
            name: 'Test',
            energyKcal: 200,
            proteinG: 10,
            carbsG: 30,
            fatG: 5,
            fiberG: 3,
            saltG: 1.5,
          );
          final offProduct = product.toOffProduct();
          final n = offProduct.nutriments!;
          expect(
            n.getValue(off.Nutrient.energyKCal, off.PerSize.oneHundredGrams),
            200,
          );
          expect(
            n.getValue(off.Nutrient.proteins, off.PerSize.oneHundredGrams),
            10,
          );
          expect(
            n.getValue(off.Nutrient.carbohydrates, off.PerSize.oneHundredGrams),
            30,
          );
          expect(n.getValue(off.Nutrient.fat, off.PerSize.oneHundredGrams), 5);
          expect(
            n.getValue(off.Nutrient.fiber, off.PerSize.oneHundredGrams),
            3,
          );
          expect(
            n.getValue(off.Nutrient.salt, off.PerSize.oneHundredGrams),
            1.5,
          );
        });

        test('omits nutriments when all values are null', () {
          const product = Product(barcode: '123', name: 'Test');
          final offProduct = product.toOffProduct();
          expect(offProduct.nutriments, isNull);
        });

        test('maps quantity and lang', () {
          const product = Product(
            barcode: '123',
            name: 'Test',
            quantity: '500 g',
            languageCode: 'fr',
          );
          final offProduct = product.toOffProduct();
          expect(offProduct.quantity, '500 g');
          expect(offProduct.lang, off.OpenFoodFactsLanguage.FRENCH);
        });

        test('falls back to English for unknown language codes', () {
          const product = Product(
            barcode: '123',
            name: 'Test',
            languageCode: 'zz',
          );
          final offProduct = product.toOffProduct();
          expect(offProduct.lang, off.OpenFoodFactsLanguage.ENGLISH);
        });
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
