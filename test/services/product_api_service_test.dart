import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/services/product_api_service.dart';

/// A minimal implementation of [ProductApiService] for testing.
class FakeProductApiService implements ProductApiService {
  @override
  Future<Product> getByBarcode(String barcode) async {
    return Product(barcode: barcode, name: 'Fake');
  }

  @override
  Future<void> close() async {}
}

/// Tests for [ProductApiService] interface.
void main() {
  group('ProductApiService', () {
    test('close() completes without error', () async {
      final service = FakeProductApiService();
      await service.close(); // exercises the default implementation
    });
  });
}
