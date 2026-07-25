import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/models/recipe_history_entry.dart';
import 'package:pantry_app/providers/database_provider.dart';
import 'package:pantry_app/screens/recipe_history_screen.dart';
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

  setUp(() async {
    mockDb = MockDatabaseHelper();
    db = await databaseFactory.openDatabase(inMemoryDatabasePath);
    SharedPreferences.setMockInitialValues({});

    when(() => mockDb.database).thenAnswer((_) async => db);
    when(() => mockDb.getRecipeHistory(1)).thenAnswer((_) async => []);
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> pumpHistoryScreen(WidgetTester tester) {
    return pumpApp(
      tester,
      const RecipeHistoryScreen(recipeId: 1, recipeName: 'Omelette'),
      overrides: [
        databaseProvider.overrideWithValue(mockDb),
      ],
    );
  }

  group('RecipeHistoryScreen', () {
    testWidgets('shows empty state when no history', (tester) async {
      await pumpHistoryScreen(tester);

      expect(find.text('No cooking history yet'), findsOneWidget);
    });

    testWidgets('shows history entries', (tester) async {
      when(() => mockDb.getRecipeHistory(1)).thenAnswer(
        (_) async => [
          RecipeHistoryEntry(
            recipeId: 1,
            madeAt: DateTime(2026, 7, 20).millisecondsSinceEpoch,
            costAtTime: 12.50,
            ingredientSnapshot: '[{"name":"Eggs","quantity":2}]',
          ),
          RecipeHistoryEntry(
            recipeId: 1,
            madeAt: DateTime(2026, 7, 18).millisecondsSinceEpoch,
            costAtTime: 15,
            ingredientSnapshot:
                '[{"name":"Eggs","quantity":2},{"name":"Cheese","quantity":1}]',
          ),
        ],
      );

      await pumpHistoryScreen(tester);

      expect(find.text('20/7/2026'), findsOneWidget);
      expect(find.text('18/7/2026'), findsOneWidget);
    });

    testWidgets('shows title with recipe name', (tester) async {
      await pumpHistoryScreen(tester);

      expect(find.text('Omelette - History'), findsOneWidget);
    });
  });
}
