import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/models/product_type.dart';
import 'package:pantry_app/providers/active_inventory_provider.dart';
import 'package:pantry_app/providers/database_provider.dart';
import 'package:pantry_app/providers/product_repository_provider.dart';
import 'package:pantry_app/providers/settings_provider.dart';
import 'package:pantry_app/screens/recipe_form_screen.dart';
import 'package:pantry_app/services/product_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../helpers/pump_app.dart';

class MockDatabaseHelper extends Mock implements DatabaseHelper {}

class MockProductRepository2 extends Mock implements ProductRepository {}

class FakeActiveInventoryNotifier extends ActiveInventoryNotifier {
  @override
  int build() => 1;

  @override
  void setActiveInventory(int newValue) {}
}

class FakeSettingsNotifierImperial extends SettingsNotifier {
  @override
  Settings build() => const Settings(
    unitSystem: UnitSystem.imperial,
    preferredWeightUnit: WeightUnitPreference.ounces,
  );
}

/// Fake with metric global but imperial override for recipe ingredients.
class FakeSettingsNotifierRecipeImperial extends SettingsNotifier {
  @override
  Settings build() => const Settings(
    unitSystemRecipeIngredients: UnitSystem.imperial,
    preferredWeightUnit: WeightUnitPreference.ounces,
  );
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late MockDatabaseHelper mockDb;
  late MockProductRepository2 mockRepo;

  setUp(() {
    mockDb = MockDatabaseHelper();
    mockRepo = MockProductRepository2();
    when(mockRepo.isCacheOverdue).thenAnswer((_) async => false);
    when(mockRepo.getLastRefreshTime).thenAnswer((_) async => null);
    SharedPreferences.setMockInitialValues({});
  });

