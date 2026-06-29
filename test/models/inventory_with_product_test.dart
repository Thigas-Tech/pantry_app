/// Unit tests for the [InventoryWithProduct] read‑only view.
///
/// Covers construction from a raw database row map and the application
/// of default values.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/models/inventory_with_product.dart';

void main() {
  group('InventoryWithProduct', () {
    final map = {
      'id': 1,
      'barcode': '123',
      'quantity': 2,
      'unit': 'pcs',
      'expiry_date': '2026-12-31',
      'location': 'pantry',
      'notes': null,
      'date_added': 123456789,
      'product_name': 'Test Product',
      'product_image_url': 'http://example.com/img.jpg',
    };

    test('fromMap creates a valid instance', () {
      /// All fields from a complete row map are assigned correctly.
      final item = InventoryWithProduct.fromMap(map);
      expect(item.id, 1);
      expect(item.barcode, '123');
      expect(item.quantity, 2);
      expect(item.unit, 'pcs');
      expect(item.expiryDate, '2026-12-31');
      expect(item.location, 'pantry');
      expect(item.notes, isNull);
      expect(item.dateAdded, 123456789);
      expect(item.productName, 'Test Product');
      expect(item.productImageUrl, 'http://example.com/img.jpg');
    });

    test('defaults applied when missing', () {
      /// Missing columns from the query result default to sensible
      /// values or `null`.
      final minimal = {
        'barcode': '456',
        'quantity': 1,
        'unit': 'pcs',
        'location': 'fridge',
      };
      final item = InventoryWithProduct.fromMap(minimal);
      expect(item.quantity, 1);
      expect(item.unit, 'pcs');
      expect(item.location, 'fridge');
      expect(item.id, isNull);
      expect(item.expiryDate, isNull);
      expect(item.productName, isNull);
      expect(item.productImageUrl, isNull);
    });
  });
}
