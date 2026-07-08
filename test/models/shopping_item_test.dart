import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/models/shopping_item.dart';

void main() {
  group('ShoppingItem', () {
    test('creates with required fields', () {
      const item = ShoppingItem(name: 'Milk');
      expect(item.name, 'Milk');
      expect(item.barcode, isNull);
      expect(item.quantity, 1.0);
      expect(item.unit, 'pieces');
      expect(item.isPurchased, false);
      expect(item.id, isNull);
    });

    test('creates with all fields', () {
      const item = ShoppingItem(
        name: 'Organic Milk',
        barcode: '123456',
        quantity: 2,
        unit: 'L',
        isPurchased: true,
        id: 1,
        dateAdded: 1000,
        datePurchased: 2000,
      );
      expect(item.name, 'Organic Milk');
      expect(item.barcode, '123456');
      expect(item.quantity, 2.0);
      expect(item.unit, 'L');
      expect(item.isPurchased, true);
      expect(item.id, 1);
      expect(item.dateAdded, 1000);
      expect(item.datePurchased, 2000);
    });

    test('copyWith preserves unset fields', () {
      const item = ShoppingItem(name: 'Eggs', barcode: '789');
      final copied = item.copyWith(quantity: 12);
      expect(copied.name, 'Eggs');
      expect(copied.barcode, '789');
      expect(copied.quantity, 12.0);
      expect(copied.isPurchased, false);
    });

    test('equality works', () {
      const a = ShoppingItem(name: 'Bread', id: 1);
      const b = ShoppingItem(name: 'Bread', id: 1);
      const c = ShoppingItem(name: 'Bread', id: 2);
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('default values are correct', () {
      const item = ShoppingItem(name: 'Water');
      expect(item.quantity, 1.0);
      expect(item.unit, 'pieces');
      expect(item.isPurchased, false);
    });
  });
}
