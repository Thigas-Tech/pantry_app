# Produce Carousel: Navigate to Product Detail Screen

## Summary

The produce quick-add carousel on the home screen currently inserts an inventory
item directly (150 g, gram unit) when tapped. This spec changes the flow so that
tapping a produce chip resolves the product **without inserting it**, then
navigates to the existing `ProductDetailScreen` — the same screen reached after
scanning a barcode. Users see the nutrition table, can add a price, and use the
"Add to Inventory" button (which defaults to **unit mode** with quantity 1).

## Motivation

- Users want produce in **units** (1 apple, 1 onion), not grams.
- Users want to see **nutritional data** before adding.
- Users want to optionally **add a price** before adding.
- Reuse the existing `ProductDetailScreen` flow (barcode scan reachs it already).

## Behavioural specification

### Tap produce chip → loading state

1. The tapped chip is immediately **disabled** and shows a small
   `CircularProgressIndicator` replacing its label text.
2. Other chips remain interactive.
3. `HomeScreen` calls `ProductRepository.resolveProduceProduct(produceName)` to
   obtain a `Product` with the synthetic barcode `produce-$produceName`.
4. Resolution follows the existing chain:
   - USDA API (via `UsdaApiClient`)
   - Hardcoded fallback (via `ProduceNutritionFallback`)
   - Minimal product with no nutrition values
5. If the resolve call throws, the loading state is cleared and an error
   snackbar is shown.
6. If the resolve succeeds, the loading state is cleared and the screen
   navigates to `ProductDetailScreen(product: resolvedProduct)`.

### Product detail screen

7. The `ProductDetailScreen` displays the produce name, the `NutritionTable`
   (showing `-` for missing values), the price section, and the
   "Add to Inventory" button — identical to the barcode scan flow.
8. The "View on Open Food Facts" appbar button is present but will show an
   OFF URL for the synthetic barcode, which will 404. This is acceptable
   (same behaviour as any unknown product). **No change needed.**

### Add to Inventory screen

9. "Add to Inventory" opens `AddToInventoryScreen` in **unit mode** for
   produce products (the weight/unit toggle defaults to "Unit").
10. The default quantity is **1**, size is **Medium**.
11. The unit defaults to `'pieces'` for farm produce like apples and onions,
    consistent with the existing `AddToInventoryScreen` behaviour when
    `productType == ProductType.produce`.

### After returning from ProductDetailScreen

12. `ProducePurchaseTracker.recordPurchase(produceName)` is called so the
    carousel learns user preferences (regardless of whether the user completed
    the add-to-inventory flow).
13. `ref.invalidate(inventoryWithProductProvider)` is called to refresh the
    home screen inventory list (a no-op if nothing was added, but safe).

### Error handling

| Scenario | Behaviour |
|----------|-----------|
| `resolveProduceProduct` throws | Loading state cleared; error snackbar shown |
| User taps a chip already loading | No-op (loading set prevents re-entry) |
| User navigates back without adding | Purchase still recorded (intent), inventory invalidated |
| USDA API rate-limited | Falls through to hardcoded fallback silently |
| No network + no cached product | Falls through to minimal product (no nutrition) |

## Architecture changes

### `ProductRepository` (`lib/services/product_repository.dart`)

- **New public method** `resolveProduceProduct(String produceName)` that
  generates the synthetic barcode `produce-$produceName` and delegates to
  the existing private `_resolveProduceProduct(String, String)`.
- The method is **pure** (no DB writes, no inventory mutations).

### `QuickAddProduce` (`lib/widgets/quick_add_produce.dart`)

- Accept new optional parameter `Set<String> loadingItems`.
- Parameter is not required (backward-compatible).
- When a chip's name is in `loadingItems`:
  - Chip is disabled (`onPressed: null`).
  - Label shows a small `SizedBox` with `CircularProgressIndicator(strokeWidth: 2)`.
- No internal state changes (remains a `StatelessWidget`).

### `HomeScreen` (`lib/screens/home_screen.dart`)

- Add `Set<String> _loadingProduce` state variable.
- In `_handleQuickProduceAdd`:
  ```dart
  if (_loadingProduce.contains(produceName)) return; // deduplicate
  setState(() => _loadingProduce.add(produceName));
  try {
    final product = await repo.resolveProduceProduct(produceName);
    if (!mounted) return;
    setState(() => _loadingProduce.remove(produceName));
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(product: product),
      ),
    );
    if (!mounted) return;
    ref.invalidate(inventoryWithProductProvider);
    await ProducePurchaseTracker().recordPurchase(produceName);
  } on Exception catch (e) {
    setState(() => _loadingProduce.remove(produceName));
    logError('Failed to resolve produce product: $e');
    if (mounted) SnackbarHelper.showError(context, l10n.couldNotCreateInventory);
  }
  ```
