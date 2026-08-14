import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pantry_app/models/recipe_suggestion.dart';
import 'package:pantry_app/services/recipe_api_client.dart';
import 'package:pantry_app/services/recipe_suggestion_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockRecipeApiClient extends Mock implements RecipeApiClient {}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('RecipeSuggestionService', () {
    late MockRecipeApiClient api;
    late RecipeSuggestionService service;

    const chickenHandi = RecipeSuggestion(name: 'Chicken Handi', idMeal: '1');
    const penne = RecipeSuggestion(
      name: 'Spicy Arrabiata Penne',
      idMeal: '2',
    );
    const curry = RecipeSuggestion(name: 'Curry', idMeal: '3');

    setUp(() {
      api = MockRecipeApiClient();
      when(() => api.filterByIngredients(any())).thenAnswer(
        (_) async => [chickenHandi, penne, curry],
      );
      service = RecipeSuggestionService(
        api: api,
        random: Random(42),
      );
    });

    test('returns null when the ingredient list is empty', () async {
      final result = await service.pickSuggestion([]);

      expect(result, isNull);
      verifyNever(() => api.filterByIngredients(any()));
    });

    test('queries the API with the given ingredients', () async {
      await service.pickSuggestion(['chicken', 'rice']);

      verify(() => api.filterByIngredients(['chicken', 'rice'])).called(1);
    });

    test('returns null when the API returns no suggestions', () async {
      when(() => api.filterByIngredients(any())).thenAnswer((_) async => []);

      final result = await service.pickSuggestion(['chicken']);

      expect(result, isNull);
    });

    test('returns a suggestion and persists it as last suggested', () async {
      final result = await service.pickSuggestion(['chicken']);

      expect(result, isNotNull);
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString(RecipeSuggestionService.lastSuggestedKey),
        result!.idMeal,
      );
    });

    test(
      'excludes the last suggested recipe when more than one exists',
      () async {
        final first = await service.pickSuggestion(['chicken']);

        // Stub a fresh service that has read the persisted last suggestion.
        final service2 = RecipeSuggestionService(
          api: api,
          random: Random(42),
        );
        final second = await service2.pickSuggestion(['chicken']);

        expect(second, isNotNull);
        expect(second!.idMeal, isNot(first!.idMeal));
      },
    );

    test(
      'falls back to the full pool when only one candidate exists',
      () async {
        when(() => api.filterByIngredients(any())).thenAnswer(
          (_) async => [chickenHandi],
        );
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(RecipeSuggestionService.lastSuggestedKey, '1');

        final result = await service.pickSuggestion(['chicken']);

        expect(result, isNotNull);
        expect(result!.idMeal, '1');
      },
    );
  });
}
