import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/database/recipe_dao.dart';
import 'package:pantry_app/database/recipe_ingredient_dao.dart';
import 'package:pantry_app/models/recipe.dart';
import 'package:pantry_app/models/recipe_ingredient.dart';
import 'package:pantry_app/providers/active_inventory_provider.dart';
import 'package:pantry_app/providers/database_provider.dart';
import 'package:pantry_app/providers/pantry_provider.dart';
import 'package:pantry_app/providers/settings_provider.dart';
import 'package:pantry_app/services/currency_service.dart';
import 'package:pantry_app/utils/logger.dart';

/// Provides a singleton [RecipeDao] instance.
final recipeDaoProvider = Provider<RecipeDao>((ref) {
  return const RecipeDao();
});

/// Provides a singleton [RecipeIngredientDao] instance.
final recipeIngredientDaoProvider = Provider<RecipeIngredientDao>((ref) {
  return const RecipeIngredientDao();
});

final _currencyServiceProvider = Provider<CurrencyService>((ref) {
  return CurrencyService();
});

/// Provides all recipes, ordered by updated_at descending.
final allRecipesProvider = FutureProvider.autoDispose<List<Recipe>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.getAllRecipes();
});

/// Provides ingredients for a specific recipe.
final allRecipeIngredientsProvider = FutureProvider.autoDispose
    .family<List<RecipeIngredient>, int>((
      ref,
      recipeId,
    ) {
      final db = ref.watch(databaseProvider);
      return db.getRecipeIngredients(recipeId);
    });

/// Invalidates all recipe-related providers.
///
/// Call this after every mutation so the UI refreshes.
void invalidateRecipes(WidgetRef ref) {
  ref.invalidate(allRecipesProvider);
}

/// Saves a recipe — creates a new one or updates an existing one.
///
/// If [existingRecipeId] is null, a new recipe is created with the given
/// [name], [instructions], and [ingredients]. If [existingRecipeId] is
/// provided, the recipe and its ingredients are updated.
///
/// Throws [ArgumentError] if [name] is empty.
Future<void> saveRecipe(
  WidgetRef ref, {
  required String name,
  required List<RecipeIngredient> ingredients,
  int? existingRecipeId,
  String instructions = '',
}) async {
  if (name.trim().isEmpty) {
    throw ArgumentError('Recipe name is required');
  }

  final db = ref.read(databaseProvider);
  final now = DateTime.now().millisecondsSinceEpoch;

  if (existingRecipeId != null) {
    final recipe = Recipe(
      id: existingRecipeId,
      name: name.trim(),
      instructions: instructions.trim(),
      updatedAt: now,
    );
    await db.updateRecipeWithIngredients(recipe, ingredients);
    logInfo('Recipe $existingRecipeId updated: $name');
  } else {
    final recipe = Recipe(
      name: name.trim(),
      instructions: instructions.trim(),
      createdAt: now,
      updatedAt: now,
    );
    await db.insertRecipeWithIngredients(recipe, ingredients);
    logInfo('Recipe created: $name');
  }

  invalidateRecipes(ref);
}

/// Deletes a recipe by [id]. Invalidates providers on success.
Future<void> deleteRecipe(WidgetRef ref, int id) async {
  final db = ref.read(databaseProvider);
  await db.deleteRecipe(id);
  logInfo('Recipe $id deleted');
  invalidateRecipes(ref);
}

/// Calculates the total cost of a recipe by summing ingredient prices.
///
/// For each ingredient with a barcode, the most recent price from the
/// prices table is fetched and converted to the user's base currency.
/// Ingredients without a barcode contribute zero to the total.
///
/// Returns 0.0 if no ingredients have price data.
Future<double> calculateRecipeCost(WidgetRef ref, int recipeId) async {
  final db = ref.read(databaseProvider);
  final ingredients = await db.getRecipeIngredients(recipeId);
  final settings = ref.read(settingsProvider);
  final baseCurrency = settings.baseCurrency;
  final currencyService = ref.read(_currencyServiceProvider);

  if (ingredients.isEmpty) return 0.0;

  final database = await db.database;
  var total = 0.0;
  for (final ingredient in ingredients) {
    if (ingredient.barcode == null || ingredient.barcode!.isEmpty) continue;

    final rows = await database.rawQuery(
      'SELECT price, currency FROM prices'
      ' WHERE barcode = ?'
      ' ORDER BY date_purchased DESC LIMIT 1',
      [ingredient.barcode],
    );
    if (rows.isEmpty) continue;

    final price = (rows.first['price'] as num?)?.toDouble() ?? 0.0;
    final currency = rows.first['currency'] as String? ?? baseCurrency;

    final converted = await currencyService.convert(
      price,
      currency,
      baseCurrency,
    );
    total += converted;
  }

  return total;
}

/// Calculates the average cost across all recipes.
///
/// Returns 0.0 if no recipes exist (guards division by zero).
Future<double> calculateAverageRecipeCost(WidgetRef ref) async {
  final db = ref.read(databaseProvider);
  final recipes = await db.getAllRecipes();
  if (recipes.isEmpty) return 0.0;

  var totalCost = 0.0;
  for (final recipe in recipes) {
    final cost = await calculateRecipeCost(ref, recipe.id!);
    totalCost += cost;
  }

  return totalCost / recipes.length;
}

