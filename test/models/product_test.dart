// the test doc comments tend to get too long
// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/models/product.dart';

/// Tests for the [Product] model.
///
/// Covers JSON deserialization from the Open Food Facts v3 API format,
/// handling of missing optional fields, immutability via `copyWith`, and
/// safe API merge semantics via `Product.mergeFromApi`.
void main() {
  group('Product', () {
    /// A complete JSON response as returned by the OFF v3 API.
    final completeJson = {
      '_id': '123',
      'product_name': 'Test Product',
      'brands': 'Test Brand',
      'image_url': 'http://example.com/image.jpg',
      'category': 'Test Category',
      'ingredients_text': 'sugar, water',
      'serving_size': '100 g',
      'energy_kcal': 100,
      'protein_g': 5.5,
      'carbs_g': 20.0,
      'fat_g': 2.0,
      'fiber_g': 1.0,
      'salt_g': 0.5,
      'last_synced': 123456789,
    };

    test('fromJson creates a valid Product from a complete JSON', () {
      /// Parses every field correctly from the API response.
      final product = Product.fromJson(completeJson);
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
      expect(product.lastSynced, 123456789);
    });

    test('fromJson handles missing optional fields', () {
      /// Only the required fields are present; all optional fields become `null`.
      final minimalJson = {'_id': '456', 'product_name': 'Minimal'};
      final product = Product.fromJson(minimalJson);
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
      expect(product.lastSynced, isNull);
    });

    test('copyWith creates a modified copy', () {
      /// The original product remains unchanged; only the specified fields are updated.
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
        final api = Product.fromJson({
          '_id': '1',
          'product_name': 'P',
        });
        // API product has default source='api' and submissionStatus='not_submitted'.
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
