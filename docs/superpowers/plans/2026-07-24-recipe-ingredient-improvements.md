# Recipe Ingredient Improvements Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add product images to recipe ingredients list, implement automatic unit conversion (kg/g, L/ml), and fix ingredient shortage accumulation + distinct ingredient counting.

**Architecture:** Three independent concerns: (1) a `UnitConverter` utility normalizes units before comparison/deduction; (2) ingredient grouping by barcode in `cookRecipe` for correct shortage accumulation and unit-aware deduction; (3) a `recipeIngredientsWithProductsProvider` joins ingredients with product data for images and distinct counting in the detail screen.

**Tech Stack:** Flutter/Dart, Riverpod, freezed, mocktail, sqflite, ImageCacheService, WebP

## Global Constraints

- Keep 80-char lines, single quotes, const constructors
- /// doc comments on every public member
- Tests for ALL new/changed code (use mocktail)
- No emoji in code, docs, or ARB strings
- RecipeIngredient model stays freezed (no change to it)
- `Product()` must pass `source: 'api' or 'manual'` (Rule 8 from AGENTS.md)
- All user-visible strings in ARB files; update app_en.arb + app_pt.arb + app_pt_BR.arb
- After freezed changes: `dart run build_runner build --delete-conflicting-outputs`
- Run `dart analyze`, `flutter test --concurrency=2`, `flutter build apk --debug` before committing

---

### Task 1: Create UnitConverter utility

**Files:**
- Create: `lib/utils/unit_conversion.dart`
- Test: `test/utils/unit_conversion_test.dart`

**Interfaces:**
- Produces: `UnitConverter` class with:
  - `static double normalizeToGrams(double quantity, String unit)` — converts kg->g, passes g through
  - `static double normalizeToMilliliters(double quantity, String unit)` — converts L->ml, passes ml through; tsp->ml (5), tbsp->ml (15), cup->ml (240)
  - `static String baseUnitFor(String unit)` — returns 'g' for kg/g, 'ml' for volume, 'pieces' for pieces
  - `static double convertBack(double normalizedQty, String targetUnit)` — reverse conversion (g->kg, ml->L, etc.)
  - `static bool areUnitsCompatible(String unitA, String unitB)` — checks same measurement group
  - `static double convert(double quantity, String fromUnit, String toUnit)` — full round-trip

Unit groups: `weight` -> g, kg; `volume` -> ml, L, tbsp, tsp, cup; `count` -> pieces
Conversion factors: 1 kg = 1000 g; 1 L = 1000 ml; 1 tbsp = 15 ml; 1 tsp = 5 ml; 1 cup = 240 ml

- [ ] **Step 1: Write the failing test**

```dart
// test/utils/unit_conversion_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/utils/unit_conversion.dart';

void main() {
  group('normalizeToGrams', () {
    test('passes grams through', () {
      expect(UnitConverter.normalizeToGrams(100, 'g'), 100.0);
    });
    test('converts kg to g', () {
      expect(UnitConverter.normalizeToGrams(1, 'kg'), 1000.0);
    });
    test('handles zero', () {
      expect(UnitConverter.normalizeToGrams(0, 'g'), 0.0);
    });
  });

  group('normalizeToMilliliters', () {
    test('passes ml through', () {
      expect(UnitConverter.normalizeToMilliliters(500, 'ml'), 500.0);
    });
    test('converts L to ml', () {
      expect(UnitConverter.normalizeToMilliliters(1, 'L'), 1000.0);
    });
    test('converts tbsp to ml', () {
      expect(UnitConverter.normalizeToMilliliters(1, 'tbsp'), 15.0);
    });
    test('converts tsp to ml', () {
      expect(UnitConverter.normalizeToMilliliters(1, 'tsp'), 5.0);
    });
    test('converts cup to ml', () {
      expect(UnitConverter.normalizeToMilliliters(1, 'cup'), 240.0);
    });
  });

  group('areUnitsCompatible', () {
    test('g and kg are compatible', () {
      expect(UnitConverter.areUnitsCompatible('g', 'kg'), isTrue);
    });
    test('ml and L are compatible', () {
      expect(UnitConverter.areUnitsCompatible('ml', 'L'), isTrue);
    });
    test('pieces and pieces are compatible', () {
      expect(UnitConverter.areUnitsCompatible('pieces', 'pieces'), isTrue);
    });
    test('g and ml are not compatible', () {
      expect(UnitConverter.areUnitsCompatible('g', 'ml'), isFalse);
    });
    test('kg and tsp are not compatible', () {
      expect(UnitConverter.areUnitsCompatible('kg', 'tsp'), isFalse);
    });
    test('pieces and g are not compatible', () {
      expect(UnitConverter.areUnitsCompatible('pieces', 'g'), isFalse);
    });
  });

  group('convertBack', () {
    test('converts g back to kg', () {
      expect(UnitConverter.convertBack(1000, 'kg'), 1.0);
    });
    test('converts ml back to L', () {
      expect(UnitConverter.convertBack(2000, 'L'), 2.0);
    });
    test('passes g through unchanged', () {
      expect(UnitConverter.convertBack(500, 'g'), 500.0);
    });
    test('passes ml through unchanged', () {
      expect(UnitConverter.convertBack(300, 'ml'), 300.0);
    });
  });

  group('convert', () {
    test('converts 2 kg to 2000 g', () {
      expect(UnitConverter.convert(2, 'kg', 'g'), 2000.0);
    });
    test('converts 500 ml to 0.5 L', () {
      expect(UnitConverter.convert(500, 'ml', 'L'), 0.5);
    });
    test('leaves pieces unchanged', () {
      expect(UnitConverter.convert(3, 'pieces', 'pieces'), 3.0);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/utils/unit_conversion_test.dart`
