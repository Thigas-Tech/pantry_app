import 'package:pantry_app/providers/currency_service_provider.dart';
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
  return RecipeService(
    ref.read(databaseProvider),
    ref.read(currencyServiceProvider),
  );
}

/// Provides the cost of a single recipe for the given inventory and base
/// currency.
///
/// Keyed by a (recipeId, inventoryId, baseCurrency) record so the cost
/// query is cached across rebuilds and only recomputed when one of the
/// inputs changes.
@riverpod
Future<double> recipeCost(Ref ref, (int, int, String) args) {
  final (recipeId, inventoryId, baseCurrency) = args;
  return ref
      .read(recipeServiceProvider)
      .calculateRecipeCost(
        recipeId,
        activeInventoryId: inventoryId,
        baseCurrency: baseCurrency,
      );
}

/// Provides the average cost across all recipes for the given inventory
/// and base currency.
///
/// Keyed by a (inventoryId, baseCurrency) record so the cost query is
/// cached across rebuilds.
@riverpod
Future<double> averageRecipeCost(Ref ref, (int, String) args) {
  final (inventoryId, baseCurrency) = args;
  return ref
      .read(recipeServiceProvider)
      .calculateAverageRecipeCost(
        activeInventoryId: inventoryId,
        baseCurrency: baseCurrency,
      );
}

/// Provides the scaled cost per ingredient for a recipe, keyed by the
/// ingredient barcode.
///
/// Keyed by a (recipeId, inventoryId, baseCurrency) record. The recipe's
/// own inventory wins over the active one, matching [recipeCost].
/// Ingredients without a barcode or without a recorded price are absent
/// from the map.
@riverpod
Future<Map<String, double>> recipeIngredientCosts(
  Ref ref,
  (int, int, String) args,
) async {
  final (recipeId, activeInventoryId, baseCurrency) = args;
  final db = ref.read(databaseProvider);
  final recipe = await db.getRecipe(recipeId);
  final inventoryId = recipe?.inventoryId ?? activeInventoryId;
  final ingredients = await db.getRecipeIngredients(recipeId);
  return ref
      .read(recipeServiceProvider)
      .ingredientCosts(
        ingredients,
        inventoryId: inventoryId,
        baseCurrency: baseCurrency,
      );
}
