# Changelog

## Unreleased

### Added

- **Nutrition editor for all Open Food Facts nutrients**: the manual product
  form (`lib/screens/add_product_screen.dart`) keeps the six core rows
  (energy, protein, carbs, fat, fiber, salt) but adds a per-row unit
  dropdown (g/mg/mcg for macros, kcal/kJ for energy). An "Add nutrient"
  action opens a picker of curated contributor nutrients (vitamins,
  minerals, fats, sugars, percent nutrients) so the user can add and remove
  rows; values are converted to each nutrient's canonical unit before
  storage. The nutrition table
  (`lib/widgets/nutrition_table.dart`) renders these additional nutrients
  below the six core rows with their persisted unit.

- **Additional-nutrient model and persistence**: a new `ProductNutrient`
  freezed model (`lib/models/product_nutrient.dart`) stores an OFF nutrient
  tag, a value, and its app-canonical unit. `Product.additionalNutrients`
  holds the list; `Product.fromOffProduct` imports curated nutrients from
  the API (converting grams to the nutrient's typical unit), and
  `Product.toOffProduct` converts them back to grams for submission. The
  Firebase product cache (`lib/models/product_cache_entry.dart`) round-trips
  the list, and a new v35 migration adds the `additional_nutrients` JSON
  column to the local `products` table.

- **Nutrient catalog and conversion helpers**: `NutrientCatalog`
  (`lib/utils/nutrient_catalog.dart`) curates the supported nutrients, their
  allowed unit sets, and the tag lookup; `NutrientConverter`
  (`lib/utils/nutrient_conversion.dart`) converts between g/mg/mcg and
  kcal/kJ; `OffUnitCatalog.canonicalToSdkUnit` maps app-canonical unit
  spellings back to the SDK enum for submission.

- **Separated local save from OFF submission**: the manual product form
  (`lib/screens/add_product_screen.dart`) now offers two distinct actions.
  "Save to inventory" caches the product locally only and pops the screen.
  "Submit to Open Food Facts" caches locally and submits through the existing
  submission machinery, keeping the inline progress panel and retry button.
  Both actions are always available (the local save is the fallback when a
  submission is rejected, e.g. a duplicate), and a new `submitToOff` flag
  decides which button is visually primary. The search panel's
  "Contribute to Open Food Facts" action now opens this form in submit mode
  instead of showing a Coming Soon dialog
  (`lib/widgets/not_found_flow.dart`, `lib/widgets/search_panel.dart`).

- **Spec-compliant OFF submissions**: `Product.toOffProduct` now maps the six
  nutrition values (per 100 g), the display quantity, and the product language
  code onto the SDK product, so submissions carry the data the OFF upload
  tutorial requires (`lib/models/product.dart`). Image uploads now forward the
  product's language code so the uploaded photo language matches
  (`lib/services/product_submission_service.dart`). The reusable
  `OffQuery.codeToLanguage` helper backs the language fallback
  (`lib/services/off_query.dart`).

- **Detail-screen submission retry and status**: the product detail screen
  for a manual product now shows its persistent submission status
  (submitted, pending, partially completed, failed, or not submitted) in a
  new `ProductSubmissionStatus` widget
  (`lib/widgets/product_submission_status.dart`). While a submission for
  that barcode is in flight it shows the same live progress panel as the
  add form; on a transient failure a "Retry now" button drives the shared
  `ProductSubmissionNotifier`, re-reading the product from the local
  database first so the retried data is fresh, and the screen refreshes
  when the retry finishes. The old detail-screen retry path that called the
  submission service directly was removed.
  (`lib/screens/product_detail_screen.dart`)

- **Photo management on the product detail screen**: manual products now
  expose their three local photos (nutrition table, ingredients, product)
  directly on the detail screen through a new `ProductPhotoManagement`
  widget (`lib/widgets/product_photo_management.dart`). Each slot reuses the
  add-form photo tile and full-screen preview, so photos can be added,
  replaced, or deleted with an undo snackbar. Every change is persisted with
  a raw upsert so a cleared path is truly removed, and the screen deletes
  orphaned photo files on dispose via the new
  `ProductImageService.deleteOrphanedFiles`, keeping the disk clean while
  undo still restores a live file.
  (`lib/services/product_image_service.dart`)

- **Observable, durable submission progress**: `ProductSubmissionService`
  now reports typed `SubmissionProgress` snapshots through an `onProgress`
  callback (`lib/models/submission_progress.dart`), covering checking,
  submitting-metadata, per-photo upload (front, ingredients, nutrition)
  with completed/total counts, and terminal states. A new
  `ProductSubmissionNotifier`/`productSubmissionProvider`
  (`lib/providers/product_submission_provider.dart`) owns the submission
  lifecycle, ignores duplicate in-flight submissions, and keeps running
  after the screen that started it is disposed. `AddProductScreen` now
  stays open while submitting, shows an inline determinate progress bar,
  auto-pops with a success snackbar, and offers an in-form retry button on
  transient failures; the old fire-and-forget `unawaited(_cacheAndSubmit)`
  path was removed.

- **Categorized OFF write results**: `OffAdapter.submitProduct` and
  `uploadProductImage` now return `OffWriteResult` carrying an
  `OffWriteError` category — missing credentials, network, rate-limited,
  or server-rejected — so the submission service can distinguish transient
  failures (queued for retry, `retryAvailable`) from permanent ones. The
  adapter already retries 429 responses with exponential backoff. A new
  `submissionErrorLabel` helper (`lib/utils/submission_error_label.dart`)
  maps each category to a localized message.

- **Partial-success persistence**: when metadata and at least one photo
  succeed but another photo fails, the product's submission status is now
  persisted as `productSubmissionPartiallyCompleted` instead of `failed`,
  matching the chip vocabulary added earlier.

- **Localized submission-flow vocabulary**: new ARB keys in English, European
  Portuguese, and Brazilian Portuguese for the manual submission and photo
  flow — gallery permission explanations, submitting-metadata progress, the
  per-photo upload progress label `uploadingPhotos`, the partially-completed
  submission state, duplicate-product responses, a localized fetch-failure
  message, and a localized N/A fallback. The product detail language-switch
  error now surfaces `l10n.fetchProductFailed` on
  `FetchFailedException`, and the serving-size fallback uses `l10n.notAvailable`.
  (`lib/l10n/app_en.arb`, `lib/l10n/app_pt.arb`, `lib/l10n/app_pt_BR.arb`,
  `lib/screens/product_detail_screen.dart`)

- **Extracted submission status label mapping**: the status-chip label logic
  now lives in `submissionStatusLabel`
  (`lib/utils/submission_status_label.dart`) and is unit-tested for every
  status, including the new `productSubmissionPartiallyCompleted` constant
  (`lib/models/product.dart`). The detail-screen chip renders a partial-state
  variant with a retry action. (`lib/screens/product_detail_screen.dart`)
  The submission service now persists this state for real partial uploads.

- **ARB integrity guard**: new `test/l10n/arb_integrity_test.dart` fails when
  the Portuguese ARB files drift from the English template — missing keys,
  empty values, or missing placeholder metadata — so gen-l10n can never
  silently fall back to English. Fixed the existing pt/pt_BR drift (10 missing
  keys and the missing placeholder metadata blocks).

- **Doc-comment cleanup**: removed backticks from `///` comments in the
  submission-flow services, replacing literal paths with plain text and HTML
  entities where needed. (`lib/services/product_image_service.dart`,
  `lib/services/off_adapter.dart`)

- **Testable product photo persistence and cleanup**: photo storage for the
  manual product form now lives in a dedicated `ProductImageService` behind
  the immutable `ProductPhotoSlots` snapshot. Picked files are copied
  immediately into deterministic managed paths under the app's
  `product_images` directory (`<barcode>_<suffix>.jpg`), replacing a photo
  overwrites the same file, and files are only deleted once they are no
  longer referenced or committed. `AddProductScreen.dispose()` removes
  photos the form never saved, so backing out leaves no orphaned files,
  while undo can still restore a removed photo from its live file.
  (`lib/services/product_image_service.dart`,
  `lib/models/product_photo_slots.dart`,
  `lib/providers/product_image_service_provider.dart`,
  `lib/screens/add_product_screen.dart`)

- **Product photo preview, retake, replace, and delete**: photos added to
  the manual product form now open in a full-screen preview with visible
  Close, Retake, Replace, and Delete actions. Empty photo slots open a
  source chooser with camera and gallery options. Deleting a photo shows an
  undo snackbar that restores it; picking compresses the image so Open Food
  Facts uploads stay small. Camera permission denials surface a dialog with
  an "Open Settings" action.
  (`lib/widgets/product_photo_preview.dart`,
  `lib/widgets/product_photo_tile.dart`,
  `lib/widgets/photo_source_chooser.dart`,
  `lib/services/product_photo_picker.dart`,
  `lib/models/photo_pick_result.dart`,
  `lib/utils/camera_permission_dialog.dart`,
  `lib/screens/add_product_screen.dart`)

- **Per-inventory price tracking**: prices now belong to the inventory
  (pantry) that is active when they are recorded. The Product Detail screen
  shows prices relevant to the current inventory, and a new inline trend
  section displays the last 5 prices as a sparkline with a compact list
  (date, masked price, store) plus a "View all" link to the full history.
  Migration v34 adds `inventory_id` to the `prices` table, backfills existing
  prices to the first inventory, and adds a scoping index.
  (`lib/database/migrations/v34_prices_inventory.dart`,
  `lib/models/price.dart`, `lib/database/price_dao.dart`,
  `lib/providers/price_provider.dart`,
  `lib/screens/product_detail_screen.dart`)
- **Price rows survive inventory deletion**: deleting a pantry does not
  delete its recorded prices — they are barcode observations that stay
  available if the product is re-added to another pantry.
  (`lib/database/inventories_dao.dart`)
- **Inventory-scoped price stats**: value, average, priced-item count, and
  monthly/store spending aggregations now only consider prices recorded for
  the queried inventory.
  (`lib/database/price_dao.dart`)
- **Per-inventory recipes**: recipes now belong to the inventory (pantry)
  that is active when they are created. The Recipes screen shows only the
  active inventory's recipes and includes the same inventory switcher used
  on the Home screen, so you can switch pantries directly from Recipes.
  Migration v33 adds `inventory_id` to the `recipes` table, backfills
  existing recipes to the first inventory, and adds a scoping index.
  (`lib/database/migrations/v33_recipes_inventory.dart`,
  `lib/models/recipe.dart`, `lib/database/recipe_dao.dart`,
  `lib/providers/recipe_provider.dart`,
  `lib/screens/recipe_list_screen.dart`)
- **Cascade delete**: deleting an inventory now also deletes its recipes,
  their ingredients, and their cook history.
  (`lib/database/inventories_dao.dart`)
- **Cooking uses the recipe's own inventory**: `cookRecipe` now deducts
  ingredient stock from the recipe's own inventory (falling back to the
  active one), so shortage checks and FEFO deduction stay consistent with
  per-inventory recipes.
  (`lib/providers/recipe_provider.dart`)
