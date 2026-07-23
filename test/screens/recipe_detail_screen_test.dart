import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/models/recipe.dart';
import 'package:pantry_app/models/recipe_ingredient.dart';
import 'package:pantry_app/providers/active_inventory_provider.dart';
import 'package:pantry_app/providers/database_provider.dart';
import 'package:pantry_app/screens/recipe_detail_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../helpers/pump_app.dart';

class MockDatabaseHelper extends Mock implements DatabaseHelper {}

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

  setUp(() async {
    mockDb = MockDatabaseHelper();
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
        const RecipeIngredient(recipeId: 1, name: 'Eggs', quantity: 2.0),
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

      expect(find.text('I made this'), findsOneWidget);
    });

    testWidgets('shows Edit button in AppBar', (tester) async {
      await pumpDetailScreen(tester);

      expect(find.byIcon(Icons.edit), findsOneWidget);
    });
  });
}
