import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/services/exceptions.dart';

/// Unit tests for the custom exception classes.
void main() {
  group('ProductNotFoundException', () {
    test('stores and displays the message', () {
      final ex = ProductNotFoundException('Barcode 123 not found');
      expect(ex.message, 'Barcode 123 not found');
      expect(ex.toString(), contains('Barcode 123 not found'));
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
