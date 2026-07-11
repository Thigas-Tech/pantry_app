import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:pantry_app/services/open_prices_api_client.dart';

class MockHttpClient extends Mock implements http.Client {}

void main() {
  late MockHttpClient mockHttp;
  late OpenPricesApiClient client;

  setUpAll(() {
    registerFallbackValue(Uri());
    registerFallbackValue(<String, String>{});
  });

  setUp(() {
    mockHttp = MockHttpClient();
    client = OpenPricesApiClient(
      client: mockHttp,
      baseUrl: 'https://test.prices.api/v1',
      token: 'test-token',
      contactEmail: 'test@example.com',
    );
  });

  group('hasToken', () {
    test('returns true when token is non-empty', () {
      expect(client.hasToken, isTrue);
    });

    test('returns false when token is empty', () {
      final noTokenClient = OpenPricesApiClient(
        client: mockHttp,
        baseUrl: 'https://test.prices.api/v1',
        token: '',
        contactEmail: 'test@example.com',
      );
      expect(noTokenClient.hasToken, isFalse);
    });
  });

  group('fetchPricesByBarcode', () {
    test('returns prices on successful response', () async {
      when(
        () => mockHttp.get(
          any<Uri>(),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer(
        (_) async => http.Response('''
          {
            "items": [
              {
                "id": 1,
                "product_code": "123",
                "price": 4.99,
                "currency": "EUR",
                "date": "2024-01-15",
                "product": {"product_name": "Test Product"},
                "location": {"osm_name": "Walmart"}
              }
            ],
            "total": 1,
            "page": 1,
            "pages": 1
          }
        ''', 200),
      );

      final result = await client.fetchPricesByBarcode('123');

      expect(result.total, 1);
      expect(result.prices.length, 1);
      expect(result.prices.first.price, 4.99);
      expect(result.prices.first.store, 'Walmart');
      expect(result.prices.first.productName, 'Test Product');
      expect(result.prices.first.productCode, '123');
    });

    test('returns empty result on non-200', () async {
      when(
        () => mockHttp.get(
          any<Uri>(),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer(
        (_) async => http.Response('Not Found', 404),
      );

      final result = await client.fetchPricesByBarcode('123');

      expect(result.total, 0);
      expect(result.prices, isEmpty);
    });

    test('returns empty result on network error', () async {
      when(
        () => mockHttp.get(
          any<Uri>(),
          headers: any(named: 'headers'),
        ),
      ).thenThrow(Exception('Network error'));

      final result = await client.fetchPricesByBarcode('123');

      expect(result.total, 0);
      expect(result.prices, isEmpty);
    });

    test('handles missing items field gracefully', () async {
      when(
        () => mockHttp.get(
          any<Uri>(),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer(
        (_) async => http.Response('{}', 200),
      );

      final result = await client.fetchPricesByBarcode('123');

      expect(result.total, 0);
      expect(result.prices, isEmpty);
    });
  });

  group('validateToken', () {
    test('returns true on 200', () async {
      when(
        () => mockHttp.get(
          any<Uri>(),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer(
        (_) async => http.Response('{"items": []}', 200),
      );

      final valid = await client.validateToken();

      expect(valid, isTrue);
    });

    test('returns false on 401', () async {
      when(
        () => mockHttp.get(
          any<Uri>(),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer(
        (_) async => http.Response('Unauthorized', 401),
      );

      final valid = await client.validateToken();

      expect(valid, isFalse);
    });

    test('returns false on network error', () async {
      when(
        () => mockHttp.get(
          any<Uri>(),
          headers: any(named: 'headers'),
        ),
      ).thenThrow(Exception('Network error'));

      final valid = await client.validateToken();

      expect(valid, isFalse);
    });
  });

  group('submitPrice', () {
    test('returns success on 201', () async {
      when(
        () => mockHttp.post(
          any<Uri>(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => http.Response('{"id": 42}', 201),
      );

      final result = await client.submitPrice(
        barcode: '123',
        price: 4.99,
        currency: 'EUR',
        proofId: 1,
        date: '2024-01-15',
      );

      expect(result.success, isTrue);
      expect(result.remoteId, 42);
    });

    test('returns failure when no token configured', () async {
      final noTokenClient = OpenPricesApiClient(
        client: mockHttp,
        baseUrl: 'https://test.prices.api/v1',
        token: '',
        contactEmail: 'test@example.com',
      );

      final result = await noTokenClient.submitPrice(
        barcode: '123',
        price: 4.99,
        currency: 'EUR',
        proofId: 1,
      );

      expect(result.success, isFalse);
      expect(result.errorMessage, 'No API token configured');
    });

    test('returns failure on non-201 response', () async {
      when(
        () => mockHttp.post(
          any<Uri>(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => http.Response('Bad Request', 400),
      );

      final result = await client.submitPrice(
        barcode: '123',
        price: 4.99,
        currency: 'EUR',
        proofId: 1,
      );

      expect(result.success, isFalse);
    });

    test('returns failure on network error', () async {
      when(
        () => mockHttp.post(
          any<Uri>(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenThrow(Exception('Network error'));

      final result = await client.submitPrice(
        barcode: '123',
        price: 4.99,
        currency: 'EUR',
        proofId: 1,
      );

      expect(result.success, isFalse);
    });
  });
}
