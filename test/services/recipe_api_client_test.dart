import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:pantry_app/services/recipe_api_client.dart';

class MockHttpClient extends Mock implements http.Client {}

void main() {
  setUpAll(() {
    registerFallbackValue(Uri.parse('https://example.com'));
    registerFallbackValue(<String, String>{});
  });

  group('RecipeApiClient', () {
    late MockHttpClient mockClient;
    late RecipeApiClient client;

    setUp(() {
      mockClient = MockHttpClient();
      client = RecipeApiClient(
        client: mockClient,
        contactEmail: 'pantry-app@example.com',
      );
    });

    test('returns suggestions parsed from a successful response', () async {
      when(
        () => mockClient.get(
          any(),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer(
        (_) async => http.Response(
          jsonEncode({
            'meals': [
              {'strMeal': 'Chicken Handi', 'idMeal': '52795'},
              {'strMeal': 'Spicy Arrabiata Penne', 'idMeal': '52771'},
            ],
          }),
          200,
        ),
      );

      final result = await client.filterByIngredients(['chicken']);

      expect(result, hasLength(2));
      expect(result.first.name, 'Chicken Handi');
      expect(result.first.idMeal, '52795');
      expect(result.last.name, 'Spicy Arrabiata Penne');
    });

    test('joins multiple ingredients with commas in the query', () async {
      when(
        () => mockClient.get(
          any(),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer(
        (_) async => http.Response(
          jsonEncode({
            'meals': [
              {'strMeal': 'Chicken Handi', 'idMeal': '52795'},
            ],
          }),
          200,
        ),
      );

      await client.filterByIngredients(['chicken', 'rice']);

      final captured = verify(
        () => mockClient.get(
          captureAny(),
          headers: any(named: 'headers'),
        ),
      ).captured;
      final uri = captured.single as Uri;
      expect(
        uri,
        Uri.parse(
          'https://www.themealdb.com/api/json/v1/1/filter.php?i=chicken%2Crice',
        ),
      );
      expect(uri.queryParameters['i'], 'chicken,rice');
    });

    test('returns empty list when meals is null', () async {
      when(
        () => mockClient.get(
          any(),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer(
        (_) async => http.Response(jsonEncode({'meals': null}), 200),
      );

      final result = await client.filterByIngredients(['carrot']);

      expect(result, isEmpty);
    });

    test('returns empty list on non-200 response', () async {
      when(
        () => mockClient.get(
          any(),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer(
        (_) async => http.Response('Server Error', 503),
      );

      final result = await client.filterByIngredients(['carrot']);

      expect(result, isEmpty);
    });

    test('returns empty list when the request throws', () async {
      when(
        () => mockClient.get(
          any(),
          headers: any(named: 'headers'),
        ),
      ).thenThrow(Exception('network down'));

      final result = await client.filterByIngredients(['carrot']);

      expect(result, isEmpty);
    });

    test('skips meals missing a name or id', () async {
      when(
        () => mockClient.get(
          any(),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer(
        (_) async => http.Response(
          jsonEncode({
            'meals': [
              {'strMeal': '', 'idMeal': '1'},
              {'strMeal': 'No Id', 'idMeal': ''},
              {'strMeal': 'Valid', 'idMeal': '2'},
            ],
          }),
          200,
        ),
      );

      final result = await client.filterByIngredients(['carrot']);

      expect(result, hasLength(1));
      expect(result.single.name, 'Valid');
      expect(result.single.idMeal, '2');
    });
  });
}
