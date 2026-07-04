import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/services/exceptions.dart';

void main() {
  group('ProductNotFoundException', () {
    test('stores the barcode and provides a string representation', () {
      final ex = ProductNotFoundException('5012345678900');
      expect(ex.barcode, '5012345678900');
      expect(ex.toString(), contains('5012345678900'));
    });
  });

  group('FetchFailedException', () {
    test('stores and displays the message', () {
      final ex = FetchFailedException('Network error');
      expect(ex.message, 'Network error');
      expect(ex.toString(), contains('Network error'));
    });
  });
}
