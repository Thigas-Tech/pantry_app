import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/models/inventory_product_option.dart';
import 'package:pantry_app/models/inventory_summary.dart';

void main() {
  group('InventorySummary.fromMap', () {
    test('maps a complete row', () {
      final summary = InventorySummary.fromMap(const {
        'id': 3,
        'name': 'Work',
        'created_at': 1700000000000,
        'item_count': 5,
      });

      expect(summary.id, 3);
      expect(summary.name, 'Work');
      expect(
        summary.createdAt,
        DateTime.fromMillisecondsSinceEpoch(1700000000000),
      );
      expect(summary.itemCount, 5);
    });

    test('falls back to safe defaults for missing values', () {
      final summary = InventorySummary.fromMap(const {'id': 7});

      expect(summary.id, 7);
      expect(summary.name, isEmpty);
      expect(summary.createdAt, DateTime.fromMillisecondsSinceEpoch(0));
      expect(summary.itemCount, 0);
    });

    test('tolerates non-numeric id', () {
      final summary = InventorySummary.fromMap(const {'id': null});
      expect(summary.id, 0);
    });
  });

  group('InventoryProductOption.fromMap', () {
    test('maps a complete row', () {
      final option = InventoryProductOption.fromMap(const {
        'barcode': '123',
        'name': 'Eggs',
        'image_url': 'https://example.com/e.png',
        'product_type': 'produce',
      });

      expect(option.barcode, '123');
      expect(option.name, 'Eggs');
      expect(option.imageUrl, 'https://example.com/e.png');
      expect(option.productType, 'produce');
    });

    test('falls back to empty barcode and null optionals', () {
      final option = InventoryProductOption.fromMap(const {});

      expect(option.barcode, isEmpty);
      expect(option.name, isNull);
      expect(option.imageUrl, isNull);
      expect(option.productType, isNull);
    });
  });
}
