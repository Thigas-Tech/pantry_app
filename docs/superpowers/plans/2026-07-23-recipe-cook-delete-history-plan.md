# Recipe Cook, Detail, History, and Price Toggle — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add recipe detail screen (view-only), "I made this" cook flow with FEFO inventory deduction and undo, recipe history table, and price visibility toggle on recipe screens.

**Architecture:** Freezed model + DAO for `recipe_history` table (migration v26), new `RecipeDetailScreen`, `CookResult` record for undo wiring, `PriceVisibilityToggle` + `PriceMask` on recipe screens following existing pattern. `cookRecipe()` top-level function in provider file orchestrates validation, FEFO deduction, history insert, and returns `CookResult`.

**Tech Stack:** Flutter, Riverpod, sqflite, freezed, mocktail + sqflite_common_ffi for testing.

## Global Constraints

- TDD: failing test first, then implementation, then verification.
- All user-visible strings in `app_en.arb`, then pt/pt_BR translations.
- `///` doc comments on every public class, method, field.
- No backticks in doc comments — use [square brackets] for xrefs.
- Single quotes. 80-char lines. const constructors.
- SnackbarHelper.showUndo for destructive actions.
- `unawaited()` for fire-and-forget futures.
- Commit after every task.
- Run `dart analyze` and `flutter test --concurrency=2` before each commit.
- `flutter gen-l10n` after ARB changes.

---

## File Structure

### Create
| File | Purpose |
|---|---|
| `lib/models/recipe_history_entry.dart` | Freezed model |
| `lib/database/recipe_history_dao.dart` | CRUD for recipe_history |
| `lib/screens/recipe_detail_screen.dart` | View-only recipe detail |
| `test/models/recipe_history_entry_test.dart` | Model tests |
| `test/database/recipe_history_dao_test.dart` | DAO tests |
| `test/screens/recipe_detail_screen_test.dart` | Widget tests |

### Modify
| File | Change |
|---|---|
| `lib/database/database_helper.dart` | v26 migration, delegation methods |
| `lib/providers/recipe_provider.dart` | Add `cookRecipe()` + `CookResult` |
| `lib/screens/recipe_list_screen.dart` | Navigate to detail, add eye icon |
| `lib/l10n/app_en.arb` | ~15 new strings |
| `lib/l10n/app_pt.arb` | Translations |
| `lib/l10n/app_pt_BR.arb` | Translations |
| `lib/screens/recipe_form_screen.dart` | No structural change (detail nav only) |
| `CHANGELOG.md`, `USER_CHANGELOG.md` + pt/pt_BR | Entries |

### Existing patterns to follow
- DAO pattern: `recipe_ingredient_dao.dart` (const class, toMap/fromMap, createTable, insert/listBy/delete)
- Model pattern: `recipe_ingredient.dart` (freezed, id/recipeId fields, `@Default`)
- Provider top-level function: `deleteRecipe()` in `recipe_provider.dart`
- Screen with eye icon: `stats_screen.dart` — `if (priceTrackingEnabled) const PriceVisibilityToggle()`
- FEFO query: `inventory` rows `WHERE barcode = ? AND inventory_id = ? ORDER BY expiry_date ASC NULLS LAST`

---

### Task 1: RecipeHistoryEntry freezed model

**Files:**
- Create: `lib/models/recipe_history_entry.dart`
- Create: `test/models/recipe_history_entry_test.dart`

**Interfaces:**
- Produces: `RecipeHistoryEntry` class used by Task 2 DAO and Task 5 provider.

- [ ] **Step 1: Write the failing test**

