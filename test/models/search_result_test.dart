/// Unit tests for the [SearchResult] model and [ResultSource] enum.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/models/search_result.dart';

void main() {
  const product = Product(barcode: '001', name: 'Local Milk');

  group('ResultSource', () {
    test('has local and api values', () {
      expect(ResultSource.local, isA<ResultSource>());
      expect(ResultSource.api, isA<ResultSource>());
      expect(ResultSource.values, [ResultSource.local, ResultSource.api]);
    });
  });

  group('SearchResult', () {
    test('stores product and source', () {
      const result = SearchResult(
        product: product,
        source: ResultSource.api,
      );
      expect(result.product.barcode, '001');
      expect(result.product.name, 'Local Milk');
      expect(result.source, ResultSource.api);
    });

    test('defaults isInPantry to false', () {
      const result = SearchResult(
        product: product,
        source: ResultSource.local,
      );
      expect(result.isInPantry, isFalse);
    });

    test('stores isInPantry when provided', () {
      const result = SearchResult(
        product: product,
        source: ResultSource.local,
        isInPantry: true,
      );
      expect(result.isInPantry, isTrue);
    });
  });
}
