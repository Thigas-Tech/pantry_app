import 'dart:convert';

// The .autoDispose.family type is inferred from the value expression.
// ignore_for_file: specify_nonobvious_property_types

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/database/recipe_dao.dart';
import 'package:pantry_app/database/recipe_ingredient_dao.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/models/recipe.dart';
import 'package:pantry_app/models/recipe_ingredient.dart';
import 'package:pantry_app/models/recipe_nutrition.dart';
import 'package:pantry_app/providers/active_inventory_provider.dart';
import 'package:pantry_app/providers/database_provider.dart';
import 'package:pantry_app/providers/pantry_provider.dart';
import 'package:pantry_app/providers/product_repository_provider.dart';
import 'package:pantry_app/providers/settings_provider.dart';
import 'package:pantry_app/services/currency_service.dart';
import 'package:pantry_app/services/exceptions.dart';
import 'package:pantry_app/services/produce_barcode.dart';
import 'package:pantry_app/services/produce_serving_presets.dart';
import 'package:pantry_app/services/product_repository.dart';
import 'package:pantry_app/services/recipe_nutri_score_service.dart';
import 'package:pantry_app/services/recipe_nutrition_service.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:pantry_app/utils/unit_conversion.dart';

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
final FutureProvider<List<Recipe>> allRecipesProvider =
    FutureProvider.autoDispose<List<Recipe>>((ref) {
      final db = ref.watch(databaseProvider);
      return db.getAllRecipes();
    });

/// Provides ingredients for a specific recipe.
final allRecipeIngredientsProvider = FutureProvider.autoDispose
    .family<List<RecipeIngredient>, int>(
      (ref, recipeId) {
        final db = ref.watch(databaseProvider);
        return db.getRecipeIngredients(recipeId);
      },
    );

/// Invalidates all recipe-related providers.
///
/// Call this after every mutation so the UI refreshes. Invalidation is
/// deferred to the next frame via [WidgetsBinding.addPostFrameCallback] to
/// prevent build-phase crashes when called from async gaps (e.g. database
/// transactions).
void invalidateRecipes(WidgetRef ref) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    ref.invalidate(allRecipesProvider);
  });
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
  int servings = 0,
  String imagePath = '',
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
      servings: servings,
      imagePath: imagePath,
      updatedAt: now,
    );
    await db.updateRecipeWithIngredients(recipe, ingredients);
    logInfo('Recipe $existingRecipeId updated: $name');
  } else {
    final recipe = Recipe(
      name: name.trim(),
      instructions: instructions.trim(),
      servings: servings,
      imagePath: imagePath,
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

/// Provides aggregated nutrition data for a recipe.
///
/// Returns [RecipeNutrition] computed from the recipe's ingredients and their
/// product nutrition data. Auto-disposes when no listener remains.
final recipeNutritionProvider = FutureProvider.autoDispose
    .family<RecipeNutrition?, int>(
      (ref, recipeId) async {
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
      },
    );

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
final recipeIngredientsWithProductsProvider = FutureProvider.autoDispose
    .family<List<IngredientWithProduct>, int>(
      (ref, recipeId) async {
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
                product: ing.barcode != null
                    ? productsByBarcode[ing.barcode]
                    : null,
              ),
            )
            .toList();
      },
    );

/// Provides the Nutri-Score grade for a recipe.
///
/// Returns a grade letter ('A'–'E') or null if not enough ingredients have
/// known scores.
final recipeNutriScoreProvider = FutureProvider.autoDispose
    .family<String?, int>(
      (ref, recipeId) async {
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
      },
    );

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

/// Groups [ingredients] by barcode, sums quantities, normalizes units, and
/// checks availability against inventory.
///
/// Returns a map of ingredient name -> deficit, or empty map if all
/// ingredients are sufficiently stocked. Ingredients without a barcode are
/// skipped.
Future<Map<String, double>> checkIngredientShortages(
  DatabaseHelper db,
  List<RecipeIngredient> ingredients,
  int activeInventoryId,
) async {
  final grouped = <String, _GroupedIngredient>{};
  for (final ing in ingredients) {
    if (ing.barcode == null || ing.barcode!.isEmpty) continue;
    grouped.putIfAbsent(
      ing.barcode!,
      () => _GroupedIngredient(name: ing.name, unit: ing.unit),
    );
    grouped[ing.barcode!]!.totalQuantity += ing.quantity;
  }

  final shortages = <String, double>{};
  for (final entry in grouped.entries) {
    final barcode = normalizeProduceBarcode(entry.key);
    final grp = entry.value;
    var rows = await db.getInventoryRowsByBarcode(
      barcode: barcode,
      inventoryId: activeInventoryId,
    );
    if (rows.isEmpty && grp.name.isNotEmpty) {
      rows = await db.getInventoryRowsByProductName(
        name: grp.name,
        inventoryId: activeInventoryId,
      );
    }
    var available = 0.0;
    for (final row in rows) {
      final rowQty = (row['quantity']! as num).toDouble();
      final rowUnit = row['unit'] as String? ?? 'pieces';
      if (UnitConverter.areUnitsCompatible(grp.unit, rowUnit)) {
        available += UnitConverter.convert(rowQty, rowUnit, grp.unit);
      } else {
        final svG = _resolveServingWeightG(row, grp.name);
        if (svG != null && svG > 0) {
          final grpIsWeight = UnitConverter.areUnitsCompatible(grp.unit, 'g');
          final rowIsWeight = UnitConverter.areUnitsCompatible(rowUnit, 'g');
          if (grpIsWeight && !rowIsWeight) {
            available += rowQty * svG;
          } else if (!grpIsWeight && rowIsWeight) {
            available += UnitConverter.convert(rowQty, rowUnit, 'g') / svG;
          } else if (!grpIsWeight && !rowIsWeight) {
            available += rowQty;
          }
        }
      }
    }
    if (available < grp.totalQuantity) {
      shortages[grp.name] = grp.totalQuantity - available;
    }
  }
  return shortages;
}