Expected: FAIL - class not found

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/utils/unit_conversion.dart
import 'package:pantry_app/utils/logger.dart';

/// Normalizes and converts between compatible measurement units.
///
/// Supported unit groups:
///   - weight: g, kg
///   - volume: ml, L, tbsp, tsp, cup
///   - count: pieces
class UnitConverter {
  UnitConverter._();

  static const _weightUnits = {'g', 'kg'};
  static const _volumeUnits = {'ml', 'L', 'tbsp', 'tsp', 'cup'};

  static const _toMl = <String, double>{
    'ml': 1, 'L': 1000, 'tbsp': 15, 'tsp': 5, 'cup': 240,
  };

  /// Normalizes [quantity] in [unit] to grams.
  static double normalizeToGrams(double quantity, String unit) {
    if (unit == 'kg') return quantity * 1000;
    if (unit == 'g') return quantity;
    logWarning('normalizeToGrams: unsupported unit $unit, returning 0');
    return 0;
  }

  /// Normalizes [quantity] in [unit] to milliliters.
  static double normalizeToMilliliters(double quantity, String unit) {
    final factor = _toMl[unit];
    if (factor != null) return quantity * factor;
    logWarning('normalizeToMilliliters: unsupported unit $unit, returning 0');
    return 0;
  }

  /// Returns the base unit for the group of [unit].
  static String baseUnitFor(String unit) {
    if (_weightUnits.contains(unit)) return 'g';
    if (_volumeUnits.contains(unit)) return 'ml';
    return 'pieces';
  }

  /// Converts a normalized quantity (grams or ml) back to [targetUnit].
  static double convertBack(double normalizedQty, String targetUnit) {
    if (targetUnit == 'g' || targetUnit == 'ml' || targetUnit == 'pieces') {
      return normalizedQty;
    }
    if (targetUnit == 'kg') return normalizedQty / 1000;
    if (targetUnit == 'L') return normalizedQty / 1000;
    final factor = _toMl[targetUnit];
    if (factor != null && factor > 0) return normalizedQty / factor;
    return normalizedQty;
  }

  /// Whether two units belong to the same measurement group.
  static bool areUnitsCompatible(String unitA, String unitB) {
    if (unitA == unitB) return true;
    if (_weightUnits.contains(unitA) && _weightUnits.contains(unitB)) {
      return true;
    }
    if (_volumeUnits.contains(unitA) && _volumeUnits.contains(unitB)) {
      return true;
    }
    return false;
  }

