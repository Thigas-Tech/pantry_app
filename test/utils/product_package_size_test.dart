import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/utils/product_package_size.dart';

void main() {
  test('extracts the per-unit size from a multi-pack quantity', () {
    final size = productPackageSize(
      const Product(
        barcode: '1',
        name: 'Yogurt',
        productQuantity: 0.45,
        quantity: '3 x 150 g',
      ),
    );

    expect(size, isNotNull);
    expect(size!.quantity, 150);
    expect(size.unit, 'g');
  });

  test('parses a plain quantity string', () {
    final size = productPackageSize(
      const Product(barcode: '2', name: 'Flour', quantity: '500 g'),
    );

    expect(size, isNotNull);
    expect(size!.quantity, 500);
    expect(size.unit, 'g');
  });

  test('returns null when nothing is parseable', () {
    final size = productPackageSize(
      const Product(barcode: '3', name: 'No size'),
    );

    expect(size, isNull);
  });

  test('falls back to the serving size when packaging data is absent', () {
    final size = productPackageSize(
      const Product(
        barcode: '4',
        name: 'Snack',
        servingQuantity: 25,
        servingSize: '25.0g',
      ),
    );

    expect(size, isNotNull);
    expect(size!.quantity, 25);
    expect(size.unit, 'g');
  });

  test('package size wins over the serving size when both are present', () {
    final size = productPackageSize(
      const Product(
        barcode: '5',
        name: 'Yogurt',
        productQuantity: 0.45,
        quantity: '3 x 150 g',
        servingQuantity: 125,
        servingSize: '125 g',
      ),
    );

    expect(size!.quantity, 150);
    expect(size.unit, 'g');
  });

  test('unparseable package data falls back to the serving size', () {
    final size = productPackageSize(
      const Product(
        barcode: '6',
        name: 'Odd',
        quantity: '1 pack of 12',
        servingQuantity: 30,
        servingSize: '30 g',
      ),
    );

    expect(size!.quantity, 30);
    expect(size.unit, 'g');
  });
}