- **Inventory-scoped shared recipe cache keys**: the Firebase recipe cache
  key now includes the inventory id, so same-named recipes in different
  pantries no longer overwrite each other.
  (`lib/models/recipe_cache_entry.dart`,
  `lib/providers/recipe_provider.dart`)

- **Predictable OFF submission retries and partial success**: manual product
  submissions now block fresh entries whose barcode already exists on Open
  Food Facts with a dedicated duplicate failure category (`#270`). The
  metadata-save adapter distinguishes validation rejections (HTTP 400 or a
  verbose error message) from generic server rejections. Image uploads are
  bounded by a 60-second per-upload timeout, already-uploaded images are
  detected (a "status not ok" response carrying an `imgid`, and a retry-time
  server-image check that skips re-uploading them), and photos are
  recompressed to under 1 MB before upload via the new
  `ProductImageCompressor` (`lib/services/product_image_compressor.dart`).
  The submission queue now runs on an injectable clock so backoff scheduling
  is deterministic and testable, and `OffAdapter`/`ProductSubmissionService`
  logs redact the OFF password so credentials never reach the logs.
  (`lib/services/off_adapter.dart`,
  `lib/services/product_submission_service.dart`,
  `lib/database/product_submission_queue_dao.dart`,
  `lib/models/submission_progress.dart`,
  `lib/utils/submission_error_label.dart`,
  `lib/utils/redaction.dart`,
  `lib/l10n/app_en.arb`)