  /// Converts [quantity] from [fromUnit] to [toUnit] directly.
  ///
  /// Returns the original [quantity] if units are identical or incompatible
  /// (with a warning log).
  static double convert(double quantity, String fromUnit, String toUnit) {
    if (fromUnit == toUnit) return quantity;
    if (!areUnitsCompatible(fromUnit, toUnit)) {
      logWarning('Incompatible units: $fromUnit -> $toUnit');
      return quantity;
    }
    final base = baseUnitFor(fromUnit);
    if (base == 'g') {
      final inGrams = normalizeToGrams(quantity, fromUnit);
      return convertBack(inGrams, toUnit);
    }
    if (base == 'ml') {
      final inMl = normalizeToMilliliters(quantity, fromUnit);
      return convertBack(inMl, toUnit);
    }
    return quantity;
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/utils/unit_conversion_test.dart`
Expected: PASS

- [ ] **Step 5: Check formatting and analyze**

Run: `dart format lib/utils/unit_conversion.dart test/utils/unit_conversion_test.dart`
Run: `dart analyze lib/utils/unit_conversion.dart test/utils/unit_conversion_test.dart`

- [ ] **Step 6: Commit**

```bash
git add lib/utils/unit_conversion.dart test/utils/unit_conversion_test.dart
git commit -m "feat: add UnitConverter utility for kg/g/ml/L/piece conversion"
```

---

### Task 2: Fix shortage accumulation and add unit-aware deduction in cookRecipe

**Files:**
- Modify: `lib/providers/recipe_provider.dart` lines 304-382 (shortage check + deduction loops)
- Modify: `lib/services/exceptions.dart` (RecipeCookException: change shortages key from name to barcode after grouping)
- Test: `test/providers/recipe_provider_test.dart`

**Problem:**
1. The shortage check loops over individual `RecipeIngredient` rows — if two rows share the same barcode, each checks against total inventory independently, potentially missing cumulative shortages.
2. No unit normalization: recipe qty=100 in "g" and inventory qty=1 in "kg" compares 1 < 100 and falsely reports a shortage.
3. The shortage map key is `ing.name` (display name), but after grouping we should use a stable key.

**Solution:**
Replace the ingredient-by-ingredient pre-flight loop with a grouped-by-barcode approach. After grouping, normalize both the recipe qty and inventory qty to the same base unit before comparing. For deduction, also loop by grouped barcode and normalize inventory unit against the recipe's unit.

- [ ] **Step 1: Write the failing test**

Add these tests to `test/providers/recipe_provider_test.dart`:

```dart
group('cookRecipe', () {
  test('accumulates shortages when same barcode appears in multiple rows', () async {
    when(() => mockDb.getRecipeIngredients(1)).thenAnswer(
      (_) async => [
        const RecipeIngredient(recipeId: 1, name: 'Garlic', barcode: '001', quantity: 3, unit: 'pieces'),
        const RecipeIngredient(recipeId: 1, name: 'Garlic', barcode: '001', quantity: 4, unit: 'pieces'),
      ],
    );
    when(() => mockDb.getInventoryRowsByBarcode(barcode: '001', inventoryId: 1)).thenAnswer(
      (_) async => [{'quantity': 5, 'unit': 'pieces', 'id': 1, 'barcode': '001', 'inventory_id': 1, 'expiry_date': null}],
    );

    // Total needed = 7, available = 5 (not 3+5 and 4+5 independently)
    expect(
      () => cookRecipe(ref, 1),
      throwsA(isA<RecipeCookException>().having((e) => e.shortages.values.first, 'shortage', closeTo(2, 0.01))),
    );
  });

  test('handles unit conversion in shortage check (recipe g, inventory kg)', () async {
    when(() => mockDb.getRecipeIngredients(1)).thenAnswer(
      (_) async => [
        const RecipeIngredient(recipeId: 1, name: 'Flour', barcode: '002', quantity: 100, unit: 'g'),
      ],
    );
    when(() => mockDb.getInventoryRowsByBarcode(barcode: '002', inventoryId: 1)).thenAnswer(
      (_) async => [{'quantity': 1, 'unit': 'kg', 'id': 1, 'barcode': '002', 'inventory_id': 1, 'expiry_date': null}],
    );

    // 1 kg = 1000 g, ingredient needs 100 g -> should NOT throw
    await expectLater(cookRecipe(ref, 1), completes);
  });

  test('reports shortage when inventory unit is incompatible', () async {
    when(() => mockDb.getRecipeIngredients(1)).thenAnswer(
      (_) async => [
        const RecipeIngredient(recipeId: 1, name: 'Flour', barcode: '002', quantity: 100, unit: 'g'),
      ],
    );
    when(() => mockDb.getInventoryRowsByBarcode(barcode: '002', inventoryId: 1)).thenAnswer(
      (_) async => [{'quantity': 1, 'unit': 'L', 'id': 1, 'barcode': '002', 'inventory_id': 1, 'expiry_date': null}],
    );

    // Incompatible units: treat as shortage
    expect(
      () => cookRecipe(ref, 1),
      throwsA(isA<RecipeCookException>()),
    );
  });
});
```

Note: These tests require a `ProviderContainer` setup similar to what `recipe_nutrition_provider_test.dart` does. The `cookRecipe` function takes `(WidgetRef ref, int recipeId)`, so the test needs to create a `ProviderContainer` with overrides:

```dart
final container = ProviderContainer(
  overrides: [
    databaseProvider.overrideWithValue(mockDb),
    activeInventoryProvider.overrideWithValue(1),
    settingsProvider.overrideWith(FakeSettingsNotifier.new),
  ],
);
final ref = container;
// ... test ...
container.dispose();
```

Define:
```dart
class FakeSettingsNotifier extends Notifier<Settings> {
  @override
  Settings build() => const Settings();
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/providers/recipe_provider_test.dart -p "accumulates shortages\|handles unit conversion\|reports shortage when inventory unit"`
Expected: FAIL — cookRecipe still uses old logic

- [ ] **Step 3: Modify cookRecipe in recipe_provider.dart**

Replace lines 304-382 with a unit-aware, grouped-by-barcode approach:

```dart
  if (ingredients.isEmpty) throw const RecipeCookException({});

  // Group ingredients by barcode, summing quantities
  final grouped = <String, {required String name, required double totalQuantity, required String unit}>{
    for (final ing in ingredients)
      if (ing.barcode != null && ing.barcode!.isNotEmpty)
        ing.barcode!: {
          name: ing.name,
          totalQuantity: (grouped[ing.barcode!]?.totalQuantity ?? 0) + ing.quantity,
          unit: ing.unit,
        }
  };

  // Pre-flight validation with unit normalization
  final shortages = <String, double>{};
  for (final entry in grouped.entries) {
    final barcode = entry.key;
    final grp = entry.value;
    final rows = await db.getInventoryRowsByBarcode(
      barcode: barcode,
      inventoryId: activeInventoryId,
    );
    var available = 0.0;
    for (final row in rows) {
      final rowQty = (row['quantity']! as num).toDouble();
      final rowUnit = row['unit'] as String? ?? 'pieces';
      if (UnitConverter.areUnitsCompatible(grp.unit, rowUnit)) {
        available += UnitConverter.convert(rowQty, rowUnit, grp.unit);
      }
    }
    if (available < grp.totalQuantity) {
      shortages[grp.name] = grp.totalQuantity - available;
    }
  }
  if (shortages.isNotEmpty) {
    throw RecipeCookException(shortages);
  }

  // Compute current cost
  final database = await db.database;
  var totalCost = 0.0;
  for (final ing in ingredients) {
    if (ing.barcode == null || ing.barcode!.isEmpty) continue;
    final rows = await database.rawQuery(
      'SELECT price, currency FROM prices WHERE barcode = ? ORDER BY date_purchased DESC LIMIT 1',
      [ing.barcode],
    );
    if (rows.isEmpty) continue;
    final price = (rows.first['price'] as num?)?.toDouble() ?? 0.0;
    final currency = rows.first['currency'] as String? ?? baseCurrency;
    totalCost += await currencyService.convert(price, currency, baseCurrency);
  }

  // Transaction: FEFO deduction + history (grouped by barcode)
  final affectedRows = <InventoryRowSnapshot>[];

  return database
      .transaction<CookResult>((txn) async {
        for (final entry in grouped.entries) {
          final barcode = entry.key;
          var remaining = entry.value.totalQuantity;
          final rows = await txn.rawQuery(
            'SELECT * FROM inventory WHERE barcode = ? AND inventory_id = ? ORDER BY expiry_date ASC NULLS LAST',
            [barcode, activeInventoryId],
          );
          for (final row in rows) {
            if (remaining <= 0) break;
            final rowId = row['id']! as int;
            final rowQty = (row['quantity']! as num).toDouble();
            final rowUnit = row['unit'] as String? ?? 'pieces';
            final effectiveQty = UnitConverter.areUnitsCompatible(entry.value.unit, rowUnit)
                ? UnitConverter.convert(rowQty, rowUnit, entry.value.unit)
                : rowQty;
            final consumed = effectiveQty < remaining ? effectiveQty : remaining;
            affectedRows.add(
              InventoryRowSnapshot(
                rowId: rowId,
                originalQuantity: rowQty,
                originalRow: Map<String, dynamic>.from(row),
              ),
            );
            final remainingInRowUnits = rowQty - UnitConverter.convertBack(consumed, rowUnit);
            if (remainingInRowUnits > 0.001) {
              await txn.update(
                'inventory',
                {'quantity': remainingInRowUnits},
                where: 'id = ?',
                whereArgs: [rowId],
              );
            } else {
              await txn.delete('inventory', where: 'id = ?', whereArgs: [rowId]);
            }
            remaining -= consumed;
          }
        }

        final snapshotJson = const JsonEncoder().convert(
          ingredients.map((ing) => {
            'barcode': ing.barcode,
            'name': ing.name,
            'quantity': ing.quantity,
            'unit': ing.unit,
          }).toList(),
        );

        final historyId = await txn.insert('recipe_history', {
          'recipe_id': recipeId,
          'made_at': DateTime.now().millisecondsSinceEpoch,
          'cost_at_time': totalCost,
          'ingredient_snapshot': snapshotJson,
        });

        return CookResult(historyEntryId: historyId, affectedRows: affectedRows);
      })
      .then((result) {
        invalidateRecipes(ref);
        ref.invalidate(pantryProvider);
        return result;
      });
```

Also add import:
```dart
import 'package:pantry_app/utils/unit_conversion.dart';
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/providers/recipe_provider_test.dart -p "accumulates shortages\|handles unit conversion\|reports shortage when inventory unit"`
Expected: PASS

- [ ] **Step 5: Run all tests to check for regressions**

Run: `flutter test --concurrency=2`
Expected: All pass

- [ ] **Step 6: Run analyze**

Run: `dart analyze`
Expected: No issues

- [ ] **Step 7: Commit**

```bash
git add lib/providers/recipe_provider.dart test/providers/recipe_provider_test.dart
git commit -m "fix: accumulate shortages by barcode and add unit-aware deduction in cookRecipe"
```

---

### Task 3: Add ingredient images and distinct ingredient count to recipe detail screen

**Files:**
- Modify: `lib/providers/recipe_provider.dart` — add `recipeIngredientsWithProductsProvider`
- Modify: `lib/screens/recipe_detail_screen.dart` — use new provider, add images, show distinct count
- Modify: `lib/l10n/app_en.arb` — add `recipeIngredientsCount` key
- Modify: `lib/l10n/app_pt.arb` — add corresponding translation
- Modify: `lib/l10n/app_pt_BR.arb` — add corresponding translation
- Test: `test/providers/recipe_provider_test.dart` — add tests for new provider
- Test: `test/screens/recipe_detail_screen_test.dart` — update for new display

**Interfaces:**
- Consumes: `UnitConverter` (for display rounding), `ImageCacheService`, `ProductRepository`
- Produces: `recipeIngredientsWithProductsProvider` returning `List<({RecipeIngredient ingredient, Product? product})>`
- Produces: `IngredientGroup` local helper in recipe_detail_screen.dart `{final String name; final String? barcode; final double totalQuantity; final String unit; Product? product;}`

- [ ] **Step 1: Add recipeIngredientsWithProductsProvider**

In `lib/providers/recipe_provider.dart`, add a new provider:

```dart
/// A record pairing a [RecipeIngredient] with its optional [Product].
///
/// The product is null if the ingredient has no barcode or the product is not
/// in the local database.
typedef IngredientWithProduct = ({RecipeIngredient ingredient, Product? product});

/// Provides ingredients with their product data (including image URL).
///
/// Fetches each ingredient's product via [ProductRepository] so that images
/// are available for display. Ingredients without a barcode get a null product.
final recipeIngredientsWithProductsProvider = FutureProvider.autoDispose
    .family<List<IngredientWithProduct>, int>(
      (ref, recipeId) async {
        final db = ref.watch(databaseProvider);
        final repo = ref.read(productRepositoryProvider);
        final ingredients = await db.getRecipeIngredients(recipeId);

        final barcodes = ingredients
            .map((i) => i.barcode)
            .where((b) => b != null && b.isNotEmpty)
            .cast<String>()
            .toSet()
            .toList();

        final productsByBarcode = <String, Product>{};
        for (final barcode in barcodes) {
          try {
            final product = await repo.getProduct(barcode);
            if (product != null) {
              productsByBarcode[barcode] = product;
            }
          } on Exception catch (e) {
            logWarning('Could not fetch product $barcode for ingredient image: $e');
          }
        }

        return ingredients.map((ing) => (
          ingredient: ing,
          product: ing.barcode != null ? productsByBarcode[ing.barcode] : null,
        )).toList();
      },
    );
```

- [ ] **Step 2: Write failing test for the provider**

Add to `test/providers/recipe_provider_test.dart`:

```dart
group('recipeIngredientsWithProductsProvider', () {
  test('returns ingredients with products', () async {
    const ingredients = [
      RecipeIngredient(recipeId: 1, name: 'Eggs', barcode: '001', quantity: 2),
      RecipeIngredient(recipeId: 1, name: 'Salt', quantity: 1), // no barcode
    ];
    when(() => mockDb.getRecipeIngredients(1)).thenAnswer((_) async => ingredients);
    when(() => mockRepo.getProduct('001')).thenAnswer(
      (_) async => const Product(
        barcode: '001',
        name: 'Eggs',
        imageUrl: 'http://example.com/egg.jpg',
        source: 'api',
      ),
    );
    registerFallbackValue(const Product(barcode: '', name: '', source: 'api'));

    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(mockDb),
        productRepositoryProvider.overrideWithValue(mockRepo),
      ],
    );
    addTearDown(container.dispose);

    final result = await container.read(
      recipeIngredientsWithProductsProvider(1).future,
    );
    expect(result.length, 2);
    expect(result[0].ingredient.name, 'Eggs');
    expect(result[0].product?.imageUrl, 'http://example.com/egg.jpg');
    expect(result[1].product, isNull);
  });
});
```

- [ ] **Step 3: Run to verify it fails**

Run: `flutter test test/providers/recipe_provider_test.dart -p "returns ingredients with products"`
Expected: FAIL — provider not found

- [ ] **Step 4: Update recipe_detail_screen.dart**

Replace the ingredients list section (lines ~180-193) with an `IngredientWithProduct`-aware rendering:

```dart
final ingredientsWithProducts = ref.watch(recipeIngredientsWithProductsProvider(widget.recipeId));

// ... inside the ListView builder ...

ingredientsWithProducts.when(
  data: (data) {
    final grouped = <String, _DisplayIngredient>{};
    for (final item in data) {
      final key = item.ingredient.barcode ?? item.ingredient.name;
      final existing = grouped[key];
      if (existing != null) {
        grouped[key] = existing.copyWith(
          totalQuantity: existing.totalQuantity + item.ingredient.quantity,
        );
      } else {
        grouped[key] = _DisplayIngredient(
          name: item.ingredient.name,
          barcode: item.ingredient.barcode,
          totalQuantity: item.ingredient.quantity,
          unit: item.ingredient.unit,
          product: item.product,
        );
      }
    }
    final distinctCount = grouped.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$distinctCount ${l10n.recipeIngredients}', // e.g. "3 Ingredients"
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ...grouped.values.map((g) => ListTile(
          dense: true,
          leading: _buildIngredientImage(g.product?.imageUrl, g.barcode),
          title: Text('${g.totalQuantity} x ${g.name}'),
        )),
      ],
    );
  },
  loading: () => const CircularProgressIndicator(),
  error: (e, _) => Text('Error: $e'),
),
```

Add these helper methods to `_RecipeDetailScreenState`:

```dart
Widget _buildIngredientImage(String? imageUrl, String? barcode) {
  if (imageUrl == null || barcode == null) {
    return const CircleAvatar(child: Icon(Icons.fastfood), radius: 20);
  }
  final imageCache = ref.read(imageCacheProvider);
  return FutureBuilder<String?>(
    future: imageCache.cacheImage(imageUrl, barcode),
    builder: (context, snapshot) {
      if (snapshot.hasData && snapshot.data != null) {
        return ClipOval(
          child: Image.file(
            File(snapshot.data!),
            width: 40, height: 40,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _fallbackIngredientIcon(),
          ),
        );
      }
      return ClipOval(
        child: Image.network(
          imageUrl,
          width: 40, height: 40,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return const CircleAvatar(child: CircularProgressIndicator(), radius: 20);
          },
          errorBuilder: (_, _, _) => _fallbackIngredientIcon(),
        ),
      );
    },
  );
}

