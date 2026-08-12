import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/models/recipe.dart';
import 'package:pantry_app/models/recipe_ingredient.dart';
import 'package:pantry_app/providers/active_inventory_provider.dart';
import 'package:pantry_app/providers/database_provider.dart';
import 'package:pantry_app/providers/firebase_cache_provider.dart';
import 'package:pantry_app/providers/product_repository_provider.dart';
import 'package:pantry_app/screens/recipe_detail_screen.dart';
import 'package:pantry_app/services/firebase_cache_service.dart';
import 'package:pantry_app/services/product_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../helpers/pump_app.dart';

class MockDatabaseHelper extends Mock implements DatabaseHelper {}

class MockFirebaseCacheService extends Mock implements FirebaseCacheService {}

class FakeActiveInventoryNotifier extends ActiveInventoryNotifier {
  @override
  int build() => 1;

  @override
  void setActiveInventory(int newValue) {}
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Database db;
  late MockDatabaseHelper mockDb;
  late ProductRepository mockRepo;

  setUp(() async {
    mockDb = MockDatabaseHelper();
    mockRepo = MockProductRepository();
    when(
      () =>
          mockRepo.getProduct(any(), languageCode: any(named: 'languageCode')),
    ).thenAnswer(
      (_) async => const Product(
        barcode: '',
        name: '',
        source: 'manual',
      ),
    );
    when(mockRepo.isCacheOverdue).thenAnswer((_) async => false);
    when(mockRepo.getLastRefreshTime).thenAnswer((_) async => null);
    when(
      () => mockRepo.getProductFromCache(any()),
    ).thenAnswer((_) async => null);
    db = await databaseFactory.openDatabase(inMemoryDatabasePath);
    SharedPreferences.setMockInitialValues({});

    when(() => mockDb.database).thenAnswer((_) async => db);
    when(() => mockDb.getRecipe(1)).thenAnswer(
      (_) async => const Recipe(
        id: 1,
        name: 'Omelette',
        instructions: 'Beat eggs. Cook.',
      ),
    );
    when(() => mockDb.getRecipeIngredients(1)).thenAnswer(
      (_) async => [
        const RecipeIngredient(recipeId: 1, name: 'Eggs', quantity: 2),
      ],
    );
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> pumpDetailScreen(WidgetTester tester) {
    return pumpApp(
      tester,
      const RecipeDetailScreen(recipeId: 1),
      overrides: [
        databaseProvider.overrideWithValue(mockDb),
        activeInventoryProvider.overrideWith(FakeActiveInventoryNotifier.new),
        productRepositoryProvider.overrideWithValue(mockRepo),
        firebaseCacheProvider.overrideWithValue(MockFirebaseCacheService()),
      ],
    );
  }

  group('RecipeDetailScreen', () {
    testWidgets('displays recipe name, ingredients, and instructions', (
      tester,
    ) async {
      await pumpDetailScreen(tester);

      expect(find.text('Omelette'), findsOneWidget);
      expect(find.text('2.0 x Eggs'), findsOneWidget);
      expect(find.text('Beat eggs. Cook.'), findsOneWidget);
    });

    testWidgets('shows I made this button', (tester) async {
      await pumpDetailScreen(tester);

      expect(find.text('I made this', skipOffstage: false), findsOneWidget);
    });

    testWidgets('shows Edit button in AppBar', (tester) async {
      await pumpDetailScreen(tester);

      expect(find.byIcon(Icons.edit), findsOneWidget);
    });

    testWidgets('shows History button in AppBar', (tester) async {
      await pumpDetailScreen(tester);

      expect(find.byIcon(Icons.history), findsOneWidget);
    });
  });
}
