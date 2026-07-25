import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pantry_app/models/recipe_ingredient.dart';

part 'recipe_ingredient_cache.freezed.dart';
part 'recipe_ingredient_cache.g.dart';

/// Firestore-serializable ingredient for anonymous recipe sharing.
///
/// Mirrors [RecipeIngredient] but strips all local-only fields:
/// [RecipeIngredient.id], [RecipeIngredient.recipeId].
@freezed
abstract class RecipeIngredientCache with _$RecipeIngredientCache {
  /// Creates a [RecipeIngredientCache] with all required fields.
  const factory RecipeIngredientCache({
    /// Ingredient display name.
    required String name,

    /// Optional product barcode for price/nutrition lookup.
    @JsonKey(includeIfNull: false) String? barcode,

    /// Quantity, defaults to 1.
    @Default(1.0) double quantity,

    /// Unit of measurement, defaults to 'pieces'.
    @Default('pieces') String unit,
  }) = _RecipeIngredientCache;

  const RecipeIngredientCache._();

  /// Deserializes from a JSON map.
  factory RecipeIngredientCache.fromJson(Map<String, dynamic> json) =>
      _$RecipeIngredientCacheFromJson(json);
}

/// Extension to convert from a local [RecipeIngredient].
extension RecipeIngredientCacheConversions on RecipeIngredientCache {
  /// Creates a cache entry from a local [RecipeIngredient], stripping
  /// local-only fields [RecipeIngredient.id] and [RecipeIngredient.recipeId].
  static RecipeIngredientCache fromIngredient(RecipeIngredient ingredient) {
    return RecipeIngredientCache(
      name: ingredient.name,
      barcode: ingredient.barcode,
      quantity: ingredient.quantity,
      unit: ingredient.unit,
    );
  }
}
