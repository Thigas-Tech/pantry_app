import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/models/recipe_history_entry.dart';

void main() {
  group('RecipeHistoryEntry', () {
    test('creates with required fields', () {
      const entry = RecipeHistoryEntry(
        recipeId: 1,
        madeAt: 1000,
        ingredientSnapshot: '[]',
      );
      expect(entry.recipeId, 1);
      expect(entry.madeAt, 1000);
      expect(entry.costAtTime, 0);
      expect(entry.ingredientSnapshot, '[]');
      expect(entry.id, isNull);
    });

    test('creates with all fields', () {
      const entry = RecipeHistoryEntry(
        id: 1,
        recipeId: 2,
        madeAt: 2000,
        costAtTime: 15.50,
        ingredientSnapshot: '[{"name":"eggs"}]',
      );
      expect(entry.id, 1);
      expect(entry.recipeId, 2);
      expect(entry.madeAt, 2000);
      expect(entry.costAtTime, 15.50);
      expect(entry.ingredientSnapshot, '[{"name":"eggs"}]');
    });

    test('copyWith preserves unset fields', () {
      const entry = RecipeHistoryEntry(
        id: 1,
        recipeId: 1,
        madeAt: 1000,
        ingredientSnapshot: '[]',
      );
      final copied = entry.copyWith(costAtTime: 10);
      expect(copied.id, 1);
      expect(copied.costAtTime, 10.0);
      expect(copied.ingredientSnapshot, '[]');
    });

    test('equality works', () {
      const a = RecipeHistoryEntry(
        id: 1,
        recipeId: 1,
        madeAt: 1000,
        ingredientSnapshot: '[]',
      );
      const b = RecipeHistoryEntry(
        id: 1,
        recipeId: 1,
        madeAt: 1000,
        ingredientSnapshot: '[]',
      );
      const c = RecipeHistoryEntry(
        id: 2,
        recipeId: 1,
        madeAt: 1000,
        ingredientSnapshot: '[]',
      );
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });
}
