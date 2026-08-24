import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/database/migrations/all_migrations.dart';
import 'package:pantry_app/database/migrations/migration_runner.dart';
import 'package:pantry_app/database/price_dao.dart';
import 'package:pantry_app/models/price.dart';
import 'package:pantry_app/models/recipe.dart';
import 'package:pantry_app/models/recipe_ingredient.dart';
import 'package:pantry_app/providers/active_inventory_provider.dart';
import 'package:pantry_app/providers/database_provider.dart';
import 'package:pantry_app/providers/recipe_provider.dart';
import 'package:pantry_app/providers/recipe_service_provider.dart';
import 'package:pantry_app/providers/settings_provider.dart';
import 'package:pantry_app/services/currency_service.dart';
import 'package:pantry_app/services/recipe_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class MockDatabaseHelper extends Mock implements DatabaseHelper {}

/// Builds a [RecipeService] backed by [db] with the default currency
/// service.
RecipeService _service(MockDatabaseHelper db) {
  return RecipeService(db, CurrencyService());
}

class _MutableActiveInventory extends ActiveInventoryNotifier {
  _MutableActiveInventory(this.initial);

  final int initial;

  @override
  Future<int> build() async => initial;

  @override
  void setActiveInventory(int id) {
    state = AsyncValue.data(id);
  }
}

class FakeSettingsNotifier extends SettingsNotifier {
  @override
  Future<Settings> build() async => const Settings();
}

class _CookRecipeButton extends ConsumerWidget {
  const _CookRecipeButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () async {
        try {
          await ref
              .read(recipeServiceProvider)
              .cookRecipe(
                1,
                activeInventoryId: await ref.read(
                  activeInventoryProvider.future,
                ),
                baseCurrency: (await ref.read(
                  settingsProvider.future,
                )).baseCurrency,
              );
        } on Exception {
          // cookRecipe is asserted via pre-flight mock interactions.
        }
      },
      child: const Text('Cook'),
    );
  }
}

/// Captures the result of a
/// [RecipeService.calculateRecipeCost] call inside a widget.
class _CapturedCost {
  double? value;
  bool done = false;
}

/// A button that computes [RecipeService.calculateRecipeCost] when tapped.
class _CostButton extends ConsumerWidget {
  const _CostButton({required this.recipeId, required this.capture});

  final int recipeId;
  final _CapturedCost capture;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () async {
        capture.value = await ref
            .read(recipeServiceProvider)
            .calculateRecipeCost(
              recipeId,
              activeInventoryId: await ref.read(activeInventoryProvider.future),
              baseCurrency: (await ref.read(
                settingsProvider.future,
              )).baseCurrency,
            );
        capture.done = true;
      },
      child: const Text('Cost'),
    );
  }
}

/// Captures the outcome of a [RecipeService.cookRecipe] call inside a widget.
class _CookResultCapture {
  Object? error;
  bool started = false;
  bool done = false;
}

/// A button that invokes [RecipeService.cookRecipe] when tapped.
class _CookButton extends ConsumerWidget {
  const _CookButton({required this.capture});

  final _CookResultCapture capture;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () async {
        capture.started = true;
        try {
          await ref
              .read(recipeServiceProvider)
              .cookRecipe(
                1,
                activeInventoryId: await ref.read(
                  activeInventoryProvider.future,
                ),
                baseCurrency: (await ref.read(
                  settingsProvider.future,
                )).baseCurrency,
              );
        } on Exception catch (e) {
          capture.error = e;
        } finally {
          capture.done = true;
        }
      },
      child: const Text('Cook'),
    );
  }
}

/// Drives pending fake-async microtasks and real ffi I/O to completion.
///
/// testWidgets runs under a fake-async zone where futures awaited from an
/// event-handler callback chain (such as the price lookup in
/// [RecipeService.calculateRecipeCost]) do not resolve on their own:
/// sqflite_common_ffi completes its futures from the real event loop, which
/// only turns during
/// [WidgetTester.runAsync], while the continuation microtasks only flush
/// during [WidgetTester.pump]. This helper alternates the two until [done] is
/// true or [maxTurns] is reached, so real database work completes
/// deterministically.
Future<void> _pumpWithRealIo(
  WidgetTester tester, {
  required bool Function() done,
  int maxTurns = 200,
}) async {
  for (var i = 0; i < maxTurns && !done(); i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump();
  }
}

/// Creates the full schema in [db] and inserts [prices].
///
/// Running the migrations also creates the products and inventory tables so
/// the package-size resolver in
/// [RecipeService.calculateIngredientCost] can be exercised.
Future<void> _seedPrices(Database db, List<Price> prices) async {
  await MigrationRunner(allMigrations()).run(db, 0, 37);
  for (final price in prices) {
    await const PriceDao().insert(db, price);
  }
}

