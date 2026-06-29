/// Unit tests for the [Product] model.
///
/// Verifies JSON parsing from the Open Food Facts v3 format and
/// immutability via `copyWith`.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/models/product.dart';

void main() {
  group('Product', () {
    final json = {
      '_id': '123',
      'product_name': 'Test Product',
      'brands': 'Test Brand',
      'image_url': 'http://example.com/image.jpg',
      'categories': 'Test Category',
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

    test('fromJson creates a valid Product', () {
      /// All fields from a complete API response are mapped correctly.
      final product = Product.fromJson(json);
      expect(product.barcode, '123');
      expect(product.name, 'Test Product');
      expect(product.brand, 'Test Brand');
      expect(product.energyKcal, 100);
      expect(product.proteinG, 5.5);
      expect(product.lastSynced, 123456789);
    });

    test('fromJson handles missing optional fields', () {
      /// Products with only the required fields are parsed without
      /// errors; optional fields become `null`.
      final minimal = {'_id': '456', 'product_name': 'Minimal'};
      final product = Product.fromJson(minimal);
      expect(product.brand, isNull);
      expect(product.energyKcal, isNull);
    });

    test('copyWith creates a modified copy', () {
      /// `copyWith` returns a new instance with only the specified
      /// fields changed.
      const product = Product(barcode: '789', name: 'Original');
      final updated = product.copyWith(name: 'Updated', brand: 'Brand');
      expect(updated.name, 'Updated');
      expect(updated.brand, 'Brand');
      expect(updated.barcode, '789');
    });
  });
}