class _GroupedIngredient {
  _GroupedIngredient({required this.name, required this.unit});
  final String name;
  final String unit;
  double totalQuantity = 0;
}

/// Tries to resolve a per-piece serving weight in grams for an inventory row.
///
/// Checks the inventory row's serving_weight_g column first, then falls back
/// to [ProduceServingPresets] using the ingredient name. Returns null when no
/// serving weight can be determined.
double? _resolveServingWeightG(Map<String, dynamic> row, String name) {
  final fromRow = (row['serving_weight_g'] as num?)?.toDouble();
  if (fromRow != null && fromRow > 0) return fromRow;
  final presets = ProduceServingPresets.forName(name);
  return presets?['Medium'] ?? presets?.values.firstOrNull;
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

  if (ingredients.isEmpty) throw const RecipeCookException({});

  // Pre-flight validation with grouping and unit normalization
  final shortages = await checkIngredientShortages(
    db,
    ingredients,
    activeInventoryId,
  );
  if (shortages.isNotEmpty) {
    throw RecipeCookException(shortages);
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

  final grouped = <String, _GroupedIngredient>{};
  for (final ing in ingredients) {
    if (ing.barcode == null || ing.barcode!.isEmpty) continue;
    grouped.putIfAbsent(
      ing.barcode!,
      () => _GroupedIngredient(name: ing.name, unit: ing.unit),
    );
    grouped[ing.barcode!]!.totalQuantity += ing.quantity;
  }

  return database
      .transaction<CookResult>((txn) async {
        for (final entry in grouped.entries) {
          final barcode = normalizeProduceBarcode(entry.key);
          var remaining = entry.value.totalQuantity;
          var rows = await txn.rawQuery(
            'SELECT * FROM inventory WHERE barcode = ? AND inventory_id = ?'
            ' ORDER BY expiry_date ASC NULLS LAST',
            [barcode, activeInventoryId],
          );
          if (rows.isEmpty && entry.value.name.isNotEmpty) {
            final normalizedName = entry.value.name.trim().toLowerCase();
            rows = await txn.rawQuery(
              'SELECT i.* FROM inventory i'
              ' INNER JOIN products p ON p.barcode = i.barcode'
              ' WHERE LOWER(p.name) LIKE ? AND i.inventory_id = ?'
              ' ORDER BY i.expiry_date ASC NULLS LAST',
              ['%$normalizedName%', activeInventoryId],
            );
          }
          for (final row in rows) {
            if (remaining <= 0) break;
            final rowId = row['id']! as int;
            final rowQty = (row['quantity']! as num).toDouble();
            final rowUnit = row['unit'] as String? ?? 'pieces';
            double effectiveQty;
            double Function(double consumed) toRowUnits;
            if (UnitConverter.areUnitsCompatible(
              entry.value.unit,
              rowUnit,
            )) {
              effectiveQty = UnitConverter.convert(
                rowQty,
                rowUnit,
                entry.value.unit,
              );
              toRowUnits = (c) => UnitConverter.convertBack(c, rowUnit);
            } else {
              final svG = _resolveServingWeightG(row, entry.value.name);
              if (svG != null && svG > 0) {
                final entryIsWeight = UnitConverter.areUnitsCompatible(
                  entry.value.unit,
                  'g',
                );
                final rowIsWeight = UnitConverter.areUnitsCompatible(
                  rowUnit,
                  'g',
                );
                if (!entryIsWeight && rowIsWeight) {
                  effectiveQty =
                      UnitConverter.convert(rowQty, rowUnit, 'g') / svG;
                  toRowUnits = (c) => c * svG;
                } else if (entryIsWeight && !rowIsWeight) {
                  effectiveQty = rowQty * svG;
                  toRowUnits = (c) => c / svG;
                } else if (!entryIsWeight && !rowIsWeight) {
                  effectiveQty = rowQty;
                  toRowUnits = (c) => c;
                } else {
                  effectiveQty = 0;
                  toRowUnits = (_) => 0;
                }
              } else {
                effectiveQty = 0;
                toRowUnits = (_) => 0;
              }
            }
            final consumed = effectiveQty < remaining
                ? effectiveQty
                : remaining;
            affectedRows.add(
              InventoryRowSnapshot(
                rowId: rowId,
                originalQuantity: rowQty,
                originalRow: Map<String, dynamic>.from(row),
              ),
            );
            final remainingInRowUnits = rowQty - toRowUnits(consumed);
            if (remainingInRowUnits > 0.001) {
              await txn.update(
                'inventory',
                {'quantity': remainingInRowUnits},
                where: 'id = ?',
                whereArgs: [rowId],
              );
            } else {
              await txn.delete(
                'inventory',
                where: 'id = ?',
                whereArgs: [rowId],
              );
            }
            remaining -= consumed;
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
        WidgetsBinding.instance.addPostFrameCallback((_) {
          invalidateRecipes(ref);
          ref.invalidate(pantryProvider);
        });
        return result;
      });
}