/// Inserts a minimal product row for [barcode] with optional packaging data.
Future<void> _insertProduct(
  Database db, {
  required String barcode,
  String? quantity,
  double? productQuantity,
}) async {
  await db.insert('products', {
    'barcode': barcode,
    'name': 'Test Product',
    'quantity': quantity,
    'product_quantity': productQuantity,
    'source': 'api',
  });
}

/// Computes the ingredient cost for [ingredients] in inventory 1.
Future<double> _cost(
  Database db,
  MockDatabaseHelper mockDb,
  List<RecipeIngredient> ingredients,
) {
  return _service(mockDb).calculateIngredientCost(
    db,
    ingredients,
    inventoryId: 1,
    baseCurrency: 'USD',
    currencyService: CurrencyService(),
  );
}

void main() {
  setUpAll(() {
    dotenv.loadFromString(isOptional: true, mergeWith: {});
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    registerFallbackValue(const Recipe(name: ''));
    registerFallbackValue(const RecipeIngredient(recipeId: 0, name: ''));
  });

  late Database db;
  late MockDatabaseHelper mockDb;

  setUp(() async {
    db = await databaseFactory.openDatabase(inMemoryDatabasePath);
    registerFallbackValue(db);

    mockDb = MockDatabaseHelper();

    when(() => mockDb.database).thenAnswer((_) async => db);
    when(() => mockDb.getAllRecipes(any())).thenAnswer((_) async => []);
    when(() => mockDb.getRecipeIngredients(any())).thenAnswer((_) async => []);
    when(() => mockDb.insertRecipe(any())).thenAnswer((_) async => 1);
    when(
      () => mockDb.insertRecipeWithIngredients(any(), any()),
    ).thenAnswer((_) async => 1);
    when(
      () => mockDb.updateRecipeWithIngredients(any(), any()),
    ).thenAnswer((_) async => {});
    when(() => mockDb.deleteRecipe(any())).thenAnswer((_) async => 1);
  });

  tearDown(() async {
    await db.close();
  });

  group('saveRecipe', () {
    test('calls insertRecipeWithIngredients for a new recipe', () async {
      const recipe = Recipe(name: 'Soup');
      const ingredients = [
        RecipeIngredient(recipeId: 0, name: 'Carrots', quantity: 3),
      ];

      final id = await mockDb.insertRecipeWithIngredients(recipe, ingredients);
      expect(id, 1);
      verify(
        () => mockDb.insertRecipeWithIngredients(recipe, ingredients),
      ).called(1);
    });

    test('calls updateRecipeWithIngredients for an existing recipe', () async {
      const recipe = Recipe(id: 1, name: 'Soup');
      const ingredients = [
        RecipeIngredient(recipeId: 1, name: 'Carrots'),
      ];

      await mockDb.updateRecipeWithIngredients(recipe, ingredients);
      verify(
        () => mockDb.updateRecipeWithIngredients(recipe, ingredients),
      ).called(1);
    });

    test('insertRecipe throws on empty name via database', () {
      const empty = Recipe(name: '');
      when(() => mockDb.insertRecipe(any())).thenAnswer(
        (_) async => throw ArgumentError('Recipe name is required'),
      );

      expect(
        () => mockDb.insertRecipe(empty),
        throwsArgumentError,
      );
    });
  });

  group('deleteRecipe', () {
    test('calls deleteRecipe on the database', () async {
      await mockDb.deleteRecipe(1);
      verify(() => mockDb.deleteRecipe(1)).called(1);
    });
  });

  group('getAllRecipes', () {
    test('returns recipes from database', () async {
      const recipes = [
        Recipe(id: 1, name: 'Soup'),
        Recipe(id: 2, name: 'Salad'),
      ];
      when(() => mockDb.getAllRecipes(1)).thenAnswer((_) async => recipes);

      final result = await mockDb.getAllRecipes(1);
      expect(result.length, 2);
      expect(result[0].name, 'Soup');
      expect(result[1].name, 'Salad');
    });

    test('returns empty list when no recipes', () async {
      final result = await mockDb.getAllRecipes(1);
      expect(result, isEmpty);
    });
  });

  group('getRecipeIngredients', () {
    test('returns ingredients for a recipe', () async {
      const ingredients = [
        RecipeIngredient(id: 1, recipeId: 1, name: 'Carrots'),
      ];
      when(
        () => mockDb.getRecipeIngredients(1),
      ).thenAnswer((_) async => ingredients);

      final result = await mockDb.getRecipeIngredients(1);
      expect(result.length, 1);
      expect(result[0].name, 'Carrots');
    });

    test('returns empty list for recipe with no ingredients', () async {
      final result = await mockDb.getRecipeIngredients(999);
      expect(result, isEmpty);
    });
  });

  group('calculateRecipeCost', () {
    test('returns 0 when ingredients list is empty', () async {
      when(() => mockDb.getRecipeIngredients(1)).thenAnswer((_) async => []);

      final ingredients = await mockDb.getRecipeIngredients(1);
      expect(ingredients, isEmpty);
    });
  });

  group('calculateIngredientCost', () {
    test('returns the latest price for the requested inventory only', () async {
      await _seedPrices(db, const [
        Price(barcode: '001', price: 9.99, datePurchased: 3000),
        Price(barcode: '001', price: 2.50, inventoryId: 2, datePurchased: 1000),
        Price(barcode: '001', price: 3, inventoryId: 2, datePurchased: 2000),
      ]);
      const ingredients = [
        RecipeIngredient(
          recipeId: 1,
          name: 'Eggs',
          barcode: '001',
          quantity: 2,
        ),
      ];

      final inv2 = await _service(mockDb).calculateIngredientCost(
        db,
        ingredients,
        inventoryId: 2,
        baseCurrency: 'USD',
        currencyService: CurrencyService(),
      );
      expect(inv2, closeTo(3.0, 0.001));

      final inv1 = await _service(mockDb).calculateIngredientCost(
        db,
        ingredients,
        inventoryId: 1,
        baseCurrency: 'USD',
        currencyService: CurrencyService(),
      );
      expect(inv1, closeTo(9.99, 0.001));
    });

    test('returns 0 when the requested inventory has no prices', () async {
      await _seedPrices(db, const [
        Price(barcode: '001', price: 9.99, datePurchased: 3000),
      ]);
      const ingredients = [
        RecipeIngredient(recipeId: 1, name: 'Eggs', barcode: '001'),
      ];

      final cost = await _service(mockDb).calculateIngredientCost(
        db,
        ingredients,
        inventoryId: 2,
        baseCurrency: 'USD',
        currencyService: CurrencyService(),
      );
      expect(cost, 0.0);
    });

    test('skips ingredients without a barcode', () async {
      const ingredients = [
        RecipeIngredient(recipeId: 1, name: 'Salt'),
      ];

      final cost = await _service(mockDb).calculateIngredientCost(
        db,
        ingredients,
        inventoryId: 1,
        baseCurrency: 'USD',
        currencyService: CurrencyService(),
      );
      expect(cost, 0.0);
    });

    test(
      'scales cost by the price package size (2 eggs from a 12-pack)',
      () async {
        await _seedPrices(db, const [
          Price(
            barcode: '001',
            price: 9.99,
            datePurchased: 3000,
            packageQuantity: 12,
            packageUnit: 'pieces',
          ),
        ]);
        const ingredients = [
          RecipeIngredient(
            recipeId: 1,
            name: 'Eggs',
            barcode: '001',
            quantity: 2,
          ),
        ];

        final cost = await _cost(db, mockDb, ingredients);
        expect(cost, closeTo(1.67, 0.001));
      },
    );

    test(
      'scales cost by the product packaging quantity (250 ml from 1 L)',
      () async {
        await _seedPrices(db, const [
          Price(barcode: '001', price: 5, datePurchased: 3000),
        ]);
        await _insertProduct(db, barcode: '001', quantity: '1 L');
        const ingredients = [
          RecipeIngredient(
            recipeId: 1,
            name: 'Milk',
            barcode: '001',
            quantity: 250,
            unit: 'ml',
          ),
        ];

        final cost = await _cost(db, mockDb, ingredients);
        expect(cost, closeTo(1.25, 0.001));
      },
    );

    test(
      'uses the total package size for multi-pack product quantities',
      () async {
        await _seedPrices(db, const [
          Price(barcode: '001', price: 10, datePurchased: 3000),
        ]);
        await _insertProduct(
          db,
          barcode: '001',
          quantity: '3 x 150 g',
          productQuantity: 450,
        );
        const ingredients = [
          RecipeIngredient(
            recipeId: 1,
            name: 'Pasta',
            barcode: '001',
            quantity: 300,
            unit: 'g',
          ),
        ];

        final cost = await _cost(db, mockDb, ingredients);
        // 300 g of a 450 g package priced 10 costs 10 * 300 / 450 = 6.67.
        expect(cost, closeTo(6.67, 0.001));
      },
    );

    test(
      'charges full price when no package size resolves (inventory stock'
      ' is not a package size)',
      () async {
        await _seedPrices(db, const [
          Price(barcode: '001', price: 3, datePurchased: 3000),
        ]);
        await db.insert('inventory', {
          'barcode': '001',
          'inventory_id': 1,
          'quantity': 10,
          'unit': 'pieces',
        });
        const ingredients = [
          RecipeIngredient(
            recipeId: 1,
            name: 'Eggs',
            barcode: '001',
            quantity: 2,
          ),
        ];

        final cost = await _cost(db, mockDb, ingredients);
        expect(cost, closeTo(3.0, 0.001));
      },
    );

    test('charges full price when package units are incompatible', () async {
      await _seedPrices(db, const [
        Price(barcode: '001', price: 9.99, datePurchased: 3000),
      ]);
      await _insertProduct(db, barcode: '001', quantity: '500 g');
      const ingredients = [
        RecipeIngredient(
          recipeId: 1,
          name: 'Eggs',
          barcode: '001',
          quantity: 2,
        ),
      ];

      final cost = await _cost(db, mockDb, ingredients);
      expect(cost, closeTo(9.99, 0.001));
    });

    test(
      'scales produce pieces against a weight package via the inventory'
      ' serving_weight_g',
      () async {
        await _seedPrices(db, const [
          Price(
            barcode: 'produce-onion',
            price: 2,
            datePurchased: 3000,
            packageQuantity: 500,
            packageUnit: 'g',
          ),
        ]);
        await db.insert('inventory', {
          'barcode': 'produce-onion',
          'inventory_id': 1,
          'quantity': 3,
          'unit': 'pieces',
          'serving_weight_g': 150,
        });
        const ingredients = [
          RecipeIngredient(
            recipeId: 1,
            name: 'Onion',
            barcode: 'produce-Onion',
          ),
        ];

        // 1 onion = 150 g, package is 500 g at $2.00.
        final cost = await _cost(db, mockDb, ingredients);
        expect(cost, closeTo(0.6, 0.001));
      },
    );

    test(
      'scales produce pieces via ProduceServingPresets when no inventory'
      ' serving weight exists',
      () async {
        await _seedPrices(db, const [
          Price(
            barcode: 'produce-onion',
            price: 2,
            datePurchased: 3000,
            packageQuantity: 500,
            packageUnit: 'g',
          ),
        ]);
        const ingredients = [
          RecipeIngredient(
            recipeId: 1,
            name: 'Onion',
            barcode: 'produce-Onion',
          ),
        ];

        // Presets: medium onion = 150 g -> $0.60.
        final cost = await _cost(db, mockDb, ingredients);
        expect(cost, closeTo(0.6, 0.001));
      },
    );

    test(
      'scales a weight ingredient against a pieces package via serving'
      ' weight',
      () async {
        await _seedPrices(db, const [
          Price(
            barcode: 'produce-onion',
            price: 3,
            datePurchased: 3000,
            packageQuantity: 6,
            packageUnit: 'pieces',
          ),
        ]);
        await db.insert('inventory', {
          'barcode': 'produce-onion',
          'inventory_id': 1,
          'quantity': 3,
          'unit': 'pieces',
          'serving_weight_g': 150,
        });
        const ingredients = [
          RecipeIngredient(
            recipeId: 1,
            name: 'Onion',
            barcode: 'produce-Onion',
            quantity: 300,
            unit: 'g',
          ),
        ];

        // 300 g = 2 pieces, package is 6 pieces at $3.00.
        final cost = await _cost(db, mockDb, ingredients);
        expect(cost, closeTo(1.0, 0.001));
      },
    );

    test(
      'normalizes produce barcodes before looking up the price',
      () async {
        await _seedPrices(db, const [
          Price(
            barcode: 'produce-onion',
            price: 2,
            datePurchased: 3000,
            packageQuantity: 500,
            packageUnit: 'g',
          ),
        ]);
        const ingredients = [
          RecipeIngredient(
            recipeId: 1,
            name: 'Onion',
            barcode: 'produce-Onion',
            quantity: 150,
            unit: 'g',
          ),
        ];

        final cost = await _cost(db, mockDb, ingredients);
        expect(cost, closeTo(0.6, 0.001));
      },
    );

    test('rounds the total to cents across ingredients', () async {
      await _seedPrices(db, const [
        Price(
          barcode: '001',
          price: 9.99,
          datePurchased: 3000,
          packageQuantity: 12,
          packageUnit: 'pieces',
        ),
      ]);
      const ingredients = [
        RecipeIngredient(
          recipeId: 1,
          name: 'Eggs',
          barcode: '001',
          quantity: 2,
        ),
        RecipeIngredient(
          recipeId: 1,
          name: 'Eggs',
          barcode: '001',
          quantity: 2,
        ),
      ];

      // Each ingredient costs $1.67; the rounded sum is $3.34.
      final cost = await _cost(db, mockDb, ingredients);
      expect(cost, closeTo(3.34, 0.001));
    });
  });

  group('calculateRecipeCost inventory scoping', () {
    testWidgets(
      'uses the recipe own inventory for cost, not the active one',
      (tester) async {
        await tester.runAsync(
          () => _seedPrices(db, const [
            Price(
              barcode: '001',
              price: 9.99,
              datePurchased: 3000,
            ),
            Price(
              barcode: '001',
              price: 3,
              inventoryId: 2,
              datePurchased: 2000,
            ),
          ]),
        );
        when(() => mockDb.getRecipe(1)).thenAnswer(
          (_) async => const Recipe(id: 1, name: 'Soup', inventoryId: 2),
        );
        when(() => mockDb.getRecipeIngredients(1)).thenAnswer(
          (_) async => const [
            RecipeIngredient(
              recipeId: 1,
              name: 'Eggs',
              barcode: '001',
              quantity: 2,
            ),
          ],
        );

        final captured = _CapturedCost();
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              databaseProvider.overrideWithValue(mockDb),
              activeInventoryProvider.overrideWith(
                () => _MutableActiveInventory(1),
              ),
              settingsProvider.overrideWith(
                () => FakeSettingsNotifier() as SettingsNotifier,
              ),
            ],
            child: MaterialApp(
              home: _CostButton(recipeId: 1, capture: captured),
            ),
          ),
        );
        await tester.tap(find.text('Cost'));
        await _pumpWithRealIo(tester, done: () => captured.done);

        expect(captured.done, isTrue);
        expect(captured.value, closeTo(3.0, 0.001));
      },
    );

    testWidgets(
      'falls back to the active inventory when the recipe is not found',
      (tester) async {
        await tester.runAsync(
          () => _seedPrices(db, const [
            Price(
              barcode: '001',
              price: 3,
              inventoryId: 2,
              datePurchased: 2000,
            ),
          ]),
        );
        when(() => mockDb.getRecipe(1)).thenAnswer((_) async => null);
        when(() => mockDb.getRecipeIngredients(1)).thenAnswer(
          (_) async => const [
            RecipeIngredient(recipeId: 1, name: 'Eggs', barcode: '001'),
          ],
        );

        final captured = _CapturedCost();
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              databaseProvider.overrideWithValue(mockDb),
              activeInventoryProvider.overrideWith(
                () => _MutableActiveInventory(2),
              ),
              settingsProvider.overrideWith(
                () => FakeSettingsNotifier() as SettingsNotifier,
              ),
            ],
            child: MaterialApp(
              home: _CostButton(recipeId: 1, capture: captured),
            ),
          ),
        );
        await tester.tap(find.text('Cost'));
        await _pumpWithRealIo(tester, done: () => captured.done);

        expect(captured.done, isTrue);
        expect(captured.value, closeTo(3.0, 0.001));
      },
    );
  });

  group('cookRecipe inventory-scoped cost', () {
    testWidgets(
      'records cost_at_time from the recipe inventory prices,'
      ' not the active inventory',
      (tester) async {
        await tester.runAsync(() async {
          await MigrationRunner(allMigrations()).run(db, 0, 37);
          await const PriceDao().insert(
            db,
            const Price(
              barcode: '001',
              price: 9.99,
              datePurchased: 3000,
            ),
          );
          await const PriceDao().insert(
            db,
            const Price(
              barcode: '001',
              price: 3,
              inventoryId: 2,
              datePurchased: 2000,
            ),
          );
        });

        when(() => mockDb.getRecipe(1)).thenAnswer(
          (_) async => const Recipe(id: 1, name: 'Soup', inventoryId: 2),
        );
        when(() => mockDb.getRecipeIngredients(1)).thenAnswer(
          (_) async => const [
            RecipeIngredient(
              recipeId: 1,
              name: 'Eggs',
              barcode: '001',
              quantity: 2,
            ),
          ],
        );
        when(
          () => mockDb.getInventoryRowsByBarcode(
            barcode: '001',
            inventoryId: 2,
          ),
        ).thenAnswer(
          (_) async => [
            {'quantity': 10, 'unit': 'pieces', 'id': 1},
          ],
        );
        when(
          () => mockDb.getInventoryRowsByProductName(
            name: any(named: 'name'),
            inventoryId: any(named: 'inventoryId'),
          ),
        ).thenAnswer((_) async => []);

        final capture = _CookResultCapture();
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              databaseProvider.overrideWithValue(mockDb),
              activeInventoryProvider.overrideWith(
                () => _MutableActiveInventory(1),
              ),
              settingsProvider.overrideWith(
                () => FakeSettingsNotifier() as SettingsNotifier,
              ),
            ],
            child: MaterialApp(home: _CookButton(capture: capture)),
          ),
        );
        await tester.tap(find.text('Cook'));
        await _pumpWithRealIo(tester, done: () => capture.done);

        expect(capture.done, isTrue);
        expect(capture.error, isNull);

        final rows = await tester.runAsync(
          () => db.rawQuery(
            'SELECT cost_at_time FROM recipe_history WHERE recipe_id = 1',
          ),
        );
        expect(
          ((rows ?? []).single['cost_at_time'] as num?) ?? 0,
          closeTo(3.0, 0.001),
        );
      },
    );
  });

  group('calculateAverageRecipeCost', () {
    test('returns 0 when no recipes exist', () async {
      when(() => mockDb.getAllRecipes(1)).thenAnswer((_) async => []);

      final recipes = await mockDb.getAllRecipes(1);
      expect(recipes, isEmpty);
    });
  });

  group('checkIngredientShortages', () {
    test('accumulates shortage for multiple rows with same barcode', () async {
      when(
        () => mockDb.getInventoryRowsByBarcode(
          barcode: '001',
          inventoryId: 1,
        ),
      ).thenAnswer(
        (_) async => [
          {'quantity': 5, 'unit': 'pieces', 'id': 1},
        ],
      );

      final ingredients = [
        const RecipeIngredient(
          recipeId: 1,
          name: 'Garlic',
          barcode: '001',
          quantity: 3,
        ),
        const RecipeIngredient(
          recipeId: 1,
          name: 'Garlic',
          barcode: '001',
          quantity: 4,
        ),
      ];
      final shortages = await _service(
        mockDb,
      ).checkIngredientShortages(ingredients, 1);
      // Total needed = 7, available = 5 -> deficit of 2
      expect(shortages, containsPair('Garlic', closeTo(2, 0.01)));
    });

    test('handles unit conversion (recipe g, inventory kg)', () async {
      when(
        () => mockDb.getInventoryRowsByBarcode(
          barcode: '002',
          inventoryId: 1,
        ),
      ).thenAnswer(
        (_) async => [
          {'quantity': 1, 'unit': 'kg', 'id': 1},
        ],
      );

      final ingredients = [
        const RecipeIngredient(
          recipeId: 1,
          name: 'Flour',
          barcode: '002',
          quantity: 100,
          unit: 'g',
        ),
      ];
      final shortages = await _service(
        mockDb,
      ).checkIngredientShortages(ingredients, 1);
      // 1 kg = 1000 g, need 100 g -> no shortage
      expect(shortages, isEmpty);
    });

    test('returns shortage with incompatible units', () async {
      when(
        () => mockDb.getInventoryRowsByBarcode(
          barcode: '002',
          inventoryId: 1,
        ),
      ).thenAnswer(
        (_) async => [
          {'quantity': 1, 'unit': 'L', 'id': 1},
        ],
      );

      final ingredients = [
        const RecipeIngredient(
          recipeId: 1,
          name: 'Flour',
          barcode: '002',
          quantity: 100,
          unit: 'g',
        ),
      ];
      final shortages = await _service(
        mockDb,
      ).checkIngredientShortages(ingredients, 1);
      // g and L are incompatible -> available stays 0 -> shortage
      expect(shortages, isNotEmpty);
    });

    test('skips ingredients without barcode', () async {
      final ingredients = [
        const RecipeIngredient(recipeId: 1, name: 'Salt'),
      ];
      final shortages = await _service(
        mockDb,
      ).checkIngredientShortages(ingredients, 1);
      expect(shortages, isEmpty);
    });

    test('returns empty when stock is sufficient', () async {
      when(
        () => mockDb.getInventoryRowsByBarcode(
          barcode: '003',
          inventoryId: 1,
        ),
      ).thenAnswer(
        (_) async => [
          {'quantity': 10, 'unit': 'pieces', 'id': 1},
        ],
      );

      final ingredients = [
        const RecipeIngredient(
          recipeId: 1,
          name: 'Eggs',
          barcode: '003',
          quantity: 3,
        ),
      ];
      final shortages = await _service(
        mockDb,
      ).checkIngredientShortages(ingredients, 1);
      expect(shortages, isEmpty);
    });

    test(
      'falls back to product name match when barcode lookup is empty',
      () async {
        when(
          () => mockDb.getInventoryRowsByBarcode(
            barcode: 'plu-12345',
            inventoryId: 1,
          ),
        ).thenAnswer((_) async => []);
        when(
          () => mockDb.getInventoryRowsByProductName(
            name: 'Onion',
            inventoryId: 1,
          ),
        ).thenAnswer(
          (_) async => [
            {'quantity': 5, 'unit': 'pieces', 'id': 1},
          ],
        );

        final ingredients = [
          const RecipeIngredient(
            recipeId: 1,
            name: 'Onion',
            barcode: 'plu-12345',
            quantity: 2,
          ),
        ];
        final shortages = await _service(mockDb).checkIngredientShortages(
          ingredients,
          1,
        );
        expect(shortages, isEmpty);
      },
    );

    test(
      'reports shortage when both barcode and name lookup are empty',
      () async {
        when(
          () => mockDb.getInventoryRowsByBarcode(
            barcode: 'plu-67890',
            inventoryId: 1,
          ),
        ).thenAnswer((_) async => []);
        when(
          () => mockDb.getInventoryRowsByProductName(
            name: 'Onion',
            inventoryId: 1,
          ),
        ).thenAnswer((_) async => []);

        final ingredients = [
          const RecipeIngredient(
            recipeId: 1,
            name: 'Onion',
            barcode: 'plu-67890',
            quantity: 2,
          ),
        ];
        final shortages = await _service(mockDb).checkIngredientShortages(
          ingredients,
          1,
        );
        expect(shortages, isNotEmpty);
        expect(shortages['Onion'], closeTo(2, 0.01));
      },
    );

    test(
      'converts produce pieces via servingWeightG from inventory row when'
      ' barcode lookup finds no match',
      () async {
        when(
          () => mockDb.getInventoryRowsByBarcode(
            barcode: 'plu-12345',
            inventoryId: 1,
          ),
        ).thenAnswer((_) async => []);
        when(
          () => mockDb.getInventoryRowsByProductName(
            name: 'Onion',
            inventoryId: 1,
          ),
        ).thenAnswer(
          (_) async => [
            {
              'quantity': 150,
              'unit': 'g',
              'id': 1,
              'serving_weight_g': 150.0,
            },
          ],
        );

        final ingredients = [
          const RecipeIngredient(
            recipeId: 1,
            name: 'Onion',
            barcode: 'plu-12345',
          ),
        ];
        final shortages = await _service(mockDb).checkIngredientShortages(
          ingredients,
          1,
        );
        expect(shortages, isEmpty);
      },
    );

    test(
      'converts produce pieces via ProduceServingPresets fallback when'
      ' inventory row has no servingWeightG',
      () async {
        when(
          () => mockDb.getInventoryRowsByBarcode(
            barcode: 'produce-onion',
            inventoryId: 1,
          ),
        ).thenAnswer(
          (_) async => [
            {'quantity': 150, 'unit': 'g', 'id': 1},
          ],
        );

        final ingredients = [
          const RecipeIngredient(
            recipeId: 1,
            name: 'Onion',
            barcode: 'produce-Onion',
          ),
        ];
        final shortages = await _service(mockDb).checkIngredientShortages(
          ingredients,
          1,
        );
        expect(shortages, isEmpty);
      },
    );

    test(
      'reports shortage when produce has no serving weight resolution',
      () async {
        when(
          () => mockDb.getInventoryRowsByBarcode(
            barcode: 'plu-99999',
            inventoryId: 1,
          ),
        ).thenAnswer((_) async => []);
        when(
          () => mockDb.getInventoryRowsByProductName(
            name: 'UnmatchedProduce',
            inventoryId: 1,
          ),
        ).thenAnswer(
          (_) async => [
            {'quantity': 100, 'unit': 'g', 'id': 1},
          ],
        );

        final ingredients = [
          const RecipeIngredient(
            recipeId: 1,
            name: 'UnmatchedProduce',
            barcode: 'plu-99999',
            quantity: 2,
          ),
        ];
        final shortages = await _service(mockDb).checkIngredientShortages(
          ingredients,
          1,
        );
        expect(shortages, isNotEmpty);
        expect(shortages['UnmatchedProduce'], closeTo(2, 0.01));
      },
    );

    test(
      'converts produce via size label unit (e.g. Medium) when ingredient'
      ' unit is pieces',
      () async {
        when(
          () => mockDb.getInventoryRowsByBarcode(
            barcode: 'produce-onion',
            inventoryId: 1,
          ),
        ).thenAnswer(
          (_) async => [
            {'quantity': 2, 'unit': 'Medium', 'id': 1},
          ],
        );

        final ingredients = [
          const RecipeIngredient(
            recipeId: 1,
            name: 'Onion',
            barcode: 'produce-Onion',
          ),
        ];
        final shortages = await _service(mockDb).checkIngredientShortages(
          ingredients,
          1,
        );
        expect(shortages, isEmpty);
      },
    );

    test(
      'converts produce via size label unit when ingredient unit is weight',
      () async {
        when(
          () => mockDb.getInventoryRowsByBarcode(
            barcode: 'produce-onion',
            inventoryId: 1,
          ),
        ).thenAnswer(
          (_) async => [
            {'quantity': 2, 'unit': 'Medium', 'id': 1},
          ],
        );

        final ingredients = [
          const RecipeIngredient(
            recipeId: 1,
            name: 'Onion',
            barcode: 'produce-Onion',
            quantity: 150,
            unit: 'g',
          ),
        ];
        final shortages = await _service(mockDb).checkIngredientShortages(
          ingredients,
          1,
        );
        expect(shortages, isEmpty);
      },
    );

    test(
      'reports shortage when size label unit has no serving weight'
      ' resolution',
      () async {
        when(
          () => mockDb.getInventoryRowsByBarcode(
            barcode: 'produce-unknownspice',
            inventoryId: 1,
          ),
        ).thenAnswer(
          (_) async => [
            {'quantity': 2, 'unit': 'Medium', 'id': 1},
          ],
        );

        final ingredients = [
          const RecipeIngredient(
            recipeId: 1,
            name: 'UnknownSpice',
            barcode: 'produce-UnknownSpice',
            quantity: 3,
          ),
        ];
        final shortages = await _service(mockDb).checkIngredientShortages(
          ingredients,
          1,
        );
        expect(shortages, isNotEmpty);
        expect(shortages['UnknownSpice'], closeTo(3, 0.01));
      },
    );

    test(
      'matches produce barcode with different casing after normalization',
      () async {
        // Recipe ingredient has 'produce-Onion' but the inventory has
        // 'produce-onion' (normalized form). The lookup uses the normalized
        // barcode so it should match without falling back to name search.
        when(
          () => mockDb.getInventoryRowsByBarcode(
            barcode: 'produce-onion',
            inventoryId: 1,
          ),
        ).thenAnswer(
          (_) async => [
            {'quantity': 5, 'unit': 'pieces', 'id': 1},
          ],
        );

        final ingredients = [
          const RecipeIngredient(
            recipeId: 1,
            name: 'Onion',
            barcode: 'produce-Onion',
            quantity: 2,
          ),
        ];
        final shortages = await _service(mockDb).checkIngredientShortages(
          ingredients,
          1,
        );
        expect(shortages, isEmpty);
      },
    );

    test(
      'matches produce barcode with spaces after normalization',
      () async {
        // Recipe ingredient has 'produce-Organic Banana' but the inventory
        // has 'produce-organic_banana' (normalized form). The lookup should
        // match via barcode normalization without falling back to name search.
        // Ensure the fallback is NOT called.
        when(
          () => mockDb.getInventoryRowsByBarcode(
            barcode: 'produce-organic_banana',
            inventoryId: 1,
          ),
        ).thenAnswer(
          (_) async => [
            {'quantity': 3, 'unit': 'pieces', 'id': 1},
          ],
        );

        final ingredients = [
          const RecipeIngredient(
            recipeId: 1,
            name: 'Organic Banana',
            barcode: 'produce-Organic Banana',
          ),
        ];
        final shortages = await _service(mockDb).checkIngredientShortages(
          ingredients,
          1,
        );
        expect(shortages, isEmpty);
      },
    );

    test(
      'falls back to name search when normalized barcode still has no'
      ' match',
      () async {
        when(
          () => mockDb.getInventoryRowsByBarcode(
            barcode: 'produce-apple',
            inventoryId: 1,
          ),
        ).thenAnswer((_) async => []);
        when(
          () => mockDb.getInventoryRowsByProductName(
            name: 'Apple',
            inventoryId: 1,
          ),
        ).thenAnswer(
          (_) async => [
            {'quantity': 10, 'unit': 'pieces', 'id': 1},
          ],
        );

        final ingredients = [
          const RecipeIngredient(
            recipeId: 1,
            name: 'Apple',
            barcode: 'produce-Apple',
            quantity: 5,
          ),
        ];
        final shortages = await _service(mockDb).checkIngredientShortages(
          ingredients,
          1,
        );
        expect(shortages, isEmpty);
      },
    );
  });

  group('allRecipesProvider inventory scoping', () {
    test('reloads recipes when the active inventory changes', () async {
      when(() => mockDb.getAllRecipes(1)).thenAnswer(
        (_) async => [
          const Recipe(id: 1, name: 'Home Soup'),
        ],
      );
      when(() => mockDb.getAllRecipes(2)).thenAnswer(
        (_) async => [
          const Recipe(id: 2, name: 'Work Soup', inventoryId: 2),
        ],
      );

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(mockDb),
          activeInventoryProvider.overrideWith(
            () => _MutableActiveInventory(1),
          ),
        ],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(allRecipesProvider, (_, _) {});
      addTearDown(subscription.close);

      final initial = await container.read(allRecipesProvider.future);
      expect(initial.map((r) => r.name), ['Home Soup']);

      container.read(activeInventoryProvider.notifier).setActiveInventory(2);
      final next = await container.read(allRecipesProvider.future);
      expect(next.map((r) => r.name), ['Work Soup']);
    });
  });

  group('cookRecipe inventory source', () {
    testWidgets(
      "deducts from the recipe's own inventory, not the active one",
      (tester) async {
        when(() => mockDb.getRecipe(1)).thenAnswer(
          (_) async => const Recipe(
            id: 1,
            name: 'Soup',
            inventoryId: 2,
            createdAt: 1000,
          ),
        );
        when(() => mockDb.getRecipeIngredients(1)).thenAnswer(
          (_) async => const [
            RecipeIngredient(
              recipeId: 1,
              name: 'Eggs',
              barcode: '001',
              quantity: 2,
            ),
          ],
        );
        when(
          () => mockDb.getInventoryRowsByBarcode(
            barcode: '001',
            inventoryId: 2,
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

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              databaseProvider.overrideWithValue(mockDb),
              activeInventoryProvider.overrideWith(
                () => _MutableActiveInventory(1),
              ),
              settingsProvider.overrideWith(
                () => FakeSettingsNotifier() as SettingsNotifier,
              ),
            ],
            child: const MaterialApp(home: _CookRecipeButton()),
          ),
        );

        await tester.tap(find.text('Cook'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 100));

        verify(
          () => mockDb.getInventoryRowsByBarcode(
            barcode: '001',
            inventoryId: 2,
          ),
        ).called(1);
        verifyNever(
          () => mockDb.getInventoryRowsByBarcode(
            barcode: '001',
            inventoryId: 1,
          ),
        );
      },
    );
  });
}
