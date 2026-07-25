# Recipe Cook, Detail, History, and Price Toggle

## Overview

Extend the existing recipe feature (issue #156) with four capabilities that
close the loop between meal planning and inventory management: a read-only
recipe detail screen, an "I made this" action that deducts ingredients from
inventory and logs the event, a recipe history table for immutable records,
and a price visibility toggle (eye icon) on recipe screens.

## In scope

1. RecipeDetailScreen (view-only)
2. "I made this" cook flow (FEFO deduction, shortage warnings, undo)
3. RecipeHistory table + DAO
4. PriceVisibilityToggle + PriceMask on recipe screens

## Deferred (follow-up issues)

- Nutri-Score for recipes (aggregate per-100g from ingredient nutrition)
- Stats screen integration (30-day recipe metrics)
- Recommendation notifications (expiring-ingredient-based)

## 1. Recipe Detail Screen

### Navigation change

- `RecipeListScreen`: tapping a recipe card navigates to
  `RecipeDetailScreen(id)` instead of `RecipeFormScreen(existingRecipeId:)`.
  The edit icon/button on the detail screen opens the form for editing.

### Layout

```
AppBar(title: recipe.name, actions: [PriceVisibilityToggle, Edit IconButton])
─ Ingredient list (each row: "2 x eggs", cost masked)
─ Instructions section (hidden if empty)
─ Total cost row (PriceMask)
─ Full-width "I made this" button (raised, cooking-pot icon)
```

- No form fields here — this is a pure preview.
- All cost labels use the existing `PriceMask` widget.

## 2. "I Made This" (Cook / Inventory Deduction)

### Location

The prominent "I made this" button is the primary action on
`RecipeDetailScreen`.

### Pre-flight validation

1. For each `RecipeIngredient`, find inventory rows with matching barcode in
   the active inventory.
2. Sum available quantity per barcode.
3. If `available < needed` for any ingredient, show an AlertDialog listing
   each shortage: "Not enough X: have Y, need Z". The cook is blocked.
4. If all pass, proceed.

### Deduction (FEFO)

For each ingredient barcode:
1. Query inventory rows WHERE barcode = ? AND inventory_id = activeInventoryId
   ORDER BY expiry_date ASC NULLS LAST.
2. Remaining = needed quantity.
3. For each row:
   - If row.quantity > remaining: row.quantity -= remaining, update row, done.
   - Else: remaining -= row.quantity, delete row, continue.

### Transactional guarantee

All deductions + history insert run in a single `db.transaction()`. Rollback
on any failure or if the user navigates away mid-flow.

### History entry

Insert into `recipe_history`:
- `recipeId`
- `madeAt` = `DateTime.now().millisecondsSinceEpoch`
- `costAtTime` = current total recipe cost (computed at cook time)
- `ingredientSnapshot` = JSON string encoding the list of ingredients used

### Undo

`SnackbarHelper.showUndo("Recipe made", callback)`. The undo callback:
1. Runs a transaction: deletes the history entry by id, reverses all inventory
   deductions (add back quantities / re-insert deleted rows).
2. Invalidates relevant providers.

## 3. Recipe History Table & Data Layer

### Migration v26

```sql
CREATE TABLE recipe_history (
  id                 INTEGER PRIMARY KEY AUTOINCREMENT,
  recipe_id          INTEGER NOT NULL,
  made_at            INTEGER NOT NULL,
  cost_at_time       REAL DEFAULT 0,
  ingredient_snapshot TEXT
);
-- No FK CASCADE — history is immutable even if the recipe is deleted later.
CREATE INDEX idx_recipe_history_recipe ON recipe_history(recipe_id);
CREATE INDEX idx_recipe_history_made_at ON recipe_history(made_at);
```

### RecipeHistoryDao

| Method | Description |
|---|---|
| `insert(Database, RecipeHistoryEntry)` | Returns new id |
| `getByRecipeId(Database, recipeId)` | Ordered by made_at DESC |
| `getRecent(Database, sinceMillis)` | All entries after timestamp |
| `deleteById(Database, id)` | For undo |

### RecipeHistoryEntry (freezed model)

- `id` (int?, auto)
- `recipeId` (int)
- `madeAt` (int, millis)
- `costAtTime` (double)
- `ingredientSnapshot` (String, JSON)

### Provider / mutation function

```dart
Future<CookResult> cookRecipe(WidgetRef ref, int recipeId)
```

Orchestrates: validate → FEFO deduct → insert history → invalidate providers.
Throws descriptive errors for shortages.

Returns a `CookResult` containing:
- `historyEntryId` (int) — for undo
- `affectedRows` (List of `{inventoryItem, originalQuantity}`) — for reversing

The undo callback on `SnackbarHelper.showUndo` receives this result and
restores each inventory row to its original quantity, then deletes the
history entry.

## 4. Price Visibility Toggle

Follow the existing pattern:

- `RecipeListScreen` AppBar: add `PriceVisibilityToggle` conditionally
  (when `priceTrackingEnabled`).
- `RecipeDetailScreen` AppBar: add `PriceVisibilityToggle` conditionally.
- Cost labels on both screens use `PriceMask` — no extra state needed.

The toggle is shared globally via `pricesHiddenProvider` /
`settingsProvider.setPricesHidden()`, already implemented.

### CookResult model

A plain (non-freezed) data class or a simple record:

```dart
class CookResult {
  final int historyEntryId;
  final List<_RestoredRow> affectedRows;
}

class _RestoredRow {
  final int inventoryItemId;
  final double originalQuantity;
}
```

Used only internally by the undo callback — not persisted.

## Files to create

| File | Purpose |
|---|---|
| `lib/models/recipe_history_entry.dart` | Freezed model |
| `lib/database/recipe_history_dao.dart` | CRUD for recipe_history |
| `lib/screens/recipe_detail_screen.dart` | View-only recipe detail |
| `test/models/recipe_history_entry_test.dart` | Model unit test |
| `test/database/recipe_history_dao_test.dart` | DAO unit test |
| `test/screens/recipe_detail_screen_test.dart` | Widget test |
| `test/providers/recipe_provider_test.dart` | Extend with cook tests |

## Files to modify

| File | Change |
|---|---|
| `lib/database/database_helper.dart` | v26 migration, delegation methods |
| `lib/providers/recipe_provider.dart` | Add `cookRecipe()` |
| `lib/screens/recipe_list_screen.dart` | Navigate to detail, add eye icon |
| `lib/screens/recipe_form_screen.dart` | No structural change |
| `lib/l10n/app_en.arb` | New strings (cook, detail, shortages, history) |
| `lib/l10n/app_pt.arb` | Translations |
| `lib/l10n/app_pt_BR.arb` | Translations |
| `CHANGELOG.md` | Entry |
| `USER_CHANGELOG.md` + pt/pt_BR | Entry |
