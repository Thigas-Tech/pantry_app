import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pantry_app/firebase_cache_config.dart';
import 'package:pantry_app/models/recipe.dart';
import 'package:pantry_app/models/recipe_ingredient.dart';
import 'package:pantry_app/models/recipe_ingredient_cache.dart';

part 'recipe_cache_entry.freezed.dart';
part 'recipe_cache_entry.g.dart';

/// Computes a deterministic SHA-256 hex hash from a recipe's name and
/// createdAt timestamp, avoiding any local DB IDs. The result is used as
/// the Firestore document ID.
String _computeRecipeId(String name, int createdAt) {
  final bytes = utf8.encode('$name:$createdAt');
  final digest = sha256.convert(bytes);
  return digest.toString();
}

List<RecipeIngredientCache> _ingredientsFromJson(List<dynamic> json) => json
    .map((e) => RecipeIngredientCache.fromJson(e as Map<String, dynamic>))
    .toList();

List<Map<String, dynamic>> _ingredientsToJson(
  List<RecipeIngredientCache> ingredients,
) => ingredients.map((e) => e.toJson()).toList();

/// Firestore document for the recipe_cache/{recipeId} collection.
///
/// Stores an anonymized, cross-device shareable snapshot of a user's
/// recipe. No PII (user ID, device ID, local file paths) is stored.
///
/// [recipeId] is a SHA-256 hex hash derived from the original recipe's
/// name and createdAt, ensuring deterministic, collision-resistant IDs
/// that cannot be traced back to the local SQLite database.
@freezed
abstract class RecipeCacheEntry with _$RecipeCacheEntry {
  /// Creates a [RecipeCacheEntry] with all required fields.
  const factory RecipeCacheEntry({
    /// SHA-256 hex hash (name + createdAt), used as Firestore doc ID.
    required String recipeId,

    /// Recipe display name.
    required String name,

    /// Free-text preparation instructions.
    required String instructions,

    /// Number of servings this recipe yields.
    required int servings,

    /// Anonymized ingredient list (no local IDs).
    @JsonKey(
      fromJson: _ingredientsFromJson,
      toJson: _ingredientsToJson,
    )
    required List<RecipeIngredientCache> ingredients,

    /// Epoch ms of first creation (copied from original recipe).
    required int createdAt,

    /// Epoch ms of last refresh.
    required int lastRefreshedAt,

    /// Epoch ms of next scheduled refresh.
    required int nextRefreshAt,

    /// Optional Firebase Storage URL for the recipe photo.
    ///
    /// Null when no photo has been uploaded. Never a local file path.
    @JsonKey(includeIfNull: false) String? imageUrl,

    /// Schema version for forward compatibility.
    @Default(1) int schemaVersion,
  }) = _RecipeCacheEntry;

  const RecipeCacheEntry._();

  /// Deserializes from a JSON map.
  factory RecipeCacheEntry.fromJson(Map<String, dynamic> json) =>
      _$RecipeCacheEntryFromJson(json);
}

/// Extension providing conversions to/from local [Recipe].
extension RecipeCacheEntryConversions on RecipeCacheEntry {
  /// Creates an anonymized cache entry from a local [Recipe] and its
  /// [ingredients].
  ///
  /// [imageUrl] is the optional Firebase Storage URL for the recipe photo
  /// (never a local file path). If [createdAt] is omitted, it defaults to
  /// the current time.
  static RecipeCacheEntry fromRecipe(
    Recipe recipe,
    List<RecipeIngredient> ingredients, {
    String? imageUrl,
    int? createdAt,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final effectiveCreatedAt = createdAt ?? recipe.createdAt;
    final recipeId = _computeRecipeId(recipe.name, effectiveCreatedAt);

    return RecipeCacheEntry(
      recipeId: recipeId,
      name: recipe.name,
      instructions: recipe.instructions,
      servings: recipe.servings,
      ingredients: ingredients
          .map(RecipeIngredientCacheConversions.fromIngredient)
          .toList(),
      createdAt: effectiveCreatedAt,
      lastRefreshedAt: now,
      nextRefreshAt: now + recipeRefreshIntervalMs,
      imageUrl: imageUrl,
    );
  }

  /// Converts this cache entry back to a local [Recipe].
  ///
  /// The returned [Recipe] has [Recipe.id] set to null (cache entries are
  /// anonymized and carry no local primary key).
  Recipe toRecipe() {
    return Recipe(
      name: name,
      instructions: instructions,
      servings: servings,
    );
  }
}
