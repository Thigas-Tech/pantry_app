import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/models/recipe.dart';
import 'package:pantry_app/models/recipe_ingredient.dart';
import 'package:pantry_app/providers/active_inventory_provider.dart';
import 'package:pantry_app/providers/database_provider.dart';
import 'package:pantry_app/providers/firebase_cache_provider.dart';
import 'package:pantry_app/providers/settings_provider.dart';
import 'package:pantry_app/screens/manage_inventories_screen.dart';
import 'package:pantry_app/screens/recipe_list_screen.dart';
import 'package:pantry_app/services/firebase_cache_service.dart';
import 'package:pantry_app/widgets/inventory_switcher_card.dart';
import 'package:pantry_app/widgets/price_mask.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import '../helpers/pump_app.dart';

class MockDatabaseHelper extends Mock implements DatabaseHelper {}

class MockFirebaseCacheService extends Mock implements FirebaseCacheService {}

class MockSqfliteDatabase extends Mock implements Database {}

class FakeSettingsNotifier extends SettingsNotifier {
  FakeSettingsNotifier(this.settings);

  final Settings settings;

  @override
  Settings build() => settings;
}

class FakeActiveInventoryNotifier extends ActiveInventoryNotifier {
  @override
  int build() => 1;

  @override
  void setActiveInventory(int id) {
    state = id;
  }
}

void main() {
  late MockDatabaseHelper mockDb;
  late MockSqfliteDatabase mockSqfliteDb;

  setUp(() {
    mockDb = MockDatabaseHelper();
    mockSqfliteDb = MockSqfliteDatabase();
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpList(
    WidgetTester tester,
    Settings settings, {
    bool hasPriceData = true,
    List<Recipe> homeRecipes = const [Recipe(id: 1, name: 'Omelette')],
    List<Override> extraOverrides = const [],
  }) async {
    when(() => mockDb.getInventories()).thenAnswer(
      (_) async => [
        {'id': 1, 'name': 'Home', 'created_at': 1, 'item_count': 0},
        {'id': 2, 'name': 'Work', 'created_at': 2, 'item_count': 0},
      ],
    );
    when(() => mockDb.getAllRecipes(1)).thenAnswer((_) async => homeRecipes);
    when(() => mockDb.getRecipe(any())).thenAnswer(
      (_) async => homeRecipes.isNotEmpty ? homeRecipes.first : null,
    );
    when(() => mockDb.getRecipeIngredients(any())).thenAnswer(
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

    when(
      () => mockSqfliteDb.query(
        any(),
        columns: any(named: 'columns'),
        where: any(named: 'where'),
        whereArgs: any(named: 'whereArgs'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer((_) async => []);

    final notifier = FakeSettingsNotifier(settings);

    await pumpApp(
      tester,
      const RecipeListScreen(),
      overrides: [
        databaseProvider.overrideWithValue(mockDb),
        settingsProvider.overrideWith(() => notifier),
        activeInventoryProvider.overrideWith(
          FakeActiveInventoryNotifier.new,
        ),
        firebaseCacheProvider.overrideWithValue(MockFirebaseCacheService()),
        ...extraOverrides,
      ],
      settle: false,
    );

    // Multiple pumps to resolve FutureProvider + FutureBuilders
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  group('PriceMask in recipe list', () {
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

  group('inventory switcher', () {
    testWidgets('shows the active inventory name', (tester) async {
      await pumpList(tester, const Settings());

      expect(find.byType(InventorySwitcherCard), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('tapping the switcher opens ManageInventoriesScreen', (
      tester,
    ) async {
      await pumpList(tester, const Settings());

      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();

      expect(find.byType(ManageInventoriesScreen), findsOneWidget);
    });

    testWidgets('switching inventory reloads the recipe list', (
      tester,
    ) async {
      await pumpList(
        tester,
        const Settings(),
        homeRecipes: const [Recipe(id: 1, name: 'Home Soup')],
      );
      when(() => mockDb.getAllRecipes(2)).thenAnswer(
        (_) async => [
          const Recipe(id: 2, name: 'Work Soup'),
        ],
      );

      expect(find.text('Home Soup'), findsOneWidget);
      expect(find.text('Work Soup'), findsNothing);

      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Work'));
      await tester.pumpAndSettle();

      expect(find.text('Work Soup'), findsOneWidget);
      expect(find.text('Home Soup'), findsNothing);
    });
  });
}
