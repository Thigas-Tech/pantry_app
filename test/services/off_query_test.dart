import 'package:flutter_test/flutter_test.dart';
import 'package:openfoodfacts/openfoodfacts.dart';
import 'package:pantry_app/services/off_query.dart';

void main() {
  group('OffQuery', () {
    test('productFields contains expected fields', () {
      expect(OffQuery.productFields, contains(ProductField.BARCODE));
      expect(OffQuery.productFields, contains(ProductField.NAME));
      expect(OffQuery.productFields, contains(ProductField.BRANDS));
      expect(OffQuery.productFields, contains(ProductField.NUTRIMENTS));
      expect(OffQuery.productFields, contains(ProductField.NUTRISCORE));
    });

    test('barcodeConfig returns ProductQueryConfiguration', () {
      final config = OffQuery.barcodeConfig('5901234123457');
      expect(config.barcode, '5901234123457');
      expect(config.language, OpenFoodFactsLanguage.ENGLISH);
      expect(config.version, ProductQueryVersion.v3);
    });

    test('searchConfig returns ProductSearchQueryConfiguration', () {
      final config = OffQuery.searchConfig('guarana');
      expect(config.additionalParameters, hasLength(2));
    });

    test('searchConfig respects custom pageSize', () {
      final config = OffQuery.searchConfig('guarana', pageSize: 5);
      final pageSizeParam = config.additionalParameters
          .whereType<PageSize>()
          .firstOrNull;
      expect(pageSizeParam, isNotNull);
      expect(pageSizeParam!.size, 5);
    });
  });
}