Widget _fallbackIngredientIcon() {
  return const CircleAvatar(child: Icon(Icons.fastfood), radius: 20);
}
```

Add this class at the top level of the file or inside the state class:

```dart
class _DisplayIngredient {
  const _DisplayIngredient({
    required this.name,
    this.barcode,
    required this.totalQuantity,
    required this.unit,
    this.product,
  });

  final String name;
  final String? barcode;
  final double totalQuantity;
  final String unit;
  final Product? product;

  _DisplayIngredient copyWith({double? totalQuantity}) => _DisplayIngredient(
    name: name,
    barcode: barcode,
    totalQuantity: totalQuantity ?? this.totalQuantity,
    unit: unit,
    product: product,
  );
}
```

Add new imports:
```dart
import 'dart:io';
import 'package:pantry_app/providers/image_cache_provider.dart';
import 'package:pantry_app/services/product_repository.dart';
```

- [ ] **Step 5: Update ARB files**

In `lib/l10n/app_en.arb`, replace the `recipeIngredients` key's value with just "Ingredients" (used as label) and add nothing new — the count is shown as "$count Ingredients" via a formatted string. Actually, the simplest approach: keep `recipeIngredients` as the section header label and format the count inline in the Dart code.

No new ARB keys needed if we format the count like `"${grouped.length} ${l10n.recipeIngredients}"`.

- [ ] **Step 6: Update widget test**

Update `test/screens/recipe_detail_screen_test.dart` to:
- Mock `productRepositoryProvider` with `createMockProductRepository()`
- Stub `ref.read(imageCacheProvider)` — needs a `ProviderScope` override
- Update the text matcher for ingredient display (now shows grouped + image)

The widget test now needs more overrides. Update `pumpDetailScreen`:

```dart
import 'package:pantry_app/providers/product_repository_provider.dart';
import 'package:pantry_app/providers/image_cache_provider.dart';

