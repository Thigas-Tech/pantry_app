import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/models/recipe.dart';
import 'package:pantry_app/models/recipe_ingredient.dart';
import 'package:pantry_app/providers/database_provider.dart';
import 'package:pantry_app/providers/product_repository_provider.dart';
import 'package:pantry_app/providers/recipe_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../helpers/pump_app.dart';

class MockDatabaseHelper extends Mock implements DatabaseHelper {}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Database db;
  late MockDatabaseHelper mockDb;
  late MockProductRepository mockRepo;

  setUp(() async {
    mockDb = MockDatabaseHelper();
    mockRepo = createMockProductRepository();
    db = await databaseFactory.openDatabase(inMemoryDatabasePath);
    SharedPreferences.setMockInitialValues({});

    when(() => mockDb.database).thenAnswer((_) async => db);
  });

  tearDown(() async {
    await db.close();
  });

  group('recipeNutritionProvider', () {
    test('returns null for non-existent recipe', () async {
      when(() => mockDb.getRecipeIngredients(1)).thenAnswer((_) async => []);
      when(() => mockDb.getRecipe(1)).thenAnswer((_) async => null);

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(mockDb),
          productRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(recipeNutritionProvider(1).future);
      expect(result, isNull);
    });

    test('returns aggregated nutrition', () async {
      when(() => mockDb.getRecipeIngredients(1)).thenAnswer(
        (_) async => [
          const RecipeIngredient(
            recipeId: 1,
            name: 'Milk',
            barcode: '001',
            quantity: 200,
            unit: 'g',
          ),
        ],
      );
      when(() => mockDb.getRecipe(1)).thenAnswer(
        (_) async => const Recipe(id: 1, name: 'Test', servings: 4),
      );
      when(() => mockRepo.getProduct('001')).thenAnswer(
        (_) async => const Product(
          barcode: '001',
          name: 'Milk',
          energyKcal: 42,
          proteinG: 3.4,
          carbsG: 5,
          fatG: 1,
          fiberG: 0,
          saltG: 0.1,
        ),
      );

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(mockDb),
          productRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(recipeNutritionProvider(1).future);
      expect(result, isNotNull);
      expect(result!.totalWeightG, 200);
      expect(result.totalEnergyKcal, closeTo(84, 0.01));
      expect(result.servings, 4);
      expect(result.perServingEnergyKcal, closeTo(21, 0.01));
    });
  });

  group('recipeNutriScoreProvider', () {
    test('returns null for empty ingredients', () async {
      when(() => mockDb.getRecipeIngredients(1)).thenAnswer((_) async => []);

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(mockDb),
          productRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(recipeNutriScoreProvider(1).future);
      expect(result, isNull);
    });

    test('returns grade when ingredients have scores', () async {
      when(() => mockDb.getRecipeIngredients(1)).thenAnswer(
        (_) async => [
          const RecipeIngredient(
            recipeId: 1,
            name: 'Healthy',
            barcode: '001',
            quantity: 100,
            unit: 'g',
          ),
        ],
      );
      when(() => mockDb.getProduct('001')).thenAnswer(
        (_) async => const Product(
          barcode: '001',
          name: 'Healthy',
          nutriscoreGrade: 'a',
        ),
      );

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(mockDb),
          productRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(recipeNutriScoreProvider(1).future);
      expect(result, 'A');
    });
  });
}