- Pass `_loadingProduce` to `QuickAddProduce(loadingItems: _loadingProduce)`.

### `ProductDetailScreen._openAddEditScreen` (`lib/screens/product_detail_screen.dart`)

- Pass `productType: widget.product.productType` to `AddToInventoryScreen`
  constructor call.

### `AddToInventoryScreen._produceIsWeightMode` (`lib/screens/add_to_inventory_screen.dart`)

- Default `_produceIsWeightMode` to `false` when `_isProduce` is `true`.
- This is the initial value set in `initState`:
  ```dart
  _produceIsWeightMode = !_isProduce; // true for non-produce, false for produce
  ```

## Data flow

```
User taps "Apple" chip
  │
  ▼
HomeScreen._handleQuickProduceAdd("Apple")
  │
  ├─ Add "Apple" to _loadingProduce set
  │
  ├─ repo.resolveProduceProduct("Apple")
  │   └─ _resolveProduceProduct("Apple", "produce-Apple")
  │       ├─ USDA API → Product (USDA data)
  │       ├─ ProduceNutritionFallback → Product (fallback data)
  │       └─ Minimal Product (null nutrition)
  │
  ├─ Remove "Apple" from _loadingProduce set
  │
  ├─ Navigator.push → ProductDetailScreen(product: product)
  │   ├─ NutritionTable renders product nutrition
  │   ├─ User can add/edit price
  │   └─ User taps "Add to Inventory"
  │       └─ AddToInventoryScreen (unit mode, qty 1, Medium)
  │           └─ repo.cacheProduct + repo.addInventoryItem
  │
  ├─ (after detail screen returns)
  ├─ ref.invalidate(inventoryWithProductProvider)
  └─ ProducePurchaseTracker().recordPurchase("Apple")
```

## Test plan (TDD)

### Unit tests: `ProductRepository`

| Test | Expected |
|------|----------|
| `resolveProduceProduct` returns product with correct barcode | Barcode is `produce-$name` |
| `resolveProduceProduct` returns product with `ProductType.produce` | `productType` is `produce` |
| Falls through USDA → fallback → minimal | Same as existing `_resolveProduceProduct` tests |

### Unit tests: `QuickAddProduce`

| Test | Expected |
|------|----------|
| Shows loading indicator for items in loadingItems | `CircularProgressIndicator` found |
| Loading chip is disabled | `ActionChip.onPressed` is null |
| Non-loading chips remain interactive | All other chips work normally |
| Empty loadingItems set shows normal chips | No progress indicators |

### Widget tests: `HomeScreen` (carousel)

| Test | Expected |
|------|----------|
| Tapping produce chip starts loading | Chip shows progress indicator |
| After resolve succeeds, navigates to ProductDetailScreen | `ProductDetailScreen` is visible |
| After detail screen returns, purchase recorded | `ProducePurchaseTracker.recordPurchase` called |
| After detail screen returns, inventory invalidated | Provider invalidation triggered |
| Resolve failure shows error snackbar | Error snackbar visible, loading cleared |
| Rapid tap same chip is deduplicated | `resolveProduceProduct` called once |

### Widget tests: `AddToInventoryScreen`

| Test | Expected |
|------|----------|
| Produce type defaults to unit mode | `SegmentedButton` shows "Unit" selected |
| Non-produce defaults to weight mode | `SegmentedButton` shows "Weight" selected |

## Files changed

| File | Change |
|------|--------|
| `lib/services/product_repository.dart` | Add public `resolveProduceProduct` method |
| `lib/widgets/quick_add_produce.dart` | Add `loadingItems` parameter, loading UI |
| `lib/screens/home_screen.dart` | Refactor `_handleQuickProduceAdd`, add loading state |
| `lib/screens/product_detail_screen.dart` | Pass `productType` to `AddToInventoryScreen` |
| `lib/screens/add_to_inventory_screen.dart` | Default produce to unit mode |
| `test/services/product_repository_test.dart` | Add `resolveProduceProduct` unit tests |
| `test/widgets/quick_add_produce_test.dart` | Loading state tests |
| `test/screens/home_screen_test.dart` | Update existing carousel tests, add new ones |

## Out of scope

- Changing the synthetic barcode format (`produce-$name`).
- Modifying the OFF "view on web" URL behaviour for produce products.
- Adding new nutrition data sources beyond the existing USD/fallback chain.
- Rewriting the ProductDetailScreen layout or the AddToInventoryScreen form.
- Changing how the carousel items are loaded (`ProducePurchaseTracker` unchanged).
