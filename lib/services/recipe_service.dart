import 'dart:async';
import 'dart:convert';

import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/models/recipe.dart';
import 'package:pantry_app/models/recipe_ingredient.dart';
import 'package:pantry_app/services/exceptions.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:pantry_app/utils/unit_conversion.dart';

/// Groups ingredients by barcode with a summed quantity.
class _GroupedIngredient {
  _GroupedIngredient({required this.name, required this.unit});

  /// The ingredient display name.
  final String name;

  /// The ingredient unit.
  final String unit;

  /// The summed quantity across grouped rows.
  double totalQuantity = 0;
}

/// Returned by [RecipeService.cookRecipe] with data needed for undo.
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

/// Owns all recipe business logic: saving, deleting,
/// shortage checking and the cook transaction.
///
/// Kept free of Riverpod so every method is testable with plain
/// dependencies. The active inventory id and base currency are passed in by
/// the caller (which reads them from the providers).
class RecipeService {
  /// Creates a [RecipeService].
  RecipeService(this._db);

  final DatabaseHelper _db;

  /// Saves a recipe — creates a new one or updates an existing one.
  ///
  /// If [existingRecipeId] is null, a new recipe is created with the given
  /// [name], [instructions], and [ingredients]. If [existingRecipeId] is
  /// provided, the recipe and its ingredients are updated. The recipe's
  /// inventory defaults to [activeInventoryId].
  Future<void> saveRecipe({
    required String name,
    required List<RecipeIngredient> ingredients,
    required int activeInventoryId,
    int? existingRecipeId,
    String instructions = '',
    int servings = 0,
    String imagePath = '',
  }) async {
    if (name.trim().isEmpty) {
      throw ArgumentError('Recipe name is required');
    }

    final now = DateTime.now().millisecondsSinceEpoch;

    if (existingRecipeId != null) {
      // Preserve the recipe's original inventory when editing.
      final existing = await _db.getRecipe(existingRecipeId);
      final recipe = Recipe(
        id: existingRecipeId,
        name: name.trim(),
        instructions: instructions.trim(),
        servings: servings,
        imagePath: imagePath,
        inventoryId: existing?.inventoryId ?? activeInventoryId,
        updatedAt: now,
      );
      await _db.updateRecipeWithIngredients(recipe, ingredients);
      logInfo('Recipe $existingRecipeId updated: $name');
    } else {
      final recipe = Recipe(
        name: name.trim(),
        instructions: instructions.trim(),
        servings: servings,
        imagePath: imagePath,
        inventoryId: activeInventoryId,
        createdAt: now,
        updatedAt: now,
      );
      await _db.insertRecipeWithIngredients(
        recipe,
        ingredients,
      );
      logInfo('Recipe created: $name');
    }
  }

  /// Deletes a recipe by [id].
  Future<void> deleteRecipe(int id) async {
    await _db.deleteRecipe(id);
    logInfo('Recipe $id deleted');
  }
  /// Groups [ingredients] by barcode, sums quantities, normalizes units, and
  /// checks availability against inventory.
  ///
  /// Returns a map of ingredient name -> deficit, or empty map if all
  /// ingredients are sufficiently stocked. Ingredients without a barcode are
  /// skipped.
  Future<Map<String, double>> checkIngredientShortages(
    List<RecipeIngredient> ingredients,
    int activeInventoryId,
  ) async {
    final grouped = <String, _GroupedIngredient>{};
    for (final ing in ingredients) {
      final barcode = ing.barcode;
      if (barcode == null || barcode.isEmpty) continue;
      grouped
              .putIfAbsent(
                barcode,
                () => _GroupedIngredient(name: ing.name, unit: ing.unit),
              )
              .totalQuantity +=
          ing.quantity;
    }

    final shortages = <String, double>{};
    for (final entry in grouped.entries) {
      final barcode = entry.key;
      final grp = entry.value;
      var rows = await _db.getInventoryRowsByBarcode(
        barcode: barcode,
        inventoryId: activeInventoryId,
      );
      if (rows.isEmpty && grp.name.isNotEmpty) {
        rows = await _db.getInventoryRowsByProductName(
          name: grp.name,
          inventoryId: activeInventoryId,
        );
      }
      var available = 0.0;
      for (final row in rows) {
        final rowQty = (row['quantity'] as num?)?.toDouble() ?? 0;
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

  /// Tries to resolve the user-set per-piece serving weight in grams for
  /// an inventory row, so the shortage check, cook transaction, and cost
  /// scaling share the same source.
  double? _resolveServingWeightG(Map<String, dynamic> row, String name) {
    return (row['serving_weight_g'] as num?)?.toDouble();
  }

  /// Cooks a recipe: deducts ingredients from the recipe's own inventory
  /// (FEFO) and logs history.
  ///
  /// The inventory used is the recipe's own [Recipe.inventoryId], falling
  /// back to the active inventory when the recipe has no inventory. Throws
  /// [StateError] with shortage details if any ingredient has insufficient
  /// stock. Returns a [CookResult] for undo support.
  Future<CookResult> cookRecipe(
    int recipeId, {
    required int activeInventoryId,
  }) async {
    final recipe = await _db.getRecipe(recipeId);
    final inventoryId = recipe?.inventoryId ?? activeInventoryId;
    final ingredients = await _db.getRecipeIngredients(recipeId);

    if (ingredients.isEmpty) throw const RecipeCookException({});

    // Pre-flight validation with grouping and unit normalization
    final shortages = await checkIngredientShortages(
      ingredients,
      inventoryId,
    );
    if (shortages.isNotEmpty) {
      throw RecipeCookException(shortages);
    }

    // Transaction: FEFO deduction + history
    final database = await _db.database;
    final affectedRows = <InventoryRowSnapshot>[];

    final grouped = <String, _GroupedIngredient>{};
    for (final ing in ingredients) {
      final barcode = ing.barcode;
      if (barcode == null || barcode.isEmpty) continue;
      grouped
              .putIfAbsent(
                barcode,
                () => _GroupedIngredient(name: ing.name, unit: ing.unit),
              )
              .totalQuantity +=
          ing.quantity;
    }

    return await database.transaction<CookResult>((txn) async {
      for (final entry in grouped.entries) {
        final barcode = entry.key;
        var remaining = entry.value.totalQuantity;
        var rows = await txn.rawQuery(
          'SELECT * FROM inventory WHERE barcode = ? AND inventory_id = ?'
          ' ORDER BY (expiry_date IS NULL), expiry_date ASC',
          [barcode, inventoryId],
        );
        if (rows.isEmpty && entry.value.name.isNotEmpty) {
          final normalizedName = entry.value.name.trim().toLowerCase();
          final escaped = normalizedName
              .replaceAll('%', r'\%')
              .replaceAll('_', r'\_');
          rows = await txn.rawQuery(
            'SELECT i.* FROM inventory i'
            ' INNER JOIN products p ON p.barcode = i.barcode'
            r" WHERE LOWER(p.name) LIKE ? ESCAPE '\' AND i.inventory_id = ?"
            ' ORDER BY (i.expiry_date IS NULL), i.expiry_date ASC',
            ['%$escaped%', inventoryId],
          );
        }
        for (final row in rows) {
          if (remaining <= 0) break;
          final rowId = row['id'] as int?;
          if (rowId == null) continue;
          final rowQty = (row['quantity'] as num?)?.toDouble() ?? 0;
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
          final consumed = effectiveQty < remaining ? effectiveQty : remaining;
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
        'ingredient_snapshot': snapshotJson,
      });

      return CookResult(
        historyEntryId: historyId,
        affectedRows: affectedRows,
      );
    });
  }
}