/// Returned by [cookRecipe] with data needed for undo.
class CookResult {
  /// Creates a [CookResult].
  const CookResult({
    required this.historyEntryId,
    required this.affectedRows,
  });

  /// The id of the inserted recipe_history row.
  final int historyEntryId;

  /// Each inventory row that was modified during the cook.
  final List<InventoryRowSnapshot> affectedRows;
}

/// A snapshot of an inventory row before it was modified by cooking.
///
/// Stores the full original row so the undo callback can accurately re-insert
/// or restore the row to its pre-cook state.
class InventoryRowSnapshot {
  /// Creates an [InventoryRowSnapshot].
  const InventoryRowSnapshot({
    required this.rowId,
    required this.originalQuantity,
    required this.originalRow,
  });

  /// The inventory row id.
  final int rowId;

  /// The quantity before the cook deduction.
  final double originalQuantity;

  /// Full row data as a mutable map, used by undo to re-insert deleted rows.
  final Map<String, dynamic> originalRow;
}

/// Cooks a recipe: deducts ingredients from inventory (FEFO) and logs history.
///
/// Throws [StateError] with shortage details if any ingredient has
/// insufficient stock. Returns a [CookResult] for undo support.
Future<CookResult> cookRecipe(WidgetRef ref, int recipeId) async {
  final db = ref.read(databaseProvider);
  final activeInventoryId = ref.read(activeInventoryProvider);
  final ingredients = await db.getRecipeIngredients(recipeId);
  final settings = ref.read(settingsProvider);
  final currencyService = CurrencyService();
  final baseCurrency = settings.baseCurrency;

  if (ingredients.isEmpty) throw StateError('Recipe has no ingredients');

  // Pre-flight validation
  final shortages = <String, double>{};
  for (final ing in ingredients) {
    if (ing.barcode == null || ing.barcode!.isEmpty) continue;
    final rows = await db.getInventoryRowsByBarcode(
      barcode: ing.barcode!,
      inventoryId: activeInventoryId,
    );
    final available = rows.fold<double>(
      0,
      (sum, r) => sum + (r['quantity']! as num).toDouble(),
    );
    if (available < ing.quantity)
      shortages[ing.name] = ing.quantity - available;
  }
  if (shortages.isNotEmpty) {
    final details = shortages.entries
        .map((e) => 'Not enough ${e.key}: need ${e.value} more')
        .join('; ');
    throw StateError(details);
  }

  // Compute current cost
  final database = await db.database;
  var totalCost = 0.0;
  for (final ing in ingredients) {
    if (ing.barcode == null || ing.barcode!.isEmpty) continue;
    final rows = await database.rawQuery(
      'SELECT price, currency FROM prices'
      ' WHERE barcode = ?'
      ' ORDER BY date_purchased DESC LIMIT 1',
      [ing.barcode],
    );
    if (rows.isEmpty) continue;
    final price = (rows.first['price'] as num?)?.toDouble() ?? 0.0;
    final currency = rows.first['currency'] as String? ?? baseCurrency;
    totalCost += await currencyService.convert(price, currency, baseCurrency);
  }

  // Transaction: FEFO deduction + history
  final affectedRows = <InventoryRowSnapshot>[];

  return database
      .transaction<CookResult>((txn) async {
        for (final ing in ingredients) {
          if (ing.barcode == null || ing.barcode!.isEmpty) continue;
          var remaining = ing.quantity;
          final rows = await txn.rawQuery(
            'SELECT * FROM inventory WHERE barcode = ? AND inventory_id = ?'
            ' ORDER BY expiry_date ASC NULLS LAST',
            [ing.barcode, activeInventoryId],
          );
          for (final row in rows) {
            if (remaining <= 0) break;
            final rowId = row['id']! as int;
            final rowQty = (row['quantity']! as num).toDouble();
            affectedRows.add(
              InventoryRowSnapshot(
                rowId: rowId,
                originalQuantity: rowQty,
                originalRow: Map<String, dynamic>.from(row),
              ),
            );
            if (rowQty > remaining) {
              await txn.update(
                'inventory',
                {'quantity': rowQty - remaining},
                where: 'id = ?',
                whereArgs: [rowId],
              );
              remaining = 0;
            } else {
              await txn.delete(
                'inventory',
                where: 'id = ?',
                whereArgs: [rowId],
              );
              remaining -= rowQty;
            }
          }
        }

        final snapshotJson = const JsonEncoder().convert(
          ingredients
              .map(
                (ing) => {
                  'barcode': ing.barcode,
                  'name': ing.name,
                  'quantity': ing.quantity,
                  'unit': ing.unit,
                },
              )
              .toList(),
        );

        final historyId = await txn.insert('recipe_history', {
          'recipe_id': recipeId,
          'made_at': DateTime.now().millisecondsSinceEpoch,
          'cost_at_time': totalCost,
          'ingredient_snapshot': snapshotJson,
        });

        return CookResult(
          historyEntryId: historyId,
          affectedRows: affectedRows,
        );
      })
      .then((result) {
        invalidateRecipes(ref);
        ref.invalidate(pantryProvider);
        return result;
      });
}
