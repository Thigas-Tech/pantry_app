# Changelog

## [0.0.10] — 2026-07-23

### Added
- **Recipe detail screen**: read-only view of a recipe with ingredient list,
  instructions, cost (maskable via eye icon), and a prominent "I made this"
  button. Tapping a recipe in the list now opens the detail screen instead
  of jumping directly to edit mode.
  (`lib/screens/recipe_detail_screen.dart`)
- **"I made this" (cook) flow**: marks a recipe as cooked, deducts
  ingredients from inventory using FEFO (first-expired-first-out), and
  logs an immutable history entry. Shortage warnings prevent cooking when
  stock is insufficient. Undo support via SnackbarHelper.
  (`lib/providers/recipe_provider.dart` — `cookRecipe`)
- **Recipe history**: new `recipe_history` table (database migration v26),
  freezed model and DAO for immutable cook-event logging.
  (`lib/models/recipe_history_entry.dart`,
   `lib/database/recipe_history_dao.dart`)
- **Price visibility toggle**: eye icon added to the recipe list and detail
  screen AppBars, using the existing `PriceVisibilityToggle` / `PriceMask`
  pattern. (`lib/screens/recipe_list_screen.dart`,
   `lib/screens/recipe_detail_screen.dart`)
- **Duplicate ingredient merging**: when the same barcoded ingredient is added
  twice to a recipe, the quantity is incremented instead of creating a new row.
  (`lib/screens/recipe_form_screen.dart`)
- **PriceMask in recipe list**: cost labels in recipe cards and the average cost
  banner now respect the price visibility toggle via `PriceMask`.
  (`lib/screens/recipe_list_screen.dart`)
- **Search-powered ingredient picker**: "Search product" button in the recipe
  form opens a bottom sheet that searches the local database and Open Food Facts
  API by name or barcode. Tapping a result adds it as an ingredient.
  (`lib/widgets/search_ingredient_sheet.dart`,
   `lib/screens/recipe_form_screen.dart`)

## [0.0.9] — 2026-07-23

