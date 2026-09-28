import 'package:pantry_app/providers/database_provider.dart';
import 'package:pantry_app/services/recipe_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'recipe_service_provider.g.dart';

/// Provides the singleton [RecipeService] used by screens and the recipe
/// providers.
///
/// Kept alive for the app lifetime; the service holds no per-inventory
/// state, so a single instance is safe.
@Riverpod(keepAlive: true)
RecipeService recipeService(Ref ref) {
  return RecipeService(ref.read(databaseProvider));
}
