import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/models/recipe.dart';

void main() {
  group('Recipe', () {
    test('creates with required fields', () {
      const recipe = Recipe(name: 'Chicken Sandwich');
      expect(recipe.name, 'Chicken Sandwich');
      expect(recipe.instructions, '');
      expect(recipe.createdAt, 0);
      expect(recipe.updatedAt, 0);
      expect(recipe.id, isNull);
      expect(recipe.inventoryId, 1);
    });

    test('creates with all fields', () {
      const recipe = Recipe(
        id: 1,
        name: 'Chicken Sandwich',
        instructions: 'Cook the chicken. Assemble the sandwich.',
        createdAt: 1000,
        updatedAt: 2000,
        inventoryId: 2,
      );
      expect(recipe.id, 1);
      expect(recipe.name, 'Chicken Sandwich');
      expect(recipe.instructions, 'Cook the chicken. Assemble the sandwich.');
      expect(recipe.createdAt, 1000);
      expect(recipe.updatedAt, 2000);
      expect(recipe.inventoryId, 2);
    });

    test('copyWith preserves unset fields', () {
      const recipe = Recipe(
        id: 1,
        name: 'Omelette',
        instructions: 'Beat eggs. Cook.',
      );
      final copied = recipe.copyWith(name: 'Cheese Omelette');
      expect(copied.id, 1);
      expect(copied.name, 'Cheese Omelette');
      expect(copied.instructions, 'Beat eggs. Cook.');
    });

    test('equality works', () {
      const a = Recipe(id: 1, name: 'Soup');
      const b = Recipe(id: 1, name: 'Soup');
      const c = Recipe(id: 2, name: 'Soup');
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('default values are correct', () {
      const recipe = Recipe(name: 'Salad');
      expect(recipe.id, isNull);
      expect(recipe.instructions, '');
      expect(recipe.servings, 0);
      expect(recipe.imagePath, '');
      expect(recipe.createdAt, 0);
      expect(recipe.updatedAt, 0);
    });

    test('servings can be set', () {
      const recipe = Recipe(name: 'Salad', servings: 4);
      expect(recipe.servings, 4);
    });

    test('imagePath can be set and copyWith works', () {
      const recipe = Recipe(name: 'Soup', imagePath: '/path/to/photo.jpg');
      expect(recipe.imagePath, '/path/to/photo.jpg');
      final copied = recipe.copyWith(imagePath: '/new/path.jpg');
      expect(copied.imagePath, '/new/path.jpg');
    });
  });
}
