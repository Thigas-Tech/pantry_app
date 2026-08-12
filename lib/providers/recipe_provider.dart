import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/models/recipe.dart';
import 'package:pantry_app/models/recipe_ingredient.dart';
import 'package:pantry_app/models/recipe_nutrition.dart';
import 'package:pantry_app/providers/active_inventory_provider.dart';
import 'package:pantry_app/providers/database_provider.dart';
import 'package:pantry_app/providers/product_repository_provider.dart';
import 'package:pantry_app/services/product_repository.dart';
import 'package:pantry_app/services/recipe_nutri_score_service.dart';
import 'package:pantry_app/services/recipe_nutrition_service.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'recipe_provider.g.dart';

/// Provides all recipes for the active inventory, ordered by updated_at
/// descending.
///
/// Watches [activeInventoryProvider] so the list automatically reloads when
/// the user switches pantries.
@riverpod
Future<List<Recipe>> allRecipes(Ref ref) async {
  final db = ref.watch(databaseProvider);
  final activeId = await ref.watch(activeInventoryProvider.future);
  return db.getAllRecipes(activeId);
}

/// Provides ingredients for a specific recipe.
@riverpod
Future<List<RecipeIngredient>> allRecipeIngredients(Ref ref, int recipeId) {
  final db = ref.watch(databaseProvider);
  return db.getRecipeIngredients(recipeId);
}

/// Invalidates all recipe-related providers.
///
/// Call this after every mutation so the UI refreshes. The
/// [BuildContext.mounted] guard prevents crashes when the widget has been
/// disposed before the invalidation runs, such as during widget tests.
void invalidateRecipes(WidgetRef ref) {
  if (ref.context.mounted) {
    ref.invalidate(allRecipesProvider);
  }
}

/// Provides aggregated nutrition data for a recipe.
///
/// Returns [RecipeNutrition] computed from the recipe's ingredients and their
/// product nutrition data. Auto-disposes when no listener remains.
@riverpod
Future<RecipeNutrition?> recipeNutrition(Ref ref, int recipeId) async {
  ref.keepAlive();
  final db = ref.watch(databaseProvider);
  final repo = ref.read(productRepositoryProvider);
  final ingredients = await db.getRecipeIngredients(recipeId);
  if (ingredients.isEmpty) return null;

  final recipe = await db.getRecipe(recipeId);
  final servings = recipe?.servings ?? 0;

  final barcodes = ingredients
      .map((i) => i.barcode)
      .where((b) => b != null && b.isNotEmpty)
      .cast<String>()
      .toSet()
      .toList();

  final productsByBarcode = <String, Product>{};
  for (final barcode in barcodes) {
    try {
      final product = await repo.getProduct(barcode);
      productsByBarcode[barcode] = product;
    } on Exception catch (e) {
      logWarning(
        'Could not fetch product $barcode for recipe nutrition: $e',
      );
    }
  }

  final nutritionService = RecipeNutritionService();
  return nutritionService.aggregate(
    ingredients,
    productsByBarcode,
    servings: servings,
  );
}

/// A record pairing a [RecipeIngredient] with its optional [Product].
///
/// The product is null if the ingredient has no barcode or the product is not
/// in the local database.
typedef IngredientWithProduct = ({
  RecipeIngredient ingredient,
  Product? product,
});

/// Provides ingredients with their product data (including image URL).
///
/// Fetches each ingredient's product via [ProductRepository] so that images
/// are available for display. Ingredients without a barcode get a null
/// product.
@riverpod
Future<List<IngredientWithProduct>> recipeIngredientsWithProducts(
  Ref ref,
  int recipeId,
) async {
  ref.keepAlive();
  final db = ref.watch(databaseProvider);
  final repo = ref.read(productRepositoryProvider);
  final ingredients = await db.getRecipeIngredients(recipeId);

  final barcodes = ingredients
      .map((i) => i.barcode)
      .where((b) => b != null && b.isNotEmpty)
      .cast<String>()
      .toSet()
      .toList();

  final productsByBarcode = <String, Product>{};
  for (final barcode in barcodes) {
    try {
      final product = await repo.getProduct(barcode);
      productsByBarcode[barcode] = product;
    } on Exception catch (e) {
      logWarning(
        'Could not fetch product $barcode for ingredient image: $e',
      );
    }
  }

  return ingredients
      .map(
        (ing) => (
          ingredient: ing,
          product: ing.barcode != null ? productsByBarcode[ing.barcode] : null,
        ),
      )
      .toList();
}

/// Provides the Nutri-Score grade for a recipe.
///
/// Returns a grade letter ('A'–'E') or null if not enough ingredients have
/// known scores.
@riverpod
Future<String?> recipeNutriScore(Ref ref, int recipeId) async {
  ref.keepAlive();
  final db = ref.watch(databaseProvider);
  final ingredients = await db.getRecipeIngredients(recipeId);
  if (ingredients.isEmpty) return null;

  final barcodes = ingredients
      .map((i) => i.barcode)
      .where((b) => b != null && b.isNotEmpty)
      .cast<String>()
      .toSet()
      .toList();

  final productsByBarcode = <String, Product>{};
  for (final barcode in barcodes) {
    final product = await db.getProduct(barcode);
    if (product != null) {
      productsByBarcode[barcode] = product;
    }
  }

  final scoreService = RecipeNutriScoreService();
  return scoreService.compute(ingredients, productsByBarcode);
}
