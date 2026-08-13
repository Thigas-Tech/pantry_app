// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe_cache_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RecipeCacheEntry _$RecipeCacheEntryFromJson(Map<String, dynamic> json) =>
    _RecipeCacheEntry(
      recipeId: json['recipeId'] as String,
      name: json['name'] as String,
      instructions: json['instructions'] as String,
      servings: (json['servings'] as num).toInt(),
      ingredients: _ingredientsFromJson(json['ingredients'] as List),
      createdAt: (json['createdAt'] as num).toInt(),
      lastRefreshedAt: (json['lastRefreshedAt'] as num).toInt(),
      nextRefreshAt: (json['nextRefreshAt'] as num).toInt(),
      ingestedBy: json['ingestedBy'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      schemaVersion: (json['schemaVersion'] as num?)?.toInt() ?? 1,
    );

Map<String, dynamic> _$RecipeCacheEntryToJson(_RecipeCacheEntry instance) =>
    <String, dynamic>{
      'recipeId': instance.recipeId,
      'name': instance.name,
      'instructions': instance.instructions,
      'servings': instance.servings,
      'ingredients': _ingredientsToJson(instance.ingredients),
      'createdAt': instance.createdAt,
      'lastRefreshedAt': instance.lastRefreshedAt,
      'nextRefreshAt': instance.nextRefreshAt,
      'ingestedBy': instance.ingestedBy,
      'imageUrl': ?instance.imageUrl,
      'schemaVersion': instance.schemaVersion,
    };