```dart
// test/models/recipe_history_entry_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/models/recipe_history_entry.dart';

void main() {
  group('RecipeHistoryEntry', () {
    test('creates with required fields', () {
      final entry = RecipeHistoryEntry(
        recipeId: 1,
        madeAt: 1000,
        ingredientSnapshot: '[]',
      );
      expect(entry.recipeId, 1);
      expect(entry.madeAt, 1000);
      expect(entry.costAtTime, 0.0);
      expect(entry.ingredientSnapshot, '[]');
      expect(entry.id, isNull);
    });

    test('creates with all fields', () {
      const entry = RecipeHistoryEntry(
        id: 1,
        recipeId: 2,
        madeAt: 2000,
        costAtTime: 15.50,
        ingredientSnapshot: '[{"name":"eggs"}]',
      );
      expect(entry.id, 1);
      expect(entry.recipeId, 2);
      expect(entry.madeAt, 2000);
      expect(entry.costAtTime, 15.50);
      expect(entry.ingredientSnapshot, '[{"name":"eggs"}]');
    });

    test('copyWith preserves unset fields', () {
      const entry = RecipeHistoryEntry(
        id: 1, recipeId: 1, madeAt: 1000,
        ingredientSnapshot: '[]',
      );
      final copied = entry.copyWith(costAtTime: 10.0);
      expect(copied.id, 1);
      expect(copied.costAtTime, 10.0);
      expect(copied.ingredientSnapshot, '[]');
    });

    test('equality works', () {
      const a = RecipeHistoryEntry(id: 1, recipeId: 1, madeAt: 1000, ingredientSnapshot: '[]');
      const b = RecipeHistoryEntry(id: 1, recipeId: 1, madeAt: 1000, ingredientSnapshot: '[]');
      const c = RecipeHistoryEntry(id: 2, recipeId: 1, madeAt: 1000, ingredientSnapshot: '[]');
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/models/recipe_history_entry_test.dart`
Expected: FAIL — "Target not found: recipe_history_entry"

- [ ] **Step 3: Write minimal freezed model**

```dart
// lib/models/recipe_history_entry.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'recipe_history_entry.freezed.dart';

@freezed
class RecipeHistoryEntry with _$RecipeHistoryEntry {
  const factory RecipeHistoryEntry({
    int? id,
    required int recipeId,
    required int madeAt,
    @Default(0.0) double costAtTime,
    required String ingredientSnapshot,
  }) = _RecipeHistoryEntry;
}
```

