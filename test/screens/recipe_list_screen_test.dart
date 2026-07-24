import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/models/recipe.dart';
import 'package:pantry_app/models/recipe_ingredient.dart';
import 'package:pantry_app/providers/database_provider.dart';
import 'package:pantry_app/providers/settings_provider.dart';
import 'package:pantry_app/screens/recipe_list_screen.dart';
import 'package:pantry_app/widgets/price_mask.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import '../helpers/pump_app.dart';

class MockDatabaseHelper extends Mock implements DatabaseHelper {}

class MockSqfliteDatabase extends Mock implements Database {}

class FakeSettingsNotifier extends SettingsNotifier {
  FakeSettingsNotifier(this.settings);

  final Settings settings;

  @override
  Settings build() => settings;
}

void main() {
  late MockDatabaseHelper mockDb;
  late MockSqfliteDatabase mockSqfliteDb;

  setUp(() {
    mockDb = MockDatabaseHelper();
    mockSqfliteDb = MockSqfliteDatabase();
    SharedPreferences.setMockInitialValues({});
  });

  group('PriceMask in recipe list', () {
    Future<void> pumpList(
      WidgetTester tester,
      Settings settings, {
      bool hasPriceData = true,
    }) async {
      when(() => mockDb.getAllRecipes()).thenAnswer(
        (_) async => [
          const Recipe(id: 1, name: 'Omelette'),
        ],
      );
      when(() => mockDb.getRecipeIngredients(1)).thenAnswer(
        (_) async => [
          const RecipeIngredient(
            recipeId: 1,
            name: 'Eggs',
            quantity: 2,
            barcode: '123456',
          ),
        ],
      );
      when(() => mockDb.database).thenAnswer((_) async => mockSqfliteDb);

      if (hasPriceData) {
        when(
          () => mockSqfliteDb.rawQuery(
            any(),
            any(),
          ),
        ).thenAnswer(
          (_) async => [
            {'price': 3.50, 'currency': 'USD'},
          ],
        );
      } else {
        when(
          () => mockSqfliteDb.rawQuery(
            any(),
            any(),
          ),
        ).thenAnswer((_) async => []);
      }

      final notifier = FakeSettingsNotifier(settings);

      await pumpApp(
        tester,
        const RecipeListScreen(),
        overrides: [
          databaseProvider.overrideWithValue(mockDb),
          settingsProvider.overrideWith(() => notifier),
        ],
        settle: false,
      );

      // Multiple pumps to resolve FutureProvider + FutureBuilders
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    testWidgets('wraps cost labels when prices visible', (tester) async {
      await pumpList(
        tester,
        const Settings(priceTrackingEnabled: true),
      );

      expect(find.byType(PriceMask), findsAtLeast(1));
      expect(find.textContaining('3.50'), findsAtLeast(1));
    });

    testWidgets('masks cost labels when prices hidden', (tester) async {
      await pumpList(
        tester,
        const Settings(
          priceTrackingEnabled: true,
          pricesHidden: true,
        ),
      );

      expect(find.byType(PriceMask), findsAtLeast(1));
      expect(find.textContaining('3.50'), findsNothing);
    });

    testWidgets('shows unknown cost when cost is zero', (tester) async {
      await pumpList(
        tester,
        const Settings(),
        hasPriceData: false,
      );

      expect(find.byType(PriceMask), findsAtLeast(1));
      expect(find.text('Unknown'), findsOneWidget);
    });
  });
}
