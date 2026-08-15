import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/models/product_type.dart';
import 'package:pantry_app/services/usda_api_client.dart';

class MockHttpClient extends Mock implements http.Client {}

/// Builds a single USDA food entry for test fixtures.
Map<String, dynamic> _food(int fdcId, String description, {double kcal = 0}) {
  return {
    'fdcId': fdcId,
    'description': description,
    'foodNutrients': [
      {'nutrientId': 1008, 'value': kcal, 'unitName': 'KCAL'},
    ],
  };
}

/// Wraps a list of food entries into a USDA search response.
String _foodsResponse(List<Map<String, dynamic>> foods) {
  return jsonEncode({'foods': foods});
}

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
      expect(apple.source, 'manual');
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

  group('searchFood produce filtering', () {
    late MockHttpClient mockClient;
    late UsdaApiClient client;

    setUp(() {
      mockClient = MockHttpClient();
      client = UsdaApiClient(httpClient: mockClient, apiKey: 'test-key');
    });

    test('keeps raw produce', () async {
      when(
        () => mockClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => http.Response(_mixedTomatoResponse, 200),
      );

      final results = await client.searchFood('tomato');
      final names = results.map((p) => p.name).toList();

      expect(names, contains('Tomatoes, raw'));
    });

    test('filters out processed derivatives', () async {
      when(
        () => mockClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => http.Response(_mixedTomatoResponse, 200),
      );

      final results = await client.searchFood('tomato');
      final names = results.map((p) => p.name).toList();

      expect(names, isNot(contains('Tomato powder')));
    });

    test('filters out canned items', () async {
      when(
        () => mockClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => http.Response(_cannedTomatoResponse, 200),
      );

      final results = await client.searchFood('tomato');
      final names = results.map((p) => p.name).toList();

      expect(names, ['Tomatoes, raw']);
    });

    test('filters out dried items', () async {
      when(
        () => mockClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => http.Response(_appleMixedResponse, 200),
      );

      final results = await client.searchFood('apple');
      final names = results.map((p) => p.name).toList();

      expect(names, ['Apples, raw, with skin']);
    });

    test('filters out juice derivatives', () async {
      when(
        () => mockClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => http.Response(_orangeMixedResponse, 200),
      );

      final results = await client.searchFood('orange');
      final names = results.map((p) => p.name).toList();

      expect(names, ['Oranges, raw']);
    });

    test('keeps multiple tomato varieties', () async {
      when(
        () => mockClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => http.Response(_varietyTomatoResponse, 200),
      );

      final results = await client.searchFood('tomato');
      final names = results.map((p) => p.name).toList();

      expect(names, hasLength(3));
      expect(
        names,
        containsAll([
          'Cherry tomatoes, raw',
          'Grape tomatoes, raw',
          'Roma tomatoes, raw',
        ]),
      );
    });

    test('keeps bare-name produce without qualifiers', () async {
      when(
        () => mockClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => http.Response(_bareNameResponse, 200),
      );

      final results = await client.searchFood('tomato');
      final names = results.map((p) => p.name).toList();

      expect(names, ['Tomatoes']);
    });

    test('returns empty list when all items are filtered out', () async {
      when(
        () => mockClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => http.Response(_allProcessedResponse, 200),
      );

      final results = await client.searchFood('tomato');
      expect(results, isEmpty);
    });
  });

  group('searchFood non-produce filtering', () {
    late MockHttpClient mockClient;
    late UsdaApiClient client;

    setUp(() {
      mockClient = MockHttpClient();
      client = UsdaApiClient(httpClient: mockClient, apiKey: 'test-key');
    });

    test('filters croissant', () async {
      when(
        () => mockClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => http.Response(
          _foodsResponse([
            _food(1, 'Tomatoes, raw'),
            _food(2, 'Croissant'),
          ]),
          200,
        ),
      );

      final results = await client.searchFood('tomato');
      final names = results.map((p) => p.name).toList();

      expect(names, ['Tomatoes, raw']);
    });

    test('filters strudel danish and pastry', () async {
      when(
        () => mockClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => http.Response(
          _foodsResponse([
            _food(1, 'Apples'),
            _food(2, 'Strudel'),
            _food(3, 'Danish'),
            _food(4, 'Pastry'),
          ]),
          200,
        ),
      );

      final results = await client.searchFood('apple');
      final names = results.map((p) => p.name).toList();

      expect(names, ['Apples']);
    });

    test('filters muffin coffeecake and pie', () async {
      when(
        () => mockClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => http.Response(
          _foodsResponse([
            _food(1, 'Oranges, raw'),
            _food(2, 'Muffins'),
            _food(3, 'Coffeecake'),
            _food(4, 'Pie'),
          ]),
          200,
        ),
      );

      final results = await client.searchFood('orange');
      final names = results.map((p) => p.name).toList();

      expect(names, ['Oranges, raw']);
    });

    test('filters butter and yogurt', () async {
      when(
        () => mockClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => http.Response(
          _foodsResponse([
            _food(1, 'Tomatoes, raw'),
            _food(2, 'Butter'),
            _food(3, 'Yogurt'),
          ]),
          200,
        ),
      );

      final results = await client.searchFood('tomato');
      final names = results.map((p) => p.name).toList();

      expect(names, ['Tomatoes, raw']);
    });

    test('filters ice cream sherbet and sundae', () async {
      when(
        () => mockClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => http.Response(
          _foodsResponse([
            _food(1, 'Strawberries'),
            _food(2, 'Ice cream'),
            _food(3, 'Sherbet'),
            _food(4, 'Sundae'),
          ]),
          200,
        ),
      );

      final results = await client.searchFood('strawberry');
      final names = results.map((p) => p.name).toList();

      expect(names, ['Strawberries']);
    });

    test('filters kefir lifeway and silk', () async {
      when(
        () => mockClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => http.Response(
          _foodsResponse([
            _food(1, 'Blueberries'),
            _food(2, 'Kefir'),
            _food(3, 'Lifeway'),
            _food(4, 'Silk'),
          ]),
          200,
        ),
      );

      final results = await client.searchFood('blueberry');
      final names = results.map((p) => p.name).toList();

      expect(names, ['Blueberries']);
    });

    test('filters mcdonald restaurant and taco', () async {
      when(
        () => mockClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => http.Response(
          _foodsResponse([
            _food(1, 'Apples, raw'),
            _food(2, "McDonald's"),
            _food(3, 'Restaurant'),
            _food(4, 'Taco'),
          ]),
          200,
        ),
      );

      final results = await client.searchFood('apple');
      final names = results.map((p) => p.name).toList();

      expect(names, ['Apples, raw']);
    });

    test('filters beverage tea and carbonated', () async {
      when(
        () => mockClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => http.Response(
          _foodsResponse([
            _food(1, 'Oranges, raw'),
            _food(2, 'Beverage'),
            _food(3, 'Tea'),
            _food(4, 'Carbonated'),
          ]),
          200,
        ),
      );

      final results = await client.searchFood('orange');
      final names = results.map((p) => p.name).toList();

      expect(names, ['Oranges, raw']);
    });

    test('filters topping syrup and marmalade', () async {
      when(
        () => mockClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => http.Response(
          _foodsResponse([
            _food(1, 'Apples'),
            _food(2, 'Toppings'),
            _food(3, 'Syrup'),
            _food(4, 'Marmalade'),
          ]),
          200,
        ),
      );

      final results = await client.searchFood('apple');
      final names = results.map((p) => p.name).toList();

      expect(names, ['Apples']);
    });

    test('filters snack candy mars atkins and twizzlers', () async {
      when(
        () => mockClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => http.Response(
          _foodsResponse([
            _food(1, 'Bananas'),
            _food(2, 'Snack'),
            _food(3, 'Candy'),
            _food(4, 'Mars'),
            _food(5, 'Atkins'),
            _food(6, 'Twizzlers'),
          ]),
          200,
        ),
      );

      final results = await client.searchFood('banana');
      final names = results.map((p) => p.name).toList();

      expect(names, ['Bananas']);
    });

    test('filters diet instant unenriched unsweetened dry and mix', () async {
      when(
        () => mockClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => http.Response(
          _foodsResponse([
            _food(1, 'Tomatoes'),
            _food(2, 'Diet'),
            _food(3, 'Instant'),
            _food(4, 'Unenriched'),
            _food(5, 'Unsweetened'),
            _food(6, 'Dry'),
            _food(7, 'Mix'),
          ]),
          200,
        ),
      );

      final results = await client.searchFood('tomato');
      final names = results.map((p) => p.name).toList();

      expect(names, ['Tomatoes']);
    });

    test('filters babyfood and souffle', () async {
      when(
        () => mockClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => http.Response(
          _foodsResponse([
            _food(1, 'Carrots, raw'),
            _food(2, 'Babyfood'),
            _food(3, 'Souffle'),
          ]),
          200,
        ),
      );

      final results = await client.searchFood('carrot');
      final names = results.map((p) => p.name).toList();

      expect(names, ['Carrots, raw']);
    });

    test('keeps produce with embedded marker substrings', () async {
      when(
        () => mockClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => http.Response(
          _foodsResponse([
            _food(1, 'Breadfruit, raw'),
            _food(2, 'Eggplant, raw'),
            _food(3, 'Butterhead lettuce'),
          ]),
          200,
        ),
      );

      final results = await client.searchFood('breadfruit');
      final names = results.map((p) => p.name).toList();

      expect(names, hasLength(3));
      expect(
        names,
        containsAll([
          'Breadfruit, raw',
          'Eggplant, raw',
          'Butterhead lettuce',
        ]),
      );
    });

    test('case insensitive filter', () async {
      when(
        () => mockClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => http.Response(
          _foodsResponse([
            _food(1, 'Lemons'),
            _food(2, "MCDONALD'S"),
            _food(3, 'YOGURT'),
            _food(4, 'SYRUP'),
          ]),
          200,
        ),
      );

      final results = await client.searchFood('lemon');
      final names = results.map((p) => p.name).toList();

      expect(names, ['Lemons']);
    });
  });

  group('enrichProductWithServingData', () {
    late MockHttpClient mockClient;
    late UsdaApiClient client;

    setUp(() {
      mockClient = MockHttpClient();
      client = UsdaApiClient(httpClient: mockClient, apiKey: 'test-key');
    });

    test(
      'extracts foodPortions from detail endpoint for Foundation data type',
      () async {
        when(() => mockClient.get(any())).thenAnswer(
          (_) async => http.Response(_detailResponseFoundation, 200),
        );

        const product = Product(
          barcode: 'plu-1750339',
          name: 'Apple',
          productType: ProductType.produce,
        );
        final enriched = await client.enrichProductWithServingData(product);

        expect(enriched, isNotNull);
        expect(enriched!.usdaServingAmount, 1.0);
        expect(enriched.usdaServingUnit, 'fruit');
        expect(enriched.usdaGramWeight, 182.0);
        expect(enriched.name, 'Apple');
        expect(enriched.barcode, 'plu-1750339');
      },
    );

    test('returns null for SR Legacy data type (no foodPortions)', () async {
      when(() => mockClient.get(any())).thenAnswer(
        (_) async => http.Response(_detailResponseSRLegacy, 200),
      );

      const product = Product(
        barcode: 'plu-170379',
        name: 'Broccoli',
        productType: ProductType.produce,
      );
      final enriched = await client.enrichProductWithServingData(product);
      expect(enriched, isNull);
    });

    test('returns null when detail endpoint returns error', () async {
      when(() => mockClient.get(any())).thenAnswer(
        (_) async => http.Response('Not Found', 404),
      );

      const product = Product(
        barcode: 'plu-999999',
        name: 'Unknown',
        productType: ProductType.produce,
      );
      final enriched = await client.enrichProductWithServingData(product);
      expect(enriched, isNull);
    });

    test('returns null when foodPortions array is empty', () async {
      when(() => mockClient.get(any())).thenAnswer(
        (_) async => http.Response(_detailResponseEmptyPortions, 200),
      );

      const product = Product(
        barcode: 'plu-1750339',
        name: 'Apple',
        productType: ProductType.produce,
      );
      final enriched = await client.enrichProductWithServingData(product);
      expect(enriched, isNull);
    });

    test('uses first portion when multiple foodPortions exist', () async {
      when(() => mockClient.get(any())).thenAnswer(
        (_) async => http.Response(_detailResponseMultiplePortions, 200),
      );

      const product = Product(
        barcode: 'plu-1750339',
        name: 'Apple',
        productType: ProductType.produce,
      );
      final enriched = await client.enrichProductWithServingData(product);

      expect(enriched, isNotNull);
      expect(enriched!.usdaServingAmount, 1.0);
      expect(enriched.usdaGramWeight, 182.0);
      expect(enriched.usdaServingUnit, 'fruit');
    });

    test('returns null when barcode has no plu- prefix', () async {
      const product = Product(
        barcode: 'produce-Apple',
        name: 'Apple',
        productType: ProductType.produce,
      );
      final enriched = await client.enrichProductWithServingData(product);
      expect(enriched, isNull);
    });

    test('returns null when detail endpoint throws network error', () async {
      when(() => mockClient.get(any())).thenThrow(
        Exception('Connection refused'),
      );

      const product = Product(
        barcode: 'plu-1750339',
        name: 'Apple',
        productType: ProductType.produce,
      );
      final enriched = await client.enrichProductWithServingData(product);
      expect(enriched, isNull);
    });

    test('sends api_key as query parameter on GET request', () async {
      when(() => mockClient.get(any())).thenAnswer(
        (_) async => http.Response(_detailResponseFoundation, 200),
      );

      const product = Product(
        barcode: 'plu-1750339',
        name: 'Apple',
        productType: ProductType.produce,
      );
      await client.enrichProductWithServingData(product);

      final captured = verify(() => mockClient.get(captureAny())).captured;
      final uri = captured[0] as Uri;
      expect(uri.path, contains('/v1/food/1750339'));
      expect(uri.queryParameters['api_key'], 'test-key');
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

const _detailResponseFoundation = '''
{
  "fdcId": 1750339,
  "dataType": "Foundation",
  "description": "Apple, raw, with skin",
  "foodNutrients": [
    {"nutrientId": 1008, "value": 52.0},
    {"nutrientId": 1003, "value": 0.26},
    {"nutrientId": 1005, "value": 13.81},
    {"nutrientId": 1004, "value": 0.17},
    {"nutrientId": 1079, "value": 2.4}
  ],
  "foodPortions": [
    {
      "id": 476860,
      "amount": 1.0,
      "gramWeight": 182.0,
      "portionDescription": "apple, medium",
      "modifier": "medium",
      "measureUnit": {"id": 999, "name": "fruit"}
    }
  ]
}
''';

const _detailResponseSRLegacy = '''
{
  "fdcId": 170379,
  "dataType": "SR Legacy",
  "description": "Broccoli, raw",
  "foodNutrients": [
    {"nutrientId": 1008, "value": 34.0}
  ]
}
''';

const _detailResponseEmptyPortions = '''
{
  "fdcId": 1750339,
  "dataType": "Foundation",
  "description": "Apple, raw, with skin",
  "foodPortions": []
}
''';

const _detailResponseMultiplePortions = '''
{
  "fdcId": 1750339,
  "dataType": "Foundation",
  "description": "Apple, raw, with skin",
  "foodPortions": [
    {
      "id": 476860,
      "amount": 1.0,
      "gramWeight": 182.0,
      "portionDescription": "apple, medium",
      "modifier": "medium",
      "measureUnit": {"id": 999, "name": "fruit"}
    },
    {
      "id": 476861,
      "amount": 1.0,
      "gramWeight": 125.0,
      "portionDescription": "apple, small",
      "modifier": "small",
      "measureUnit": {"id": 998, "name": "fruit"}
    }
  ]
}
''';

const _mixedTomatoResponse = '''
{
  "foods": [
    {
      "fdcId": 1750339,
      "description": "Tomatoes, raw",
      "foodNutrients": [
        {"nutrientId": 1008, "value": 18.0, "unitName": "KCAL"}
      ]
    },
    {
      "fdcId": 1750340,
      "description": "Tomato powder",
      "foodNutrients": [
        {"nutrientId": 1008, "value": 302.0, "unitName": "KCAL"}
      ]
    }
  ]
}
''';

const _cannedTomatoResponse = '''
{
  "foods": [
    {
      "fdcId": 1750339,
      "description": "Tomatoes, raw",
      "foodNutrients": [
        {"nutrientId": 1008, "value": 18.0, "unitName": "KCAL"}
      ]
    },
    {
      "fdcId": 1750341,
      "description": "Tomato sauce, canned",
      "foodNutrients": [
        {"nutrientId": 1008, "value": 24.0, "unitName": "KCAL"}
      ]
    }
  ]
}
''';

const _appleMixedResponse = '''
{
  "foods": [
    {
      "fdcId": 1750339,
      "description": "Apples, raw, with skin",
      "foodNutrients": [
        {"nutrientId": 1008, "value": 52.0, "unitName": "KCAL"}
      ]
    },
    {
      "fdcId": 1750342,
      "description": "Apples, dried",
      "foodNutrients": [
        {"nutrientId": 1008, "value": 243.0, "unitName": "KCAL"}
      ]
    }
  ]
}
''';

const _orangeMixedResponse = '''
{
  "foods": [
    {
      "fdcId": 1750343,
      "description": "Oranges, raw",
      "foodNutrients": [
        {"nutrientId": 1008, "value": 47.0, "unitName": "KCAL"}
      ]
    },
    {
      "fdcId": 1750344,
      "description": "Orange juice, raw",
      "foodNutrients": [
        {"nutrientId": 1008, "value": 45.0, "unitName": "KCAL"}
      ]
    }
  ]
}
''';

const _varietyTomatoResponse = '''
{
  "foods": [
    {
      "fdcId": 1750345,
      "description": "Cherry tomatoes, raw",
      "foodNutrients": [
        {"nutrientId": 1008, "value": 18.0, "unitName": "KCAL"}
      ]
    },
    {
      "fdcId": 1750346,
      "description": "Grape tomatoes, raw",
      "foodNutrients": [
        {"nutrientId": 1008, "value": 18.0, "unitName": "KCAL"}
      ]
    },
    {
      "fdcId": 1750347,
      "description": "Roma tomatoes, raw",
      "foodNutrients": [
        {"nutrientId": 1008, "value": 18.0, "unitName": "KCAL"}
      ]
    }
  ]
}
''';

const _bareNameResponse = '''
{
  "foods": [
    {
      "fdcId": 1750348,
      "description": "Tomatoes",
      "foodNutrients": [
        {"nutrientId": 1008, "value": 18.0, "unitName": "KCAL"}
      ]
    }
  ]
}
''';

const _allProcessedResponse = '''
{
  "foods": [
    {
      "fdcId": 1750349,
      "description": "Tomato powder",
      "foodNutrients": [
        {"nutrientId": 1008, "value": 302.0, "unitName": "KCAL"}
      ]
    },
    {
      "fdcId": 1750350,
      "description": "Tomato sauce, canned",
      "foodNutrients": [
        {"nutrientId": 1008, "value": 24.0, "unitName": "KCAL"}
      ]
    }
  ]
}
''';
