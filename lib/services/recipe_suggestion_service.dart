import 'dart:math';

import 'package:pantry_app/models/recipe_suggestion.dart';
import 'package:pantry_app/services/recipe_api_client.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Picks a personalised recipe suggestion from a [RecipeApiClient].
///
/// Given the user's inventory ingredient names, queries the recipe API,
/// excludes the last-suggested recipe (so the same meal is not offered
/// twice in a row), and picks one at random. The chosen recipe id is
/// persisted in [SharedPreferences] as `lastSuggestedRecipe`.
class RecipeSuggestionService {
  /// Creates a [RecipeSuggestionService].
  ///
  /// [_api] is injected for testability. [random] is injectable so tests
  /// can force a deterministic choice; it defaults to [Random].
  RecipeSuggestionService({
    required this._api,
    Random? random,
  }) : _random = random ?? Random();

  final RecipeApiClient _api;
  final Random _random;

  /// SharedPreferences key holding the last suggested recipe id.
  static const lastSuggestedKey = 'lastSuggestedRecipe';

  /// Fetches recipe candidates for [ingredientNames] and returns one at
  /// random, excluding the most recent suggestion.
  ///
  /// Returns null when [ingredientNames] is empty, the API returns no
  /// matches, or an error occurs.
  Future<RecipeSuggestion?> pickSuggestion(List<String> ingredientNames) async {
    if (ingredientNames.isEmpty) {
      logInfo('No ingredient names, skipping recipe suggestion');
      return null;
    }

    final candidates = await _api.filterByIngredients(ingredientNames);
    if (candidates.isEmpty) {
      logWarning('No recipe suggestions returned by the API');
      return null;
    }

    final prefs = await SharedPreferences.getInstance();
    final lastSuggested = prefs.getString(lastSuggestedKey);

    var pool = candidates;
    if (lastSuggested != null && candidates.length > 1) {
      final filtered = candidates
          .where((s) => s.idMeal != lastSuggested)
          .toList();
      if (filtered.isNotEmpty) pool = filtered;
    }

    final choice = pool[_random.nextInt(pool.length)];
    await prefs.setString(lastSuggestedKey, choice.idMeal);
    logInfo('Selected recipe suggestion: ${choice.name}');
    return choice;
  }
}
