import 'dart:async';
import 'dart:convert';

import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/models/recipe.dart';
import 'package:pantry_app/models/recipe_ingredient.dart';
import 'package:pantry_app/services/currency_service.dart';
import 'package:pantry_app/services/exceptions.dart';
import 'package:pantry_app/services/firebase_cache_service.dart';
import 'package:pantry_app/services/produce_barcode.dart';
import 'package:pantry_app/services/produce_serving_presets.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:pantry_app/utils/money.dart';
import 'package:pantry_app/utils/price_calculator.dart';
import 'package:pantry_app/utils/quantity_parser.dart';
import 'package:pantry_app/utils/serving_weight.dart';
import 'package:pantry_app/utils/unit_conversion.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

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

/// Owns all recipe business logic: saving, deleting, cost calculation,
/// shortage checking and the cook transaction.
///
/// Kept free of Riverpod so every method is testable with plain
/// dependencies. The active inventory id and base currency are passed in by
/// the caller (which reads them from the providers).
class RecipeService {
  /// Creates a [RecipeService].
  RecipeService(
    this._db,
    this._cache,
    this._currencyService,
  );

  final DatabaseHelper _db;
  final FirebaseCacheService _cache;
  final CurrencyService _currencyService;

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
        sharedRecipeId: existing?.sharedRecipeId ?? _newSharedId(),
      );
      await _db.updateRecipeWithIngredients(recipe, ingredients);
      logInfo('Recipe $existingRecipeId updated: $name');
      unawaited(
        _cache.cacheRecipe(
          recipe,
          ingredients,
          recipeId: recipe.sharedRecipeId,
        ),
      );
    } else {
      final sharedId = _newSharedId();
      final recipe = Recipe(
        name: name.trim(),
        instructions: instructions.trim(),
        servings: servings,
        imagePath: imagePath,
        inventoryId: activeInventoryId,
        createdAt: now,
        updatedAt: now,
        sharedRecipeId: sharedId,
      );
      final newId = await _db.insertRecipeWithIngredients(
        recipe,
        ingredients,
      );
      logInfo('Recipe created: $name');
      unawaited(
        _cache.cacheRecipe(
          recipe.copyWith(id: newId),
          ingredients,
          recipeId: sharedId,
        ),
      );
    }
  }

  /// Deletes a recipe by [id], including its shared-cache entry.
  Future<void> deleteRecipe(int id) async {
    final recipe = await _db.getRecipe(id);
    await _db.deleteRecipe(id);
    logInfo('Recipe $id deleted');
    if (recipe != null && recipe.sharedRecipeId.isNotEmpty) {
      unawaited(
        _cache.deleteSharedRecipe(recipe.sharedRecipeId),
      );
    }
  }

  /// Returns a fresh random id for a recipe's shared-cache snapshot.
  String _newSharedId() => const Uuid().v4();

  /// Calculates the total cost of [recipeId] from its ingredients' latest
  /// prices, scoped to the recipe's own inventory (falling back to
  /// [activeInventoryId]) and converted to [baseCurrency].
  Future<double> calculateRecipeCost(
    int recipeId, {
    required int activeInventoryId,
    required String baseCurrency,
  }) async {
    final ingredients = await _db.getRecipeIngredients(recipeId);
    if (ingredients.isEmpty) return 0.0;

    final recipe = await _db.getRecipe(recipeId);
    final inventoryId = recipe?.inventoryId ?? activeInventoryId;
    final database = await _db.database;

    return calculateIngredientCost(
      database,
      ingredients,
      inventoryId: inventoryId,
      baseCurrency: baseCurrency,
      currencyService: _currencyService,
    );
  }

  /// Sums the latest price of each [ingredients] row found in the prices
  /// table for the given [inventoryId], converted to [baseCurrency].
  ///
  /// Each ingredient's cost is scaled by the fraction of the package
  /// actually used when a package size can be resolved. The package size is
  /// looked up in this order: the price row itself, then the product's
  /// packaging quantity. When the ingredient and package units are
  /// incompatible (e.g. pieces vs grams for produce), a per-piece serving
  /// weight is used to convert before scaling. When no package size or
  /// conversion can be resolved, the full price is charged (legacy
  /// behavior).
  ///
  /// Ingredients without a barcode, or with no price recorded in
  /// [inventoryId], contribute zero. Each ingredient cost and the final
  /// total are rounded to cents. Returns 0.0 when nothing can be priced.
  Future<double> calculateIngredientCost(
    Database database,
    List<RecipeIngredient> ingredients, {
    required int inventoryId,
    required String baseCurrency,
    required CurrencyService currencyService,
  }) async {
    var total = 0.0;
    for (final ingredient in ingredients) {
      final rawBarcode = ingredient.barcode;
      if (rawBarcode == null || rawBarcode.isEmpty) continue;
      final barcode = normalizeProduceBarcode(rawBarcode);

      final rows = await database.rawQuery(
        'SELECT price, currency, package_quantity, package_unit FROM prices'
        ' WHERE barcode = ? AND inventory_id = ?'
        ' ORDER BY date_purchased DESC LIMIT 1',
        [barcode, inventoryId],
      );
      if (rows.isEmpty) continue;

      final price = (rows.first['price'] as num?)?.toDouble() ?? 0.0;
      final currency = rows.first['currency'] as String? ?? baseCurrency;

      var cost = price;
      final packageSize = await _resolvePackageSize(
        database,
        barcode,
        priceRow: rows.first,
      );
      if (packageSize != null) {
        cost =
            await _scaleIngredientCost(
              database,
              barcode,
              inventoryId,
              price: price,
              ingredient: ingredient,
              package: packageSize,
            ) ??
            price;
      }

      final converted = await currencyService.convert(
        cost,
        currency,
        baseCurrency,
      );
      total += Money.roundToCents(converted);
    }

    return Money.roundToCents(total);
  }

  /// Scales [ingredient]'s share of [price] against [package].
  ///
  /// First tries a plain same-group scale via [PriceCalculator]. When the
  /// units are incompatible (pieces vs weight for produce), resolves a
  /// per-piece serving weight from the inventory row or
  /// [ProduceServingPresets] and converts before scaling. Returns null when
  /// no conversion is possible.
  Future<double?> _scaleIngredientCost(
    Database database,
    String barcode,
    int inventoryId, {
    required double price,
    required RecipeIngredient ingredient,
    required ({double packageQuantity, String packageUnit}) package,
  }) async {
    final scaled = PriceCalculator.scaledIngredientCost(
      price: price,
      ingredientQuantity: ingredient.quantity,
      ingredientUnit: ingredient.unit,
      packageQuantity: package.packageQuantity,
      packageUnit: package.packageUnit,
    );
    if (scaled != null) return scaled;

    final servingWeightG = await _servingWeightForIngredient(
      database,
      barcode,
      inventoryId,
      ingredient.name,
    );
    if (servingWeightG == null || servingWeightG <= 0) return null;

    final ingredientIsWeight = UnitConverter.areUnitsCompatible(
      ingredient.unit,
      'g',
    );
    final packageIsWeight = UnitConverter.areUnitsCompatible(
      package.packageUnit,
      'g',
    );

    final double? convertedQuantity;
    final String convertedUnit;
    if (ingredientIsWeight && !packageIsWeight) {
      // Grams needed -> pieces to take from a pieces package.
      convertedQuantity = ingredient.quantity / servingWeightG;
      convertedUnit = 'pieces';
    } else if (!ingredientIsWeight && packageIsWeight) {
      // Pieces needed -> grams to take from a weight package.
      convertedQuantity = ingredient.quantity * servingWeightG;
      convertedUnit = 'g';
    } else {
      return null;
    }

    return PriceCalculator.scaledIngredientCost(
      price: price,
      ingredientQuantity: convertedQuantity,
      ingredientUnit: convertedUnit,
      packageQuantity: package.packageQuantity,
      packageUnit: package.packageUnit,
    );
  }

  /// Resolves the grams-per-piece serving weight for [barcode] in
  /// [inventoryId], falling back to [ProduceServingPresets] keyed by
  /// [ingredientName].
  Future<double?> _servingWeightForIngredient(
    Database database,
    String barcode,
    int inventoryId,
    String ingredientName,
  ) async {
    final rows = await database.rawQuery(
      'SELECT serving_weight_g FROM inventory'
      ' WHERE barcode = ? AND inventory_id = ?'
      ' ORDER BY (expiry_date IS NULL), expiry_date ASC LIMIT 1',
      [barcode, inventoryId],
    );
    final rowWeight = rows.isEmpty
        ? null
        : (rows.first['serving_weight_g'] as num?)?.toDouble();
    return ServingWeightResolver.resolve(
      rowServingWeightG: rowWeight,
      produceName: ingredientName,
    );
  }

  /// Resolves the package size for [barcode] to scale recipe ingredient
  /// costs.
  ///
  /// Checks, in order:
  ///   1. The [priceRow]'s own package_quantity / package_unit columns.
  ///   2. The product's packaging quantity ([Product.quantity] /
  ///      [Product.productQuantity]), parsing multi-pack strings like
  ///      "3 x 150 g" to their per-unit value.
  ///
  /// The inventory row is deliberately not consulted: its stored quantity
  /// is the current stock, not the size of the package the price applies
  /// to, so using it as a package size would distort the scaled cost.
  ///
  /// Returns null when no usable package size is found.
  Future<({double packageQuantity, String packageUnit})?> _resolvePackageSize(
    Database database,
    String barcode, {
    required Map<String, dynamic> priceRow,
  }) async {
    final priceQty = (priceRow['package_quantity'] as num?)?.toDouble();
    final priceUnit = priceRow['package_unit'] as String?;
    if (priceQty != null && priceUnit != null && priceQty > 0) {
      return (packageQuantity: priceQty, packageUnit: priceUnit);
    }

    final productRows = await database.query(
      'products',
      columns: ['quantity', 'product_quantity'],
      where: 'barcode = ?',
      whereArgs: [barcode],
      limit: 1,
    );
    if (productRows.isNotEmpty) {
      final parsed = parseQuantity(
        productQuantity: (productRows.first['product_quantity'] as num?)
            ?.toDouble(),
        quantity: productRows.first['quantity'] as String?,
      );
      if (parsed != null) {
        return (packageQuantity: parsed.amount, packageUnit: parsed.unit);
      }
    }

    return null;
  }

  /// Calculates the average cost across all recipes in the active inventory.
  ///
  /// Returns 0.0 if no recipes exist (guards division by zero).
  Future<double> calculateAverageRecipeCost({
    required int activeInventoryId,
    required String baseCurrency,
  }) async {
    final recipes = await _db.getAllRecipes(activeInventoryId);
    if (recipes.isEmpty) return 0.0;

    var totalCost = 0.0;
    for (final recipe in recipes) {
      final cost = await calculateRecipeCost(
        recipe.id!,
        activeInventoryId: activeInventoryId,
        baseCurrency: baseCurrency,
      );
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
      final barcode = normalizeProduceBarcode(entry.key);
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

  /// Tries to resolve a per-piece serving weight in grams for an inventory
  /// row.
  ///
  /// Delegates to [ServingWeightResolver] so the shortage check, cook
  /// transaction, and cost scaling share the same sources.
  double? _resolveServingWeightG(Map<String, dynamic> row, String name) {
    return ServingWeightResolver.resolve(
      rowServingWeightG: (row['serving_weight_g'] as num?)?.toDouble(),
      produceName: name,
    );
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
    required String baseCurrency,
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

    // Compute current cost
    final database = await _db.database;
    final totalCost = await calculateIngredientCost(
      database,
      ingredients,
      inventoryId: inventoryId,
      baseCurrency: baseCurrency,
      currencyService: _currencyService,
    );

    // Transaction: FEFO deduction + history
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

    return database.transaction<CookResult>((txn) async {
      for (final entry in grouped.entries) {
        final barcode = normalizeProduceBarcode(entry.key);
        var remaining = entry.value.totalQuantity;
        var rows = await txn.rawQuery(
          'SELECT * FROM inventory WHERE barcode = ? AND inventory_id = ?'
          ' ORDER BY (expiry_date IS NULL), expiry_date ASC',
          [barcode, inventoryId],
        );
        if (rows.isEmpty && entry.value.name.isNotEmpty) {
          final normalizedName = entry.value.name.trim().toLowerCase();
          rows = await txn.rawQuery(
            'SELECT i.* FROM inventory i'
            ' INNER JOIN products p ON p.barcode = i.barcode'
            ' WHERE LOWER(p.name) LIKE ? AND i.inventory_id = ?'
            ' ORDER BY (i.expiry_date IS NULL), i.expiry_date ASC',
            ['%$normalizedName%', inventoryId],
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
        'cost_at_time': totalCost,
        'ingredient_snapshot': snapshotJson,
      });

      return CookResult(
        historyEntryId: historyId,
        affectedRows: affectedRows,
      );
    });
  }
}
