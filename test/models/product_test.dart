// the test doc comments tend to get too long
// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/models/product.dart';

/// Tests for the [Product] model.
///
/// Covers JSON deserialization from the Open Food Facts v3 API format,
/// handling of missing optional fields, and immutability via `copyWith`.
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
  });
}
