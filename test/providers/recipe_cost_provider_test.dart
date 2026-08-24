import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/models/recipe.dart';
import 'package:pantry_app/models/recipe_ingredient.dart';
import 'package:pantry_app/providers/database_provider.dart';
import 'package:pantry_app/providers/recipe_service_provider.dart';
import 'package:pantry_app/services/recipe_service.dart';

class _MockRecipeService extends Mock implements RecipeService {}

class _MockDatabaseHelper extends Mock implements DatabaseHelper {}

void main() {
  late _MockRecipeService mockService;

  setUp(() {
    mockService = _MockRecipeService();
    when(
      () => mockService.calculateRecipeCost(
        any(),
        activeInventoryId: any(named: 'activeInventoryId'),
        baseCurrency: any(named: 'baseCurrency'),
      ),
    ).thenAnswer((_) async => 12.5);
    when(
      () => mockService.calculateAverageRecipeCost(
        activeInventoryId: any(named: 'activeInventoryId'),
        baseCurrency: any(named: 'baseCurrency'),
      ),
    ).thenAnswer((_) async => 8.0);
  });

  test('recipeCostProvider caches across reads for the same key', () async {
    final container = ProviderContainer(
      overrides: [recipeServiceProvider.overrideWithValue(mockService)],
    );
    addTearDown(container.dispose);

    final first = await container.read(
      recipeCostProvider((7, 1, 'USD')).future,
    );
    final second = await container.read(
      recipeCostProvider((7, 1, 'USD')).future,
    );

    expect(first, 12.5);
    expect(second, 12.5);
    verify(
      () => mockService.calculateRecipeCost(
        7,
        activeInventoryId: any(named: 'activeInventoryId'),
        baseCurrency: any(named: 'baseCurrency'),
      ),
    ).called(1);
  });

  test('recipeCostProvider passes the key values through', () async {
    final container = ProviderContainer(
      overrides: [recipeServiceProvider.overrideWithValue(mockService)],
    );
    addTearDown(container.dispose);

    await container.read(recipeCostProvider((3, 2, 'EUR')).future);

    verify(
      () => mockService.calculateRecipeCost(
        3,
        activeInventoryId: 2,
        baseCurrency: 'EUR',
      ),
    ).called(1);
  });

  test(
    'averageRecipeCostProvider caches across reads for the same key',
    () async {
      final container = ProviderContainer(
        overrides: [recipeServiceProvider.overrideWithValue(mockService)],
      );
      addTearDown(container.dispose);

      final first = await container.read(
        averageRecipeCostProvider((1, 'USD')).future,
      );
      final second = await container.read(
        averageRecipeCostProvider((1, 'USD')).future,
      );

      expect(first, 8.0);
      expect(second, 8.0);
      verify(
        () => mockService.calculateAverageRecipeCost(
          activeInventoryId: any(named: 'activeInventoryId'),
          baseCurrency: any(named: 'baseCurrency'),
        ),
      ).called(1);
    },
  );

  group('recipeIngredientCostsProvider', () {
    test('passes the recipe inventory through and maps costs', () async {
      registerFallbackValue(<RecipeIngredient>[]);
      registerFallbackValue(const Recipe(id: 7, name: 'R', inventoryId: 2));
      final mockDb = _MockDatabaseHelper();
      when(() => mockDb.getRecipe(7)).thenAnswer(
        (_) async => const Recipe(id: 7, name: 'R', inventoryId: 2),
      );
      when(() => mockDb.getRecipeIngredients(7)).thenAnswer(
        (_) async => <RecipeIngredient>[],
      );
      when(
        () => mockService.ingredientCosts(
          any(),
          inventoryId: any(named: 'inventoryId'),
          baseCurrency: any(named: 'baseCurrency'),
        ),
      ).thenAnswer((_) async => {'b': 0.5});

      final container = ProviderContainer(
        overrides: [
          recipeServiceProvider.overrideWithValue(mockService),
          databaseProvider.overrideWithValue(mockDb),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(
        recipeIngredientCostsProvider((7, 1, 'USD')).future,
      );

      expect(result, {'b': 0.5});
      verify(
        () => mockService.ingredientCosts(
          any(),
          inventoryId: 2,
          baseCurrency: 'USD',
        ),
      ).called(1);
    });
  });
}
