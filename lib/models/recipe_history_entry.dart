import 'package:freezed_annotation/freezed_annotation.dart';

part 'recipe_history_entry.freezed.dart';

/// An immutable record of a recipe being cooked (marked as "made").
///
/// Each [RecipeHistoryEntry] logs when a user cooked a recipe, the cost at
/// that time, and a snapshot of the ingredients that were used. Once created,
/// this entry is never modified — it serves as an audit log.
///
/// ## Identity
///
/// - [id] is the auto-generated primary key from the recipe_history table.
/// - [recipeId] is the foreign key referencing the recipes table. Note that
///   if the recipe is later deleted, this entry survives so stats remain
///   accurate.
@freezed
abstract class RecipeHistoryEntry with _$RecipeHistoryEntry {
  /// Creates a [RecipeHistoryEntry].
  ///
  /// [recipeId], [madeAt], and [ingredientSnapshot] are required. [costAtTime]
  /// defaults to 0.0 for recipes with no priced ingredients.
  const factory RecipeHistoryEntry({
    /// Foreign key referencing the cooked recipe.
    required int recipeId,

    /// Epoch millis timestamp of when the recipe was made.
    required int madeAt,

    /// JSON-encoded snapshot of `[{barcode, name, quantity, unit}]` at cook
    /// time, so the entry is accurate even if the recipe changes later.
    required String ingredientSnapshot,

    /// Auto-increment primary key from the recipe_history table.
    int? id,

    /// Total recipe cost computed at cook time.
    @Default(0.0) double costAtTime,
  }) = _RecipeHistoryEntry;
}
