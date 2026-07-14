import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/models/product_type.dart';
import 'package:pantry_app/services/off_adapter.dart';
import 'package:pantry_app/services/plu_service.dart';
import 'package:pantry_app/services/produce_search_service.dart';
import 'package:pantry_app/services/usda_api_client.dart';

class MockOffAdapter extends Mock implements OffAdapter {}

class MockPluService extends Mock implements PluService {}

class MockUsdaApiClient extends Mock implements UsdaApiClient {}

void main() {
  group('ProduceSearchService', () {
    late MockOffAdapter mockOff;
    late MockPluService mockPlu;
    late MockUsdaApiClient mockUsda;
    late ProduceSearchService service;

    setUp(() {
      mockOff = MockOffAdapter();
      mockPlu = MockPluService();
      mockUsda = MockUsdaApiClient();
      service = ProduceSearchService(
        offAdapter: mockOff,
        pluService: mockPlu,
        usdaClient: mockUsda,
      );
    });

    test('returns OFF results enriched with PLU codes', () async {
      when(
        () => mockOff.searchProducts(
          'apple',
          languageCode: any(named: 'languageCode'),
        ),
      ).thenAnswer(
        (_) async => [
          const Product(barcode: '123', name: 'Apple'),
        ],
      );
      when(() => mockPlu.search('apple')).thenReturn([
        const PluEntry(code: '4032', name: 'Apple', category: 'Fruits'),
      ]);

      final results = await service.search('apple');

      expect(results, isNotEmpty);
      final apple = results.firstWhere((p) => p.name == 'Apple');
      expect(apple.pluCode, '4032');
      expect(apple.productType, ProductType.produce);
    });

    test('falls back to USDA when OFF returns no results', () async {
      when(
        () => mockOff.searchProducts(
          'tomato',
          languageCode: any(named: 'languageCode'),
        ),
      ).thenAnswer((_) async => []);
      when(() => mockPlu.search('tomato')).thenReturn([]);
      when(() => mockUsda.searchFood('tomato')).thenAnswer(
        (_) async => [
          const Product(
            barcode: 'plu-123',
            name: 'Tomato, raw',
            productType: ProductType.produce,
          ),
        ],
      );

      final results = await service.search('tomato');

      expect(results, isNotEmpty);
      expect(results.first.name, 'Tomato, raw');
    });

    test('returns empty when both OFF and USDA have no results', () async {
      when(
        () => mockOff.searchProducts(
          'xyznotfound',
          languageCode: any(named: 'languageCode'),
        ),
      ).thenAnswer((_) async => []);
      when(() => mockPlu.search('xyznotfound')).thenReturn([]);
      when(() => mockUsda.searchFood('xyznotfound')).thenAnswer(
        (_) async => [],
      );

      final results = await service.search('xyznotfound');

      expect(results, isEmpty);
    });

    test('deduplicates by barcode', () async {
      when(
        () => mockOff.searchProducts(
          'banana',
          languageCode: any(named: 'languageCode'),
        ),
      ).thenAnswer(
        (_) async => [
          const Product(barcode: '4011-produce', name: 'Banana'),
        ],
      );
      when(() => mockPlu.search('banana')).thenReturn([
        const PluEntry(code: '4011', name: 'Banana', category: 'Fruits'),
      ]);

      final results = await service.search('banana');

      expect(results.length, 1);
    });
  });
}
