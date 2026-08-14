import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:pantry_app/config.dart';
import 'package:pantry_app/models/recipe_suggestion.dart';
import 'package:pantry_app/utils/logger.dart';

/// HTTP client for the TheMealDB recipe API.
///
/// TheMealDB is free and requires no API key for the free tier
/// (`/api/json/v1/1`). The [filterByIngredients] endpoint returns meals
/// that contain at least one of the given ingredients, which is exactly
/// what the pantry recipe-suggestion feature needs.
///
/// See https://www.themealdb.com/api.php for the API documentation.
class RecipeApiClient {
  /// Creates a [RecipeApiClient].
  ///
  /// [client] is injected for testability and defaults to a real
  /// [http.Client]. [contactEmail] is included in the User-Agent header
  /// as a courtesy to the API maintainers and defaults to the configured
  /// contact email.
  RecipeApiClient({
    http.Client? client,
    String? contactEmail,
  }) : _client = client ?? http.Client(),
       _contactEmail = contactEmail ?? AppConfig.contactEmail;

  final http.Client _client;
  final String _contactEmail;

  /// Base URL of the TheMealDB free-tier API.
  static const _baseUrl = 'https://www.themealdb.com/api/json/v1/1';

  /// Queries TheMealDB for meals that contain at least one of [ingredients].
  ///
  /// Ingredient names are joined with commas (TheMealDB matches a meal if
  /// it contains any listed ingredient). Returns an empty list when the
  /// API returns no meals, an error occurs, or the response is malformed.
  Future<List<RecipeSuggestion>> filterByIngredients(
    List<String> ingredients,
  ) async {
    final query = ingredients.join(',');
    final uri = Uri.parse('$_baseUrl/filter.php').replace(
      queryParameters: {'i': query},
    );

    try {
      final response = await _client.get(
        uri,
        headers: {
          'User-Agent': 'PantryApp ($_contactEmail)',
        },
      );
      if (response.statusCode != 200) {
        logWarning('TheMealDB returned ${response.statusCode}');
        return const [];
      }

      final decoded = jsonDecode(response.body);
      final meals = decoded is Map<String, dynamic> ? decoded['meals'] : null;
      if (meals is! List) return const [];

      final suggestions = <RecipeSuggestion>[];
      for (final meal in meals) {
        if (meal is! Map<String, dynamic>) continue;
        final name = meal['strMeal'];
        final id = meal['idMeal'];
        if (name is! String || name.isEmpty) continue;
        if (id is! String || id.isEmpty) continue;
        suggestions.add(RecipeSuggestion(name: name, idMeal: id));
      }
      logInfo('TheMealDB returned ${suggestions.length} suggestions');
      return suggestions;
    } on Exception catch (e) {
      logWarning('TheMealDB request failed: $e');
      return const [];
    }
  }

  /// Closes the underlying HTTP client.
  void dispose() {
    _client.close();
  }
}