// ...

Future<void> pumpDetailScreen(WidgetTester tester) {
  final mockRepo = createMockProductRepository();
  return pumpApp(
    tester,
    const RecipeDetailScreen(recipeId: 1),
    overrides: [
      databaseProvider.overrideWithValue(mockDb),
      activeInventoryProvider.overrideWith(FakeActiveInventoryNotifier.new),
      productRepositoryProvider.overrideWithValue(mockRepo),
    ],
  );
}
```

Update test that checks "2.0 x Eggs" — now it should still appear after grouping since there's only one Eggs row:

```dart
expect(find.text('2.0 x Eggs'), findsOneWidget);
```

And additionally check for a CircleAvatar or image widget in the leading position.

- [ ] **Step 7: Run all tests to verify**

Run: `flutter test --concurrency=2`
Expected: All pass

- [ ] **Step 8: Run analyze**

Run: `dart analyze`
Expected: No issues

- [ ] **Step 9: Commit**

```bash
git add lib/providers/recipe_provider.dart lib/screens/recipe_detail_screen.dart lib/l10n/app_en.arb lib/l10n/app_pt.arb lib/l10n/app_pt_BR.arb test/providers/recipe_provider_test.dart test/screens/recipe_detail_screen_test.dart
git commit -m "feat: add product images and distinct ingredient count to recipe detail"
```

---

### Task 4: Run full verification gate

- [ ] **Step 1: Run complete test suite**

Run: `flutter test --concurrency=2`
Expected: All tests pass

- [ ] **Step 2: Run static analysis**

Run: `dart analyze`
Expected: No issues

- [ ] **Step 3: Build APK**

Run: `flutter build apk --debug`
Expected: Builds successfully

- [ ] **Step 4: Final commit if any fixes were needed**

```bash
git add -A
git commit -m "chore: fix lint and test issues from recipe ingredient improvements"
```