### Removed

- **Home-screen "Recent scans" carousel**: the horizontal strip of recent
  scans with one-tap quick-add was removed from the home screen to reduce
  UI clutter. Scan history is still recorded locally on every successful
  scan, and products remain reachable through search, the pantry, and the
  scanner. The `RecentScansSection` widget, the `quickAdd` scan-history
  path, and the `recentScans` / `quickAdd` / `quickAddAdded` /
  `quickAddFailed` l10n keys were deleted.
  (`lib/screens/home_screen.dart`, `lib/providers/scan_history_provider.dart`)

### Changed

- **Unit selector for manual products and mg/mcg unit support (issue #294)**:
  the manual product form's serving size is now a structured amount field
  with a unit dropdown offering the OFF quantity units (g, mg, mcg, ml, L)
  derived from the SDK `Unit` enum, instead of a free-text field
  (`lib/screens/add_product_screen.dart`). The unit lists now come from a
  single `OffUnitCatalog` (`lib/utils/off_units.dart`) shared by the unit
  resolver and the unit converter, and the inventory presets gained mg and
  mcg. The quantity parser now normalizes mg/mcg (including the microgram
  symbol) so OFF products such as "500 mg" pre-fill correctly, and the unit
  converter converts mg/mcg to grams for recipe deduction and display.
  (`lib/utils/off_units.dart`, `lib/utils/unit_resolver.dart`,
  `lib/utils/unit_conversion.dart`, `lib/utils/quantity_parser.dart`,
  `lib/screens/add_to_inventory_screen.dart`, `lib/screens/add_product_screen.dart`)

- **Lint-suppression cleanup**: removed all `// ignore` and
  `// ignore_for_file` comments from hand-written code. The `QuantityParser`
  utility class was dissolved into top-level functions (`parseQuantity`,
  `parseUsdaQuantity`, `parseServingQuantity`, `normalizeUnit`),
  `ParsedQuantity` is now annotated `@immutable`, and the Riverpod `.family`
  providers in `price_provider.dart` and `recipe_provider.dart` declare their
  `FutureProviderFamily` types explicitly. `dart analyze lib/ test/` reports
  zero issues.
  (`lib/utils/quantity_parser.dart`, `lib/providers/price_provider.dart`,
  `lib/providers/recipe_provider.dart`)

- **Camera and gallery permission handling for product photos**: the photo
  picker now distinguishes a permanent camera denial from a one-time denial.
  A permanent denial shows the localized dialog with an Open Settings action;
  a one-time denial shows a recoverable warning so the user can try again.
  Gallery picks request a photo-library permission only when the platform
  requires one (the default system pickers need none), and a denied or
  blocked gallery surfaces a localized dialog with Cancel and Open Settings.
  (`lib/models/photo_permission.dart`, `lib/models/photo_pick_result.dart`,
  `lib/services/product_photo_picker.dart`,
  `lib/utils/gallery_permission_dialog.dart`,
  `lib/screens/add_product_screen.dart`)

### Fixed

- **Product photos open the rear camera (issue #297)**: taking a photo for a
  product (nutrition table, ingredients, or front image) now opens an in-app
  camera preview that deterministically selects the back lens via
  `availableCameras()`, instead of delegating to the system camera app which
  restored its last-used (often front) lens. The `camera` plugin powers the
  preview on Android, iOS, and web; on desktop the flow falls back to
  image_picker with a rear-camera hint. Captured photos are re-encoded to
  1600 x 1600 px at quality 85 so stored files and OFF uploads stay small, and
  a new `PhotoCameraUnavailable` result surfaces a localized message when no
  camera can be opened.
  (`lib/screens/camera_capture_screen.dart`,
  `lib/services/camera_service.dart`,
  `lib/services/camera_image_processor.dart`,
  `lib/models/camera_capture_result.dart`,
  `lib/models/photo_pick_result.dart`,
  `lib/services/product_photo_picker.dart`,
  `lib/utils/navigator_key.dart`)

- **Distinguish rejected OFF credentials from other submission failures
  (issue #293)**: when Open Food Facts responds with "Incorrect user name or
  password" (HTTP 400), the write path now classifies it as a distinct
  `OffWriteError.wrongCredentials` instead of a generic validation failure.
  `OffAdapter.submitProduct` and `uploadProductImage` detect the message in
  the status body, verbose message, error field, or a thrown SDK exception,
  and `ProductSubmissionService` surfaces it through a new
  `SubmissionErrorCategory.wrongCredentials` with a clear, non-retryable
  localized message. A new best-effort `OffAdapter.validateCredentials`
  pre-flight (via `OpenFoodAPIClient.login2`) aborts a submission fast only
  when the server definitively rejects the credentials; an inconclusive
  network check never blocks a legitimate submission. Wrong-credential
  failures are never queued for background retry.
  (`lib/services/off_adapter.dart`, `lib/services/product_submission_service.dart`,
  `lib/models/submission_progress.dart`, `lib/utils/submission_error_label.dart`,
  `lib/l10n/app_en.arb`)

- **Scanner redirects unknown barcodes to the contribution form**: when a
  scanned (or manually entered) barcode is not found, `ScannerScreen` now
  opens `AddProductScreen` in submit mode (`submitToOff: true`) instead of
  only showing a warning snackbar, matching the search panel's
  "Contribute to Open Food Facts" flow. `ScanFailed` now carries the barcode
  so the screen can act on it
  (`lib/providers/scanner_providers.dart`,
  `lib/screens/scanner_screen.dart`). The unused `productNotFound`
  localization key was removed from all locales.

- **Final verification for the OFF submission flow (issue #157)**: ran all
  repository quality gates (`dart analyze`, `dart format`,
  `build_runner`, `gen-l10n`, full test suite, debug APK build, `dart doc`)
  and fixed the only two issues they surfaced. Regenerated
  `lib/models/product.freezed.dart` so the generated output documents the
  `productSubmissionPartiallyCompleted` status, and reformatted one
  misindented block in `lib/screens/settings_screen.dart`.

- **Recipe cost scoped to the recipe's own inventory**: `calculateRecipeCost`
  and the cost computation in `cookRecipe` now price ingredients using prices
  recorded in the recipe's own inventory (falling back to the active one when
  the recipe has no inventory), instead of the latest price across all
  pantries. A recipe therefore never costs using prices recorded in a
  different pantry. Refactored into a shared `calculateIngredientCost`
  helper.
  (`lib/providers/recipe_provider.dart`)

## [0.0.9+5] — 2026-08-03

### Added

- **Barcode history**: every successful barcode or PLU scan is now recorded
  in a new `scan_history` table (migration v32), capped at the latest 50
  entries. The home screen shows a "Recent scans" strip with a one-tap
  quick-add that inserts the product directly into the active inventory,
  falling back to a manual snapshot when offline.
  (`lib/database/scan_history_dao.dart`,
  `lib/database/migrations/v32_scan_history.dart`,
  `lib/providers/scan_history_provider.dart`,
  `lib/providers/scanner_providers.dart`,
  `lib/widgets/recent_scans_section.dart`, `lib/screens/home_screen.dart`)
- **Serving-size auto-fill for recipe ingredients**: when adding a product as
  an ingredient in a recipe form, the quantity and unit are now pre-filled from
  the product's serving size. Uses `offProduct.servingQuantity` when available
  (OFF products) or `usdaGramWeight` (USDA produce), falling back to parsing
  the `servingSize` string. A new `parseServing()` method on `QuantityParser`
  handles the logic.
  (`lib/utils/quantity_parser.dart`, `lib/screens/recipe_form_screen.dart`)
- **`servingQuantity` field on Product**: new `double? servingQuantity` field
  mapped from the OFF SDK's `off.Product.servingQuantity`. Stored in the
  database (migration v31) and serialised in the Firebase cache.
  (`lib/models/product.dart`, `lib/database/product_dao.dart`,
  `lib/database/migrations/v31_serving_quantity.dart`)
- **Quantity auto-fill from OFF**: when adding a product to inventory, the
  quantity and unit are now pre-filled from the product's OFF data. A new
  `QuantityParser` utility handles multi-pack strings ("3 x 150 g") by using
  the per-unit value, and normalizes units (cl -> ml, etc.).
  (`lib/utils/quantity_parser.dart`, `lib/screens/add_to_inventory_screen.dart`)
- **Serving weight auto-fill for fresh produce from USDA**: when adding fresh
  produce to inventory, the quantity is now pre-filled with the USDA serving
  gram weight (e.g. 182 g for an apple). A new `parseUsda()` method on
  `QuantityParser` and `enrichProductWithServingData()` on `UsdaApiClient`
  fetch `foodPortions` from the USDA detail endpoint.
  (`lib/services/usda_api_client.dart`,
  `lib/services/product_repository.dart`)

### Removed

- **Produce quick-add carousel**: removed the horizontal row of produce chips
  (Apple, Banana, Tomato, etc.) below the search bar on the home screen,
  along with the associated `QuickAddProduce` widget,
  `QuickAddProvider`, and `ProducePurchaseTracker` service. The carousel
  was used for one-tap produce adding but is no longer needed now that
  search works well. (`lib/widgets/quick_add_produce.dart`,
  `lib/providers/quick_add_provider.dart`,
  `lib/services/produce_purchase_tracker.dart`,
  `lib/screens/home_screen.dart`)
- **SearchFilterNotifier provider**: `searchFilterProvider` — a
  `NotifierProvider<SearchFilterNotifier, SearchFilter>` that exposes the
  current [SearchFilter] via a shared Riverpod provider, with
  `addListener`/`removeListener` for external callers.
  (`lib/providers/search_filter_provider.dart`)
- **SearchPanel widget**: reusable search UI extracted into
  `lib/widgets/search_panel.dart`. Supports standalone usage (via
  `SearchScreen` route), inline mode (embedded in `HomeScreen` with
  `onProductSelected` callback), and picker mode (`selectMode` pops with the
  selected product). (`lib/widgets/search_panel.dart`)
- **SearchPanel picker support**: new `selectMode`, `autoFocus`,
  `showBackButton`, and `onBack` parameters for flexible embedding.
  (`lib/widgets/search_panel.dart`)
- **ProductPickerScreen**: full-screen product picker wrapping `SearchPanel`
  in select mode, used by the recipe form for ingredient selection.
  (`lib/screens/product_picker_screen.dart`)
- **SearchFilter.inPantry**: filters search results to show only products
  already in the active inventory. (`lib/screens/search_screen.dart`)
- **UsdaApiClient provider**: `usdaApiClientProvider` for injectable USDA
  searches. (`lib/providers/usda_provider.dart`)
- **NotFoundFlow widget**: progressive-disclosure flow shown when OFF search
  returns no results. Guides users through barcode scanning, manual barcode
  entry, and offers to contribute to OFF (stub) or save locally.
  (`lib/widgets/not_found_flow.dart`, `lib/widgets/not_found_flow_test.dart`)

### Changed

- **SearchPanel split into three widgets**: the 928-line `SearchPanel`
  monolith was refactored into a Riverpod `SearchPanelController` with an
  immutable `SearchPanelState` and three extracted widgets:
  `SearchQueryBar` (search input with clear button and autofocus),
  `SearchSourceSelector` (source dropdown), and `SearchResultsList`
  (swipe-to-add list rows). `SearchPanel` remains a thin composition root;
  there is no user-visible change.
  (`lib/widgets/search_panel.dart`, `lib/widgets/search_query_bar.dart`,
  `lib/widgets/search_source_selector.dart`,
  `lib/widgets/search_results_list.dart`,
  `lib/providers/search_panel_controller.dart`,
  `lib/models/search_result.dart`)


- **inPantry search cross-reference**: search results from OFF and USDA are
  now batch-checked against the active inventory. Results already in the
  pantry show a kitchen icon indicator, and a "In Pantry" `FilterChip`
  toggles the list to show only those results. Swipe-to-add background
  turns blue (instead of green) for items already in the pantry.
  (`lib/widgets/search_panel.dart`, `lib/database/database_helper.dart`)
- **Category filter removed**: the `SearchFilter` dropdown (All, Produce,
  Barcoded, In Pantry) was redundant with the source selector and has been
  removed. The source dropdown (Packaged Products, Fresh Produce, My Pantry)
  already determines the product category. The `searchFilterProvider` and
  `SearchFilter` enum have been deleted.
  (`lib/widgets/search_panel.dart`)


- **Source filter labels**: renamed from API names to user-friendly labels
  — "Open Food Facts" → "Packaged Products", "USDA" → "Fresh Produce".
  (`lib/l10n/*.arb`)
- **Source filter**: replaced oversized `SegmentedButton` with a compact
  `DropdownButton` — no horizontal scrolling needed.
  (`lib/widgets/search_panel.dart`)
- **Home screen inline search**: home search bar is now functional — tapping
  activates inline search mode, replacing home content with `SearchPanel`.
  Tapping a result restores the normal view before navigating to
  `ProductDetailScreen`. Back button / hardware back exits search mode.
  (`lib/screens/home_screen.dart`)
- **Home screen AppBar**: no longer changes when search mode activates
  (back arrow moved into the search bar leading instead).
  (`lib/screens/home_screen.dart`)
- **Recipe ingredient search**: now uses `ProductPickerScreen` (backed by
  `SearchPanel` with full source and category filters) instead of the
  standalone `SearchIngredientSheet` bottom sheet.
  (`lib/screens/recipe_form_screen.dart`)
- **SearchScreen**: simplified to a thin wrapper around `SearchPanel`
  (still used from onboarding and FAB entry points).
  (`lib/screens/search_screen.dart`)
- **Search empty state for OFF source**: now shows `NotFoundFlow` widget
  with barcode scanning/entry options instead of a generic empty state.
  (`lib/widgets/search_panel.dart`, `lib/widgets/not_found_flow.dart`)
- **searchSourceLabel ARB**: removed trailing colon from value (code already
  appends `': '`), fixing double-colon rendering.
  (`lib/l10n/app_en.arb`, `app_pt.arb`, `app_pt_BR.arb`)
- **Portuguese ARB translations**: filled in missing translations for
  `searchSourceLabel`, `searchSourceInventory`, and added translations for
  renamed source labels. (`lib/l10n/app_pt.arb`, `app_pt_BR.arb`)
- **Shell navigation**: Recipes tab replaces Search in the bottom navigation bar
  (new `navRecipes` ARB key). Search is now accessed from the home screen search
  bar. (`lib/screens/pantry_shell.dart`, `lib/l10n/*.arb`)
- **HomeScreenController**: removed `searchQuery` state and `setSearchQuery` /
  `filterItems` methods (no longer used). (`lib/providers/home_screen_controller.dart`)
- **RecipeListScreen**: added `AutomaticKeepAliveClientMixin` to preserve scroll
  state when switching tabs. (`lib/screens/recipe_list_screen.dart`)
- **SearchFilter enum**: moved to `lib/models/search_filter.dart` for shared
  access. (`lib/models/search_filter.dart`)

### Removed

- **SearchIngredientSheet**: replaced by `ProductPickerScreen` backed by
  `SearchPanel`. (`lib/widgets/search_ingredient_sheet.dart`)
- **search_filter_provider**: removed `SearchFilterNotifier` and
  `SearchSourceNotifier` — `SearchPanel` manages filter/source state locally.
  (`lib/providers/search_filter_provider.dart`)

### Changed

- **Progress indicators**: all 22 `CircularProgressIndicator` and
  `LinearProgressIndicator` instances across 15 files now use
  `ProgressIndicatorHelper.build()` for consistent defaults and
  centralized theming. No visual or behavioural changes.
  (`lib/utils/progress_indicator_helper.dart`)
- **Removed functional debt**: deleted the superseded
  `ProduceSearchService` and `ScanResult`/`BarcodeResult`/`PluResult`
  (replaced by `ScanResolution` in `scanner_providers.dart`), the unused
  `openPricesServiceProvider`, and the unused photo capture/gallery/delete
  methods on `PhotoService`. Fresh-install database schema now matches the
  migration chain: `_onCreate` creates the v29 unique inventory index and
  the v30 recipe `search_text` column and indexes, and the prices table is
  built through `PriceDao.createTable` (shared with migration v12).
  (`lib/services/produce_search_service.dart`,
  `lib/services/scan_result.dart`, `lib/providers/open_prices_provider.dart`,
  `lib/services/photo_service.dart`, `lib/database/database_helper.dart`,
  `lib/database/price_dao.dart`,
  `lib/database/migrations/v12_prices_table.dart`,
  `lib/database/recipe_dao.dart`,
  `test/database/oncreate_schema_parity_test.dart`)

### Fixed

- **Debug APK build on PRs**: the `build` job in `build.yml` previously
  depended on the `testing` job, which only runs on pushes, so the APK/AAB
  builds were silently skipped for every pull request. The build job now runs
  independently for both pushes and PRs (PR tests are gated by `ci.yml`).
  Artifact uploads are also gated so release and app-bundle combos, which only
  build on pushes, no longer fail their upload steps on pull requests.
  (`.github/workflows/build.yml`)
- **Market trip coming-soon message**: the home screen action sheet now shows
  the "Coming soon" message through the shared `SnackbarHelper` (styled,
  floating snackbar) instead of a raw `ScaffoldMessenger.showSnackBar`,
  aligning with the AGENTS.md feedback rule. (`lib/screens/home_screen.dart`)
- **Pull-to-refresh deduplication**: the `RefreshIndicator.onRefresh` callback
  on the home screen now delegates to `Pantry.refresh()` instead of
  duplicating the repository refresh and deferred invalidation logic.
  (`lib/screens/home_screen.dart`, `lib/providers/pantry_provider.dart`)
- **Search panel cleanup**: removed a duplicated `@override` annotation in
  `SearchPanel` and added widget-test coverage for the clear button, the
  in-pantry filter chip, source-switch re-search, and empty-query reset.
  (`lib/widgets/search_panel.dart`)

- **Produce carousel error message**: changed "Could not create inventory." to
  "Could not load product details." since the new flow resolves and navigates
  instead of directly creating inventory. (`lib/l10n/app_en.arb`)
- **Produce carousel invalidation chain**: now also invalidates
  `quickAddItemsProvider` after returning from `ProductDetailScreen`, ensuring
  the carousel reflects updated purchase counts.
  (`lib/screens/home_screen.dart`)
- **AddToInventoryScreen serving weight lookup**: replaced hardcoded `'Apple'`
  with the actual produce name from the product or barcode, so non-Apple items
  (Banana, Tomato, etc.) get correct serving weights in unit mode.
  (`lib/screens/add_to_inventory_screen.dart`)

### Added

- **Produce carousel test coverage**: barcode assertion verifies the correct
  product is passed to `ProductDetailScreen`; pop-back round-trip verifies the
  home screen survives navigation return without errors.
  (`test/screens/home_screen_test.dart`)
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

- **Recipe registration**: new `recipes` and `recipe_ingredients` tables
  (migration v25). Freezed models with DAOs, providers, and cost calculation
  using the user's base currency setting. RecipeFormScreen for create/edit,
  RecipeListScreen for browsing with swipe-to-delete. Auto-populate
  ingredients from current inventory. Average recipe cost banner.
  (`lib/models/recipe.dart`, `lib/models/recipe_ingredient.dart`,
  `lib/database/recipe_dao.dart`, `lib/database/recipe_ingredient_dao.dart`,
  `lib/providers/recipe_provider.dart`, `lib/screens/recipe_form_screen.dart`,
  `lib/screens/recipe_list_screen.dart`, fixes #156)

### Fixed

- **OFF write success and rate-limit handling**: `OffAdapter.submitProduct`
  and `uploadProductImage` now treat the image endpoint's string form
  `status ok` as success (previously only the integer `1` matched, so image
  uploads could report failure after a successful upload). Writes now also
  detect HTTP 429 rate limits in the returned `off.Status` and retry with a
  5x backoff instead of failing immediately. New `isStatusOk` and
  `isRateLimitStatus` helpers cover both forms, and the OFF submission
  contract is documented in
  `docs/superpowers/agents/off_submission_contract.md`.
  (`lib/services/off_adapter.dart`, `test/services/off_adapter_test.dart`)
- **Zero-warning static analysis**: fixed all remaining info-level lint
  issues across `lib/` and `test/`. Migrated deprecated `RadioListTile`
  `groupValue`/`onChanged` usage to the `RadioGroup` ancestor API, added
  missing enum doc comments, sorted imports, and removed redundant default
  arguments. `dart analyze lib/ test/` now reports no issues.
  (`lib/screens/settings_screen.dart`,
  `lib/providers/settings_provider.dart`, `lib/utils/unit_resolver.dart`,
  `test/screens/settings_screen_test.dart`, and others)

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

- **Agent docs for bottom sheet safe area pattern**: `docs/superpowers/agents/bottom_sheet_safe_area.md` documents the fix pattern, why `SafeArea` is not used, and how to write new bottom sheets correctly. (`docs/superpowers/agents/bottom_sheet_safe_area.md` new)

## [0.0.6]

### Added

- **Expiry notifications now show product name**: Changed notification builder functions from barcode to product name. `NotificationService.scheduleExpiryReminders` accepts an optional `productName` parameter; falls back to barcode when name is unavailable. `rescheduleAllItems` accepts a `barcodeToName` map for batch name lookup on startup. Updated all 4 call sites in `product_detail_screen.dart` to pass the product name from the detail page. (`lib/services/notification_service.dart`, `lib/main.dart`, `lib/screens/product_detail_screen.dart`, `lib/l10n/app_*.arb`, fixes #125)
- **"From your pantry" suggestions in shopping list**: The add-to-shopping-list sheet now shows distinct products from the active inventory as quick-pick suggestions when the search field is empty. Tapping an inventory item links it by barcode. New `InventoryDao.distinctProductsFromInventory` method and `inventoryProductsProvider`. (`lib/database/inventory_dao.dart`, `lib/database/database_helper.dart`, `lib/providers/shopping_list_provider.dart`, `lib/widgets/add_to_shopping_list_sheet.dart`, `lib/l10n/app_*.arb`, fixes #68)
- **New stats charts: monthly spending, spending by store, Nutri-Score by store**: Added `MonthlySpending`, `StoreSpending`, and `StoreNutriscore` freezed models to `PantryStats`. New `PriceDao` aggregation methods (`monthlyExpenditure`, `storeSpending`, `nutriscoreByStore`) with CTE-based queries scoped to inventory items. New chart sections on Stats screen: line chart for monthly trends, bar chart for per-store spending, progress bars for Nutri-Score by store. (`lib/models/pantry_stats.dart`, `lib/database/price_dao.dart`, `lib/providers/stats_provider.dart`, `lib/screens/stats_screen.dart`, `lib/l10n/app_*.arb`, fixes #33)
- **New ARB keys**: `fromYourPantry`, `inYourPantry`, `monthlySpendingTitle`, `storeSpendingTitle`, `nutriscoreByStoreTitle`, `noStoreData`, `noSpendingData`, `monthLabel`, `averageScore` in en, pt, and pt*BR. (`lib/l10n/app*\*.arb`)
- **Renamed ARB placeholders**: `expiresTomorrow` and `expiresToday` now use `{name}` instead of `{barcode}` for clarity when product names are displayed. (`lib/l10n/app_*.arb`, fixes #125)
- **Barcode-less product support (produce)**: PLU (Price Look-Up) code entry on the scanner screen via a numeric keypad. PLU codes like 4011 (Banana) are resolved locally to produce names, then nutritional data is fetched from Open Food Facts. A new `ProductType` enum (`barcoded`, `produce`, `custom`) and `pluCode` field on `Product` distinguish produce from barcoded products. DB migration v21 adds `plu_code` and `product_type` columns. New `PluService` with ~70 common produce PLU codes. New `UsdaApiClient` for USDA FoodData Central API fallback. New `ProduceSearchService` coordinates OFF API → USDA → manual entry with PLU enrichment. Scanner now returns `ScanResult` (sealed class: `BarcodeResult` or `PluResult`) instead of raw string. (`lib/models/product_type.dart` new, `lib/models/product.dart`, `lib/database/database_helper.dart`, `lib/database/product_dao.dart`, `lib/services/plu_service.dart` new, `lib/services/usda_api_client.dart` new, `lib/services/produce_search_service.dart` new, `lib/services/scan_result.dart` new, `lib/screens/scanner_screen.dart`, `lib/screens/home_screen.dart`, `lib/config.dart`, fixes #113)
- **Weight/unit toggle for produce**: `AddToInventoryScreen` now shows a weight/unit `SegmentedButton` for products with `productType: ProductType.produce`. Weight mode stores quantity in grams (`unit: 'g'`). Unit mode stores serving count and label (e.g., `unit: 'medium apple'`) with `servingWeightG` for nutrition calculations. New `ProduceServingPresets` maps ~35 produce names to Small/Medium/Large sizes. DB migration v22 adds `serving_weight_g` column on `inventory`. (`lib/services/produce_serving_presets.dart` new, `lib/models/inventory_item.dart`, `lib/database/database_helper.dart`, `lib/database/inventory_dao.dart`, `lib/screens/add_to_inventory_screen.dart`, fixes #113)
- **Quick-add produce carousel**: Horizontal carousel of 8 common produce items on the HomeScreen. Tapping adds a default serving to inventory with undo snackbar. New `QuickAddProduce` widget and `ProducePurchaseTracker` with frequency tracking via SharedPreferences. (`lib/widgets/quick_add_produce.dart` new, `lib/services/produce_purchase_tracker.dart` new, `lib/screens/home_screen.dart`, fixes #113)
- **Localized unit display**: "pieces" replaced with singular/plural "unit"/"units" (en) and "unidade"/"unidades" (pt/pt*BR). `formatQuantityUnit` now handles quantity-aware pluralization. (`lib/l10n/app*\*.arb`, `lib/l10n/l10n_extensions.dart`, fixes #113)
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

- **AGENTS.md simplified**: Replaced individual doc references with a single `docs/superpowers/agents/` directory pointer so new docs are discovered automatically. (`AGENTS.md`, `docs/superpowers/agents/stale_info_checklist.md`)
- **Feature freeze mechanism**: New `FEATURE_FREEZE.md` with a checkbox flag. When checked, no new features may be added — only bug fixes and polish. AGENTS.md Rule 0 requires checking this before starting feature work. CI pre-merge gate prints a warning. (`FEATURE_FREEZE.md`, `AGENTS.md`, `docs/superpowers/agents/stale_info_checklist.md`, `.github/workflows/ci.yml`)
- **Version CI check**: CI now fails if the `pubspec.yaml` version already has a GitHub release, enforcing version bumps before merges. Prevents stale release tags. (`.github/workflows/ci.yml`)
- **Cleaned up stale tags**: Removed six obsolete git tags (`untagged`, `untagged-*`, `alpha-*`) and one broken draft release from GitHub.
- **Price tracking**: Record purchase prices per product with optional currency conversion (ExchangeRate-API, free no-key endpoint with 24h cache). Prices are optional like expiry date. New `Price` freezed model, `prices` table (v12 migration), `PriceDao`, `PriceRepository`, `CurrencyService`, `OpenPricesService`. All-new UI: price section on product detail screen, price history screen with swipe-to-delete, `PriceMask` widget for privacy masking. Average price badge in the app bar (next to pantry switcher). Price statistics in Stats tab (total value + average item price). Settings: enable/disable, base currency picker, retention days, privacy masking, Open Prices sync (consent-only, proof upload pending receipt capture). Data retention defaults to 0 (keep forever) independent of inventory retention. (`lib/models/price.dart`, `lib/database/price_dao.dart`, `lib/database/database_helper.dart`, `lib/services/currency_service.dart`, `lib/services/price_repository.dart`, `lib/services/open_prices_service.dart`, `lib/providers/settings_provider.dart`, `lib/providers/price_provider.dart`, `lib/providers/price_repository_provider.dart`, `lib/providers/currency_service_provider.dart`, `lib/providers/open_prices_provider.dart`, `lib/screens/settings_screen.dart`, `lib/screens/product_detail_screen.dart`, `lib/screens/price_history_screen.dart`, `lib/screens/stats_screen.dart`, `lib/screens/home_screen.dart`, `lib/widgets/price_mask.dart`, `lib/widgets/price_entry_sheet.dart`, `lib/models/pantry_stats.dart`, `lib/l10n/app_en.arb`)
- **OFF test data**: Fetched 12 full API responses from Open Food Facts for testing. Stored as `docs/superpowers/agents/off_test_products.json` (full JSON) and `docs/superpowers/agents/off_test_products.md` (human-readable lookup table). Products cover spreads, sodas, biscuits, oils, juices. (`docs/superpowers/agents/off_test_products.json`, `docs/superpowers/agents/off_test_products.md`)
- **Performance guide**: Copied to `docs/superpowers/agents/performance_guide.md` for easy reference during development. (`docs/superpowers/agents/performance_guide.md`)
- **AMOLED dark mode**: New `amoledDarkMode` toggle in Settings > Appearance. When enabled with dark mode, surfaces use pure-black (`Colors.black`) instead of the default dark surface colours, reducing power consumption on AMOLED displays. One-time nudge dialog on first launch when device is in light mode. (`lib/providers/settings_provider.dart`, `lib/main.dart`, `lib/screens/settings_screen.dart`, `lib/screens/pantry_shell.dart`, `lib/l10n/app_en.arb`, `lib/l10n/app_pt.arb`)
- **Settings & Theme persistence**: `ThemeModeNotifier` and `SettingsNotifier` now persist to `SharedPreferences` on every change and reload on startup. Fixes reset-on-restart bug. (`lib/providers/theme_provider.dart`, `lib/providers/settings_provider.dart`)
- **Small-screen golden test**: New golden test for `HomeScreen` at 360dp width with 1.0 text scale factor. Overrides 4 providers with mock data covering expired, expiring-soon, good, and no-expiry items. (`test/screens/home_screen_golden_test.dart`, `test/screens/goldens/home_screen_360dp.png`)
- **Inactivity reminder notification**: Sends a daily notification at 9 AM if the user has not added any product for 10+ days (configurable in Settings). Tracks last add date via `MAX(date_added)` from the inventory table. New `inactivity_channel` (Importance.low) separate from expiry channel. Toggle + threshold picker in Settings. Rescheduled on product add and app startup. Permission-denied warning shown once via SnackBar. (`lib/screens/settings_screen.dart`, `lib/services/notification_service.dart`, `lib/providers/settings_provider.dart`, `lib/database/inventory_dao.dart`, `lib/database/database_helper.dart`, `lib/main.dart`, `lib/screens/pantry_shell.dart`, `lib/screens/product_detail_screen.dart`, `lib/l10n/app_en.arb`,
  `lib/l10n/app_pt.arb`)
- **Play Store CD pipeline**: New CI workflow (`.github/workflows/deploy-to-playstore.yml`)
  builds signed release AAB and APK on `v*.*.*` tags, uploads to Google Play
  Console internal track via `r0adkll/upload-google-play`. Release signing
  configured in `build.gradle.kts` reading from `android/key.properties`
  (with env-var fallback for CI). (`docs/superpowers/agents/playstore.md`,
  `android/key.properties`, `android/app/build.gradle.kts`)
- **Monetization reference docs**: Created `docs/superpowers/agents/monetization.md`
  covering AdMob, UMP consent, IAP donations, Pro subscriptions, and
  Firebase cloud backup. All features deferred pending legal/accounting
  review. (`docs/superpowers/agents/monetization.md`)
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
- **AGENTS.md**: Split into two gates: Pre-commit (local) and Pre-merge (PR + CI). Added Development workflow section. Updated performance guide reference to `docs/superpowers/agents/`. Added OFF test data to reference docs. (`AGENTS.md`)
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
  to `main`. Wiki conventions documented in `docs/superpowers/agents/wiki.md`.
  (`docs/superpowers/agents/wiki.md`, `.github/workflows/wiki.yml`)
- **Doc comment quality: AGENTS.md rule 2** now states that doc comments
  feed the public GitHub Wiki, requiring them to be written as proper
  sentences for user-facing documentation.

### Changed

- **Emulator smoke test removed** from AGENTS.md pre-merge gate. Steps
  renumbered. Dev workflow and reference docs updated. (`AGENTS.md`)

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
- **Double background refresh on startup**: `_scheduleCacheRefresh` in `main.dart` now calls `setLastRefreshTime()` _before_ firing background refreshes, so `HomeScreen._refreshIfOverdue` finds a non‑overdue cache and skips.
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
