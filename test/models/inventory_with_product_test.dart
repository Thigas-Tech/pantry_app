import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/models/inventory_with_product.dart';

/// Tests for the [InventoryWithProduct] read‑only view.
///
/// Covers construction from the raw database row map and the application
/// of default values for missing columns.
void main() {
  group('InventoryWithProduct', () {
    /// A complete row from the joined query
    /// (inventory + product + inventories).
    final completeMap = {
      'id': 1,
      'barcode': '123',
      'quantity': 2,
      'unit': 'pcs',
      'expiry_date': '2026-12-31',
      'location': 'pantry',
      'notes': null,
      'date_added': 123456789,
      'inventory_id': 2,
      'product_name': 'Test Product',
      'product_image_url': 'http://example.com/img.jpg',
      'inventory_name': 'Home',
    };

    test('fromMap creates a valid instance from a complete row', () {
      /// Every field is extracted from the joined query result.
      final item = InventoryWithProduct.fromMap(completeMap);
      expect(item.id, 1);
      expect(item.barcode, '123');
      expect(item.quantity, 2);
      expect(item.unit, 'pcs');
      expect(item.expiryDate, '2026-12-31');
      expect(item.location, 'pantry');
      expect(item.notes, isNull);
      expect(item.dateAdded, 123456789);
      expect(item.inventoryId, 2);
      expect(item.productName, 'Test Product');
      expect(item.productImageUrl, 'http://example.com/img.jpg');
      expect(item.inventoryName, 'Home');
    });

    test('defaults applied when fields are missing', () {
      /// Only the required fields are present; optional columns fall back
      /// to sensible defaults.
      final minimal = {
        'barcode': '456',
        'quantity': 1,
        'unit': 'pcs',
        'location': 'fridge',
        'inventory_id': 3,
      };
      final item = InventoryWithProduct.fromMap(minimal);
      expect(item.barcode, '456');
      expect(item.quantity, 1);
      expect(item.unit, 'pcs');
      expect(item.location, 'fridge');
      expect(item.inventoryId, 3);
      expect(item.id, isNull);
      expect(item.expiryDate, isNull);
      expect(item.notes, isNull);
      expect(item.dateAdded, isNull);
      expect(item.productName, isNull);
      expect(item.productImageUrl, isNull);
      expect(item.inventoryName, isNull);
    });
  });
}
