import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/models/recipe.dart';
import 'package:pantry_app/models/recipe_ingredient.dart';
import 'package:pantry_app/providers/active_inventory_provider.dart';
import 'package:pantry_app/providers/database_provider.dart';
import 'package:pantry_app/providers/firebase_cache_provider.dart';
import 'package:pantry_app/providers/recipe_service_provider.dart';
import 'package:pantry_app/providers/settings_provider.dart';
import 'package:pantry_app/services/currency_service.dart';
import 'package:pantry_app/services/firebase_cache_service.dart';
import 'package:pantry_app/services/recipe_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

class MockDatabaseHelper extends Mock implements DatabaseHelper {}

class MockFirebaseCacheService extends Mock implements FirebaseCacheService {}

class MockDatabase extends Mock implements Database {}

class MockTransaction extends Mock implements Transaction {}

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
    dotenv.loadFromString(isOptional: true, mergeWith: {});
    registerFallbackValue(const Recipe(name: ''));
    registerFallbackValue(const RecipeIngredient(recipeId: 0, name: ''));
  });

  group('checkIngredientShortages with NULL quantity rows', () {
    late MockDatabaseHelper mockDb;

    setUp(() {
      mockDb = MockDatabaseHelper();
      when(
        () => mockDb.getInventoryRowsByBarcode(
          barcode: any(named: 'barcode'),
          inventoryId: any(named: 'inventoryId'),
        ),
      ).thenAnswer(
        (_) async => [
          {'quantity': null, 'unit': 'pieces', 'id': 1},
        ],
      );
      when(
        () => mockDb.getInventoryRowsByProductName(
          name: any(named: 'name'),
          inventoryId: any(named: 'inventoryId'),
        ),
      ).thenAnswer((_) async => []);
    });

    test('treats NULL quantity as zero without crashing', () async {
      const ingredients = [
        RecipeIngredient(
          recipeId: 1,
          barcode: '001',
          name: 'Eggs',
          quantity: 2,
        ),
      ];

      final service = RecipeService(
        mockDb,
        MockFirebaseCacheService(),
        CurrencyService(),
      );
      final shortages = await service.checkIngredientShortages(ingredients, 1);

      expect(shortages, {'Eggs': 2.0});
    });
  });

  group('cookRecipe with NULL quantity inventory row', () {
    late MockDatabaseHelper mockDb;
    late MockDatabase mockDatabase;
    late MockTransaction mockTxn;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      mockDb = MockDatabaseHelper();
      mockDatabase = MockDatabase();
      mockTxn = MockTransaction();

      when(() => mockDb.database).thenAnswer((_) async => mockDatabase);
      when(() => mockDatabase.transaction<CookResult>(any())).thenAnswer(
        (invocation) =>
            (invocation.positionalArguments.first as dynamic)(mockTxn)
                as Future<CookResult>,
      );
      when(() => mockDatabase.rawQuery(any(), any())).thenAnswer(
        (_) async => [],
      );
      when(() => mockTxn.rawQuery(any(), any())).thenAnswer(
        (_) async => [
          {'id': 1, 'quantity': null, 'unit': 'pieces'},
        ],
      );
      when(() => mockTxn.insert(any(), any())).thenAnswer((_) async => 1);
      when(
        () => mockTxn.delete(
          any(),
          where: any(named: 'where'),
          whereArgs: any(named: 'whereArgs'),
        ),
      ).thenAnswer((_) async => 1);
      when(
        () => mockTxn.update(
          any(),
          any(),
          where: any(named: 'where'),
          whereArgs: any(named: 'whereArgs'),
        ),
      ).thenAnswer((_) async => 1);

      when(() => mockDb.getRecipe(1)).thenAnswer(
        (_) async => const Recipe(id: 1, name: 'Eggs', createdAt: 1000),
      );
      when(() => mockDb.getRecipeIngredients(1)).thenAnswer(
        (_) async => const [
          RecipeIngredient(
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
      when(() => mockDb.getAllRecipes(any())).thenAnswer((_) async => []);
      when(
        () => mockDb.getInventoryWithProduct(
          inventoryId: any(named: 'inventoryId'),
        ),
      ).thenAnswer((_) async => []);
    });

    testWidgets('deducts from a NULL quantity row without crashing', (
      tester,
    ) async {
      var cookCompleted = false;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(mockDb),
            firebaseCacheProvider.overrideWithValue(MockFirebaseCacheService()),
            activeInventoryProvider.overrideWith(
              FakeActiveInventoryNotifier.new,
            ),
            settingsProvider.overrideWith(
              () => FakeSettingsNotifier() as SettingsNotifier,
            ),
          ],
          child: MaterialApp(
            home: _CookButton(
              onCook: (ref) {
                unawaited(
                  ref
                      .read(recipeServiceProvider)
                      .cookRecipe(
                        1,
                        activeInventoryId: ref.read(activeInventoryProvider),
                        baseCurrency: ref.read(settingsProvider).baseCurrency,
                      )
                      .then((_) {
                        cookCompleted = true;
                      }),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Cook'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(cookCompleted, isTrue);
      verify(
        () => mockTxn.delete(
          'inventory',
          where: 'id = ?',
          whereArgs: [1],
        ),
      ).called(1);
    });
  });
}

class _CookButton extends ConsumerWidget {
  const _CookButton({required this.onCook});

  final void Function(WidgetRef ref) onCook;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () => onCook(ref),
      child: const Text('Cook'),
    );
  }
}
