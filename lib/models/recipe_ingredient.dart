import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/models/recipe.dart';

part 'recipe_ingredient.freezed.dart';

/// A single ingredient in a recipe.
///
/// Each [RecipeIngredient] is linked to a [Recipe] via [recipeId] and may
/// optionally reference a [Product] via [barcode]. When [barcode] is set,
/// the ingredient can be costed automatically from the prices table.
///
/// ## Identity
///
/// - [id] is the auto-generated primary key from the recipe_ingredients table.
/// - [recipeId] is the foreign key referencing the recipes table.
///
/// ## Free-text ingredients
///
/// When [barcode] is null, the ingredient is free-text (e.g. "a pinch of
/// salt"). Its cost contribution is always zero.
@freezed
abstract class RecipeIngredient with _$RecipeIngredient {
  /// Creates a [RecipeIngredient].
  ///
  /// Only [recipeId] and [name] are required. [barcode] is null for
  /// free-text ingredients. [quantity] defaults to 1.0, [unit] defaults
  /// to 'pieces'.
  const factory RecipeIngredient({
    /// Foreign key referencing the recipes table.
    required int recipeId,

    /// The ingredient display name (from the product or free-text).
    required String name,

    /// Auto-increment primary key from the recipe_ingredients table.
    int? id,

    /// The linked product barcode, or null for free-text ingredients.
    String? barcode,

    /// Quantity of this ingredient. Defaults to 1.0.
    @Default(1.0) double quantity,

    /// Unit for [quantity] (e.g. 'pieces', 'g', 'ml'). Defaults to 'pieces'.
    @Default('pieces') String unit,
  }) = _RecipeIngredient;
}
