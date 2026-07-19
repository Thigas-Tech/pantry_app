import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/models/inventory_item.dart';

/// Tests for the [InventoryItem] model.
///
/// Covers JSON deserialization with the snake_case database keys,
/// default values, and the new `inventoryId` field.
void main() {
  group('InventoryItem', () {
    /// A complete row from the `inventory` table.
    final completeJson = {
      'id': 1,
      'barcode': '123',
      'quantity': 2,
      'unit': 'kg',
      'expiry_date': '2026-12-31',
      'location': 'fridge',
      'notes': 'test note',
      'date_added': 123456789,
      'inventory_id': 2,
    };

    test('fromJson creates a valid InventoryItem from a complete JSON', () {
      /// Every field is correctly parsed, including the new `inventory_id`.
      final item = InventoryItem.fromJson(completeJson);
      expect(item.id, 1);
      expect(item.barcode, '123');
      expect(item.quantity, 2);
      expect(item.unit, 'kg');
      expect(item.expiryDate, '2026-12-31');
      expect(item.location, 'fridge');
      expect(item.notes, 'test note');
      expect(item.dateAdded, 123456789);
      expect(item.inventoryId, 2);
    });

    test('defaults are applied when fields are missing', () {
      /// Only the required [barcode] is supplied; all other fields use
      /// their defaults.
      final minimal = {'barcode': '456'};
      final item = InventoryItem.fromJson(minimal);
      expect(item.id, isNull);
      expect(item.quantity, 1);
      expect(item.unit, 'pieces');
      expect(item.expiryDate, isNull);
      expect(item.location, 'pantry');
      expect(item.notes, isNull);
      expect(item.dateAdded, isNull);
      expect(item.inventoryId, 1); // default inventory ID
    });

    test('copyWith creates a modified copy', () {
      /// The original item is untouched; a new instance is returned with
      /// the changes.
      const item = InventoryItem(barcode: '789', quantity: 3);
      final updated = item.copyWith(quantity: 5, location: 'freezer');
      expect(updated.quantity, 5);
      expect(updated.location, 'freezer');
      expect(updated.barcode, '789'); // unchanged
    });
  });

  group('InventoryItem servingWeightG', () {
    test('servingWeightG defaults to null', () {
      const item = InventoryItem(barcode: '123');
      expect(item.servingWeightG, isNull);
    });

    test('servingWeightG can be set', () {
      const item = InventoryItem(barcode: '123', servingWeightG: 182);
      expect(item.servingWeightG, 182);
    });

    test('copyWith preserves servingWeightG', () {
      const item = InventoryItem(
        barcode: '123',
        servingWeightG: 182,
      );
      final updated = item.copyWith(quantity: 3);
      expect(updated.servingWeightG, 182);
      expect(updated.quantity, 3);
    });

    test('fromJson reads serving_weight_g', () {
      final json = {
        'barcode': '123',
        'serving_weight_g': 182.0,
      };
      final item = InventoryItem.fromJson(json);
      expect(item.servingWeightG, 182.0);
    });

    test('toJson writes serving_weight_g', () {
      const item = InventoryItem(barcode: '123', servingWeightG: 182);
      final json = item.toJson();
      expect(json['serving_weight_g'], 182.0);
    });
  });
}
