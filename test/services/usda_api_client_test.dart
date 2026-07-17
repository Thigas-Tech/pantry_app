import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:pantry_app/models/product_type.dart';
import 'package:pantry_app/services/usda_api_client.dart';

class MockHttpClient extends Mock implements http.Client {}

void main() {
  setUpAll(() {
    registerFallbackValue(Uri.parse('https://example.com'));
    registerFallbackValue(<String, String>{});
    registerFallbackValue('');
  });
  group('UsdaApiClient', () {
    late MockHttpClient mockClient;
    late UsdaApiClient client;

    setUp(() {
      mockClient = MockHttpClient();
      client = UsdaApiClient(httpClient: mockClient, apiKey: 'test-key');
    });

    test('returns product on successful response', () async {
      when(
        () => mockClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => http.Response(_sampleResponse, 200));

      final results = await client.searchFood('apple');

      expect(results, isNotEmpty);
      final apple = results.firstWhere((p) => p.name.contains('Apple'));
      expect(apple.energyKcal, closeTo(52.0, 0.1));
      expect(apple.proteinG, closeTo(0.26, 0.01));
      expect(apple.carbsG, closeTo(13.81, 0.01));
      expect(apple.productType, ProductType.produce);
      expect(apple.source, 'api');
    });

    test('returns empty list on API error', () async {
      when(
        () => mockClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => http.Response('Server error', 500));

      final results = await client.searchFood('apple');
      expect(results, isEmpty);
    });

    test('returns empty list on network error', () async {
      when(
        () => mockClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenThrow(Exception('Connection refused'));

      final results = await client.searchFood('apple');
      expect(results, isEmpty);
    });

    test('normalizes nutrition to per 100g', () async {
      when(
        () => mockClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => http.Response(_sampleResponse, 200));

      final results = await client.searchFood('apple');

      final apple = results.firstWhere((p) => p.name.contains('Apple'));
      // USDA values are per 100g in our normalized format
      expect(apple.energyKcal, closeTo(52, 1));
    });

    test('uses produce barcode prefix for generated products', () async {
      when(
        () => mockClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => http.Response(_sampleResponse, 200));

      final results = await client.searchFood('apple');

      for (final product in results) {
        expect(product.barcode, startsWith('plu-'));
      }
    });

    test('sends api_key as URL query parameter not in body', () async {
      when(
        () => mockClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => http.Response('{"foods":[]}', 200));

      await client.searchFood('Orange');

      final captured = verify(
        () => mockClient.post(
          captureAny(),
          headers: any(named: 'headers'),
          body: captureAny(named: 'body'),
        ),
      ).captured;
      final uri = captured[0] as Uri;
      final body = captured[1] as String;

      expect(uri.queryParameters['api_key'], 'test-key');
      final decoded = jsonDecode(body) as Map<String, dynamic>;
      expect(decoded, isNot(contains('api_key')));
    });

    test('URL-encodes special characters in api_key', () async {
      const keyWithSpecialChars = 'key+123&a=1 b';
      final clientWithSpecialKey = UsdaApiClient(
        httpClient: mockClient,
        apiKey: keyWithSpecialChars,
      );

      when(
        () => mockClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => http.Response('{"foods":[]}', 200));

      await clientWithSpecialKey.searchFood('test');

      final captured = verify(
        () => mockClient.post(
          captureAny(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).captured;
      final uri = captured[0] as Uri;

      expect(uri.queryParameters['api_key'], keyWithSpecialChars);
      // The raw query string should be percent-encoded
      expect(uri.query, contains('api_key='));
      expect(uri.query, isNot(contains(' ')));
    });

    test('returns empty list on 403 Forbidden', () async {
      when(
        () => mockClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => http.Response('Forbidden', 403));

      final results = await client.searchFood('apple');
      expect(results, isEmpty);
    });
  });
}

const _sampleResponse = '''
{
  "foods": [
    {
      "fdcId": 1750339,
      "description": "Apple, raw, with skin",
      "foodNutrients": [
        {
          "nutrientId": 1008,
          "nutrientName": "Energy",
          "value": 52.0,
          "unitName": "KCAL"
        },
        {
          "nutrientId": 1003,
          "nutrientName": "Protein",
          "value": 0.26,
          "unitName": "G"
        },
        {
          "nutrientId": 1005,
          "nutrientName": "Carbohydrate, by difference",
          "value": 13.81,
          "unitName": "G"
        },
        {
          "nutrientId": 1004,
          "nutrientName": "Total lipid (fat)",
          "value": 0.17,
          "unitName": "G"
        },
        {
          "nutrientId": 1079,
          "nutrientName": "Fiber, total dietary",
          "value": 2.4,
          "unitName": "G"
        }
      ]
    }
  ]
}
''';
