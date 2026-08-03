import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pantry_app/models/recipe_ingredient.dart';

part 'recipe.freezed.dart';

/// A user-created recipe with ingredients and instructions.
///
/// Each [Recipe] has a [name], optional [instructions], and a list of
/// [RecipeIngredient]s stored in the recipe_ingredients table linked by
/// [id]. [createdAt] and [updatedAt] are epoch timestamps set by the
/// repository layer.
///
/// ## Identity
///
/// - [id] is the auto-generated primary key from the recipes table. It is
///   null for recipes that have not yet been persisted.
@freezed
abstract class Recipe with _$Recipe {
  /// Creates a [Recipe].
  ///
  /// Only [name] is required. [instructions] defaults to an empty string.
  /// [createdAt] and [updatedAt] default to 0 and should be set by the
  /// caller (the DAO or mutation function) at persistence time.
  const factory Recipe({
    /// The recipe display name. Must not be empty.
    required String name,

    /// Auto-increment primary key from the recipes table.
    ///
    /// Null for recipes not yet persisted.
    int? id,

    /// Free-text preparation instructions.
    @Default('') String instructions,

    /// Number of servings this recipe yields.
    ///
    /// 0 means unknown (no per-serving computation shown).
    @Default(0) int servings,

    /// Optional file path to a user-selected photo of the prepared dish.
    @Default('') String imagePath,

    /// Epoch timestamp (milliseconds since epoch) of creation.
    @Default(0) int createdAt,

    /// Epoch timestamp (milliseconds since epoch) of last update.
    @Default(0) int updatedAt,

    /// The inventory (pantry) this recipe belongs to.
    ///
    /// Defaults to 1 (the seeded "Home" inventory) so recipes created before
    /// the per-inventory feature remain in the first pantry.
    @Default(1) int inventoryId,
  }) = _Recipe;
}
