import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/models/recipe_ingredient.dart';

void main() {
  group('RecipeIngredient', () {
    test('creates with required fields', () {
      const ingredient = RecipeIngredient(
        recipeId: 1,
        name: 'Chicken breast',
      );
      expect(ingredient.recipeId, 1);
      expect(ingredient.name, 'Chicken breast');
      expect(ingredient.barcode, isNull);
      expect(ingredient.quantity, 1.0);
      expect(ingredient.unit, 'pieces');
      expect(ingredient.id, isNull);
    });

    test('creates with all fields', () {
      const ingredient = RecipeIngredient(
        id: 1,
        recipeId: 1,
        barcode: '123456',
        name: 'Chicken breast',
        quantity: 2,
        unit: 'g',
      );
      expect(ingredient.id, 1);
      expect(ingredient.recipeId, 1);
      expect(ingredient.barcode, '123456');
      expect(ingredient.name, 'Chicken breast');
      expect(ingredient.quantity, 2.0);
      expect(ingredient.unit, 'g');
    });

    test('copyWith preserves unset fields', () {
      const ingredient = RecipeIngredient(
        recipeId: 1,
        name: 'Salt',
        barcode: '001',
      );
      final copied = ingredient.copyWith(quantity: 0.5);
      expect(copied.name, 'Salt');
      expect(copied.barcode, '001');
      expect(copied.quantity, 0.5);
      expect(copied.unit, 'pieces');
    });

    test('equality works', () {
      const a = RecipeIngredient(id: 1, recipeId: 1, name: 'Eggs');
      const b = RecipeIngredient(id: 1, recipeId: 1, name: 'Eggs');
      const c = RecipeIngredient(id: 2, recipeId: 1, name: 'Eggs');
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('default values are correct', () {
      const ingredient = RecipeIngredient(recipeId: 1, name: 'Flour');
      expect(ingredient.quantity, 1.0);
      expect(ingredient.unit, 'pieces');
    });

    test('barcode can be null for free-text ingredients', () {
      const ingredient = RecipeIngredient(recipeId: 1, name: 'Pinch of love');
      expect(ingredient.barcode, isNull);
    });
  });
}
