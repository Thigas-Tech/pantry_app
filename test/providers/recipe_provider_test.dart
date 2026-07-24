import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/models/recipe.dart';
import 'package:pantry_app/models/recipe_ingredient.dart';
import 'package:pantry_app/providers/recipe_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class MockDatabaseHelper extends Mock implements DatabaseHelper {}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    registerFallbackValue(const Recipe(name: ''));
    registerFallbackValue(const RecipeIngredient(recipeId: 0, name: ''));
  });

  late Database db;
  late MockDatabaseHelper mockDb;

  setUp(() async {
    db = await databaseFactory.openDatabase(inMemoryDatabasePath);
    registerFallbackValue(db);

    mockDb = MockDatabaseHelper();

    when(() => mockDb.database).thenAnswer((_) async => db);
    when(() => mockDb.getAllRecipes()).thenAnswer((_) async => []);
    when(() => mockDb.getRecipeIngredients(any())).thenAnswer((_) async => []);
    when(() => mockDb.insertRecipe(any())).thenAnswer((_) async => 1);
    when(
      () => mockDb.insertRecipeWithIngredients(any(), any()),
    ).thenAnswer((_) async => 1);
    when(
      () => mockDb.updateRecipeWithIngredients(any(), any()),
    ).thenAnswer((_) async => {});
    when(() => mockDb.deleteRecipe(any())).thenAnswer((_) async => 1);
  });

  tearDown(() async {
    await db.close();
  });

  group('saveRecipe', () {
    test('calls insertRecipeWithIngredients for a new recipe', () async {
      const recipe = Recipe(name: 'Soup');
      const ingredients = [
        RecipeIngredient(recipeId: 0, name: 'Carrots', quantity: 3),
      ];

      final id = await mockDb.insertRecipeWithIngredients(recipe, ingredients);
      expect(id, 1);
      verify(
        () => mockDb.insertRecipeWithIngredients(recipe, ingredients),
      ).called(1);
    });

    test('calls updateRecipeWithIngredients for an existing recipe', () async {
      const recipe = Recipe(id: 1, name: 'Soup');
      const ingredients = [
        RecipeIngredient(recipeId: 1, name: 'Carrots'),
      ];

      await mockDb.updateRecipeWithIngredients(recipe, ingredients);
      verify(
        () => mockDb.updateRecipeWithIngredients(recipe, ingredients),
      ).called(1);
    });

    test('insertRecipe throws on empty name via database', () {
      const empty = Recipe(name: '');
      when(() => mockDb.insertRecipe(any())).thenAnswer(
        (_) async => throw ArgumentError('Recipe name is required'),
      );

      expect(
        () => mockDb.insertRecipe(empty),
        throwsArgumentError,
      );
    });
  });

  group('deleteRecipe', () {
    test('calls deleteRecipe on the database', () async {
      await mockDb.deleteRecipe(1);
      verify(() => mockDb.deleteRecipe(1)).called(1);
    });
  });

  group('getAllRecipes', () {
    test('returns recipes from database', () async {
      const recipes = [
        Recipe(id: 1, name: 'Soup'),
        Recipe(id: 2, name: 'Salad'),
      ];
      when(() => mockDb.getAllRecipes()).thenAnswer((_) async => recipes);

      final result = await mockDb.getAllRecipes();
      expect(result.length, 2);
      expect(result[0].name, 'Soup');
      expect(result[1].name, 'Salad');
    });

    test('returns empty list when no recipes', () async {
      final result = await mockDb.getAllRecipes();
      expect(result, isEmpty);
    });
  });

  group('getRecipeIngredients', () {
    test('returns ingredients for a recipe', () async {
      const ingredients = [
        RecipeIngredient(id: 1, recipeId: 1, name: 'Carrots'),
      ];
      when(
        () => mockDb.getRecipeIngredients(1),
      ).thenAnswer((_) async => ingredients);

      final result = await mockDb.getRecipeIngredients(1);
      expect(result.length, 1);
      expect(result[0].name, 'Carrots');
    });

    test('returns empty list for recipe with no ingredients', () async {
      final result = await mockDb.getRecipeIngredients(999);
      expect(result, isEmpty);
    });
  });

  group('calculateRecipeCost', () {
    test('returns 0 when ingredients list is empty', () async {
      when(() => mockDb.getRecipeIngredients(1)).thenAnswer((_) async => []);

      final ingredients = await mockDb.getRecipeIngredients(1);
      expect(ingredients, isEmpty);
    });
  });

  group('calculateAverageRecipeCost', () {
    test('returns 0 when no recipes exist', () async {
      when(() => mockDb.getAllRecipes()).thenAnswer((_) async => []);

      final recipes = await mockDb.getAllRecipes();
      expect(recipes, isEmpty);
    });
  });

  group('checkIngredientShortages', () {
    test('accumulates shortage for multiple rows with same barcode', () async {
      when(
        () => mockDb.getInventoryRowsByBarcode(
          barcode: '001',
          inventoryId: 1,
        ),
      ).thenAnswer(
        (_) async => [
          {'quantity': 5, 'unit': 'pieces', 'id': 1},
        ],
      );

      final ingredients = [
        const RecipeIngredient(
          recipeId: 1,
          name: 'Garlic',
          barcode: '001',
          quantity: 3,
        ),
        const RecipeIngredient(
          recipeId: 1,
          name: 'Garlic',
          barcode: '001',
          quantity: 4,
        ),
      ];
      final shortages = await checkIngredientShortages(mockDb, ingredients, 1);
      // Total needed = 7, available = 5 -> deficit of 2
      expect(shortages, containsPair('Garlic', closeTo(2, 0.01)));
    });

    test('handles unit conversion (recipe g, inventory kg)', () async {
      when(
        () => mockDb.getInventoryRowsByBarcode(
          barcode: '002',
          inventoryId: 1,
        ),
      ).thenAnswer(
        (_) async => [
          {'quantity': 1, 'unit': 'kg', 'id': 1},
        ],
      );

      final ingredients = [
        const RecipeIngredient(
          recipeId: 1,
          name: 'Flour',
          barcode: '002',
          quantity: 100,
          unit: 'g',
        ),
      ];
      final shortages = await checkIngredientShortages(mockDb, ingredients, 1);
      // 1 kg = 1000 g, need 100 g -> no shortage
      expect(shortages, isEmpty);
    });

    test('returns shortage with incompatible units', () async {
      when(
        () => mockDb.getInventoryRowsByBarcode(
          barcode: '002',
          inventoryId: 1,
        ),
      ).thenAnswer(
        (_) async => [
          {'quantity': 1, 'unit': 'L', 'id': 1},
        ],
      );

      final ingredients = [
        const RecipeIngredient(
          recipeId: 1,
          name: 'Flour',
          barcode: '002',
          quantity: 100,
          unit: 'g',
        ),
      ];
      final shortages = await checkIngredientShortages(mockDb, ingredients, 1);
      // g and L are incompatible -> available stays 0 -> shortage
      expect(shortages, isNotEmpty);
    });

    test('skips ingredients without barcode', () async {
      final ingredients = [
        const RecipeIngredient(recipeId: 1, name: 'Salt'),
      ];
      final shortages = await checkIngredientShortages(mockDb, ingredients, 1);
      expect(shortages, isEmpty);
    });

    test('returns empty when stock is sufficient', () async {
      when(
        () => mockDb.getInventoryRowsByBarcode(
          barcode: '003',
          inventoryId: 1,
        ),
      ).thenAnswer(
        (_) async => [
          {'quantity': 10, 'unit': 'pieces', 'id': 1},
        ],
      );

      final ingredients = [
        const RecipeIngredient(
          recipeId: 1,
          name: 'Eggs',
          barcode: '003',
          quantity: 3,
        ),
      ];
      final shortages = await checkIngredientShortages(mockDb, ingredients, 1);
      expect(shortages, isEmpty);
    });

    test(
      'falls back to product name match when barcode lookup is empty',
      () async {
        when(
          () => mockDb.getInventoryRowsByBarcode(
            barcode: 'plu-12345',
            inventoryId: 1,
          ),
        ).thenAnswer((_) async => []);
        when(
          () => mockDb.getInventoryRowsByProductName(
            name: 'Onion',
            inventoryId: 1,
          ),
        ).thenAnswer(
          (_) async => [
            {'quantity': 5, 'unit': 'pieces', 'id': 1},
          ],
        );

        final ingredients = [
          const RecipeIngredient(
            recipeId: 1,
            name: 'Onion',
            barcode: 'plu-12345',
            quantity: 2,
          ),
        ];
        final shortages = await checkIngredientShortages(
          mockDb,
          ingredients,
          1,
        );
        expect(shortages, isEmpty);
      },
    );

    test(
      'reports shortage when both barcode and name lookup are empty',
      () async {
        when(
          () => mockDb.getInventoryRowsByBarcode(
            barcode: 'plu-67890',
            inventoryId: 1,
          ),
        ).thenAnswer((_) async => []);
        when(
          () => mockDb.getInventoryRowsByProductName(
            name: 'Onion',
            inventoryId: 1,
          ),
        ).thenAnswer((_) async => []);

        final ingredients = [
          const RecipeIngredient(
            recipeId: 1,
            name: 'Onion',
            barcode: 'plu-67890',
            quantity: 2,
          ),
        ];
        final shortages = await checkIngredientShortages(
          mockDb,
          ingredients,
          1,
        );
        expect(shortages, isNotEmpty);
        expect(shortages['Onion'], closeTo(2, 0.01));
      },
    );

    test(
      'converts produce pieces via servingWeightG from inventory row when'
      ' barcode lookup finds no match',
      () async {
        when(
          () => mockDb.getInventoryRowsByBarcode(
            barcode: 'plu-12345',
            inventoryId: 1,
          ),
        ).thenAnswer((_) async => []);
        when(
          () => mockDb.getInventoryRowsByProductName(
            name: 'Onion',
            inventoryId: 1,
          ),
        ).thenAnswer(
          (_) async => [
            {
              'quantity': 150,
              'unit': 'g',
              'id': 1,
              'serving_weight_g': 150.0,
            },
          ],
        );

        final ingredients = [
          const RecipeIngredient(
            recipeId: 1,
            name: 'Onion',
            barcode: 'plu-12345',
          ),
        ];
        final shortages = await checkIngredientShortages(
          mockDb,
          ingredients,
          1,
        );
        expect(shortages, isEmpty);
      },
    );

    test(
      'converts produce pieces via ProduceServingPresets fallback when'
      ' inventory row has no servingWeightG',
      () async {
        when(
          () => mockDb.getInventoryRowsByBarcode(
            barcode: 'produce-Onion',
            inventoryId: 1,
          ),
        ).thenAnswer(
          (_) async => [
            {'quantity': 150, 'unit': 'g', 'id': 1},
          ],
        );

        final ingredients = [
          const RecipeIngredient(
            recipeId: 1,
            name: 'Onion',
            barcode: 'produce-Onion',
          ),
        ];
        final shortages = await checkIngredientShortages(
          mockDb,
          ingredients,
          1,
        );
        expect(shortages, isEmpty);
      },
    );

    test(
      'reports shortage when produce has no serving weight resolution',
      () async {
        when(
          () => mockDb.getInventoryRowsByBarcode(
            barcode: 'plu-99999',
            inventoryId: 1,
          ),
        ).thenAnswer((_) async => []);
        when(
          () => mockDb.getInventoryRowsByProductName(
            name: 'UnmatchedProduce',
            inventoryId: 1,
          ),
        ).thenAnswer(
          (_) async => [
            {'quantity': 100, 'unit': 'g', 'id': 1},
          ],
        );

        final ingredients = [
          const RecipeIngredient(
            recipeId: 1,
            name: 'UnmatchedProduce',
            barcode: 'plu-99999',
            quantity: 2,
          ),
        ];
        final shortages = await checkIngredientShortages(
          mockDb,
          ingredients,
          1,
        );
        expect(shortages, isNotEmpty);
        expect(shortages['UnmatchedProduce'], closeTo(2, 0.01));
      },
    );
  });
}