- [ ] **Step 4: Run build_runner to generate .freezed.dart**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: `recipe_history_entry.freezed.dart` generated

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/models/recipe_history_entry_test.dart`
Expected: PASS

- [ ] **Step 6: Run analyze gate**

Run: `dart analyze lib/models/recipe_history_entry.dart`
Expected: 0 errors

- [ ] **Step 7: Commit**

```bash
git add lib/models/recipe_history_entry.dart lib/models/recipe_history_entry.freezed.dart test/models/recipe_history_entry_test.dart
git commit -m "feat: add RecipeHistoryEntry freezed model"
```

---

### Task 2: RecipeHistoryDao (CRUD)

**Files:**
- Create: `lib/database/recipe_history_dao.dart`
- Create: `test/database/recipe_history_dao_test.dart`

**Interfaces:**
- Consumes: `RecipeHistoryEntry` from Task 1
- Produces: `RecipeHistoryDao` with `createTable`, `insert`, `getByRecipeId`, `getRecent`, `deleteById`
- Also produces `getByRecipeId(Database, int) -> Future<List<RecipeHistoryEntry>>` and `getRecent(Database, int sinceMillis) -> Future<List<RecipeHistoryEntry>>`

- [ ] **Step 1: Write the failing tests**

```dart
// test/database/recipe_history_dao_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/database/recipe_history_dao.dart';
import 'package:pantry_app/models/recipe_history_entry.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Database db;
  late RecipeHistoryDao dao;

  setUp(() async {
    dao = const RecipeHistoryDao();
    db = await databaseFactory.openDatabase(inMemoryDatabasePath);
    await dao.createTable(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('insert', () {
    test('returns an id after insert', () async {
      final id = await dao.insert(db, const RecipeHistoryEntry(
        recipeId: 1, madeAt: 1000, ingredientSnapshot: '[]',
      ));
      expect(id, isNonNegative);
    });
  });

  group('getByRecipeId', () {
    test('returns entries ordered by made_at DESC', () async {
      await dao.insert(db, const RecipeHistoryEntry(
        recipeId: 1, madeAt: 100, ingredientSnapshot: '[]',
      ));
      await dao.insert(db, const RecipeHistoryEntry(
        recipeId: 1, madeAt: 200, ingredientSnapshot: '[]',
      ));
      await dao.insert(db, const RecipeHistoryEntry(
        recipeId: 2, madeAt: 300, ingredientSnapshot: '[]',
      ));

      final entries = await dao.getByRecipeId(db, 1);
      expect(entries.length, 2);
      expect(entries[0].madeAt, 200);
      expect(entries[1].madeAt, 100);
    });

    test('returns empty for recipe with no history', () async {
      final entries = await dao.getByRecipeId(db, 999);
      expect(entries, isEmpty);
    });
  });

  group('getRecent', () {
    test('returns entries after the given timestamp', () async {
      await dao.insert(db, const RecipeHistoryEntry(
        recipeId: 1, madeAt: 100, ingredientSnapshot: '[]',
      ));
      await dao.insert(db, const RecipeHistoryEntry(
        recipeId: 1, madeAt: 200, ingredientSnapshot: '[]',
      ));

      final entries = await dao.getRecent(db, 150);
      expect(entries.length, 1);
      expect(entries[0].madeAt, 200);
    });

    test('returns empty when no entries after timestamp', () async {
      await dao.insert(db, const RecipeHistoryEntry(
        recipeId: 1, madeAt: 100, ingredientSnapshot: '[]',
      ));
      final entries = await dao.getRecent(db, 999);
      expect(entries, isEmpty);
    });
  });

  group('deleteById', () {
    test('removes the entry', () async {
      final id = await dao.insert(db, const RecipeHistoryEntry(
        recipeId: 1, madeAt: 100, ingredientSnapshot: '[]',
      ));
      await dao.deleteById(db, id);

      final entries = await dao.getByRecipeId(db, 1);
      expect(entries, isEmpty);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/database/recipe_history_dao_test.dart`
Expected: FAIL — "Target not found: recipe_history_dao"

- [ ] **Step 3: Write the DAO**

```dart
// lib/database/recipe_history_dao.dart
import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/models/recipe_history_entry.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:sqflite/sqflite.dart';

class RecipeHistoryDao {
  const RecipeHistoryDao();

  Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS recipe_history (
        id                 INTEGER PRIMARY KEY AUTOINCREMENT,
        recipe_id          INTEGER NOT NULL,
        made_at            INTEGER NOT NULL,
        cost_at_time       REAL DEFAULT 0,
        ingredient_snapshot TEXT
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_recipe_history_recipe'
      ' ON recipe_history(recipe_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_recipe_history_made_at'
      ' ON recipe_history(made_at)',
    );
  }

  Map<String, dynamic> toMap(RecipeHistoryEntry entry) => {
    if (entry.id != null) 'id': entry.id,
    'recipe_id': entry.recipeId,
    'made_at': entry.madeAt,
    'cost_at_time': entry.costAtTime,
    'ingredient_snapshot': entry.ingredientSnapshot,
  };

  RecipeHistoryEntry fromMap(Map<String, dynamic> map) => RecipeHistoryEntry(
    id: map['id'] as int?,
    recipeId: map['recipe_id'] as int,
    madeAt: map['made_at'] as int,
    costAtTime: (map['cost_at_time'] as num?)?.toDouble() ?? 0.0,
    ingredientSnapshot: map['ingredient_snapshot'] as String? ?? '[]',
  );

  Future<int> insert(Database db, RecipeHistoryEntry entry) async {
    logInfo('Inserting recipe history for recipe ${entry.recipeId}');
    final id = await db.insert('recipe_history', toMap(entry));
    logInfo('Recipe history inserted with id $id');
    return id;
  }

  Future<List<RecipeHistoryEntry>> getByRecipeId(
    Database db,
    int recipeId,
  ) async {
    final rows = await db.query(
      'recipe_history',
      where: 'recipe_id = ?',
      whereArgs: [recipeId],
      orderBy: 'made_at DESC',
    );
    return rows.map(fromMap).toList();
  }

  Future<List<RecipeHistoryEntry>> getRecent(
    Database db,
    int sinceMillis,
  ) async {
    final rows = await db.query(
      'recipe_history',
      where: 'made_at >= ?',
      whereArgs: [sinceMillis],
      orderBy: 'made_at DESC',
    );
    return rows.map(fromMap).toList();
  }

  Future<void> deleteById(Database db, int id) async {
    await db.delete('recipe_history', where: 'id = ?', whereArgs: [id]);
    logInfo('Recipe history entry $id deleted');
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/database/recipe_history_dao_test.dart`
Expected: PASS

- [ ] **Step 5: Run analyze + format gate**

Run: `dart analyze lib/database/recipe_history_dao.dart test/database/recipe_history_dao_test.dart`
Expected: 0 errors

- [ ] **Step 6: Commit**

```bash
git add lib/database/recipe_history_dao.dart test/database/recipe_history_dao_test.dart
git commit -m "feat: add RecipeHistoryDao with insert, query, delete"
```

---

### Task 3: DatabaseHelper v26 migration + delegation

**Files:**
- Modify: `lib/database/database_helper.dart`

**Interfaces:**
- Consumes: `RecipeHistoryDao` from Task 2
- Produces: delegate methods `insertRecipeHistory`, `getRecipeHistory`, `getRecentRecipeHistory`, `deleteRecipeHistory`, `getInventoryRowsByBarcode` on `DatabaseHelper`

- [ ] **Step 1: Write failing integration tests**

Add tests to `test/database/database_helper_test.dart` (or create a new file). For brevity, add in an existing test group if one exists for recipe. Let me check if there is one.

Actually for database_helper tests, they are integration tests against a real in-memory database. Let me check existing test pattern.

(Note to executor: check `test/database/database_helper_test.dart` existence and add tests there following its patterns. The tests should verify:
- migration v26 creates recipe_history table
- delegate methods work (insert, get, delete)
- `getInventoryRowsByBarcode` returns rows ordered by expiry)
Since this is a plan, we specify the behavior and let the executor implement.)

- [ ] **Step 2: Bump version to 26**

In `_initDatabase`, change `version: 25` → `version: 26`.

- [ ] **Step 3: Add `recipe_history_dao` field and import**

```dart
// near line 111 (alongside other DAO fields)
final RecipeHistoryDao recipeHistoryDao = const RecipeHistoryDao();
```

- [ ] **Step 4: Create table in `_onCreate`**

```dart
// after recipeIngredientDao.createTable(db) ~line 229
await recipeHistoryDao.createTable(db);
```

- [ ] **Step 5: Add migration block in `_onUpgrade` after v25 block**

```dart
if (oldVersion < 26) {
  try {
    await recipeHistoryDao.createTable(db);
    logInfo('Migration to version 26 (recipe_history) completed');
  } on Exception catch (e) {
    logWarning('Migration v26 failed: $e');
  }
}
```

- [ ] **Step 6: Add delegate methods**

```dart
// ---- Recipe History (delegating to RecipeHistoryDao) -------

Future<int> insertRecipeHistory(RecipeHistoryEntry entry) async {
  final db = await database;
  return recipeHistoryDao.insert(db, entry);
}

Future<List<RecipeHistoryEntry>> getRecipeHistory(int recipeId) async {
  final db = await database;
  return recipeHistoryDao.getByRecipeId(db, recipeId);
}

Future<List<RecipeHistoryEntry>> getRecentRecipeHistory(int sinceMillis) async {
  final db = await database;
  return recipeHistoryDao.getRecent(db, sinceMillis);
}

Future<void> deleteRecipeHistory(int historyId) async {
  final db = await database;
  return recipeHistoryDao.deleteById(db, historyId);
}

/// Returns inventory rows matching [barcode] in the given [inventoryId],
/// ordered by expiry_date ASC (nulls last) for FEFO deduction.
Future<List<Map<String, dynamic>>> getInventoryRowsByBarcode({
  required String barcode,
  required int inventoryId,
}) async {
  final db = await database;
  return db.rawQuery(
    'SELECT * FROM inventory WHERE barcode = ? AND inventory_id = ?'
    ' ORDER BY expiry_date ASC NULLS LAST',
    [barcode, inventoryId],
  );
}
```

- [ ] **Step 7: Add import for `RecipeHistoryEntry` and `RecipeHistoryDao`**

```dart
import 'package:pantry_app/database/recipe_history_dao.dart';
// and in model imports:
import 'package:pantry_app/models/recipe_history_entry.dart';
```

- [ ] **Step 8: Run tests**

Run: `flutter test --concurrency=2`
Expected: all existing tests still pass

- [ ] **Step 9: Run analyze**

Run: `dart analyze lib/database/database_helper.dart`
Expected: 0 errors

- [ ] **Step 10: Commit**

```bash
git add lib/database/database_helper.dart
git commit -m "feat: bump database to v26 with recipe_history table and FEFO query"
```

---

### Task 4: CookRecipe provider function (FEFO deduction, history, undo)

**Files:**
- Modify: `lib/providers/recipe_provider.dart`
- Modify: `test/providers/recipe_provider_test.dart`

**Interfaces:**
- Consumes: `DatabaseHelper` delegate methods, `RecipeHistoryDao` (via dbHelper), `activeInventoryProvider`, `settingsProvider`, `CurrencyService`
- Produces: `cookRecipe(WidgetRef ref, int recipeId) -> Future<CookResult>`, `CookResult` class

- [ ] **Step 1: Write the CookResult class**

Add at the bottom of `recipe_provider.dart`:

```dart
/// Returned by [cookRecipe] with data needed for undo.
class CookResult {
  /// Creates a [CookResult].
  const CookResult({
    required this.historyEntryId,
    required this.affectedRows,
  });

  /// The id of the inserted recipe_history row.
  final int historyEntryId;

  /// Each inventory row that was modified during the cook.
  final List<InventoryRowSnapshot> affectedRows;
}

/// A snapshot of an inventory row before it was modified by cooking.
class InventoryRowSnapshot {
  /// Creates an [InventoryRowSnapshot].
  const InventoryRowSnapshot({
    required this.rowId,
    required this.originalQuantity,
  });

  /// The inventory row id.
  final int rowId;

  /// The quantity before the cook deduction.
  final double originalQuantity;
}
```

- [ ] **Step 2: Write the failing provider tests**

```dart
// Add to test/providers/recipe_provider_test.dart

group('cookRecipe', () {
  test('deducts ingredients and inserts history on success', () async {
    when(() => mockDb.getInventoryRowsByBarcode(
      barcode: any(named: 'barcode'),
      inventoryId: any(named: 'inventoryId'),
    )).thenAnswer((_) async => [
      {'id': 1, 'barcode': '123', 'quantity': 5.0, 'unit': 'pieces', 'inventory_id': 1},
    ]);
    when(() => mockDb.insertRecipeHistory(any())).thenAnswer((_) async => 1);
    when(() => mockDb.updateInventoryItem(any())).thenAnswer((_) async => {});

    // ... verify cookRecipe called the right methods
  });

  test('throws on insufficient stock', () async {
    when(() => mockDb.getInventoryRowsByBarcode(
      barcode: any(named: 'barcode'),
      inventoryId: any(named: 'inventoryId'),
    )).thenAnswer((_) async => [
      {'id': 1, 'barcode': '123', 'quantity': 1.0, 'unit': 'pieces', 'inventory_id': 1},
    ]);
    when(() => mockDb.getRecipeIngredients(any())).thenAnswer((_) async => [
      const RecipeIngredient(recipeId: 1, name: 'Eggs', barcode: '123', quantity: 3.0),
    ]);

    expect(
      () => cookRecipe(ref, 1),
      throwsA(isA<StateError>()),
    );
  });
});
```

- [ ] **Step 3: Implement `cookRecipe`**

```dart
/// Cooks a recipe: deducts ingredients from inventory (FEFO), logs history.
///
/// Throws [StateError] with shortage details if stock is insufficient.
Future<CookResult> cookRecipe(WidgetRef ref, int recipeId) async {
  final db = ref.read(databaseProvider);
  final activeInventoryId = ref.read(activeInventoryProvider);
  final ingredients = await db.getRecipeIngredients(recipeId);
  final settings = ref.read(settingsProvider);
  final currencyService = CurrencyService();
  final baseCurrency = settings.baseCurrency;

  if (ingredients.isEmpty) {
    throw StateError('Recipe has no ingredients');
  }

  // --- Pre-flight validation ---
  final shortages = <String, double>{};
  for (final ing in ingredients) {
    if (ing.barcode == null || ing.barcode!.isEmpty) continue;
    final rows = await db.getInventoryRowsByBarcode(
      barcode: ing.barcode!,
      inventoryId: activeInventoryId,
    );
    final available = rows.fold<double>(0, (sum, r) => sum + (r['quantity'] as num).toDouble());
    if (available < ing.quantity) {
      shortages[ing.name] = ing.quantity - available;
    }
  }
  if (shortages.isNotEmpty) {
    final details = shortages.entries.map((e) => 'Not enough ${e.key}: need ${e.value} more').join('; ');
    throw StateError(details);
  }

  // --- Compute current cost ---
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

  // --- Transaction: FEFO deduction + history ---
  final affectedRows = <InventoryRowSnapshot>[];

  return database.transaction<CookResult>((txn) async {
    for (final ing in ingredients) {
      if (ing.barcode == null || ing.barcode!.isEmpty) continue;
      var remaining = ing.quantity;
      final rows = await txn.rawQuery(
        'SELECT * FROM inventory WHERE barcode = ? AND inventory_id = ?'
        ' ORDER BY expiry_date ASC NULLS LAST',
        [ing.barcode, activeInventoryId],
      );
      for (final row in rows) {
        if (remaining <= 0) break;
        final rowId = row['id'] as int;
        final rowQty = (row['quantity'] as num).toDouble();
        affectedRows.add(InventoryRowSnapshot(rowId: rowId, originalQuantity: rowQty));
        if (rowQty > remaining) {
          await txn.update('inventory', {'quantity': rowQty - remaining}, where: 'id = ?', whereArgs: [rowId]);
          remaining = 0;
        } else {
          await txn.delete('inventory', where: 'id = ?', whereArgs: [rowId]);
          remaining -= rowQty;
        }
      }
    }

    final snapshotJson = ingredients.map((ing) => {
      'barcode': ing.barcode,
      'name': ing.name,
      'quantity': ing.quantity,
      'unit': ing.unit,
    }).toList();

    final entry = RecipeHistoryEntry(
      recipeId: recipeId,
      madeAt: DateTime.now().millisecondsSinceEpoch,
      costAtTime: totalCost,
      ingredientSnapshot: const JsonEncoder().convert(snapshotJson),
    );

    final historyId = await txn.insert('recipe_history', {
      'recipe_id': entry.recipeId,
      'made_at': entry.madeAt,
      'cost_at_time': entry.costAtTime,
      'ingredient_snapshot': entry.ingredientSnapshot,
    });

    return CookResult(historyEntryId: historyId, affectedRows: affectedRows);
  }).then((result) {
    invalidateRecipes(ref);
    ref.invalidate(pantryProvider);
    return result;
  });
}
```

- [ ] **Step 4: Run tests to verify**

Run: `flutter test test/providers/recipe_provider_test.dart`
Expected: PASS

- [ ] **Step 5: Run full test suite**

Run: `flutter test --concurrency=2`
Expected: all tests pass

- [ ] **Step 6: Run analyze**

Run: `dart analyze lib/providers/recipe_provider.dart`
Expected: 0 errors

- [ ] **Step 7: Commit**

```bash
git add lib/providers/recipe_provider.dart test/providers/recipe_provider_test.dart
git commit -m "feat: add cookRecipe with FEFO deduction, history logging, and undo support"
```

---

### Task 5: RecipeDetailScreen (view-only)

**Files:**
- Create: `lib/screens/recipe_detail_screen.dart`
- Create: `test/screens/recipe_detail_screen_test.dart`

**Interfaces:**
- Consumes: `Recipe` and `RecipeIngredient` from providers, `cookRecipe()` from Task 4, `PriceVisibilityToggle`
- Produces: `RecipeDetailScreen` widget

- [ ] **Step 1: Write the failing widget test**

```dart
// test/screens/recipe_detail_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/models/recipe.dart';
import 'package:pantry_app/models/recipe_ingredient.dart';
import 'package:pantry_app/providers/database_provider.dart';
import 'package:pantry_app/providers/recipe_provider.dart';
import 'package:pantry_app/screens/recipe_detail_screen.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class MockDatabaseHelper extends Mock implements DatabaseHelper {}

Widget createTestApp(int recipeId) {
  final mockDb = MockDatabaseHelper();
  when(() => mockDb.getRecipe(recipeId)).thenAnswer((_) async => const Recipe(id: 1, name: 'Omelette', instructions: 'Beat eggs.'));
  when(() => mockDb.getRecipeIngredients(recipeId)).thenAnswer((_) async => [
    const RecipeIngredient(recipeId: 1, name: 'Eggs', quantity: 2.0),
  ]);

  return ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(mockDb),
    ],
    child: MaterialApp(
      home: RecipeDetailScreen(recipeId: recipeId),
    ),
  );
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('displays recipe name, ingredients, and instructions', (tester) async {
    await tester.pumpWidget(createTestApp(1));
    await tester.pumpAndSettle();

    expect(find.text('Omelette'), findsOneWidget);
    expect(find.text('2.0 x Eggs'), findsOneWidget);
    expect(find.text('Beat eggs.'), findsOneWidget);
    expect(find.text('I made this'), findsOneWidget);
  });

  testWidgets('shows Edit button in AppBar', (tester) async {
    await tester.pumpWidget(createTestApp(1));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.edit), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/screens/recipe_detail_screen_test.dart`
Expected: FAIL

- [ ] **Step 3: Write the RecipeDetailScreen**

```dart
// lib/screens/recipe_detail_screen.dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/l10n/app_localizations.dart';
import 'package:pantry_app/models/recipe.dart';
import 'package:pantry_app/models/recipe_ingredient.dart';
import 'package:pantry_app/providers/database_provider.dart';
import 'package:pantry_app/providers/pantry_provider.dart';
import 'package:pantry_app/providers/recipe_provider.dart';
import 'package:pantry_app/providers/settings_provider.dart';
import 'package:pantry_app/screens/recipe_form_screen.dart';
import 'package:pantry_app/services/currency_service.dart';
import 'package:pantry_app/utils/snackbar_helper.dart';
import 'package:pantry_app/widgets/price_mask.dart';
import 'package:pantry_app/widgets/price_visibility_toggle.dart';

/// Displays a single recipe in read-only mode with its ingredients,
/// instructions, cost, and a "I made this" action.
class RecipeDetailScreen extends ConsumerStatefulWidget {
  /// Creates a [RecipeDetailScreen] for the given [recipeId].
  const RecipeDetailScreen({super.key, required this.recipeId});

  /// The id of the recipe to display.
  final int recipeId;

  @override
  ConsumerState<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends ConsumerState<RecipeDetailScreen> {
  Recipe? _recipe;
  List<RecipeIngredient> _ingredients = [];
  bool _isLoading = true;
  bool _isCooking = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final db = ref.read(databaseProvider);
    final recipe = await db.getRecipe(widget.recipeId);
    final ingredients = await db.getRecipeIngredients(widget.recipeId);
    if (!mounted) return;
    setState(() {
      _recipe = recipe;
      _ingredients = ingredients;
      _isLoading = false;
    });
  }

  Future<void> _cook() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isCooking = true);
    try {
      final result = await cookRecipe(ref, widget.recipeId);
      if (!mounted) return;
      SnackbarHelper.showUndo(
        context,
        'Recipe made',
        () async {
          // Undo: restore inventory rows
          final db = ref.read(databaseProvider);
          final database = await db.database;
          await database.transaction((txn) async {
            for (final row in result.affectedRows) {
              final existing = await txn.query(
                'inventory',
                where: 'id = ?',
                whereArgs: [row.rowId],
              );
              if (existing.isNotEmpty) {
                await txn.update(
                  'inventory',
                  {'quantity': row.originalQuantity},
                  where: 'id = ?',
                  whereArgs: [row.rowId],
                );
              } else {
                // Row was deleted; re-insert with original qty
                await txn.rawInsert(
                  'INSERT INTO inventory (id, barcode, quantity, unit, inventory_id)'
                  ' VALUES (?, ?, ?, ?, ?)',
                  [row.rowId, '', row.originalQuantity, 'pieces', 0],
                );
              }
            }
            await txn.delete('recipe_history', where: 'id = ?', whereArgs: [result.historyEntryId]);
          });
          ref.invalidate(pantryProvider);
          invalidateRecipes(ref);
        },
      );
      if (!mounted) return;
      setState(() => _isCooking = false);
    } on StateError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
      setState(() => _isCooking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(settingsProvider);
    final priceTrackingEnabled = settings.priceTrackingEnabled;
    final currencyCode = settings.baseCurrency;
    final symbol = currencySymbolFor(currencyCode);

    return Scaffold(
      appBar: AppBar(
        title: Text(_recipe?.name ?? ''),
        actions: [
          if (priceTrackingEnabled) const PriceVisibilityToggle(),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              unawaited(
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RecipeFormScreen(
                      existingRecipeId: widget.recipeId,
                    ),
                  ),
                ).then((_) => _load()),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _recipe == null
              ? Center(child: Text(l10n.noRecipes))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Ingredients
                    Text(l10n.recipeIngredients,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    ..._ingredients.map((ing) => ListTile(
                          dense: true,
                          title: Text('${ing.quantity} x ${ing.name}'),
                          trailing: PriceMask(
                            child: Text(
                              '$symbol${_ingredientCost(ing, currencyCode, symbol).toStringAsFixed(2)}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        )),
                    const Divider(),
                    // Instructions
                    if (_recipe!.instructions.isNotEmpty) ...[
                      Text(l10n.recipeInstructions,
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text(_recipe!.instructions),
                      const SizedBox(height: 16),
                    ],
                    // Total cost
                    Row(
                      children: [
                        Text(l10n.recipeCost,
                            style: Theme.of(context).textTheme.titleSmall),
                        const Spacer(),
                        PriceMask(
                          child: Text(
                            '$symbol${_totalCost(currencyCode, symbol).toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Cook button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isCooking ? null : _cook,
                        icon: _isCooking
                            ? const SizedBox(
                                width: 18, height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.restaurant),
                        label: Text('I made this'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  double _ingredientCost(RecipeIngredient ing, String currencyCode, String symbol) {
    // Placeholder — will compute via price lookup in a follow-up if needed
    return 0.0;
  }

  double _totalCost(String currencyCode, String symbol) {
    // Placeholder — will compute via price lookup in a follow-up if needed
    return 0.0;
  }
}
```

- [ ] **Step 4: Run tests**

Run: `flutter test test/screens/recipe_detail_screen_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/screens/recipe_detail_screen.dart test/screens/recipe_detail_screen_test.dart
git commit -m "feat: add RecipeDetailScreen with view-only layout and 'I made this' button"
```

---

### Task 6: Wire RecipeListScreen — detail navigation + eye icon

**Files:**
- Modify: `lib/screens/recipe_list_screen.dart`

**Changes:**
- Replace `Navigator.push(RecipeFormScreen(existingRecipeId:))` on card tap with `Navigator.push(RecipeDetailScreen(recipeId:))`
- Add `PriceVisibilityToggle` in AppBar

- [ ] **Step 1: Add the eye icon to AppBar**

In the `Scaffold`'s `appBar`, add `actions`:

```dart
appBar: AppBar(
  title: Text(l10n.recipes),
  actions: [
    Consumer(
      builder: (context, ref, child) {
        final settings = ref.watch(settingsProvider);
        if (!settings.priceTrackingEnabled) return const SizedBox.shrink();
        return const PriceVisibilityToggle();
      },
    ),
  ],
),
```

- [ ] **Step 2: Change card onTap to navigate to detail screen**

In `_RecipeCard.build()`, change `onTap`:

```dart
onTap: () {
  unawaited(
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RecipeDetailScreen(recipeId: recipe.id!),
      ),
    ).then((_) {
      ref.invalidate(allRecipesProvider);
    }),
  );
},
```

- [ ] **Step 3: Add `PriceVisibilityToggle` import if not already present**

- [ ] **Step 4: Run tests**

Run: `flutter test --concurrency=2`
Expected: all tests pass (update existing tests if needed)

- [ ] **Step 5: Run analyze**

Run: `dart analyze lib/screens/recipe_list_screen.dart`
Expected: 0 errors

- [ ] **Step 6: Commit**

```bash
git add lib/screens/recipe_list_screen.dart
git commit -m "feat: wire recipe list to detail screen, add eye icon"
```

---

### Task 7: Localization — new ARB strings

**Files:**
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_pt.arb`
- Modify: `lib/l10n/app_pt_BR.arb`

- [ ] **Step 1: Add strings to app_en.arb**

```json
"madeRecipe": "I made this",
"recipeDetail": "Recipe details",
"cookRecipeShortage": "Not enough {ingredient}: have {available}, need {needed}",
"cookRecipeSuccess": "Recipe made",
"cookRecipeUndo": "Undo",
"recipeHistory": "History",
"ingredientCost": "Ingredient cost",
"totalCost": "Total cost",
"cooking": "Cooking...",
```

- [ ] **Step 2: Add translations to app_pt.arb and app_pt_BR.arb**

```json
"madeRecipe": "Fiz esta receita",
"cookRecipeSuccess": "Receita feita",
"recipeHistory": "Historico",
"totalCost": "Custo total",
```

(Full translations to match app_en.arb entries.)

- [ ] **Step 3: Run `flutter gen-l10n`**

- [ ] **Step 4: Run analyze**

Run: `dart analyze lib/l10n/`
Expected: 0 errors

- [ ] **Step 5: Commit**

```bash
git add lib/l10n/ lib/l10n/
git commit -m "feat: add recipe cook and detail localization strings"
```

---

### Task 8: Changelogs

**Files:**
- Modify: `CHANGELOG.md`
- Modify: `USER_CHANGELOG.md`
- Modify: `USER_CHANGELOG_pt.md`
- Modify: `USER_CHANGELOG_pt_BR.md`

- [ ] **Step 1: Update CHANGELOG.md**

Add entry under `## [0.0.10]` with description of all tasks.

- [ ] **Step 2: Update USER_CHANGELOG.md + translations**

Add user-facing entry.

- [ ] **Step 3: Run final verification gate**

```bash
dart analyze
flutter test --concurrency=2
```

- [ ] **Step 4: Commit**

```bash
git add CHANGELOG.md USER_CHANGELOG.md USER_CHANGELOG_pt.md USER_CHANGELOG_pt_BR.md
git commit -m "docs: update changelogs for recipe cook and detail features"
```
