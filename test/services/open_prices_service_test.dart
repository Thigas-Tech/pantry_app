import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/models/price.dart';
import 'package:pantry_app/services/open_prices_api_client.dart';
import 'package:pantry_app/services/open_prices_service.dart';

class MockHttpClient extends Mock implements http.Client {}

class MockDatabaseHelper extends Mock implements DatabaseHelper {}

void main() {
  late MockHttpClient mockHttp;
  late MockDatabaseHelper mockDb;
  late OpenPricesService service;

  setUpAll(() {
    registerFallbackValue(Uri());
    registerFallbackValue(const Price(barcode: '123', price: 4.99));
  });

  setUp(() {
    mockHttp = MockHttpClient();
    mockDb = MockDatabaseHelper();
    service = OpenPricesService(
      databaseHelper: mockDb,
      apiClient: OpenPricesApiClient(
        client: mockHttp,
        baseUrl: 'https://test.prices.api/v1',
        token: 'test-token',
        contactEmail: 'test@example.com',
      ),
    );
  });

  group('fetchPricesByBarcode', () {
    test('returns prices via API client', () async {
      when(
        () => mockHttp.get(any<Uri>(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async => http.Response(
          '{"items": [{"id": 1, "product_code": "123", "price": 4.99, '
          '"currency": "EUR", "product": {"product_name": "Test"}, '
          '"location": {"osm_name": "Walmart"}}], "total": 1}',
          200,
        ),
      );

      final result = await service.fetchPricesByBarcode('123');

      expect(result.total, 1);
      expect(result.prices.first.price, 4.99);
    });

    test('returns empty when no token', () async {
      final noTokenService = OpenPricesService(
        databaseHelper: mockDb,
        apiClient: OpenPricesApiClient(
          client: mockHttp,
          baseUrl: 'https://test.prices.api/v1',
          token: '',
          contactEmail: 'test@example.com',
        ),
      );

      final result = await noTokenService.fetchPricesByBarcode('123');

      expect(result.total, 0);
      expect(result.prices, isEmpty);
    });
  });

  group('syncPendingPrices', () {
    test('syncs pending prices (placeholder)', () async {
      when(() => mockDb.getPricesBySyncStatus(priceSyncPending)).thenAnswer(
        (_) async => [
          const Price(
            barcode: '123',
            price: 4.99,
            syncStatus: priceSyncPending,
            id: 1,
          ),
        ],
      );
      when(() => mockDb.updatePrice(any())).thenAnswer((_) async => 1);

      final result = await service.syncPendingPrices();

      expect(result.synced, 1);
      expect(result.failed, 0);
    });

    test('returns empty when no pending prices', () async {
      when(
        () => mockDb.getPricesBySyncStatus(priceSyncPending),
      ).thenAnswer((_) async => []);

      final result = await service.syncPendingPrices();

      expect(result.synced, 0);
      expect(result.failed, 0);
    });
  });

  group('validateToken', () {
    test('validates token via API client', () async {
      when(
        () => mockHttp.get(any<Uri>(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async => http.Response('{"items": []}', 200),
      );

      final valid = await service.validateToken();

      expect(valid, isTrue);
    });
  });
}
