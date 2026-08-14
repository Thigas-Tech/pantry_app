import 'package:pantry_app/services/recipe_api_client.dart';
import 'package:pantry_app/services/recipe_suggestion_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'recipe_suggestion_provider.g.dart';

/// Provides the shared [RecipeApiClient] instance.
///
/// keepAlive because recipe suggestion lookup is used by the notification
/// coordinator on startup and by the settings screen for the whole session.
@Riverpod(keepAlive: true)
RecipeApiClient recipeApiClient(Ref ref) {
  return RecipeApiClient();
}

/// Provides the shared [RecipeSuggestionService] instance.
///
/// keepAlive for the same reason as [recipeApiClientProvider].
@Riverpod(keepAlive: true)
RecipeSuggestionService recipeSuggestionService(Ref ref) {
  return RecipeSuggestionService(
    api: ref.read(recipeApiClientProvider),
  );
}
