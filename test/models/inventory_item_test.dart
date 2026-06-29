/// Unit tests for the [InventoryItem] model.
///
/// Covers JSON deserialization, default values, and basic object
/// creation.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/models/inventory_item.dart';

void main() {
  group('InventoryItem', () {
    final json = {
      'id': 1,
      'barcode': '123',
      'quantity': 2,
      'unit': 'kg',
      'expiry_date': '2026-12-31',
      'location': 'fridge',
      'notes': 'test note',
      'date_added': 123456789,
    };

    test('fromJson creates a valid InventoryItem', () {
      /// All fields present in the JSON are correctly parsed.
      final item = InventoryItem.fromJson(json);
      expect(item.id, 1);
      expect(item.barcode, '123');
      expect(item.quantity, 2);
      expect(item.unit, 'kg');
      expect(item.expiryDate, '2026-12-31');
      expect(item.location, 'fridge');
      expect(item.notes, 'test note');
      expect(item.dateAdded, 123456789);
    });

    test('defaults are applied when fields are missing', () {
      /// When optional fields are missing, the [@Default] values are
      /// used and nullable fields become `null`.
      final minimal = {'barcode': '456'};
      final item = InventoryItem.fromJson(minimal);
      expect(item.quantity, 1);
      expect(item.unit, 'pcs');
      expect(item.location, 'pantry');
      expect(item.id, isNull);
      expect(item.expiryDate, isNull);
      expect(item.notes, isNull);
      expect(item.dateAdded, isNull);
    });
  });
}
