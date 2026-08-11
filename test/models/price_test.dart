import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/models/price.dart';

void main() {
  group('Price', () {
    test('defaults inventoryId to 1', () {
      const price = Price(barcode: '123', price: 5.99);
      expect(price.inventoryId, 1);
    });

    test('creates with explicit inventoryId', () {
      const price = Price(
        barcode: '123',
        price: 5.99,
        inventoryId: 2,
      );
      expect(price.inventoryId, 2);
    });

    test('copyWith preserves inventoryId when unset', () {
      const price = Price(
        barcode: '123',
        price: 5.99,
        inventoryId: 2,
      );
      final copied = price.copyWith(price: 6.5);
      expect(copied.inventoryId, 2);
      expect(copied.price, 6.5);
    });

    test('copyWith changes inventoryId when set', () {
      const price = Price(barcode: '123', price: 5.99);
      final copied = price.copyWith(inventoryId: 3);
      expect(copied.inventoryId, 3);
    });

    test('equality includes inventoryId', () {
      const a = Price(barcode: '123', price: 5.99);
      const b = Price(barcode: '123', price: 5.99);
      const c = Price(barcode: '123', price: 5.99, inventoryId: 2);
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('package fields default to null', () {
      const price = Price(barcode: '123', price: 5.99);
      expect(price.packageQuantity, isNull);
      expect(price.packageUnit, isNull);
    });

    test('copyWith sets package fields', () {
      const price = Price(
        barcode: '123',
        price: 9.99,
        packageQuantity: 12,
        packageUnit: 'pieces',
      );
      expect(price.packageQuantity, 12);
      expect(price.packageUnit, 'pieces');

      final cleared = price.copyWith(packageQuantity: null, packageUnit: null);
      expect(cleared.packageQuantity, isNull);
      expect(cleared.packageUnit, isNull);
    });
  });
}
