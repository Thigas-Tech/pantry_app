# Changelog

## [Unreleased]

### Documentation
- `ARCHITECTURE.md` section 5: updated tree diagrams to reflect `ListView.builder` with `RepaintBoundary`, SearchScreen images, StatsScreen placeholder, and Settings changelog button.
- `ARCHITECTURE.md` section 11.2 and 11.4: updated with actual `cacheWidth`/`cacheHeight` and `RepaintBoundary` implementations.
- `AGENTS.md` code style: added `ComingSoonView` / `ComingSoonScreen` stub pattern.
- `TODO.md` marked Autocomplete, InteractiveViewer, ExpansionTile, Changelog at startup as done.

### Enhancements
- **ComingSoonView / ComingSoonScreen**: Reusable placeholder widgets (`lib/widgets/coming_soon_view.dart`, `lib/screens/coming_soon_screen.dart`). Configurable icon, title, and subtitle. Follows the `ErrorView` / `EmptyPantry` pattern.
- **StatsScreen replaced with ComingSoon placeholder**: CSV import/export features removed. The tab now shows a "Coming soon" placeholder. Original stats will be re-implemented in a future release.
- **SearchScreen product images**: Result tiles now show product thumbnails (`ClipOval` 40×40 `Image.network`) with `cacheWidth`/`cacheHeight` and `CircleAvatar` fallback.
- **Settings "What's New" button**: New "About" section with a button that loads `CHANGELOG.md` and shows the changelog sheet on demand, bypassing the version-guard auto-trigger.

### Bugfixes
- **Missing `cacheWidth` in product detail**: `Image.network` in `ProductDetailScreen` was only constraining decode height. Added `cacheWidth` at screen width × device pixel ratio.
- **Stats summary cards overflow**: `_SummaryCard` and `_PhotoCard` Column widgets overflowed by 12px on tight layouts. Added `mainAxisSize: MainAxisSize.min`.
- **Chart label colors**: Bar chart axis labels in NutriScoreBar, CategoryChart, and LocationChart now use `colorScheme.onSurface` for readability in dark mode.

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

### Bugfixes
- **Chart axis labels invisible**: `SideTitles` constructors in fl_chart were missing `showTitles: true` after an earlier lint-cleanup mistakenly removed them (fl_chart defaults to `false`). Added back to all 4 chart label sets (NutriScoreBar, CategoryChart, LocationChart).
- **Search returns fewer results than OFF website**: Added `lc=world` and `cc=world` query parameters to `searchProducts` (matches OFF website behavior). Added `code` field fallback in `_parseProduct` for legacy API barcode responses. Added retry logic (3 attempts, exponential backoff 1s/2s/4s) matching `getByBarcode` pattern.
- **Search API 503 errors without user feedback**: `searchProducts` now retries with cancel support. Search debounce increased to 500ms. Added `CancelToken` to cancel in-flight searches on new query.
- **Changelog not showing on content changes**: Replaced version-string detection with content-hash detection. `_handleAppUpdate` now compares `CHANGELOG.md.hashCode` with stored hash — shows changelog whenever content changes, regardless of version number.

### UX & Debugging
- **Changelog dev-section filter**: `whats_new_sheet` now hides `### Documentation` and `### Code health` from the in-app display. Users see only product-facing changes.
- **Connectivity transition logging**: `connectivityProvider` now logs online/offline state changes.
- **Action-level logging**: added `logInfo` before every `unawaited()` fire-and-forget, `logWarning` for guard conditions, `logInfo` for form validation failures.
- **Snackbar consistency**: replaced raw `ScaffoldMessenger.showSnackBar` in delete flow with `SnackbarHelper.showUndo`. Replaced hardcoded English string in `inventory_card` with ARB-localized `productDataUnavailable`.

### Bugfixes
- **Stats summary cards overflow**: `_SummaryCard` and `_PhotoCard` added `mainAxisSize: MainAxisSize.min` to prevent RenderFlex overflow.
- **Chart label colors**: Bar chart axis labels now use `colorScheme.onSurface` for dark mode readability.
- **Dead `Contribute Photos` button**: added `logInfo` for the unimplemented feature.

### Code health
- **AGENTS.md rule 11**: Consider performance and footprint on every plan.
- **AGENTS.md performance audit checklist**: 6-item checklist for new dependencies, screens, DB queries, providers, models, and rebuild scope.
- **TODO.md**: 3 new items (price tracking, NFC-e, photo contribution).
- 323 tests passing, 0 analyze issues.

### Code health
- Removed CSV import/export: deleted `csv_service.dart`, `csv_service_provider.dart`, `filegate_provider.dart`, and all related test files. Removed `getExportData()` / `exportData()` from `DatabaseHelper`, `InventoryDao`, and `ProductRepository`.
- Removed `csv`, `filegate`, `share_plus` dependencies from `pubspec.yaml`. Ran `flutter pub upgrade` (picked up `equatable` 2.1.0 transitively).
- Removed 19 unused ARB translation keys from all 3 locales (en, pt, pt_BR). Verified zero stale references with regex before removal.
- Added 2 new ARB keys: `settingsAbout`, `comingSoonDescription` — translated in en, pt, pt_BR.
- 340 tests passing, 0 analyze issues.

### Bugfixes
- **Changelog not showing on re-launch**: `_handleAppUpdate` returned early when the app version was unchanged (`if (lastVersion == currentVersion) return;`), which prevented the `changelog_show_pending` flag from ever being set. Moved the changelog tracking above the version-match guard so it runs unconditionally. Added `logInfo` traces at every decision point in `_showChangelogIfPending()` (skip, no entries, show) for easier debugging.

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
- `connectivity_plus` wrapping Riverpod provider
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
