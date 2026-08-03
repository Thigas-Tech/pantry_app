import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/models/recipe.dart';
import 'package:pantry_app/models/recipe_ingredient.dart';
import 'package:pantry_app/providers/active_inventory_provider.dart';
import 'package:pantry_app/providers/database_provider.dart';
import 'package:pantry_app/providers/pantry_provider.dart';
import 'package:pantry_app/providers/product_repository_provider.dart';
import 'package:pantry_app/providers/recipe_provider.dart';
import 'package:pantry_app/providers/settings_provider.dart';
import 'package:pantry_app/services/product_repository.dart';
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

class FakeSettingsNotifier extends SettingsNotifier {
  @override
  Settings build() => const Settings();
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    registerFallbackValue(const Recipe(name: ''));
    registerFallbackValue(const RecipeIngredient(recipeId: 0, name: ''));
  });

  late MockDatabaseHelper mockDb;
  late ProductRepository mockRepo;

  setUp(() {
    mockDb = MockDatabaseHelper();
    mockRepo = createMockProductRepository();
    when(() => mockDb.database).thenAnswer(
      (_) async {
        final db = await databaseFactory.openDatabase(inMemoryDatabasePath);
        return db;
      },
    );
    when(() => mockDb.getRecipe(1)).thenAnswer(
      (_) async => const Recipe(id: 1, name: 'Eggs', createdAt: 1000),
    );
    when(() => mockDb.getRecipeIngredients(1)).thenAnswer(
      (_) async => [
        const RecipeIngredient(
          recipeId: 1,
          barcode: '001',
          name: 'Eggs',
          quantity: 2,
        ),
      ],
    );
    when(
      () => mockDb.getInventoryRowsByBarcode(
        barcode: any(named: 'barcode'),
        inventoryId: any(named: 'inventoryId'),
      ),
    ).thenAnswer(
      (_) async => [
        {'quantity': 12, 'unit': 'pieces', 'id': 1},
      ],
    );
    when(
      () => mockDb.getInventoryRowsByProductName(
        name: any(named: 'name'),
        inventoryId: any(named: 'inventoryId'),
      ),
    ).thenAnswer((_) async => []);

    when(
      () =>
          mockRepo.getProduct(any(), languageCode: any(named: 'languageCode')),
    ).thenAnswer(
      (_) async => const Product(
        barcode: '001',
        name: 'Eggs',
        source: 'manual',
      ),
    );

    SharedPreferences.setMockInitialValues({});
  });

  group('cookRecipe invalidation regression', () {
    testWidgets(
      'post-frame invalidation after cookRecipe does not throw'
      ' setState-during-build',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              databaseProvider.overrideWithValue(mockDb),
              activeInventoryProvider.overrideWith(
                FakeActiveInventoryNotifier.new,
              ),
              productRepositoryProvider.overrideWithValue(mockRepo),
              settingsProvider.overrideWith(
                () => FakeSettingsNotifier() as SettingsNotifier,
              ),
            ],
            child: const MaterialApp(
              home: _CookTestWidget(),
            ),
          ),
        );

        await tester.tap(find.text('Cook'));

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('Cook'), findsOneWidget);
      },
    );
  });
}

class _CookTestWidget extends ConsumerWidget {
  const _CookTestWidget();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () async {
        try {
          await cookRecipe(ref, 1);
        } on Exception {
          // Silently ignore -- we only care that the invalidation
          // that follows does not throw setState-during-build.
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.invalidate(pantryProvider);
        });
      },
      child: const Text('Cook'),
    );
  }
}
