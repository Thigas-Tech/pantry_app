import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/models/recipe.dart';
import 'package:pantry_app/models/recipe_cache_entry.dart';
import 'package:pantry_app/models/recipe_ingredient.dart';
import 'package:pantry_app/models/recipe_ingredient_cache.dart';

void main() {
  group('RecipeIngredientCache', () {
    test('creates with required fields', () {
      const ing = RecipeIngredientCache(name: 'Sugar');
      expect(ing.name, 'Sugar');
      expect(ing.barcode, isNull);
      expect(ing.quantity, 1.0);
      expect(ing.unit, 'pieces');
    });

    test('creates with all fields', () {
      const ing = RecipeIngredientCache(
        name: 'Flour',
        barcode: '123456789',
        quantity: 500,
        unit: 'g',
      );
      expect(ing.name, 'Flour');
      expect(ing.barcode, '123456789');
      expect(ing.quantity, 500);
      expect(ing.unit, 'g');
    });

    test('JSON round-trip', () {
      const original = RecipeIngredientCache(
        name: 'Salt',
        barcode: '987654321',
        quantity: 10,
        unit: 'g',
      );
      final json = original.toJson();
      final restored = RecipeIngredientCache.fromJson(json);
      expect(restored, original);
    });

    test('JSON handles null barcode', () {
      const original = RecipeIngredientCache(name: 'Pepper');
      final json = original.toJson();
      expect(json['barcode'], isNull);
      final restored = RecipeIngredientCache.fromJson(json);
      expect(restored.barcode, isNull);
    });

    test('fromIngredient strips local IDs', () {
      const local = RecipeIngredient(
        recipeId: 42,
        name: 'Eggs',
        id: 99,
        barcode: '111',
        quantity: 3,
      );
      final cache = RecipeIngredientCacheConversions.fromIngredient(local);
      expect(cache.name, 'Eggs');
      expect(cache.barcode, '111');
      expect(cache.quantity, 3);
      expect(cache.unit, 'pieces');
      // No way to access recipeId or id — they're stripped
    });
  });

  group('RecipeCacheEntry', () {
    test('creates with required fields', () {
      const entry = RecipeCacheEntry(
        recipeId: 'abc123',
        name: 'Test Recipe',
        instructions: '',
        servings: 0,
        ingredients: [],
        createdAt: 1000,
        lastRefreshedAt: 1000,
        nextRefreshAt: 1000 + 180 * 24 * 60 * 60 * 1000,
      );
      expect(entry.recipeId, 'abc123');
      expect(entry.name, 'Test Recipe');
      expect(entry.ingredients, isEmpty);
      expect(entry.schemaVersion, 1);
    });

    test('JSON round-trip', () {
      const entry = RecipeCacheEntry(
        recipeId: 'def456',
        name: 'Pancakes',
        instructions: 'Mix and cook.',
        servings: 4,
        ingredients: [
          RecipeIngredientCache(name: 'Flour', quantity: 200, unit: 'g'),
          RecipeIngredientCache(name: 'Eggs', quantity: 2),
        ],
        createdAt: 2000,
        lastRefreshedAt: 2000,
        nextRefreshAt: 2000 + 180 * 24 * 60 * 60 * 1000,
        imageUrl: 'https://example.com/pancakes.jpg',
      );
      final json = entry.toJson();
      final restored = RecipeCacheEntry.fromJson(json);
      expect(restored, entry);
    });

    test('toJson omits null imageUrl', () {
      const entry = RecipeCacheEntry(
        recipeId: 'ghi789',
        name: 'Soup',
        instructions: '',
        servings: 0,
        ingredients: [],
        createdAt: 3000,
        lastRefreshedAt: 3000,
        nextRefreshAt: 3000 + 180 * 24 * 60 * 60 * 1000,
      );
      final json = entry.toJson();
      expect(json.containsKey('imageUrl'), false);
    });

    test('fromJson handles missing optional fields', () {
      final json = <String, dynamic>{
        'recipeId': 'abc',
        'name': 'Salad',
        'instructions': '',
        'servings': 2,
        'ingredients': <Map<String, dynamic>>[],
        'createdAt': 100,
        'lastRefreshedAt': 100,
        'nextRefreshAt': 1000,
      };
      final entry = RecipeCacheEntry.fromJson(json);
      expect(entry.schemaVersion, 1);
      expect(entry.imageUrl, isNull);
    });

    test('fromRecipe converts local Recipe to anonymous cache entry', () {
      const recipe = Recipe(
        id: 42,
        name: 'Omelette',
        instructions: 'Beat eggs. Cook.',
        servings: 2,
        createdAt: 5000,
      );
      const ingredients = [
        RecipeIngredient(
          recipeId: 42,
          name: 'Eggs',
          id: 1,
          barcode: '123',
          quantity: 3,
        ),
        RecipeIngredient(
          recipeId: 42,
          name: 'Salt',
          id: 2,
          unit: 'pinch',
        ),
      ];

      final entry = RecipeCacheEntryConversions.fromRecipe(recipe, ingredients);

      // recipeId must be a deterministic hash, not the local ID
      expect(entry.recipeId, isNotEmpty);
      expect(entry.recipeId, isNot('42'));

      // Fields from Recipe
      expect(entry.name, 'Omelette');
      expect(entry.instructions, 'Beat eggs. Cook.');
      expect(entry.servings, 2);
      expect(entry.createdAt, 5000);

      // Ingredients have no local IDs
      expect(entry.ingredients, hasLength(2));
      expect(entry.ingredients[0].name, 'Eggs');
      expect(entry.ingredients[0].barcode, '123');
      expect(entry.ingredients[0].quantity, 3);

      // Free-text ingredient
      expect(entry.ingredients[1].barcode, isNull);
      expect(entry.ingredients[1].name, 'Salt');
      expect(entry.ingredients[1].unit, 'pinch');

      // Timestamps
      expect(entry.lastRefreshedAt, greaterThan(0));
      expect(entry.nextRefreshAt, greaterThan(entry.lastRefreshedAt));

      // No PII
      expect(entry.imageUrl, isNull); // No imageUrl provided
    });

    test('fromRecipe accepts custom imageUrl', () {
      const recipe = Recipe(
        name: 'Pasta',
        createdAt: 6000,
      );

      final entry = RecipeCacheEntryConversions.fromRecipe(
        recipe,
        [],
        imageUrl: 'https://example.com/pasta.jpg',
      );

      expect(entry.imageUrl, 'https://example.com/pasta.jpg');
    });

    test('fromRecipe generates a random, unguessable recipeId', () {
      const recipe = Recipe(
        name: 'Toast',
        createdAt: 7000,
      );

      final entry1 = RecipeCacheEntryConversions.fromRecipe(recipe, []);
      final entry2 = RecipeCacheEntryConversions.fromRecipe(recipe, []);

      expect(entry1.recipeId, isNot(entry2.recipeId));
      expect(
        entry1.recipeId,
        matches(
          RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
          ),
        ),
      );
    });

    test('fromRecipe uses the provided recipeId', () {
      const recipe = Recipe(name: 'Toast', createdAt: 7000);

      final entry = RecipeCacheEntryConversions.fromRecipe(
        recipe,
        [],
        recipeId: 'fixed-id',
      );

      expect(entry.recipeId, 'fixed-id');
    });

    test('fromRecipe records the ingestedBy uid when provided', () {
      const recipe = Recipe(name: 'Toast', createdAt: 7000);

      final entry = RecipeCacheEntryConversions.fromRecipe(
        recipe,
        [],
        ingestedBy: 'user-123',
      );

      expect(entry.ingestedBy, 'user-123');
    });

    test('fromRecipe defaults ingestedBy to empty', () {
      const recipe = Recipe(name: 'Toast', createdAt: 7000);

      final entry = RecipeCacheEntryConversions.fromRecipe(recipe, []);

      expect(entry.ingestedBy, '');
    });

    test('fromRecipe generates different IDs for different names', () {
      const recipe1 = Recipe(name: 'Toast', createdAt: 7000);
      const recipe2 = Recipe(name: 'Toast2', createdAt: 7000);

      final entry1 = RecipeCacheEntryConversions.fromRecipe(recipe1, []);
      final entry2 = RecipeCacheEntryConversions.fromRecipe(recipe2, []);

      expect(entry1.recipeId, isNot(entry2.recipeId));
    });

    test(
      'fromRecipe generates different IDs for the same recipe in different'
      ' inventories',
      () {
        const recipe1 = Recipe(name: 'Toast', createdAt: 7000);
        const recipe2 = Recipe(name: 'Toast', createdAt: 7000, inventoryId: 2);

        final entry1 = RecipeCacheEntryConversions.fromRecipe(recipe1, []);
        final entry2 = RecipeCacheEntryConversions.fromRecipe(recipe2, []);

        expect(entry1.recipeId, isNot(entry2.recipeId));
      },
    );

    test(
      'fromRecipe generates distinct IDs for the same recipe in the same'
      ' inventory',
      () {
        const recipe = Recipe(name: 'Toast', createdAt: 7000, inventoryId: 2);

        final entry1 = RecipeCacheEntryConversions.fromRecipe(recipe, []);
        final entry2 = RecipeCacheEntryConversions.fromRecipe(recipe, []);

        expect(entry1.recipeId, isNot(entry2.recipeId));
      },
    );

    test('toRecipe round-trips through fromRecipe', () {
      const recipe = Recipe(
        id: 99,
        name: 'Cake',
        instructions: 'Bake.',
        servings: 8,
        createdAt: 8000,
      );
      const ingredients = [
        RecipeIngredient(
          recipeId: 99,
          name: 'Sugar',
          barcode: '111',
          quantity: 200,
          unit: 'g',
        ),
      ];

      final entry = RecipeCacheEntryConversions.fromRecipe(recipe, ingredients);
      final restored = entry.toRecipe();

      expect(restored.name, 'Cake');
      expect(restored.instructions, 'Bake.');
      expect(restored.servings, 8);
      // toRecipe always returns id=null since cache entries are anonymized
      expect(restored.id, isNull);
    });
  });
}