### Added
- **Recipe registration**: new `recipes` and `recipe_ingredients` tables
  (migration v25). Freezed models with DAOs, providers, and cost calculation
  using the user's base currency setting. RecipeFormScreen for create/edit,
  RecipeListScreen for browsing with swipe-to-delete. Auto-populate
  ingredients from current inventory. Average recipe cost banner.
  (`lib/models/recipe.dart`, `lib/models/recipe_ingredient.dart`,
   `lib/database/recipe_dao.dart`, `lib/database/recipe_ingredient_dao.dart`,
   `lib/providers/recipe_provider.dart`, `lib/screens/recipe_form_screen.dart`,
   `lib/screens/recipe_list_screen.dart`, fixes #156)

## [0.0.8+4] — 2026-07-18

### Added
- Firebase product cache: replicates OFF and USDA product data to Cloud
  Firestore with a 180-day rolling refresh cycle.
- Anonymous Firebase Auth for Firestore security rule compliance.
- `authServiceProvider` and `authStateProvider` for reactive auth state.
- AuthUser model with anonymous/non-anonymous support.

### Fixed
- Active inventory ID persistence and validation on startup (falls back to
  first available inventory or reseeds default).
- Riverpod setState during build on back-navigation.
- Bottom sheet safe area padding on gesture navigation.
- Deferred `pantryProvider` invalidation in `refreshIfOverdue` to a microtask
  to prevent "setState during build" when the overdue cache refresh completes
  during the initial frame. (`lib/providers/home_screen_controller.dart`)

## [0.0.8] - 2026-07-16

### Fixed
- **USDA FoodData Central API returned 403 on every search**: `api_key` was placed in the POST body instead of as a URL query parameter. The API ignores the body parameter and returns `403 Forbidden`. Moved `api_key` to a URI query parameter via `Uri.replace(queryParameters: ...)`. Also added a distinct warning message for 403 suggesting the user checks their `.env` config. (`lib/services/usda_api_client.dart`)
- **Refresh failed for every produce item**: `refreshInventoryProducts()` passed synthetic barcodes (`produce-Banana`, `plu-12345`) to the OFF API, which always returns `ProductNotFoundException`. Filtered out barcodes starting with `produce-` or `plu-` before the refresh batch. (`lib/services/product_repository.dart`)
- **Wrong Portuguese translation for produceApple**: `"Maca"` corrected to `"Maçã"` in `app_pt.arb` and `app_pt_BR.arb`. Regenerated via `flutter gen-l10n`. (`lib/l10n/app_pt.arb`, `lib/l10n/app_pt_BR.arb`, `lib/l10n/app_localizations_pt.dart`)

### Added
- **`productType` on `InventoryWithProduct`**: New `productType` field (`ProductType?`) fetched via `products.product_type AS product_type` in the SQL join query. (`lib/models/inventory_with_product.dart`, `lib/database/inventory_dao.dart`)
- **Tests for produce localization and leaf icons**: 4 tests in `inventory_card_test.dart` for localized produce display and null/fallback; 4 tests in `search_screen_test.dart` for produce leaf avatar + trailing icon; 2 tests in `add_to_shopping_list_sheet_test.dart` for produce leaf icon in sheet. `pumpApp` helper accepts optional `Locale? locale` parameter. (`test/widgets/inventory_card_test.dart`, `test/screens/search_screen_test.dart`, `test/widgets/add_to_shopping_list_sheet_test.dart`, `test/helpers/pump_app.dart`)

### Added
- **Localized USER_CHANGELOG in pt and pt_BR**: New `changelog_loader.dart` utility provides `loadLocalizedChangelog(Locale)` that resolves locale-specific `USER_CHANGELOG_*.md` assets with fallback to English. The "What's New" sheet now loads content in the app's current language. (`USER_CHANGELOG_pt.md` new, `USER_CHANGELOG_pt_BR.md` new, `lib/utils/changelog_loader.dart` new, `lib/screens/pantry_shell.dart`, `lib/screens/settings_screen.dart`, `pubspec.yaml`)
- **16 unit/widget tests for changelog locale resolution**: Tests for `changelogAssetPath`, `loadLocalizedChangelog` fallback, and `WhatsNewSheet` rendering with Portuguese locale and content. (`test/widgets/whats_new_sheet_test.dart`)

### Changed
- **InventoryCard localizes produce names**: New `_localizedDisplayName(AppLocalizations)` helper applies `l10n.localizeProduceName()` when `product.productType == ProductType.produce`. Title and both Semantics labels use the localized name. (`lib/widgets/inventory_card.dart`)
- **ProductDetailScreen AppBar localizes produce**: Title calls `l10n.localizeProduceName()` for produce items instead of displaying the raw product name. (`lib/screens/product_detail_screen.dart`)
- **Search screen leaf icon for produce**: `_produceOrBarcodeAvatar()` shows `Icons.eco_outlined` (green) for produce items instead of barcode text. Trailing icon also shows leaf instead of cloud icon. (`lib/screens/search_screen.dart`)
- **AddToShoppingListSheet leaf icon for produce**: Same `_produceOrBarcodeAvatar()` pattern — leaf avatar and leaf trailing icon for produce results. (`lib/widgets/add_to_shopping_list_sheet.dart`)
- **Changelog system replaced**: Removed `ChangelogParser` and `userFacingSectionContent` in favour of a hand-written `USER_CHANGELOG.md`. The app now reads user-facing changelog entries directly from the new file instead of parsing and cleaning the developer `CHANGELOG.md`. (`USER_CHANGELOG.md` new, `lib/services/changelog_parser.dart` removed, `lib/services/changelog_cleaner.dart` removed, `lib/widgets/whats_new_sheet.dart`, `lib/screens/pantry_shell.dart`, `lib/screens/settings_screen.dart`, `lib/main.dart`)

## [0.0.7]

### Fixed
- **Price calculator formatter produced leading zeros**: `_PriceCalculatorFormatter` (now `PriceCalculatorFormatter`) did not strip leading zeros from the digit string, causing inputs like typing `5,0,0` to produce `0005.00` instead of `5.00`. Fixed by wrapping integer-part extraction with `int.parse(...).toString()`. Extracted the formatter to a public class in `lib/formatters/price_calculator_formatter.dart` with 17 unit tests. (`lib/formatters/price_calculator_formatter.dart` new, `lib/widgets/price_entry_sheet.dart`)
- **Bottom sheet content obscured by Android system navigation bar**: All four bottom sheets (`price_entry_sheet`, `quantity_and_pantry_sheet`, `add_to_shopping_list_sheet`, `whats_new_sheet`) now add `MediaQuery.padding.bottom` to their content padding. Fixed by replacing `const EdgeInsets.fromLTRB(16, 16, 16, 16)` with `EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomPad)`. (`lib/widgets/price_entry_sheet.dart`, `lib/widgets/quantity_and_pantry_sheet.dart`, `lib/widgets/add_to_shopping_list_sheet.dart`, `lib/widgets/whats_new_sheet.dart`)
- **Keyboard hides bottom sheet content**: Added `MediaQuery.viewInsets.bottom` to bottom padding of all scrollable bottom sheets, providing scrollable space to see the last field/button above the keyboard. (`lib/widgets/price_entry_sheet.dart`, `lib/widgets/quantity_and_pantry_sheet.dart`, `lib/widgets/add_to_shopping_list_sheet.dart`)
- **Edit mode price input inconsistent**: Removed `_EditPriceFormatter` (plain filter) — both new and edit modes now use `PriceCalculatorFormatter` so typing `500` always produces `5.00`. (`lib/widgets/price_entry_sheet.dart`)

### Added
- **Agent docs for bottom sheet safe area pattern**: `agents_docs/bottom_sheet_safe_area.md` documents the fix pattern, why `SafeArea` is not used, and how to write new bottom sheets correctly. (`agents_docs/bottom_sheet_safe_area.md` new)

## [0.0.6]

### Added
- **Expiry notifications now show product name**: Changed notification builder functions from barcode to product name. `NotificationService.scheduleExpiryReminders` accepts an optional `productName` parameter; falls back to barcode when name is unavailable. `rescheduleAllItems` accepts a `barcodeToName` map for batch name lookup on startup. Updated all 4 call sites in `product_detail_screen.dart` to pass the product name from the detail page. (`lib/services/notification_service.dart`, `lib/main.dart`, `lib/screens/product_detail_screen.dart`, `lib/l10n/app_*.arb`, fixes #125)
- **"From your pantry" suggestions in shopping list**: The add-to-shopping-list sheet now shows distinct products from the active inventory as quick-pick suggestions when the search field is empty. Tapping an inventory item links it by barcode. New `InventoryDao.distinctProductsFromInventory` method and `inventoryProductsProvider`. (`lib/database/inventory_dao.dart`, `lib/database/database_helper.dart`, `lib/providers/shopping_list_provider.dart`, `lib/widgets/add_to_shopping_list_sheet.dart`, `lib/l10n/app_*.arb`, fixes #68)
- **New stats charts: monthly spending, spending by store, Nutri-Score by store**: Added `MonthlySpending`, `StoreSpending`, and `StoreNutriscore` freezed models to `PantryStats`. New `PriceDao` aggregation methods (`monthlyExpenditure`, `storeSpending`, `nutriscoreByStore`) with CTE-based queries scoped to inventory items. New chart sections on Stats screen: line chart for monthly trends, bar chart for per-store spending, progress bars for Nutri-Score by store. (`lib/models/pantry_stats.dart`, `lib/database/price_dao.dart`, `lib/providers/stats_provider.dart`, `lib/screens/stats_screen.dart`, `lib/l10n/app_*.arb`, fixes #33)
- **New ARB keys**: `fromYourPantry`, `inYourPantry`, `monthlySpendingTitle`, `storeSpendingTitle`, `nutriscoreByStoreTitle`, `noStoreData`, `noSpendingData`, `monthLabel`, `averageScore` in en, pt, and pt_BR. (`lib/l10n/app_*.arb`)
- **Renamed ARB placeholders**: `expiresTomorrow` and `expiresToday` now use `{name}` instead of `{barcode}` for clarity when product names are displayed. (`lib/l10n/app_*.arb`, fixes #125)
- **Barcode-less product support (produce)**: PLU (Price Look-Up) code entry on the scanner screen via a numeric keypad. PLU codes like 4011 (Banana) are resolved locally to produce names, then nutritional data is fetched from Open Food Facts. A new `ProductType` enum (`barcoded`, `produce`, `custom`) and `pluCode` field on `Product` distinguish produce from barcoded products. DB migration v21 adds `plu_code` and `product_type` columns. New `PluService` with ~70 common produce PLU codes. New `UsdaApiClient` for USDA FoodData Central API fallback. New `ProduceSearchService` coordinates OFF API → USDA → manual entry with PLU enrichment. Scanner now returns `ScanResult` (sealed class: `BarcodeResult` or `PluResult`) instead of raw string. (`lib/models/product_type.dart` new, `lib/models/product.dart`, `lib/database/database_helper.dart`, `lib/database/product_dao.dart`, `lib/services/plu_service.dart` new, `lib/services/usda_api_client.dart` new, `lib/services/produce_search_service.dart` new, `lib/services/scan_result.dart` new, `lib/screens/scanner_screen.dart`, `lib/screens/home_screen.dart`, `lib/config.dart`, fixes #113)
- **Weight/unit toggle for produce**: `AddToInventoryScreen` now shows a weight/unit `SegmentedButton` for products with `productType: ProductType.produce`. Weight mode stores quantity in grams (`unit: 'g'`). Unit mode stores serving count and label (e.g., `unit: 'medium apple'`) with `servingWeightG` for nutrition calculations. New `ProduceServingPresets` maps ~35 produce names to Small/Medium/Large sizes. DB migration v22 adds `serving_weight_g` column on `inventory`. (`lib/services/produce_serving_presets.dart` new, `lib/models/inventory_item.dart`, `lib/database/database_helper.dart`, `lib/database/inventory_dao.dart`, `lib/screens/add_to_inventory_screen.dart`, fixes #113)
- **Quick-add produce carousel**: Horizontal carousel of 8 common produce items on the HomeScreen. Tapping adds a default serving to inventory with undo snackbar. New `QuickAddProduce` widget and `ProducePurchaseTracker` with frequency tracking via SharedPreferences. (`lib/widgets/quick_add_produce.dart` new, `lib/services/produce_purchase_tracker.dart` new, `lib/screens/home_screen.dart`, fixes #113)
- **Localized unit display**: "pieces" replaced with singular/plural "unit"/"units" (en) and "unidade"/"unidades" (pt/pt_BR). `formatQuantityUnit` now handles quantity-aware pluralization. (`lib/l10n/app_*.arb`, `lib/l10n/l10n_extensions.dart`, fixes #113)
- **New ARB keys**: `unitSingular`, `unitPlural`, `pluEntryTooltip`, `enterPluCode`, `pluCodeNotFound`, `digitLabel`, `deleteDigit`, `weightModeLabel`, `unitModeLabel`, `servingSmall`, `servingMedium`, `servingLarge` in en. (`lib/l10n/app_en.arb`)
- **Created follow-up issues**: #123 (AI visual recognition for produce), #124 (seasonal produce suggestions)
- **Integration tests for produce flow**: 4 end-to-end tests covering PLU entry → weight mode add, text search → unit mode add, quick-add carousel → undo, and quick-add carousel → confirm. Tests gracefully skip network-dependent steps when OFF API is unreachable. (`integration_test/produce_add_flow_test.dart` new, fixes #113)
- **Price tracking on shopping list**: New `priceAmount`, `priceCurrency`, `priceStore`, `pricePhotoPath` fields on `ShoppingItem`. DB migration v18 adds 4 price columns + `idx_shopping_inventory_id` index. Price entry via `PriceEntrySheet` (reused) with edit/remove flow. Running total in section headers with per-currency subtotals. `PhotoService` for price tag camera/gallery capture/cleanup. (`lib/models/shopping_item.dart`, `lib/database/shopping_list_dao.dart`, `lib/database/database_helper.dart`, `lib/screens/shopping_list_screen.dart`, `lib/widgets/price_entry_sheet.dart`, `lib/services/photo_service.dart` new, fixes #36)
- **Move-to-inventory flow**: "Add to pantry" button in shopping list AppBar batch-moves purchased items (with barcodes) to the active inventory. Transaction-based: caches product, merges/creates inventory item, saves price to `prices` table, deletes shopping item. `InventoryDao.insertOrMergeByBarcode` prevents duplicate inventory entries. Barcodeless items skipped with snackbar. (`lib/database/inventory_dao.dart`, `lib/providers/shopping_list_provider.dart`, `lib/screens/shopping_list_screen.dart`, fixes #38)
- **Per-inventory shopping list**: Shopping list items are now scoped to the active inventory. The `ShoppingListDao`, `DatabaseHelper`, and providers filter by `inventory_id`. `addShoppingItem` automatically assigns the active inventory ID to new items. (`lib/database/shopping_list_dao.dart`, `lib/database/database_helper.dart`, `lib/providers/shopping_list_provider.dart`, fixes #111)
- **Product search in add-to-shopping-list sheet**: The FAB on the shopping list screen now opens a `AddToShoppingListSheet` bottom sheet that searches cached products (local DB + OFF API) by name. Results show product avatar, name, brand, and barcode. Tapping a product adds it to the shopping list with its barcode. A free-text fallback ("Add custom item") is available for items not in any product database. (`lib/widgets/add_to_shopping_list_sheet.dart` new, `lib/screens/shopping_list_screen.dart`, fixes #68)
- **New ARB keys**: `productSearchHint`, `addCustomItem`, `noProductsFound`, `backToSearch`, `addPrice`, `removePrice`, `shoppingTotal`, `shoppingMixedCurrency`, `addToInventoryFromList`, `addToInventoryConfirm`, `itemsMovedToInventory`, `itemsSkippedNoBarcode` in `en`, `pt`, and `pt_BR`. (`lib/l10n/app_en.arb`, `lib/l10n/app_pt.arb`, `lib/l10n/app_pt_BR.arb`)
- **Persistent store autocomplete**: New `stores` table and `StoreDao` store store names persistently. The store field on `PriceEntrySheet` now uses `Autocomplete<String>` with a dropdown of saved stores, a "+ Add new store" button, and automatic store-name insertion on price submit. Existing store values from `prices` and `shopping_list` are seeded at migration v19. (`lib/models/store.dart` new, `lib/database/store_dao.dart` new, `lib/database/database_helper.dart`, `lib/widgets/price_entry_sheet.dart`, `lib/providers/database_provider.dart`, fixes #69)
- **New ARB keys**: `addNewStore`, `storeAdded`, `storeAlreadyExists`, `storeName` in `en`, `pt`, and `pt_BR`. (`lib/l10n/app_en.arb`, `lib/l10n/app_pt.arb`, `lib/l10n/app_pt_BR.arb`)

### Fixed
- **Shopping list items were global instead of per-inventory**: Scoped all shopping list queries to the active inventory via the `inventory_id` column. (fixes #111)
- **Shopping list FAB created free-text items without product association**: Replaced the name+quantity AlertDialog with a product search sheet that links items to barcodes by default, with free-text as an explicit fallback. (fixes #68)
- **Duplicate inventory entries on move-to-inventory**: Added `InventoryDao.insertOrMergeByBarcode` that merges quantities when the same barcode already exists in the target inventory. (fixes #38)

### Changed
- **PriceEntrySheet accepts standalone values**: `barcode` is now optional; accepts `existingAmount`, `existingCurrency`, `existingStore` for use outside the full-price-edit flow (e.g. shopping list). (`lib/widgets/price_entry_sheet.dart`)

## [0.0.5]

### Fixed
- **Translation leak on product detail page**: Debug strings showing instead of translated text near the edit-quantity area. Added `AppLocalizationsX` extension with `formatQuantityUnit`, `localizeUnit`, `localizeLocation`, `displayInventoryName`, and `localizeThemeMode`. Duplicate `productNotFound` key removed from `app_pt_BR.arb`. Hardcoded raw unit/location/theme strings replaced with localized lookups across 10+ files. (`lib/l10n/l10n_extensions.dart` new, `lib/l10n/app_*.arb` updated, fixes #87)

### Fixed
- **Camera scanner error loop**: Controller listener catches errors from the `MobileScannerController` state before the widget's `ValueListenableBuilder` fires, preventing the overlay from flashing over the error message. `errorBuilder` is kept as a safety net with a post-frame callback to avoid mid-build `setState`. Duplicate `ScannerErrorContent` removed from `Stack` children. (`lib/screens/scanner_screen.dart`, fixes #76)
- **Camera scanner `genericError` overwriting `permissionDenied`**: The controller listener's `_setError` guard (`if (_currentException != null) return`) prevents a later error from overwriting the first one, fixing the retry loop. (`lib/screens/scanner_screen.dart`, fixes #76)
- **Missing `context.mounted` guard on `Navigator.pop`**: Added guard before `Navigator.of(context).pop()` in `onDetect` callback to prevent calling pop on a stale context. (`lib/screens/scanner_screen.dart`)
- **Mismatched ARB string in `_openSettings`**: Changed from `couldNotOpenPlayStore` to new `couldNotOpenSettings` key. (`lib/screens/scanner_screen.dart`, `lib/l10n/app_en.arb`, `lib/l10n/app_pt.arb`, `lib/l10n/app_pt_BR.arb`)
- **No user feedback on barcode scan failure**: `HomeScreen._scanBarcode` now shows a snackbar (`productNotFound` or `scanFailed`) instead of silently logging the error. (`lib/screens/home_screen.dart`, fixes #76)

### Added
- **Torch/flashlight toggle**: New `Icons.flash_on`/`Icons.flash_off` button in the scanner AppBar, wired to `MobileScannerController.toggleTorch()`. Hidden when the controller reports `TorchState.unavailable`. (`lib/screens/scanner_screen.dart`, `lib/l10n/app_en.arb`, `lib/l10n/app_pt.arb`, `lib/l10n/app_pt_BR.arb`)
- **Lifecycle-aware scanner overlay**: `_MobileScannerViewState` now mixes in `WidgetsBindingObserver`. The scanning-line animation is paused on `paused`/`inactive`/`hidden`/`detached` and resumed on `resumed`, saving battery. (`lib/screens/scanner_screen.dart`)
- **Tap-to-focus**: Enabled via `tapToFocus: true` on `MobileScanner`, allowing users to tap the preview to focus on a specific area. (`lib/screens/scanner_screen.dart`)
- **Auto-zoom**: Enabled via `autoZoom: true` on `MobileScannerController`, which automatically zooms when the detected barcode is far from the camera (Android only). (`lib/screens/scanner_screen.dart`)
- **Advanced controller API**: Switched from simple `MobileScanner(onDetect:)` usage to a `MobileScannerController` instance, enabling all advanced features (torch, zoom, tap-to-focus, state monitoring). (`lib/screens/scanner_screen.dart`)
- **`couldNotOpenSettings` ARB key**: New localised string for when `openAppSettings()` fails. Added to `en`, `pt`, and `pt_BR`. (`lib/l10n/app_en.arb`, `lib/l10n/app_pt.arb`, `lib/l10n/app_pt_BR.arb`)
- **`scanFailed` and `productNotFound` ARB keys**: New localised strings for barcode scan failure snackbars in `HomeScreen`. (`lib/l10n/app_en.arb`, `lib/l10n/app_pt.arb`, `lib/l10n/app_pt_BR.arb`)

### Changed
- **Notification init race condition**: Moved notification service initialization before `runApp()` using a shared `ProviderContainer` with `UncontrolledProviderScope`. Post-init tasks now run staggered after the first frame. Eliminated orphan `ProviderContainer` instances. (`lib/main.dart`, fixes #34)
- **Connectivity null at startup treated as online**: `connectivityProvider` now yields the initial connectivity state within 3 seconds instead of staying in `AsyncLoading`. Timeout defaults to offline. (`lib/providers/connectivity_provider.dart`, fixes #50)
- **Mixed-currency price aggregation**: `totalInventoryValue` and `averageItemPrice` now convert each price to the user's base currency before summing/averaging, using the existing `CurrencyService`. (`lib/database/price_dao.dart`, `lib/services/price_repository.dart`, `lib/providers/price_provider.dart`, `lib/providers/stats_provider.dart`, fixes #56)
- **addShoppingItem duplicate entries**: New `insertOrMergeByBarcode` method merges quantities when a pending item with the same barcode and unit already exists. Uses a transaction to prevent double-tap race conditions. (`lib/database/shopping_list_dao.dart`, `lib/providers/shopping_list_provider.dart`, fixes #57)
- **Manual product entry overwrites cached API data**: Added `mergeFromManual` extension and updated `cacheProduct` to merge manual entries with existing cached products, preserving API-only fields (Nutri-Score, OFF images). (`lib/models/product.dart`, `lib/services/product_repository.dart`, fixes #60)
- **OFF submission lacks offline retry**: Added `product_submission_queue` table with exponential backoff (2^retry min, max 24h, 5 retries). Queue is flushed at startup and when connectivity is restored. (`lib/database/product_submission_queue_dao.dart`, `lib/database/database_helper.dart`, `lib/services/product_submission_service.dart`, `lib/main.dart`, `lib/screens/pantry_shell.dart`, fixes #61)
- **Crash: late final ImagePicker**: Changed to a regular final field, preventing LateInitializationError on second photo capture. (`lib/screens/add_product_screen.dart`, fixes #43)
- **Data loss: API search result to inventory FK violation**: Now caches the product before inserting the inventory item, and shows a user-facing error on failure. (`lib/screens/search_screen.dart`, fixes #44)
- **Data loss: API search result to shopping list FK violation**: Now caches the product before inserting the shopping item. (`lib/screens/search_screen.dart`, fixes #45)
- **Data loss: Undo on Clear Purchased is a no-op**: Captures deleted items before clearing and restores them on undo. (`lib/screens/shopping_list_screen.dart`, fixes #48)
- **Editing synced price wipes syncStatus and openPricesId**: Preserves all sync metadata when rebuilding the Price object on edit. (`lib/widgets/price_entry_sheet.dart`, fixes #46)
- **NaN and Infinity prices accepted**: Validates parsed.isFinite and adds a sane upper bound (1e9). Comma decimal separator normalised for locale-aware input. (`lib/widgets/price_entry_sheet.dart`, fixes #47 and #52)
- **Search by barcode returns no results**: Detects numeric queries of 8+ digits and performs a barcode lookup via [ProductRepository.getProduct] instead of text search. (`lib/screens/search_screen.dart`, fixes #49)
- **Offline scan bypasses cache**: Now checks the local cache before falling back to manual entry when offline. Added [getProductFromCache] method to [ProductRepository]. (`lib/screens/home_screen.dart`, `lib/services/product_repository.dart`, fixes #51)
- **Search clear button leaves pending debounce timer**: Cancels debounce and grace timers before clearing results. (`lib/screens/search_screen.dart`, fixes #54)
- **Manual barcode entry accepts invalid input**: Added digits-only input formatter and length validation (min 8 digits). New ARB key [invalidBarcode]. (`lib/screens/scanner_screen.dart`, fixes #55)
- **Shopping list quantity.toInt truncation**: Added [_formatQuantity] helper that shows decimals only when needed. (`lib/screens/shopping_list_screen.dart`, fixes #58)
- **Dismissible removes by stale index**: Changed [removeAt(index)] to [removeWhere] by product barcode. (`lib/screens/search_screen.dart`, fixes #59)
- **Hardcoded English validator string**: Replaced with [l10n.invalidPriceAmount] ARB key. (`lib/widgets/price_entry_sheet.dart`, fixes #64)
- **Feedback screenshot format**: Screenshots are now decoded with [img.decodeImage] (auto-detects JPEG/PNG/WebP) instead of [img.decodePng], which silently dropped all camera photos. (`lib/services/github_issue_service.dart`)
- **Feedback screenshot upload**: Screenshots are encoded as WebP (800px max, compact) and uploaded to catbox.moe, producing rendered image URLs in GitHub issues. Falls back to a collapsible base64 block if the upload fails. Replaces the previous [data:] URI approach which GitHub does not render and which exceeded the 65536-char issue body limit. (`lib/services/github_issue_service.dart`)
- **Feedback rate limit timezone**: The daily submission limit now resets at local midnight instead of UTC midnight. (`lib/services/github_issue_service.dart`)
- **Feedback daily limit on first use**: The daily limit of 5 is now enforced even on the first-ever submission (when [feedback_daily_start] is 0). (`lib/services/github_issue_service.dart`)
- **Feedback race condition**: [_recordSubmission] is now awaited instead of [unawaited], preventing the daily count from being stale during a queue flush. (`lib/services/github_issue_service.dart`)
- **Feedback hash collision**: Duplicate detection now uses SHA-256 instead of 32-bit [String.hashCode]. Old hash keys are cleaned up after 24 hours. (`lib/services/github_issue_service.dart`)
- **Feedback HTTP errors**: Differentiated error messages for 401 (invalid token), 403 (permission denied), 422 (validation), 429 (rate limit), and 5xx (unavailable). (`lib/services/github_issue_service.dart`)
- **Feedback device info**: The app version in device info now uses [PackageInfo.fromPlatform] instead of a hardcoded "1.0". (`lib/screens/feedback_screen.dart`)
- **Feedback screenshot file extension**: Saved screenshots use [.webp] extension to match the new encoding. (`lib/services/github_issue_service.dart`)
- **Debug semantics enabled**: [SemanticsBinding.ensureSemantics] is called in debug builds so the Android accessibility tree is materialised for emulator-based UI testing. (`lib/main.dart`)
- **Foreign key enforcement**: `PRAGMA foreign_keys = ON` is now set on every database connection. Deletion operations respect foreign key constraints, preventing orphaned rows in inventory, prices, and shopping_list tables. (`lib/database/database_helper.dart`)
- **Database index**: Added `idx_inventory_date_added` on `inventory(date_added)` to speed up cleanup queries and `getLastAddDate` on large inventories. Migration v14. (`lib/database/database_helper.dart`)
- **Shopping list loading flash**: Added a loading spinner during initial fetch so the empty state does not flash before data arrives. (`lib/screens/shopping_list_screen.dart`)
- **Inventory card text overflow**: Long product names now truncate with ellipsis instead of overflowing the card. (`lib/widgets/inventory_card.dart`)
- **Localised tooltip**: The shopping cart button on inventory cards now has a localised tooltip instead of hardcoded English. ARB key `addToShoppingListTooltip`. (`lib/widgets/inventory_card.dart`, `lib/l10n/app_en.arb`)
- **Scanner manual entry scrollable**: Manual barcode entry TextField is now wrapped in `SingleChildScrollView` to prevent keyboard overlap. (`lib/screens/scanner_screen.dart`)
- **Price entry sheet uses SnackbarHelper**: Replaced raw `ScaffoldMessenger.showSnackBar()` with `SnackbarHelper.showError()` for consistent theming and logging. ARB key `invalidPriceAmount`. (`lib/widgets/price_entry_sheet.dart`, `lib/l10n/app_en.arb`)
- **Loading spinner flash on pull-to-refresh**: Home and Stats screens now show previously cached data during background refreshes instead of a full-screen `CircularProgressIndicator` flash. (`lib/screens/home_screen.dart`, `lib/screens/stats_screen.dart`)
- **Settings persistence errors now logged**: Silent `on Exception catch (_)` blocks in `SettingsNotifier` replaced with `logWarning` calls so corrupted SharedPreferences is detectable. (`lib/providers/settings_provider.dart`)
- **Startup notification scheduling uses persisted settings**: `_rescheduleNotifications`, `_scheduleInactivityReminder`, and `_runDatabaseCleanup` now read settings directly from SharedPreferences instead of creating a fresh ProviderContainer that returns stale defaults. (`lib/main.dart`)
- **Smoke test updated to 5 tabs**: Added the List (shopping list) tab to the smoke test. Updated AGENTS.md tab count references. (`integration_test/smoke_test.dart`, `AGENTS.md`)
- **Golden test updated**: Refreshed `home_screen_360dp.png` to reflect the shopping list button and loading state changes. (`test/screens/goldens/home_screen_360dp.png`)

### Added
- **Manual testing guide**: Comprehensive reference for interactive emulator + ADB testing covering per-feature scenarios, edge cases, offline behavior, database inspection, and troubleshooting. (`agents_docs/manual_testing_guide.md`)
- **AGENTS.md simplified**: Replaced individual doc references with a single `agents_docs/` directory pointer so new docs are discovered automatically. (`AGENTS.md`, `agents_docs/emulator_instructions.md`, `agents_docs/stale_info_checklist.md`)
- **Feature freeze mechanism**: New `FEATURE_FREEZE.md` with a checkbox flag. When checked, no new features may be added — only bug fixes and polish. AGENTS.md Rule 0 requires checking this before starting feature work. CI pre-merge gate prints a warning. (`FEATURE_FREEZE.md`, `AGENTS.md`, `agents_docs/stale_info_checklist.md`, `.github/workflows/ci.yml`)
- **Version CI check**: CI now fails if the `pubspec.yaml` version already has a GitHub release, enforcing version bumps before merges. Prevents stale release tags. (`.github/workflows/ci.yml`)
- **Cleaned up stale tags**: Removed six obsolete git tags (`untagged`, `untagged-*`, `alpha-*`) and one broken draft release from GitHub.
- **Price tracking**: Record purchase prices per product with optional currency conversion (ExchangeRate-API, free no-key endpoint with 24h cache). Prices are optional like expiry date. New `Price` freezed model, `prices` table (v12 migration), `PriceDao`, `PriceRepository`, `CurrencyService`, `OpenPricesService`. All-new UI: price section on product detail screen, price history screen with swipe-to-delete, `PriceMask` widget for privacy masking. Average price badge in the app bar (next to pantry switcher). Price statistics in Stats tab (total value + average item price). Settings: enable/disable, base currency picker, retention days, privacy masking, Open Prices sync (consent-only, proof upload pending receipt capture). Data retention defaults to 0 (keep forever) independent of inventory retention. (`lib/models/price.dart`, `lib/database/price_dao.dart`, `lib/database/database_helper.dart`, `lib/services/currency_service.dart`, `lib/services/price_repository.dart`, `lib/services/open_prices_service.dart`, `lib/providers/settings_provider.dart`, `lib/providers/price_provider.dart`, `lib/providers/price_repository_provider.dart`, `lib/providers/currency_service_provider.dart`, `lib/providers/open_prices_provider.dart`, `lib/screens/settings_screen.dart`, `lib/screens/product_detail_screen.dart`, `lib/screens/price_history_screen.dart`, `lib/screens/stats_screen.dart`, `lib/screens/home_screen.dart`, `lib/widgets/price_mask.dart`, `lib/widgets/price_entry_sheet.dart`, `lib/models/pantry_stats.dart`, `lib/l10n/app_en.arb`)
- **OFF test data**: Fetched 12 full API responses from Open Food Facts for emulator and CI testing. Stored as `agents_docs/off_test_products.json` (full JSON) and `agents_docs/off_test_products.md` (human-readable lookup table). Products cover spreads, sodas, biscuits, oils, juices. (`agents_docs/off_test_products.json`, `agents_docs/off_test_products.md`)
- **Performance guide**: Copied to `agents_docs/performance_guide.md` for easy reference during development. (`agents_docs/performance_guide.md`)
- **AMOLED dark mode**: New `amoledDarkMode` toggle in Settings > Appearance. When enabled with dark mode, surfaces use pure-black (`Colors.black`) instead of the default dark surface colours, reducing power consumption on AMOLED displays. One-time nudge dialog on first launch when device is in light mode. (`lib/providers/settings_provider.dart`, `lib/main.dart`, `lib/screens/settings_screen.dart`, `lib/screens/pantry_shell.dart`, `lib/l10n/app_en.arb`, `lib/l10n/app_pt.arb`)
- **Settings & Theme persistence**: `ThemeModeNotifier` and `SettingsNotifier` now persist to `SharedPreferences` on every change and reload on startup. Fixes reset-on-restart bug. (`lib/providers/theme_provider.dart`, `lib/providers/settings_provider.dart`)
- **Small-screen golden test**: New golden test for `HomeScreen` at 360dp width with 1.0 text scale factor. Overrides 4 providers with mock data covering expired, expiring-soon, good, and no-expiry items. (`test/screens/home_screen_golden_test.dart`, `test/screens/goldens/home_screen_360dp.png`)
- **Inactivity reminder notification**: Sends a daily notification at 9 AM if the user has not added any product for 10+ days (configurable in Settings). Tracks last add date via `MAX(date_added)` from the inventory table. New `inactivity_channel` (Importance.low) separate from expiry channel. Toggle + threshold picker in Settings. Rescheduled on product add and app startup. Permission-denied warning shown once via SnackBar. (`lib/screens/settings_screen.dart`, `lib/services/notification_service.dart`, `lib/providers/settings_provider.dart`, `lib/database/inventory_dao.dart`, `lib/database/database_helper.dart`, `lib/main.dart`, `lib/screens/pantry_shell.dart`,     `lib/screens/product_detail_screen.dart`, `lib/l10n/app_en.arb`,
    `lib/l10n/app_pt.arb`)
- **Play Store CD pipeline**: New CI workflow (`.github/workflows/deploy-to-playstore.yml`)
   builds signed release AAB and APK on `v*.*.*` tags, uploads to Google Play
   Console internal track via `r0adkll/upload-google-play`. Release signing
   configured in `build.gradle.kts` reading from `android/key.properties`
   (with env-var fallback for CI). (`agents_docs/playstore.md`,
   `android/key.properties`, `android/app/build.gradle.kts`, `scripts/inject_env.sh`)
- **Monetization reference docs**: Created `agents_docs/monetization.md`
   covering AdMob, UMP consent, IAP donations, Pro subscriptions, and
   Firebase cloud backup. All features deferred pending legal/accounting
   review. (`agents_docs/monetization.md`)
- **`.gitignore` updated**: Added `android/key.properties` and `*.jks`
   to prevent accidental credential commits.
- **Shopping list**: New 5th tab in NavigationBar with dedicated screen.
   `ShoppingItem` freezed model, `shopping_list` table (v13 migration),
   `ShoppingListDao`. Items can be added as free‑text (FAB dialog) or
   linked to products (from detail screen, inventory card long‑press,
   search results). Checkbox toggles purchased state; swipe‑to‑delete
   with undo snackbar. Batch clear purchased items. Share as plain text
   via share_plus. NFC‑e barcode auto‑marking reserved for future
   receipt scanning. (`lib/models/shopping_item.dart`, 
   `lib/database/shopping_list_dao.dart`, 
   `lib/database/database_helper.dart`, 
   `lib/providers/shopping_list_provider.dart`, 
   `lib/screens/shopping_list_screen.dart`, 
   `lib/screens/pantry_shell.dart`, 
   `lib/screens/product_detail_screen.dart`, 
   `lib/widgets/inventory_card.dart`, 
   `lib/screens/search_screen.dart`, 
   `lib/l10n/app_en.arb`)

### Changed
- **CI/CD workflow**: `build.yml` now triggers on pull requests to main (in addition to push). On PRs, only debug APK is built (skips release builds and publishing). Testing job only runs on push. Patrol E2E placeholder comment added. (`build.yml`)
- **AGENTS.md**: Split into two gates: Pre-commit (local) and Pre-merge (PR + CI + emulator smoke test). Added Development workflow section. Updated performance guide reference to `agents_docs/`. Added OFF test data and emulator instructions to reference docs. (`AGENTS.md`)
- **SearchScreen upgraded to M3 SearchBar**: Replaced the manual `TextField` in `SearchScreen` with Material 3 `SearchBar` widget for native M3 styling and animation. `textInputAction: TextInputAction.search` preserved. HomeScreen autocomplete unchanged (`Autocomplete` still wraps a `TextField` — `SearchAnchor.bar` tested but reverted due to poor test interaction support). (`lib/screens/search_screen.dart`)

### Fixed
- **Settings screen golden test**: Regenerated to account for the new AMOLED toggle switch. (`test/screens/__golden_test.dart`)

### Fixed
- **Feedback form fixes**: Added support for attaching multiple screenshots
  to feedback submissions. Fixed missing Portuguese (pt) translations for
  all feedback-related strings. Replaced misleading "Retry" label on
  screenshot removal with proper "Remove" string. Added `feedbackEnabled`
  config guard to hide the feedback option when disabled.
  (`lib/screens/feedback_screen.dart`, `lib/screens/settings_screen.dart`,
  `lib/services/github_issue_service.dart`, `lib/l10n/app_pt.arb`,
  `lib/l10n/app_localizations_pt.dart`, `lib/l10n/app_localizations.dart`,
  `lib/l10n/app_localizations_en.dart`)
- **Untranslated strings in stats and feedback screens**: Hardcoded English
  strings in the Nutri-Score section title, photo completeness cards, image
  attach error, link open error, and device info labels (`App version`, `OS`)
  are now localized via 6 new ARB keys (`nutriScore`, `photoCoverageRatio`,
  `offPhotosCount`, `couldNotAttachImage`, `appVersionLabel`, `osLabel`).
  Wired up the existing-but-unused `couldNotOpenLink` key.
  (`lib/screens/stats_screen.dart`, `lib/screens/feedback_screen.dart`)

### Changed
- **Inventory switcher redesign**: Replaced plain `PopupMenuButton` icon with
  `InventorySwitcherCard` widget showing the pantry name, average Nutri-Score
  badge, and a dropdown arrow. Tapping opens a modal bottom sheet with the
  inventory list, create, and manage options. Border styling matches the
  search bar for visual consistency.
  (`lib/widgets/inventory_switcher_card.dart`, `lib/screens/home_screen.dart`)
- **SearchScreen accent-insensitive search**: Normalized search queries with
  `removeDiacritics()` for both local DB and API search. Dual-pass API
  strategy: sends normalized query first, falls back to raw query if results
  are empty and the original had diacritics. This makes SearchScreen
  consistent with HomeScreen inline search.
  (`lib/screens/search_screen.dart`)
- **OFF API search retry**: Added retry loop (3 attempts, 1s/2s backoff) to
  `OffAdapter.searchProducts()` for transient 503/server errors. Added 1s
  grace timer in SearchScreen before showing "No results" when API fails and
  local results are empty.
  (`lib/services/off_adapter.dart`, `lib/screens/search_screen.dart`)
- **Notification service rewrite**: Replaced the fragile `hashCode`-based
  notification ID scheme with `itemId * 2` / `itemId * 2 + 1` (guaranteed
  positive, collision‑free). Timezone resolution now uses
  `flutter_timezone.getLocalTimezone()` instead of the
  `DateTime.now().timeZoneName` + `_resolveFromOffset` hack. New features:
  `rescheduleAllItems()` for reboot/app‑update recovery, 9:00 AM time‑of‑day
  scheduling, explicit `AndroidNotificationChannel` creation
  (`ensureNotificationChannel`), notification tap handlers with payload
  deep‑linking, and `requestPermission()` for Android 13+
  `POST_NOTIFICATIONS`. Background tap handler extracted to a separate
  `notification_background_handler.dart` top‑level function. Settings toggle
  now re‑requests permission and shows "Open Settings" dialog on denial.
  (`lib/services/notification_service.dart`,
  `lib/services/notification_background_handler.dart`,
  `lib/screens/settings_screen.dart`)
- **Doc comment style**: Replaced all triple-backtick code blocks in
  hand-written source files with `[square bracket]` cross-references or
  4-space indented blocks. This enables LSP go-to-definition and hover
  documentation on doc-comment references. Rule 14 added to `AGENTS.md`.

### Fixed
- **Screenshot compression in feedback**: `_buildBody()` now calls
  `encodeScreenshotBase64()` instead of raw `base64Encode()`, fixing the
  dead-code regression that caused screenshots to be embedded uncompressed
  and exceed the GitHub API body size limit. Added INTERNET permission to
  `AndroidManifest.xml`. Added rate-limit ARB string.
  (`lib/services/github_issue_service.dart`,
  `android/app/src/main/AndroidManifest.xml`, `lib/l10n/app_en.arb`,
  `lib/l10n/app_pt.arb`)

### Added
- **Translation report issue type**: New `IssueType.translation` enum value
  for reporting incorrect or missing product translations.
  (`lib/screens/feedback_screen.dart`, `lib/l10n/app_en.arb`,
  `lib/l10n/app_pt.arb`)
- **CI permissions fix**: Added `contents: read` to `coverage_report` job in
  `ci.yml` and `publish` job in `build.yml` to fix `actions/checkout` failure
  on private repos. (`.github/workflows/ci.yml`, `.github/workflows/build.yml`)
- **Regression tests for screenshot compression**: Three new tests verify that
  `submitIssue` compresses screenshots (not raw base64), stays under the
  GitHub API body size limit, and omits image data when no screenshots are
   provided. (`test/services/github_issue_service_test.dart`)
- **GitHub Wiki for API docs**: CI workflow (`.github/workflows/wiki.yml`)
   automatically publishes `dart doc` output to the GitHub Wiki on every push
   to `main`. Wiki conventions documented in `agents_docs/wiki.md`.
   (`agents_docs/wiki.md`, `.github/workflows/wiki.yml`)
- **Doc comment quality: AGENTS.md rule 2** now states that doc comments
   feed the public GitHub Wiki, requiring them to be written as proper
   sentences for user-facing documentation.

### Changed
- **Emulator smoke test removed** from AGENTS.md pre-merge gate. Steps
   renumbered. Dev workflow and reference docs updated. (`AGENTS.md`,
   `agents_docs/emulator_instructions.md`)

### Changed
- **Version bumped**: `pubspec.yaml` version changed from `1.0.0+1` to
  `0.0.4+1` to align with the alpha release tag sequence.
- **Branch protection**: Repository made public. GitHub ruleset `protect-main`
  applied: requires PR with 1 approval, passing status checks, and blocks
  deletion/force-push on `main`.

### Added
- **GitHub Actions CI**: PR quality gate (lint, format, test, coverage) on every PR.
- **GitHub Actions build**: APK/AAB debug artifacts on every push to `main`.
- **GitHub Actions release drafter**: Auto-creates draft releases with changelog from PR labels.
- **GitHub Actions PR labeler**: Auto-labels pull requests by title prefix.
- **Scheduled workflows**: Patrol E2E, Flashlight performance, Perfetto trace analysis (weekly, Sunday 03:00-05:00 UTC).
- **Dependabot**: Monthly auto-update of GitHub Action versions.
- **`scripts/inject_env.sh`**: Injects `.env` from GitHub secrets for CI builds.
- **`scripts/quality_gate.sh`**: Composite check running format, analyze, and test.

### Fixed
- **DotEnv not initialized in widget tests**: `pumpApp()` now calls `dotenv.loadFromString(isOptional: true, mergeWith: {})` before rendering the widget tree, preventing `NotInitializedError` from `AppConfig` accesses in tests that transitively read `dotenv.env`.

### Changed
- **Migrated to official `openfoodfacts` Dart SDK**: Replaced the custom 470-line `OpenFoodFactsApi` Dio client with the official `openfoodfacts` package (v3.30.2). The SDK is maintained by Open Food Facts and used by the official smooth-app (1.4k stars, 5k+ commits). A thin `OffAdapter` wrapper preserves Riverpod injectability and testability.
- **Open Food Facts lint rules**: Added `openfoodfacts_flutter_lints` (OFF's own lint package) to the analysis options, replacing `flutter_lints`. Existing `very_good_analysis` and `lint/strict` rules are retained with final precedence.
- **`http` package for image caching**: `ImageCacheService` now uses `package:http` for image downloads instead of the now-removed `dio` dependency.
- **Search screen simplified**: Removed `CancelToken` from search (SDK does not support cancellation). The existing 500ms debounce and `_requestId` stale guard are sufficient.

### Removed
- `lib/services/open_food_facts_api.dart` (~470 lines of hand-rolled Dio client with retry/backoff/jitter)
- `lib/providers/dio_provider.dart` (22 lines)
- `dio` dependency (SDK uses `http` package internally)
- `Product.g.dart` (model no longer parses raw JSON via `json_serializable`)
- `@JsonKey` annotations and `Product.fromJson` factory

### Documentation
- `ARCHITECTURE/UI_STRUCTURE.md`: updated tree diagrams to reflect `ListView.builder` with `RepaintBoundary`, SearchScreen images, StatsScreen placeholder, and Settings changelog button.
- `ARCHITECTURE/PERFORMANCE.md`: updated with actual `cacheWidth`/`cacheHeight` and `RepaintBoundary` implementations.
- `AGENTS.md` code style: added `ComingSoonView` / `ComingSoonScreen` stub pattern.
- `TODO.md` marked Autocomplete, InteractiveViewer, ExpansionTile, Changelog at startup as done.

### Enhancements
- **ComingSoonView / ComingSoonScreen**: Reusable placeholder widgets (`lib/widgets/coming_soon_view.dart`, `lib/screens/coming_soon_screen.dart`). Configurable icon, title, and subtitle. Follows the `ErrorView` / `EmptyPantry` pattern.
- **StatsScreen rewritten with fl_chart**: Summary cards, Nutri-Score distribution (BarChart), category/location breakdown (BarChart), photo completeness cards with OFF comparison, and ComingSoonView stubs for price tracking and NFC-e receipts.
- **SearchScreen product images**: Result tiles now show product thumbnails (`ClipOval` 40×40 `Image.network`) with `cacheWidth`/`cacheHeight` and `CircleAvatar` fallback.
- **Settings "What's New" button**: New "About" section with a button that loads `CHANGELOG.md` and shows the changelog sheet on demand, bypassing the version-guard auto-trigger.

### Bugfixes
- **Missing `cacheWidth` in product detail**: `Image.network` in `ProductDetailScreen` was only constraining decode height. Added `cacheWidth` at screen width × device pixel ratio.
- **Stats summary cards overflow**: `_SummaryCard` and `_PhotoCard` Column widgets added `mainAxisSize: MainAxisSize.min` to prevent RenderFlex overflow.
- **Chart label colors**: Bar chart axis labels now use `colorScheme.onSurface` for dark mode readability.
- **Chart axis labels invisible**: `SideTitles` constructors in fl_chart were missing `showTitles: true` after an earlier lint-cleanup mistakenly removed them (fl_chart defaults to `false`). Added back to all 4 chart label sets (NutriScoreBar, CategoryChart, LocationChart).
- **Search returns fewer results than OFF website**: Added `lc=world` and `cc=world` query parameters to `searchProducts` (matches OFF website behavior). Added `code` field fallback in `_parseProduct` for legacy API barcode responses. Added retry logic (3 attempts, exponential backoff 1s/2s/4s) matching `getByBarcode` pattern.
- **Search API 503 errors without user feedback**: `searchProducts` now retries with cancel support. Search debounce increased to 500ms. Added `CancelToken` to cancel in-flight searches on new query.
- **Changelog not showing on content changes**: Replaced version-string detection with content-hash detection. `_handleAppUpdate` now compares `CHANGELOG.md.hashCode` with stored hash — shows changelog whenever content changes, regardless of version number.
- **Changelog not showing on re-launch**: `_handleAppUpdate` returned early when the app version was unchanged, which prevented the `changelog_show_pending` flag from ever being set. Moved the changelog tracking above the version-match guard so it runs unconditionally.
- **Dead `Contribute Photos` button**: Wired to `ComingSoonScreen` navigation
  instead of a do-nothing `logInfo`.
- **`setState()` crash when invalidating providers during overlay build**:
  All 7 unwrapped `ref.invalidate()` calls wrapped in
  `addPostFrameCallback`. Removed empty `setState(() {})` from
  `_retrySubmission`. Sites fixed: stats_screen (2), manage_inventories (4),
  home_screen (1), product_detail_screen (1).
- **Expiry notification log shows "item null"**: Changed log message from
  `item.id` to `item.barcode` (barcode is always non-null).
- **CI security hardening failure**: Pinned unpinned GitHub Actions in
  `opencode.yml` to full commit SHAs.

### Stats & Analytics
- **StatsScreen rewritten with fl_chart**: Summary cards (total products, total items, added this week/month), Nutri-Score distribution (BarChart), category breakdown (BarChart), location breakdown (BarChart), photo completeness cards with OFF comparison, and ComingSoonView stubs for price tracking and NFC-e receipts.
- **fl_chart dependency added** (<300KB after tree shaking). All chart sections wrapped in `RepaintBoundary` for independent repaint isolation.
- **PantryStats freezed model** with 3 sub-models (`WeeklyCount`, `CategoryCount`, `PhotoStats`).
- **statsProvider** (FutureProvider.autoDispose) — 10 concurrent SQL aggregation queries via `Future.wait`. Refreshes on pantry switch.
- **Product model extended** with 3 OFF image URL fields (`offNutritionImageUrl`, `offIngredientsImageUrl`, `offProductImageUrl`) for photo-completeness comparison.
- **DB migration v8→v9**: 3 new TEXT columns on `products` table.
- **OFF API parser** now reads `image_nutrition_url`, `image_ingredients_url`, `image_front_url` from API responses.
- **8 new DAO aggregation methods**: `ProductDao` (nutriscoreDistribution, categoryDistribution, sourceDistribution, photoCompleteness, offPhotoCompleteness) and `InventoryDao` (locationDistribution, expiryDistribution, weeklyAdditions).
- **10 new ARB keys** added to all 3 locales (price tracking, NFC-e, photo completeness).

### UX & Debugging
- **Changelog dev-section filter**: `whats_new_sheet` now hides `### Documentation` and `### Code health` from the in-app display. Users see only product-facing changes.
- **Connectivity transition logging**: `connectivityProvider` now logs online/offline state changes.
- **Action-level logging**: added `logInfo` before every `unawaited()` fire-and-forget, `logWarning` for guard conditions, `logInfo` for form validation failures.
- **Snackbar consistency**: replaced raw `ScaffoldMessenger.showSnackBar` in delete flow with `SnackbarHelper.showUndo`. Replaced hardcoded English string in `inventory_card` with ARB-localized `productDataUnavailable`.

### Code health
- **AGENTS.md rule 11**: Consider performance and footprint on every plan.
- **AGENTS.md performance audit checklist**: 6-item checklist for new dependencies, screens, DB queries, providers, models, and rebuild scope.
- **TODO.md**: 3 new items (price tracking, NFC-e, photo contribution).
- Removed CSV import/export: deleted `csv_service.dart`, `csv_service_provider.dart`, `filegate_provider.dart`, and all related test files. Removed `getExportData()` / `exportData()` from `DatabaseHelper`, `InventoryDao`, and `ProductRepository`.
- Removed `csv`, `filegate` dependencies from `pubspec.yaml`. `share_plus` was removed temporarily and re-added later for the shopping list feature. Ran `flutter pub upgrade` (picked up `equatable` 2.1.0 transitively).
- Removed 19 unused ARB translation keys from all 3 locales (en, pt, pt_BR). Verified zero stale references with regex before removal.
- Added 2 new ARB keys: `settingsAbout`, `comingSoonDescription` — translated in en, pt, pt_BR.
- 340 tests passing, 0 analyze issues.

### Enhancements
- **Long-press to select**: Inventory cards now respond to long-press by entering multi-select mode with haptic feedback (`HapticFeedback.mediumImpact()`). Long-press is suppressed when checkboxes are already visible.
- **Batch move items between pantries**: New `moveItemsToInventory` method moves selected items to a different pantry via dialog picker. Undo snackbar restores original assignment. "Move" button appears in selection mode app bar when 2+ inventories exist.
- **Swipe between bottom nav tabs**: `PantryShell` replaced `IndexedStack` with `PageView` + `PageController`. Tabs maintain their state (`AutomaticKeepAliveClientMixin`) — preserving search results, scroll position, and form state.
- **Search: swipe-right-to-add**: Search results are now `Dismissible` — swipe right (leading) adds the product to the active pantry. Undo snackbar removes the item.
- **Search: long-press context menu**: `showModalBottomSheet` with "Add to inventory" and "Copy barcode" options.
- **Product detail: swipe-to-delete inventory items**: `_InventoryTile` wrapped in `Dismissible` (trailing) with delete confirmation via existing `_deleteItem` method.
- **Manage inventories: swipe-to-delete**: `Dismissible` with `confirmDismiss` reuses existing `_confirmDelete` dialog. Returns `bool` for proper dismiss control.
- **Stats: pull-to-refresh**: Converted to `ConsumerStatefulWidget` with `_refreshKey`. `RefreshIndicator` wraps `ListView` with `AlwaysScrollableScrollPhysics`. Pulling down re-fetches product and inventory counts.
- **New localised strings**: `copyBarcode`, `barcodeCopied`, `removedFromPantry`.

### Bugfixes
- **`removeDiacritics` producing decimal strings instead of characters**: `StringBuffer.write(int)` was outputting ASCII code-point decimal values (e.g. `77` instead of `M`). Replaced with `writeCharCode` so the function actually strips diacritics as documented.
- **`ProductDao.search()` accent‑insensitive DB queries**: Both the query AND stored product names are now normalised via in‑memory `removeDiacritics` filtering (previously only the query was normalised, leaving accented DB content unmatched).
- **SearchScreen `setState` after dispose**: Added `mounted` checks and request‑ID stale-guard before every `setState` in `_search()`. The `_requestId` counter ensures stale results from a previous query are silently discarded when the user types faster than the 300 ms debounce.
- **SearchScreen API spam**: OFF API calls are now skipped for 1‑character queries (minimum 2 chars). Inflight requests are not cancelled at the HTTP level but their results are ignored when superseded by a newer query.
- **Short barcode crash**: `product.barcode.substring(0, 3)` in the search result `CircleAvatar` now guards against barcodes shorter than 3 characters (pads with `'0'`).
- **OFF taxonomy codes in category filter**: `_displayCategory()` strips the `en:` prefix from OFF taxonomy codes and formats the remainder as human‑readable text (e.g. `en:spreads` → `Spreads`).
- **Double background refresh on startup**: `_scheduleCacheRefresh` in `main.dart` now calls `setLastRefreshTime()` *before* firing background refreshes, so `HomeScreen._refreshIfOverdue` finds a non‑overdue cache and skips.
- **Search field keyboard type**: Added `textInputAction: TextInputAction.search` to the `SearchScreen` TextField.

### Enhancements
- **Autocomplete search with product thumbnails**: Home screen `TextField` replaced with `Autocomplete<InventoryWithProduct>`. Suggestions show a 32×32 `ClipOval` product thumbnail (or barcode `CircleAvatar` fallback), capped at 20 results.
- **Accent-insensitive search**: `removeDiacritics()` normalises Latin diacritics (à→a, é→e, ü→u, ñ→n, ç→c, ß→s, etc.) for both in-memory filtering and SQL queries.
- **Pinch-to-zoom on product photos**: Product detail screen images wrapped in `InteractiveViewer` (0.5×–3× zoom) for both cached and network images.
- **Settings screen grouped by sections**: Flat `ListView` replaced with `ExpansionTile` groups (Appearance, Notifications, Data Management, Maintenance).

### Nutri-Score
- Grey dash badge for non-applicable products (food additives, sweeteners, etc.)
- Tooltip on product detail screen explains why with the OFF category name
- `nutriscore_not_applicable_category` stored in DB, exported in CSV

### Batch delete
- Multi-select checkboxes on inventory cards
- Delete confirmation with undo snackbar
- FAB hidden in selection mode, replaced by app bar delete button

### Quick quantity adjustment
- `+`/`-` buttons on inventory tiles in product detail screen
- Tap the quantity to type a number directly
- Decrementing to 0 triggers delete with undo
- Notifications re-scheduled after every change

### Cache flush on app update
- Version detection via `package_info_plus` and `shared_preferences`
- Clears image cache and product DB on first launch after upgrade
- Manual "Flush cache" button in settings screen

### Tests
- **`string_helpers_test.dart`**: 23 unit tests covering `removeDiacritics` (empty, ASCII, mixed diacritics, Latin Extended-A, non‑Latin pass‑through) and `equalsIgnoreCaseAndDiacritics` (case, accent, mismatch scenarios).

### Accessibility
- `Semantics` labels on NutriScoreBadge: "Nutri-Score A" through "Nutri-Score E", "Nutri-Score, not applicable"
- All badge golden tests also verify semantics labels

### OFF product submission
- Added `submissionStatus` to Product model (`not_submitted` / `pending` / `submitted` / `failed`)
- DB migration v7→v8 adds `submission_status` column; CSV export includes the new column
- New `ProductSubmissionService` coordinates metadata submission + image upload to OFF
- `AddProductScreen._save()` fires and forgets local caching and OFF submission
- `ProductDetailScreen` shows a status chip for manual products (with retry for failures)
- L10n: 7 additional strings for submission states and retry

### Testing and coverage
- Golden tests: NutriScoreBadge (A–E, null, not-applicable), StatsScreen, SettingsScreen
- StatsScreen: 32.8% → 83.6%
- AddProductScreen: 58.8% → 85.3%
- AddToInventoryScreen: 72.4% → 94.0%
- Connectivity provider stream emission tests
- InventoryCard tap navigation + image cache fallback tests
- HomeScreen: stats navigation, create-pantry dialog, batch delete tests
- 266 tests total, 0 analyze issues

### Code health
- Extracted `parseExpiryDate`, `isExpired`, `isExpiringSoon` into `lib/utils/date_helpers.dart`
- Removed dead `product_api_service.dart`
- Deduplicated custom-input and days-dialog builders in `AddToInventoryScreen`
- Singleton `DatabaseHelper` delegates to `const` DAOs
- Resolved lint rule conflict: disabled `prefer_adjacent_string_concatenation`, `no_adjacent_strings_in_list`, and `missing_whitespace_between_adjacent_strings` to eliminate false positives on multi-line string building
- Resolved all info‑level lint diagnostics (`avoid_redundant_argument_values` in database helper test, `omit_local_variable_types` in inventory card test). Updated AGENTS.md rule 5 to explicitly forbid info‑level issues of any severity.
- Performance audits completed (8/8 items): converted main inventory list, autocomplete suggestions, category chips, manage inventories, and changelog sheet to `ListView.builder`; wrapped inventory cards in `RepaintBoundary`; added `cacheWidth`/`cacheHeight` to all 3 `Image.network` calls (40×40 thumbnails, 32×32 autocomplete icons, 200dp product photos); verified Impeller default on API 29+ and Material Icons tree-shaken 99.5%. Single ClipRRect and empty asset folder confirmed benign. Updated AGENTS.md rule 10 requiring pitfall audits on every plan.
- Removed dead `product_api_service.dart`
- Deduplicated custom-input and days-dialog builders in `AddToInventoryScreen`
- Singleton `DatabaseHelper` delegates to `const` DAOs
- Resolved lint rule conflict: disabled `prefer_adjacent_string_concatenation`, `no_adjacent_strings_in_list`, and `missing_whitespace_between_adjacent_strings` to eliminate false positives on multi-line string building

### Localization
- All user-visible strings externalised via ARB (`flutter gen-l10n`)
- Brazilian Portuguese (pt / pt_BR) translation of all 100+ UI strings with informal/colloquial tone. Both base `pt` and country-specific `pt_BR` locale ARB files added.
- English base with Portuguese planned for future release

### Connectivity
- `internet_connection_checker` wrapping Riverpod provider
- Offline-first: cached products shown immediately, background refresh when online

### CSV export/import
- Full round-trip: product data, nutrition, Nutri-Score, inventory metadata
- Handles CRLF, UTF-8 BOM, quoted fields, content:// URIs
- Fixture tests with real Open Food Facts product data

### Multi-inventory
- Named pantries (Home, Work, Camping, …)
- Per-pantry inventory views and stats

### Documentation
- Added roadmap items to TODO.md: cosmetics/toiletries OFF API support, ingredient/nutrition photos in manual entry, upload manual products to OFF API, remake notifications from scratch, remake import/export from scratch

### Performance
- Image caching in local filesystem (`ImageCacheService`)
- Hero animations on product images when navigating between screens

### Roadmap
- Updated TODO.md: marked Phases 1–3 as completed (serving-size tests, photo paths, OFF upload service)
- Added WHO-based food quality recommendations feature item (ADI additive warnings, free-sugar thresholds, sodium awareness, Five Keys to Safer Food)
- Refined cosmetics/toiletries support item with accurate Open Beauty Facts integration details

### Bugfixes — cache flush and pull-to-refresh
- **Critical**: Fixed cache flush making inventory items disappear — changed `INNER JOIN` to `LEFT JOIN` in `listWithProduct()` and `exportData()` so inventory items remain visible even when their product record was deleted. The join now returns rows with `NULL` product fields for orphaned items instead of omitting them entirely.
- **Critical**: Fixed pull-to-refresh silently wiping Nutri-Score and other product data — the `OpenFoodFactsApi` instance in the `RefreshIndicator` callback now uses the provider's configured API (respecting `useStaging`), and fetched data is merged with cached data via `Product.mergeFromApi` so missing API fields never overwrite existing cached values.
- **Critical**: After cache flush, all inventories' products are automatically re-fetched from the API (when online) so full product data is restored without user action.
- Added graceful handling for orphaned inventory items: tapping a card whose product is unavailable (flushed + offline) shows a snackbar instead of silently failing.

### API throttling and reliability
- **Smarter retry loop**: `refreshInventoryProducts` now runs **two passes** — the first attempts every barcode sequentially with 500 ms delay; the second retries only failed barcodes after a 2 s pause. This absorbs transient rate-limiting or server hiccups.
- **Expanded retry coverage**: `getByBarcode` retries not only HTTP 429 but also **5xx server errors** and **timeout/connection errors** with exponential backoff (1s, 2s, 4s). HTTP 404 still fails immediately.
- **Background refresh**: The `refreshInventoryProductsBackground` fire-and-forget wrapper lets the UI trigger a refresh without blocking. Pull-to-refresh is now non-blocking — the UI updates from the DB immediately and the API refresh completes in the background.
- **Pull-to-refresh cooldown**: A 1‑minute gate prevents repeated pulls from hammering the API. During cooldown the provider is still invalidated (so the UI re-reads the DB), but no network calls are made.
- **5‑day automatic refresh**: On app start, if cached products haven't been refreshed in 5+ days, a background refresh is automatically scheduled for every inventory. The last‑refresh timestamp is persisted via `SharedPreferences`.
- **Empty‑string guards in mergeFromApi**: API responses with `""` for optional string fields (e.g. `nutriscore_grade`) are now treated like `null`, preventing incomplete responses from destroying cached data.

### NavigationBar
- Replaced hardcoded stats/settings buttons with a proper `NavigationBar` (Home, Search, Stats, Settings) via `PantryShell`
- Uses `IndexedStack` to preserve screen state across tab switches
- `main.dart` updated to render `PantryShell` instead of `HomeScreen` directly

### Product name search
- New `SearchScreen` tab with debounced `TextField` (300ms)
- Queries local DB first (LIKE on name + barcode), then Open Food Facts API
- Results deduplicated by barcode; API results tagged with `cloud_outlined` icon
- Tapping a result navigates to `ProductDetailScreen`
- States: idle (search icon + hint), loading (spinner), empty (search_off icon), results list
- API errors silently logged (best-effort, never shown to user)

### Stock count badges
- Horizontal badge row on `HomeScreen` above the search field: total items, expiring soon, added this week
- Colour-coded icons (primary, orange, tertiary) for quick visual scanning

### Category filter chips
- `FilterChip` row shown when 2+ unique product categories exist in the current inventory
- "All" chip resets the filter; individual category chips filter items in all sections
- Category data sourced from `InventoryWithProduct.productCategory` (aliased `products.category` in the LEFT JOIN)

### Localization
- 9 new ARB strings: nav labels (Home, Search, Stats, Settings), search screen text, stock count formatting, filter labels (`navHome`, `navSearch`, `navStats`, `navSettings`, `searchTitle`, `searchProductsHint`, `noSearchResults`, `totalItemsCount`, `expiringSoonCount`, `addedThisWeek`, `filterAll`)

### Testing
- Added `mergeFromApi` unit tests in `product_test.dart` (5 test cases: non-null overwrites, null preserves, name sentinel, local-field safety, full-nutrition update)
- Added flush cache integration test suite in `flush_cache_test.dart` (LEFT JOIN regression guard, manual product preservation, export data survive flush, re-fetch restoration)
- Added `SearchScreen` widget tests (9 tests: idle, loading, results local/API/dedup, navigation, empty, clear, debounce)
- Added `HomeScreen` stock count badge and category filter tests (6 tests: badge counts, badge icons, filter chips visibility, category selection, "All" reset)
- 309 tests total, 0 analyze issues

### Code health
- Wrapped product detail photos with `InteractiveViewer` (pinch-to-zoom)
- Grouped settings screen into `ExpansionTile` sections with 3 new ARB strings

---

## [0.1.0] — Initial release (MVP)

### Core
- Barcode scanning via `mobile_scanner`
- Open Food Facts v3 API product lookup
- Offline-first local caching (SQLite via `sqflite`)
- Expiry date tracking with local notifications
- Nutrition table (energy, protein, carbs, fat, fiber, salt per 100 g/ml)
- Ingredients list with collapsible expansion tile

### Product management
- Add products to inventory with quantity, unit, location, expiry date
- Manual product entry form with camera capture when barcode is unknown
- Product submission to Open Food Facts for new barcodes

### UI
- Dark mode support respecting device theme
- Settings screen: theme toggle, notification preferences, CSV export/import
- Snackbar notifications for errors and confirmations
- Haptic feedback on scan

### Database
- Three-table schema: `products`, `inventory`, `inventories`
- DAO pattern for all CRUD operations
- Automatic cleanup of stale entries (configurable retention)

### CSV
- Export current pantry to CSV (all columns)
- Import CSV files to rebuild inventory
- RFC-4180 compliant parser