  group('_addIngredient dedup', () {
    testWidgets('same barcode deduplicates with doubled quantity', (
      tester,
    ) async {
      when(
        () => mockDb.getDistinctProductsFromInventory(
          inventoryId: any(named: 'inventoryId'),
        ),
      ).thenAnswer(
        (_) async => [
          {'name': 'Flour', 'barcode': '123456'},
        ],
      );
      when(() => mockRepo.getProductFromCache(any())).thenAnswer(
        (_) async => null,
      );

      await pumpApp(
        tester,
        const RecipeFormScreen(),
        overrides: [
          databaseProvider.overrideWithValue(mockDb),
          activeInventoryProvider.overrideWith(
            FakeActiveInventoryNotifier.new,
          ),
          productRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );

      // First add
      await tester.tap(find.text('From your pantry'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add selected'));
      await tester.pumpAndSettle();

      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
      expect(find.text('1.0'), findsOneWidget);

      // Second add (same barcode)
      await tester.tap(find.text('From your pantry'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add selected'));
      await tester.pumpAndSettle();

      // Still one row, quantity doubled
      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
      expect(find.text('2.0'), findsOneWidget);
      expect(find.text('1.0'), findsNothing);
    });

    testWidgets('different barcodes create separate rows', (tester) async {
      when(
        () => mockDb.getDistinctProductsFromInventory(
          inventoryId: any(named: 'inventoryId'),
        ),
      ).thenAnswer(
        (_) async => [
          {'name': 'Flour', 'barcode': '123'},
          {'name': 'Sugar', 'barcode': '456'},
        ],
      );
      when(() => mockRepo.getProductFromCache(any())).thenAnswer(
        (_) async => null,
      );

      await pumpApp(
        tester,
        const RecipeFormScreen(),
        overrides: [
          databaseProvider.overrideWithValue(mockDb),
          activeInventoryProvider.overrideWith(
            FakeActiveInventoryNotifier.new,
          ),
          productRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );

      await tester.tap(find.text('From your pantry'));
      await tester.pumpAndSettle();

      final checkboxes = find.byType(CheckboxListTile);
      await tester.tap(checkboxes.at(0));
      await tester.pumpAndSettle();
      await tester.tap(checkboxes.at(1));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add selected'));
      await tester.pumpAndSettle();

      expect(find.byType(DropdownButtonFormField<String>), findsNWidgets(2));
    });

    testWidgets('free-text ingredients without barcode add separate rows', (
      tester,
    ) async {
      await pumpApp(
        tester,
        const RecipeFormScreen(),
        overrides: [
          databaseProvider.overrideWithValue(mockDb),
          activeInventoryProvider.overrideWith(
            FakeActiveInventoryNotifier.new,
          ),
        ],
      );

      await tester.tap(find.widgetWithText(TextButton, 'Add ingredient'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Add ingredient'));
      await tester.pumpAndSettle();

      expect(find.byType(DropdownButtonFormField<String>), findsNWidgets(2));
    });
  });

  group('pre-fill from product serving size', () {
    setUp(() {
      when(() => mockRepo.getProductFromCache(any())).thenAnswer(
        (_) async => null,
      );
    });

    testWidgets(
      'pre-fills quantity and unit from OFF serving data'
      ' when adding from pantry',
      (tester) async {
        when(
          () => mockDb.getDistinctProductsFromInventory(
            inventoryId: any(named: 'inventoryId'),
          ),
        ).thenAnswer(
          (_) async => [
            {'name': 'Flour', 'barcode': '123456'},
          ],
        );
        when(
          () => mockRepo.getProductFromCache('123456'),
        ).thenAnswer(
          (_) async => const Product(
            barcode: '123456',
            name: 'Flour',
            servingSize: '200g',
            servingQuantity: 200,
          ),
        );

        await pumpApp(
          tester,
          const RecipeFormScreen(),
          overrides: [
            databaseProvider.overrideWithValue(mockDb),
            activeInventoryProvider.overrideWith(
              FakeActiveInventoryNotifier.new,
            ),
            productRepositoryProvider.overrideWithValue(mockRepo),
          ],
        );

        await tester.tap(find.text('From your pantry'));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(CheckboxListTile));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Add selected'));
        await tester.pumpAndSettle();

        expect(find.text('200.0'), findsOneWidget);
        expect(find.text('1.0'), findsNothing);
      },
    );

    testWidgets(
      'pre-fills unit from servingSize when adding from pantry',
      (tester) async {
        when(
          () => mockDb.getDistinctProductsFromInventory(
            inventoryId: any(named: 'inventoryId'),
          ),
        ).thenAnswer(
          (_) async => [
            {'name': 'Flour', 'barcode': '123456'},
          ],
        );
        when(
          () => mockRepo.getProductFromCache('123456'),
        ).thenAnswer(
          (_) async => const Product(
            barcode: '123456',
            name: 'Flour',
            servingSize: '200g',
            servingQuantity: 200,
          ),
        );

        await pumpApp(
          tester,
          const RecipeFormScreen(),
          overrides: [
            databaseProvider.overrideWithValue(mockDb),
            activeInventoryProvider.overrideWith(
              FakeActiveInventoryNotifier.new,
            ),
            productRepositoryProvider.overrideWithValue(mockRepo),
          ],
        );

        await tester.tap(find.text('From your pantry'));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(CheckboxListTile));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Add selected'));
        await tester.pumpAndSettle();

        expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
        expect(find.text('g'), findsAtLeast(1));
      },
    );

    testWidgets(
      'uses default quantity and unit when product has no serving data',
      (tester) async {
        when(
          () => mockDb.getDistinctProductsFromInventory(
            inventoryId: any(named: 'inventoryId'),
          ),
        ).thenAnswer(
          (_) async => [
            {'name': 'Generic', 'barcode': '999'},
          ],
        );

        await pumpApp(
          tester,
          const RecipeFormScreen(),
          overrides: [
            databaseProvider.overrideWithValue(mockDb),
            activeInventoryProvider.overrideWith(
              FakeActiveInventoryNotifier.new,
            ),
            productRepositoryProvider.overrideWithValue(mockRepo),
          ],
        );

        await tester.tap(find.text('From your pantry'));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(CheckboxListTile));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Add selected'));
        await tester.pumpAndSettle();

        expect(find.text('1.0'), findsOneWidget);
      },
    );

    testWidgets(
      'pre-fills USDA gram weight for produce items',
      (tester) async {
        when(
          () => mockDb.getDistinctProductsFromInventory(
            inventoryId: any(named: 'inventoryId'),
          ),
        ).thenAnswer(
          (_) async => [
            {'name': 'Apple', 'barcode': 'produce-fuji-apple'},
          ],
        );
        when(
          () => mockRepo.getProductFromCache('produce-fuji-apple'),
        ).thenAnswer(
          (_) async => const Product(
            barcode: 'produce-fuji-apple',
            name: 'Apple',
            productType: ProductType.produce,
            usdaServingAmount: 1,
            usdaServingUnit: 'medium',
            usdaGramWeight: 182,
          ),
        );

        await pumpApp(
          tester,
          const RecipeFormScreen(),
          overrides: [
            databaseProvider.overrideWithValue(mockDb),
            activeInventoryProvider.overrideWith(
              FakeActiveInventoryNotifier.new,
            ),
            productRepositoryProvider.overrideWithValue(mockRepo),
          ],
        );

        await tester.tap(find.text('From your pantry'));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(CheckboxListTile));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Add selected'));
        await tester.pumpAndSettle();

        expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
        expect(find.text('182.0'), findsOneWidget);
        expect(find.text('1.0'), findsNothing);
      },
    );

    testWidgets(
      'dedup with pre-fill increments by serving quantity',
      (tester) async {
        when(
          () => mockDb.getDistinctProductsFromInventory(
            inventoryId: any(named: 'inventoryId'),
          ),
        ).thenAnswer(
          (_) async => [
            {'name': 'Flour', 'barcode': '123456'},
          ],
        );
        when(
          () => mockRepo.getProductFromCache('123456'),
        ).thenAnswer(
          (_) async => const Product(
            barcode: '123456',
            name: 'Flour',
            servingSize: '200g',
            servingQuantity: 200,
          ),
        );

        await pumpApp(
          tester,
          const RecipeFormScreen(),
          overrides: [
            databaseProvider.overrideWithValue(mockDb),
            activeInventoryProvider.overrideWith(
              FakeActiveInventoryNotifier.new,
            ),
            productRepositoryProvider.overrideWithValue(mockRepo),
          ],
        );

        await tester.tap(find.text('From your pantry'));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(CheckboxListTile));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Add selected'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('From your pantry'));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(CheckboxListTile));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Add selected'));
        await tester.pumpAndSettle();

        expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
        expect(find.text('400.0'), findsOneWidget);
        expect(find.text('200'), findsNothing);
      },
    );
  });

  // ---------- Imperial unit tests ------------------------------------------

  group('imperial pre-fill', () {
    setUp(() {
      when(() => mockRepo.getProductFromCache(any())).thenAnswer(
        (_) async => null,
      );
    });

    testWidgets(
      'pre-fills oz from serving data when system is imperial'
      ' with weightPref=ounces',
      (tester) async {
        when(
          () => mockDb.getDistinctProductsFromInventory(
            inventoryId: any(named: 'inventoryId'),
          ),
        ).thenAnswer(
          (_) async => [
            {'name': 'Flour', 'barcode': '123456'},
          ],
        );
        when(
          () => mockRepo.getProductFromCache('123456'),
        ).thenAnswer(
          (_) async => const Product(
            barcode: '123456',
            name: 'Flour',
            servingSize: '200g',
            servingQuantity: 200,
          ),
        );

        await pumpApp(
          tester,
          const RecipeFormScreen(),
          overrides: [
            databaseProvider.overrideWithValue(mockDb),
            activeInventoryProvider.overrideWith(
              FakeActiveInventoryNotifier.new,
            ),
            productRepositoryProvider.overrideWithValue(mockRepo),
            settingsProvider.overrideWith(
              FakeSettingsNotifierImperial.new,
            ),
          ],
        );

        await tester.tap(find.text('From your pantry'));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(CheckboxListTile));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Add selected'));
        await tester.pumpAndSettle();

        // 200 g = 7.1 oz
        expect(find.textContaining('7.'), findsOneWidget);
      },
    );

    testWidgets(
      'pre-fills imperial units in dropdown when system is imperial',
      (tester) async {
        when(
          () => mockDb.getDistinctProductsFromInventory(
            inventoryId: any(named: 'inventoryId'),
          ),
        ).thenAnswer(
          (_) async => [
            {'name': 'Flour', 'barcode': '123456'},
          ],
        );

        await pumpApp(
          tester,
          const RecipeFormScreen(),
          overrides: [
            databaseProvider.overrideWithValue(mockDb),
            activeInventoryProvider.overrideWith(
              FakeActiveInventoryNotifier.new,
            ),
            productRepositoryProvider.overrideWithValue(mockRepo),
            settingsProvider.overrideWith(
              FakeSettingsNotifierImperial.new,
            ),
          ],
        );

        await tester.tap(find.text('From your pantry'));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(CheckboxListTile));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Add selected'));
        await tester.pumpAndSettle();

        // Tap the dropdown to see available options
        await tester.tap(find.byType(DropdownButtonFormField<String>));
        await tester.pumpAndSettle();

        // Imperial units should be visible
        expect(find.text('oz'), findsWidgets);
        expect(find.text('lb'), findsWidgets);
        expect(find.text('fl oz'), findsWidgets);
        expect(find.text('cup'), findsWidgets);
        expect(find.text('tbsp'), findsWidgets);
        expect(find.text('tsp'), findsWidgets);
      },
    );
  });

  group('auto-convert on unit change', () {
    testWidgets(
      'converts quantity when unit changes from g to oz',
      (tester) async {
        when(
          () => mockDb.getDistinctProductsFromInventory(
            inventoryId: any(named: 'inventoryId'),
          ),
        ).thenAnswer(
          (_) async => [
            {'name': 'Flour', 'barcode': '123456'},
          ],
        );
        when(
          () => mockRepo.getProductFromCache('123456'),
        ).thenAnswer(
          (_) async => const Product(
            barcode: '123456',
            name: 'Flour',
            servingSize: '200g',
            servingQuantity: 200,
          ),
        );

        await pumpApp(
          tester,
          const RecipeFormScreen(),
          overrides: [
            databaseProvider.overrideWithValue(mockDb),
            activeInventoryProvider.overrideWith(
              FakeActiveInventoryNotifier.new,
            ),
            productRepositoryProvider.overrideWithValue(mockRepo),
            settingsProvider.overrideWith(
              FakeSettingsNotifierImperial.new,
            ),
          ],
        );

        await tester.tap(find.text('From your pantry'));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(CheckboxListTile));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Add selected'));
        await tester.pumpAndSettle();

        // Find the dropdown and change unit from oz to lb
        final dropdown = find.byType(DropdownButtonFormField<String>);
        await tester.tap(dropdown);
        await tester.pumpAndSettle();

        await tester.tap(find.text('lb').last);
        await tester.pumpAndSettle();

        // 7.1 oz should convert to ~0.4 lb
        expect(find.textContaining('0.'), findsOneWidget);
      },
    );
  });

  group('per-context override', () {
    testWidgets(
      'shows imperial dropdown units when only recipe override is imperial'
      ' and global is metric',
      (tester) async {
        when(
          () => mockDb.getDistinctProductsFromInventory(
            inventoryId: any(named: 'inventoryId'),
          ),
        ).thenAnswer(
          (_) async => [
            {'name': 'Flour', 'barcode': '123456'},
          ],
        );
        when(
          () => mockRepo.getProductFromCache('123456'),
        ).thenAnswer(
          (_) async => const Product(
            barcode: '123456',
            name: 'Flour',
            servingSize: '200g',
            servingQuantity: 200,
          ),
        );

        await pumpApp(
          tester,
          const RecipeFormScreen(),
          overrides: [
            databaseProvider.overrideWithValue(mockDb),
            activeInventoryProvider.overrideWith(
              FakeActiveInventoryNotifier.new,
            ),
            productRepositoryProvider.overrideWithValue(mockRepo),
            settingsProvider.overrideWith(
              FakeSettingsNotifierRecipeImperial.new,
            ),
          ],
        );

        await tester.tap(find.text('From your pantry'));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(CheckboxListTile));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Add selected'));
        await tester.pumpAndSettle();

        // Find the unit dropdown and verify imperial units are present
        final dropdown = find.byType(DropdownButtonFormField<String>);
        await tester.tap(dropdown);
        await tester.pumpAndSettle();

        expect(find.text('oz'), findsWidgets);
        expect(find.text('fl oz'), findsWidgets);
      },
    );

    testWidgets(
      'shows metric dropdown units when recipe override is metric'
      ' and global is imperial',
      (tester) async {
        when(
          () => mockDb.getDistinctProductsFromInventory(
            inventoryId: any(named: 'inventoryId'),
          ),
        ).thenAnswer(
          (_) async => [
            {'name': 'Flour', 'barcode': '123456'},
          ],
        );
        when(
          () => mockRepo.getProductFromCache('123456'),
        ).thenAnswer(
          (_) async => const Product(
            barcode: '123456',
            name: 'Flour',
            servingSize: '200g',
            servingQuantity: 200,
          ),
        );

        await pumpApp(
          tester,
          const RecipeFormScreen(),
          overrides: [
            databaseProvider.overrideWithValue(mockDb),
            activeInventoryProvider.overrideWith(
              FakeActiveInventoryNotifier.new,
            ),
            productRepositoryProvider.overrideWithValue(mockRepo),
            settingsProvider.overrideWith(
              _FakeSettingsNotifierMetricOverride.new,
            ),
          ],
        );

        await tester.tap(find.text('From your pantry'));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(CheckboxListTile));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Add selected'));
        await tester.pumpAndSettle();

        // Find the unit dropdown and verify metric units are present
        final dropdown = find.byType(DropdownButtonFormField<String>);
        await tester.tap(dropdown);
        await tester.pumpAndSettle();

        expect(find.text('kg'), findsWidgets);
        expect(find.text('L'), findsWidgets);
      },
    );
  });
}

/// Fake with imperial global but metric override for recipe ingredients.
class _FakeSettingsNotifierMetricOverride extends SettingsNotifier {
  @override
  Settings build() => const Settings(
    unitSystem: UnitSystem.imperial,
    unitSystemRecipeIngredients: UnitSystem.metric,
    preferredWeightUnit: WeightUnitPreference.ounces,
  );
}
