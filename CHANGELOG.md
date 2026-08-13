# Changelog

## Unreleased

### Security

- **Removed the Blaze feedback infrastructure (free-tier cleanup)**: the
  Cloud Function (`functions/`) and its CI jobs were removed after in-app
  feedback was dropped; `firebase.json` no longer configures functions and
  the `FEEDBACK_PROXY_URL` build define is gone. The repo now depends only
  on free Firebase services.
  (functions/ removed, firebase.json, .github/workflows/firebase-rules.yml,
  .github/workflows/build.yml, .github/workflows/deploy-to-playstore.yml,
  .env.example, ARCHITECTURE/SERVICES.md)
- **Removed in-app GitHub feedback (free-tier decision)**: the Cloud
  Function feedback proxy from the previous change required the paid
  Firebase Blaze plan. In-app feedback is removed instead; GitHub
  feedback, the serverless proxy, the PAT, and the offline feedback queue
  are gone. Feedback-only l10n keys were pruned. This keeps the app on
  free Firebase (Firestore rules, anonymous auth) only.
  (lib/screens/feedback_screen.dart, lib/services/github_issue_service.dart,
  lib/services/device_id.dart, lib/database/feedback_queue_dao.dart,
  lib/database/migrations/v11_feedback_queue.dart removed;
  lib/config.dart, lib/screens/settings_screen.dart,
  lib/screens/pantry_shell.dart, lib/services/app_startup_service.dart,
  lib/database/database_helper.dart, lib/l10n/*.arb)
- **Stop shipping credentials in the APK (audit S1)**: the .env file was a
  Flutter asset, so every release bundled the GitHub feedback PAT, OFF
  credentials, Open Prices token and USDA key. The asset is removed and
  `dotenv.load` is optional; credential-backed features (OFF product
  submission, Open Prices, USDA) are now disabled in release builds unless
  the user supplies their own credentials. GitHub feedback in release goes
  through a new serverless Cloud Function (`functions/`) that holds the
  PAT server-side, validates the payload and enforces server-side per-
  device rate limits (audit S6). Non-secret toggles (FIREBASE_ENABLED,
  FEEDBACK_PROXY_URL) moved to `--dart-define` CI build flags; the CI
  `.env` secret injection steps were removed.
  (pubspec.yaml, lib/config.dart, lib/main.dart,
  lib/services/github_issue_service.dart, lib/services/device_id.dart,
  lib/screens/feedback_screen.dart, functions/ new,
  .github/workflows/build.yml, .github/workflows/deploy-to-playstore.yml,
  .github/workflows/firebase-rules.yml, .env.example)
  **Owner action required: rotate/revoke the four exposed credentials and
  delete old CI artifacts.**
- **Firestore security rules added and deployed via CI (audit S2)**: the
  repo shipped no rules file, so anonymous users could overwrite or poison
  the shared product/produce cache. New `firestore.rules`: cache reads stay
  public, product_cache/produce_cache writes require a signed-in user and a
  schema-valid document, and recipe_cache documents carry an `ingestedBy`
  uid so only their author can update or delete them. Rules are unit-tested
  against the Firestore emulator (`firebase_tests/`) and deployed on main.
  (firestore.rules new, firebase.json, .github/workflows/firebase-rules.yml
  new, lib/models/recipe_cache_entry.dart, lib/services/firebase_cache_service.dart,
  lib/providers/firebase_cache_provider.dart, firebase_tests/ new)
- **Random recipe share ids (audit S8)**: the recipe_cache document id was
  a deterministic SHA-256 of name/createdAt/inventory, which low-entropy
  recipe names made dictionary-attackable. It is now a random UUID4 that
  cannot be traced back to the owner, and the recipe row persists the id
  so the shared document can still be removed on delete (DB migration
  v40). Doc comments updated to state the real property: obfuscated, not
  anonymous.
  (lib/models/recipe_cache_entry.dart, lib/models/recipe.dart,
  lib/services/recipe_service.dart, lib/services/firebase_cache_service.dart,
  lib/database/recipe_dao.dart, lib/database/migrations/v40_recipe_shared_id.dart)
- **Sanitized image cache file names (audit S3)**: [ImageCacheService]
  now scrubs unsafe characters from the barcode before building the cache
  file path, so a barcode like `../../evil` cannot escape the cache
  directory (matches the existing [ProductImageService] sanitization).
  Regression test covers the traversal case.
  (lib/services/image_cache_service.dart,
  test/services/image_cache_service_test.dart)
- **Disabled Android app-data backups (audit S5)**: [android:allowBackup]
  is now [false], so the SQLite DB (including the unsubmitted feedback
  queue) and SharedPreferences are no longer extractable via adb or cloud
  backup. The manifest policy test guards the attribute.
  (android/app/src/main/AndroidManifest.xml,
  test/manifests/android_manifest_test.dart)
- **Removed vestigial Android permissions (audit S7)**: dropped
  [READ_EXTERNAL_STORAGE], [SCHEDULE_EXACT_ALARM], [USE_EXACT_ALARM], and
  the [requestLegacyExternalStorage] attribute. Photo picking uses the
  system photo picker (no permission needed) and notifications only
  schedule inexact alarms. A manifest policy test now guards against
  regressions.
  (android/app/src/main/AndroidManifest.xml,
  test/manifests/android_manifest_test.dart new)

### Maintainability

- **One-shot UI flags routed through a [UiFlagsNotifier] (audit MA7)**:
  the notification-denied warning, AMOLED nudge, What's-New sheet, and
  notification-rationale flags were read/written ad-hoc via raw
  SharedPreferences from the shell, settings, and startup paths. A new
  keepAlive [UiFlagsNotifier] now owns all four with typed getters and
  setters; [AppUpdateHandler.updateChangelogFlag] returns whether to show
  the What's-New sheet instead of writing the flag itself.
  (lib/providers/ui_flags_provider.dart new,
  test/providers/ui_flags_provider_test.dart new, lib/screens/
  pantry_shell.dart, lib/screens/settings_screen.dart, lib/services/
  app_update_handler.dart, lib/services/app_startup_service.dart)

### Maintainability

- **main.dart slimmed from 622 to ~200 lines (audit MA1)**: the fourteen
  top-level async orchestrators plus notification-tap navigation and
  app-update bookkeeping were extracted into [AppStartupService], which
  owns the post-init task schedule (with an injectable delay seam), the
  pre-frame version check, the post-frame cache flush, anonymous
  sign-in, permission request, and notification-tap navigation.
  main.dart now keeps only main(), [PantryApp], and the raw wiring.
  (lib/services/app_startup_service.dart new,
  test/services/app_startup_service_test.dart new, lib/main.dart)

### Maintainability

- **Single [NotificationCoordinator] for all notification scheduling
  (audit MA2)**: expiry and inactivity reminders were re-implemented
  three times (startup in main.dart, the settings notifications toggle,
  and the product detail screen) with the logic drifting apart — the
  settings path had stopped resolving product names. A new
  [NotificationCoordinator] now owns rescheduling; it also loads
  barcode-to-name data only for items with an expiry date via one
  batched query instead of scanning the whole products table. The
  product detail path now also respects the inactivity-reminder toggle.
  (lib/services/notification_coordinator.dart new,
  lib/providers/notification_coordinator_provider.dart new,
  lib/main.dart, lib/screens/settings_screen.dart,
  lib/screens/product_detail_screen.dart,
  test/services/notification_coordinator_test.dart new,
  ARCHITECTURE/SERVICES.md)

### Maintainability

- **CHANGELOG.md pruned (audit MA4)**: shipped releases older than
  [0.0.8] were collapsed into one-line summaries (0.0.5 was ~515 lines
  of itemized history), keeping the current Unreleased section plus the
  last three releases verbatim. The file shrank from ~1800 to ~1270
  lines. (CHANGELOG.md)

### Maintainability

- **Verbose logging now debug-only and doc comments corrected
  (audit MA6 + S4)**: [_verbose] was hardcoded to true, so release
  builds logged barcodes, search queries, notification payloads, and DB
  paths into the ring buffer attached to opt-in feedback issues. It now
  mirrors [kDebugMode], matching the class doc: logDebug/logInfo are
  eliminated from release binaries, warnings and errors remain. This
  also resolves security finding S4. (lib/utils/logger.dart,
  test/utils/logger_test.dart)

### Maintainability

- **Zero backticks left in doc comments (audit MA3)**: 32 remaining
  rule-11 violations across 16 hand-written files were converted to
  [square-bracket] references or plain prose, and the 8 fenced code
  examples in doc comments became indented code blocks. `dart doc .`
  and `dart analyze` are clean. (lib/database/migrations/*,
  lib/providers/scanner_providers.dart, lib/services/*, lib/utils/*,
  lib/widgets/*, lib/models/*)

### Maintainability

- **Single [UsdaApiClient] and [CurrencyService] instances across the
  app (audit MA5)**: the USDA client was previously constructed in
  three places and the currency service was duplicated as a private
  provider. All layers now consume [usdaApiClientProvider] and
  [currencyServiceProvider]; [FirebaseCacheService] and
  [ProductRepository] expose their injected client so the
  provider-singleton guard test can assert instance identity at runtime.
  (lib/services/firebase_cache_service.dart,
  lib/services/product_repository.dart,
  test/providers/provider_singleton_guard_test.dart)

### Performance

- **Connectivity check no longer caches the first result forever
  (audit P7)**: [hasConnectionProvider] is a non-autoDispose one-shot
  check that was never invalidated, so an app started offline kept
  reporting offline all session (and vice versa). [PantryShell] now
  invalidates it on every connectivity-stream change, so the 8 call
  sites (search, cache refresh, settings, submission flows) get fresh
  answers. (lib/screens/pantry_shell.dart,
  test/screens/pantry_shell_test.dart)

### Performance

- **Startup no longer blocks on network and asset loads (audit P6)**:
  the anonymous Firebase sign-in (a network call) ran before runApp and
  the app-update handler loaded PackageInfo, the changelog asset, and
  flushed caches pre-frame. Sign-in is now deferred past the first
  frame, and the update handling is split: only the one-fast-call
  version comparison stays pre-frame, while the changelog content-hash
  check and the post-update cache flush run post-frame, extracted into a
  testable [AppUpdateHandler]. (lib/main.dart,
  lib/services/app_update_handler.dart, test/services/
  app_update_handler_test.dart)

### Performance

- **Notification reschedule permission check hoisted (audit P5)**:
  [FlutterNotificationService.rescheduleAllItems] called
  areNotificationsEnabled — a platform-channel round trip — once per
  item (plus up to two zonedSchedule calls), so rescheduling 200 items
  meant ~600 sequential channel round trips at startup. The check now
  runs once before the loop and the result is passed down;
  [scheduleExpiryReminders] accepts an optional
  systemNotificationsEnabled override for that case. (lib/services/
  notification_service.dart, notification_service_interface.dart,
  test/services/notification_service_test.dart)

### Performance

- **Batch deletes and leaner list-row watchers (audit P10)**:
  [HomeScreenController.deleteSelected] now deletes all selected items in
  one batch (new [InventoryDao.deleteMany] + repository passthrough)
  instead of one statement per item; the inventory card and recipe list
  no longer watch the whole settings object per row — they select only
  the fields they use, so unrelated setting changes no longer rebuild
  every card; the [DatabaseHelper.database] getter deduplicates
  concurrent first opens (cached future); and [pendingSyncCountProvider]
  counts via COUNT(*) instead of loading all pending price rows.
  (lib/database/inventory_dao.dart, lib/database/database_helper.dart,
  lib/database/price_dao.dart, lib/services/product_repository.dart,
  lib/services/price_repository.dart, lib/providers/price_provider.dart,
  lib/providers/home_screen_controller.dart, lib/widgets/inventory_card.dart,
  test/database/*, test/providers/*, test/widgets/inventory_card_test.dart)

### Performance

- **Stats screen single-pass price aggregates (audit P9)**: the stats
  visit re-executed the correlated latest-price subquery 4-6 times
  (value, average, priced count, plus the dashboard queries). New
  [PriceRepository.inventoryPriceSummary] derives all three aggregates
  from one latest-prices pass with a single currency-conversion sweep,
  and the per-row categories_hierarchy JSON decoding now runs in a
  background isolate via compute instead of on the UI path.
  (lib/services/price_repository.dart, lib/providers/stats_provider.dart,
  test/services/price_repository_test.dart,
  test/providers/stats_provider_test.dart)

### Performance

- **Database indexes and count queries (audit P8)**: new migration v39
  adds composite indexes for the hot queries —
  inventory(inventory_id, expiry_date) serves the per-pantry list
  ordering without a temporary sort, and
  shopping_list(inventory_id, is_purchased, date_added) serves the
  pending/purchased lists. The name-based FEFO fallback
  (LOWER(p.name) LIKE, a leading-wildcard scan) is now capped at 20
  rows, the orphan cleanup rewrites NOT IN (SELECT DISTINCT ...) as
  NOT EXISTS, and [totalInventoryCountProvider] counts via COUNT(*)
  per inventory instead of materializing the full joined rows.
  (lib/database/migrations/v39_inventory_shopping_indexes.dart,
  lib/database/database_helper.dart, lib/providers/inventory_provider.dart,
  test/database/migrations/v39_inventory_shopping_indexes_test.dart,
  test/database/database_helper_test.dart, test/providers/providers_test.dart)

### Performance

- **Recipe N+1 cascade removed (audit P4)**: the recipe nutrition,
  ingredient, and Nutri-Score providers fetched products one sequential
  [getProduct] call per barcode (each a DB query and possibly a network
  fetch) and pinned every viewed recipe with keepAlive. New
  [ProductDao.getByBarcodes] / [ProductRepository.getProductsForBarcodes]
  resolve a recipe's ingredients with one batched cached query, fetching
  only the misses; the keepAlive pins are dropped so providers auto-dispose.
  [ProductRepository.getProduct] deduplicates concurrent in-flight
  lookups per barcode. [CurrencyService] now caches rates in memory per
  calendar day, removing a SharedPreferences read and jsonDecode from
  every ingredient-cost conversion. (lib/database/product_dao.dart,
  lib/database/database_helper.dart, lib/services/product_repository.dart,
  lib/services/currency_service.dart, lib/providers/recipe_provider.dart,
  test/database/product_dao_test.dart,
  test/services/product_repository_test.dart,
  test/services/currency_service_test.dart,
  test/providers/recipe_nutrition_provider_test.dart)

### Performance

- **Image cache: downscale, size cap, in-flight dedup (audit P3)**:
  [ImageCacheService] stored full-resolution WebP files with no eviction
  or cap, and concurrent requests for the same barcode downloaded twice.
  It now downscales the longest side to 400 px (matching the largest
  display size at a 2x pixel ratio) before WebP encoding in the
  background isolate, evicts the oldest files by last-modified time when
  the cache exceeds 50 MB (injectable), and shares one in-flight
  download per barcode. (lib/services/image_cache_service.dart,
  test/services/image_cache_service_test.dart)

### Performance

- **Futures created in build() moved to cached providers (audit P2)**:
  product detail, settings, and recipe screens re-created futures inside
  build(), so any rebuild re-ran the DB query or image-cache call and the
  FutureBuilders flashed the loading state. New autoDispose
  FutureProvider families ([inventoryForBarcodeProvider],
  [cachedImageProvider], [recipeCostProvider], [averageRecipeCostProvider],
  [canScheduleExactNotificationsProvider], [currencyCacheSizeProvider],
  [pendingFeedbackCountProvider]) follow the existing price-provider
  pattern; mutation handlers invalidate the family instead of bumping the
  hand-rolled inventory-version counter, which was deleted. The recipe
  list's per-card ingredient-count future now reuses the existing
  [allRecipeIngredientsProvider] family. (lib/providers/*, 
  lib/screens/product_detail_screen.dart, lib/screens/settings_screen.dart,
  lib/screens/recipe_list_screen.dart, lib/screens/recipe_detail_screen.dart,
  test/providers/*, test/screens/*)

### Fixed

- **Items expiring exactly N days from now disappear from the home list
  (audit P1)**: the "good" bucket used a time-of-day-aware threshold
  while the expiring-soon bucket used a date-only one, so an item whose
  expiry date was exactly expiringSoonDays away fell into neither bucket
  for a day. Grouping now uses one date-only threshold; the item shows
  under Good.

### Performance

- **Lazy home inventory list (audit P1)**: the home list was an eager
  [ListView] with children: every card, its price provider, and its image
  future were created for all items regardless of visibility. It is now a
  lazy [ListView.builder] over a flattened section index
  ([InventoryGrouping] in lib/utils/inventory_grouping.dart), and the
  expiry groups are computed once per change of the items, the
  expiring-soon window, or the calendar day instead of re-filtering and
  re-parsing dates on every build. Section headers are a shared
  [SectionHeader] widget. (lib/screens/home_screen.dart,
  lib/utils/inventory_grouping.dart, lib/widgets/section_header.dart,
  test/utils/inventory_grouping_test.dart,
  test/screens/home_screen_test.dart)

- **Placeholder-state notifiers (audit Q5)**: active inventory, settings,
  theme mode and the onboarding flag are now AsyncNotifiers that load
  their persisted values in build — no more first-frame placeholder values
  (fake inventory 1, default settings, system theme, onboarding flash) and
  no more pre-runApp seeding in main.dart. Consumers await
  provider.future in async paths and unwrap with a safe default in build.
  (lib/providers/active_inventory_provider.dart,
  lib/providers/settings_provider.dart,
  lib/providers/theme_provider.dart,
  lib/providers/onboarding_provider.dart, lib/main.dart,
  lib/providers/*, lib/screens/*, lib/widgets/*,
  test/helpers/pump_app.dart)

- **Business logic moved out of providers (audit Q1)**: recipe logic
  (save/delete, cost calculation, shortage checks, the cook FEFO
  transaction) moved from recipe_provider.dart (772 -> ~180 lines) into a
  new [RecipeService], and shopping list logic (add/toggle/delete,
  price updates, move-purchased-to-inventory) moved from
  shopping_list_provider.dart into a new [ShoppingListService]. Both take
  DAOs/services as constructor dependencies, are exposed via keepAlive
  providers, and every screen call site now reads the service directly.
  All the moved logic is now testable without a ProviderContainer (the
  tests were ported and strengthened).
  (lib/services/recipe_service.dart,
  lib/services/shopping_list_service.dart,
  lib/providers/recipe_service_provider.dart,
  lib/providers/shopping_list_service_provider.dart,
  lib/providers/recipe_provider.dart,
  lib/providers/shopping_list_provider.dart, lib/screens/*, lib/widgets/*)

- **Legacy post-frame invalidate dance (audit Q7)**: all 30
  addPostFrameCallback((_) => ref.invalidate(...)) sites now call
  ref.invalidate directly after their async gap, with a context.mounted /
  ref.mounted guard where needed — Riverpod 3 allows invalidation from
  async gaps, so the Riverpod-1.x frame deferral is gone. The
  invalidateRecipes helper keeps its API but defers nothing. The 8
  non-invalidate post-frame uses (changelog sheets, post-init tasks,
  notification taps) are untouched.
  (lib/providers/recipe_provider.dart,
  lib/providers/shopping_list_provider.dart,
  lib/providers/home_screen_controller.dart,
  lib/providers/pantry_provider.dart, lib/screens/*, lib/widgets/*)

- **Raw DB maps exposed to UI (audit Q6)**: `inventoryListProvider` now
  returns typed `InventorySummary` rows (id, name, createdAt, itemCount)
  and `inventoryProductsProvider` returns `InventoryProductOption`
  (barcode, name, imageUrl, productType) instead of raw maps. Consumers
  (home_screen, manage_inventories_screen, recipe_list_screen,
  quantity_and_pantry_sheet, add_to_shopping_list_sheet) use typed
  access — the home screen's `asData!.value.cast().firstWhere(...)`
  force-unwrap chain is gone.
  (lib/models/inventory_summary.dart,
  lib/models/inventory_product_option.dart,
  lib/providers/inventory_provider.dart,
  lib/providers/shopping_list_provider.dart,
  test/models/inventory_summary_test.dart)

- **Layering bypass (audit Q8)**: `HomeScreenController.deleteSelected`
  and `moveSelected` now delegate to `ProductRepository` (via
  `productRepositoryProvider`) instead of calling the database facade
  directly — one DI path, matching the repository wrapping of the same
  operations. New unit tests verify the delegation and the empty-selection
  no-op.
  (`lib/providers/home_screen_controller.dart`,
  `test/providers/home_screen_controller_test.dart`)

- **l10n violations (audit Q2)**: 'Product not found' in main.dart is now
  the localized productNotFound; raw e.toString() no longer reaches users
  in product_detail_screen, stats_screen, recipe_list_screen and
  price_history_screen (replaced by the new errorGeneric, with the real
  exception still logged); the produce serving-size dropdown and the
  Nutri-Score badge semantics labels use ARB strings; the colon in the
  search source label moved into the ARB string. New ARB keys added to all
  three locales. Android notification channel names stay English by
  design - Android does not update channel names on locale change
  (documented on the interface).
  (lib/main.dart, lib/screens/product_detail_screen.dart,
  lib/screens/stats_screen.dart, lib/screens/recipe_list_screen.dart,
  lib/screens/price_history_screen.dart,
  lib/screens/add_to_inventory_screen.dart,
  lib/widgets/nutriscore_badge.dart, lib/widgets/search_panel.dart,
  lib/l10n/app_en.arb, lib/l10n/app_pt.arb, lib/l10n/app_pt_BR.arb,
  test/screens/add_to_inventory_screen_test.dart,
  test/widgets/nutriscore_badge_test.dart)

- **Silent exception swallowing (audit Q4)**: theme-mode load/persist
  failures in `theme_provider.dart` are now logged via `logWarning` instead
  of being swallowed; a price whose failure-marking also fails in
  `open_prices_service.syncPendingPrices` is now logged and reported
  instead of silently staying "pending" forever. Near-silent catch blocks
  in `home_screen_controller`, `active_inventory_provider`,
  `settings_provider`, `currency_service`, `off_query`, `changelog_loader`
  and `price_entry_sheet` now log a warning too.
  (`lib/providers/theme_provider.dart`,
  `lib/services/open_prices_service.dart`,
  `test/providers/theme_provider_test.dart`,
  `test/services/open_prices_service_test.dart`)

- **SQLite row null-safety (audit Q3)**: removed remaining non-null
  assertions on SQL row values in `checkIngredientShortages` and
  `cookRecipe` (`quantity` is a nullable schema column and is now read with
  a `?? 0` fallback; a missing `id` row is skipped) and in
  `getBarcodesInInventory` (null/empty barcode rows are filtered out).
  Regression tests cover NULL-quantity rows in both shortage checks and the
  cook FEFO transaction.
  (`lib/providers/recipe_provider.dart`,
  `lib/database/database_helper.dart`,
  `test/providers/q3_null_row_regression_test.dart`)

### Documentation

- **Price tracking architecture doc**: new `ARCHITECTURE/PRICE_TRACKING.md`
  documents the local + Open Prices data flow, the `prices`/`products`
  package-size schema (v37), unit-aware price math and recipe cost scaling,
  the proof-photo requirement, and the currently placeholder sync. Added to
  `ARCHITECTURE/INDEX.md`; refreshed `ARCHITECTURE/DATABASE.md`,
  `ARCHITECTURE/SERVICES.md`, `ARCHITECTURE/PROVIDERS.md`,
  `ARCHITECTURE/UI_STRUCTURE.md`, `ARCHITECTURE/MODELS.md`,
  `ARCHITECTURE/OVERVIEW.md` (corrected to 13 tables),
  `docs/superpowers/agents/stale_info_checklist.md`, `README.md`, `TODO.md`
  and the schema header comment in `lib/database/database_helper.dart`.

- **Migration v30 search_text backfill decision documented**: the recipe
  `search_text` backfill intentionally stays Dart-based
  (`normalizeForSearch()`) instead of raw SQL because SQLite string
  functions cannot strip diacritics; the performance gain is marginal for
  typical recipe counts, so correctness is prioritized. The rationale is
  recorded in the `MigrationV30` doc comment and
  `ARCHITECTURE/DATABASE.md`. New migration regression tests lock in
  diacritic removal, case and whitespace normalization, empty-table and
  empty-instruction handling, and data-level idempotency.
  (`lib/database/migrations/v30_recipe_indexes_and_search.dart`,
  `ARCHITECTURE/DATABASE.md`,
  `test/database/migrations/v30_recipe_indexes_test.dart`)

- **Migration test coverage gaps filled (V32-V36)**: migration tests now
  also assert the `idx_scan_history_barcode` index and an `image_url`
  round-trip (v32), the fallback backfill id when the `inventories` table
  is empty plus the `NOT NULL DEFAULT 1` constraint for rows inserted
  after the migration (v33, v34), and the non-unique flag of the
  `idx_inventory_barcode_inventory_id` index via PRAGMA (v36).
  (`test/database/migrations/v32_scan_history_test.dart`,
  `test/database/migrations/v33_recipes_inventory_test.dart`,
  `test/database/migrations/v34_prices_inventory_test.dart`,
  `test/database/migrations/v36_nonunique_inventory_index_test.dart`)

- **Recipe search_text maintained at write time**: `RecipeDao.toMap` now
  emits the derived `search_text` column via the new
  `buildRecipeSearchText` helper, so recipes created or edited through any
  write path (DAO insert/update and the
  `insertRecipeWithIngredients`/`updateRecipeWithIngredients` transaction
  helpers) keep the normalized search text in sync with their name and
  instructions. The composition mirrors the v30 migration backfill, and
  tests cover diacritics, empty instructions, and renames.
  (`lib/utils/search_utils.dart`, `lib/database/recipe_dao.dart`,
  `test/utils/search_utils_test.dart`,
  `test/database/recipe_dao_test.dart`,
  `test/database/database_helper_test.dart`)

### Changed

- **All providers migrated to `@riverpod` codegen**: the remaining 27
  hand-written provider files became annotated functions/classes with
  committed `.g.dart` files, completing the migration (3 files already
  used codegen). Lifecycle semantics are preserved exactly: plain
  `Provider`/`StreamProvider`/`Notifier` became `@Riverpod(keepAlive:
  true)`, autoDispose/family providers became plain `@riverpod`, and the
  recipe providers keep their runtime `ref.keepAlive()` calls. Provider
  names and family signatures are unchanged, so no call sites or test
  overrides were touched. ARCHITECTURE/PROVIDERS.md documents the
  convention (including the `Ref`-typed function parameters and the
  `flutter_riverpod` import needed for `select`).
  (`lib/providers/*.dart`, `ARCHITECTURE/PROVIDERS.md`)

### Fixed

- **Duplicate service singletons**: `FirebaseCacheProvider` and
  `ProductRepositoryProvider` constructed their own `UsdaApiClient`, and
  `recipe_provider` defined a private `CurrencyService` provider plus a
  third direct construction inside `cookRecipe`. All now consume the shared
  `usdaApiClientProvider` / `currencyServiceProvider`, so tests override
  one instance and no HTTP clients are silently duplicated. A source-scan
  guard test (`test/providers/provider_singleton_guard_test.dart`) fails
  if a direct construction is reintroduced.
  (`lib/providers/firebase_cache_provider.dart`,
  `lib/providers/product_repository_provider.dart`,
  `lib/providers/recipe_provider.dart`,
  `test/providers/provider_singleton_guard_test.dart`)

- **Single dependency-injection path for singletons**: `DatabaseHelper` and
  `ImageCacheService` were constructed directly in six startup/screen
  sites (main.dart x5, settings_screen) in addition to their providers,
  giving two DI paths for the same singletons. The shared `appContainer`
  is now created before `_handleAppUpdate` and every site reads
  `databaseProvider` / `imageCacheProvider`. A source-scan guard test
  (`test/database/database_helper_di_guard_test.dart`) fails if a direct
  construction is reintroduced outside the owning files.
  (`lib/main.dart`, `lib/screens/settings_screen.dart`,
  `test/database/database_helper_di_guard_test.dart`)

- **Connectivity-gated background cache refresh**: the scheduled refresh
  fired even while offline, contradicting the documented offline-first
  contract (ARCHITECTURE/PERFORMANCE.md §11.3). The decision moved into a
  testable [CacheRefreshCoordinator] (`lib/services/`) that skips the
  refresh when the device is offline or the cache is fresh, records the
  refresh timestamp before firing, refreshes inventories in parallel, and
  tolerates per-inventory failures. `main.dart` now reads the coordinator
  via `cacheRefreshCoordinatorProvider`; partial successes invalidate the
  pantry UI. Six unit tests cover the offline, fresh-cache, ordering,
  failure-tolerance, and empty-inventory paths. The PERFORMANCE.md §11.5
  claim that the home list uses `ListView.builder` was corrected to match
  the eager `ListView(children:)` implementation.
  (`lib/services/cache_refresh_coordinator.dart`,
  `lib/providers/cache_refresh_coordinator_provider.dart`,
  `lib/main.dart`, `ARCHITECTURE/PERFORMANCE.md`,
  `test/services/cache_refresh_coordinator_test.dart`)

- **Changelog error snackbar**: opening "What's New" when the changelog
  assets cannot be loaded showed the cache-flush failure message ("Failed to
  flush cache") instead of a changelog-specific error. The failure path also
  caught only `Exception`, but asset loading throws `FlutterError` (an
  `Error`), so the handler was unreachable. The snackbar now shows a
  localized "Could not load the changelog." message and the catch handles
  any load failure. New ARB key `changelogLoadFailed` (en, pt, pt_BR) with
  a widget test that simulates missing assets via the `flutter/assets`
  channel.
  (`lib/screens/settings_screen.dart`,
  `lib/l10n/app_en.arb`, `lib/l10n/app_pt.arb`, `lib/l10n/app_pt_BR.arb`,
  `test/screens/settings_screen_test.dart`)

- **SQLite version compatibility**: FEFO and price-statistics queries used
  `NULLS LAST` (SQLite 3.30+) and `ROW_NUMBER() OVER` (SQLite 3.25+),
  which crash on devices whose system SQLite predates those versions
  (Android 10 and below for NULLS LAST, Android 9 and below for window
  functions). Both syntaxes are replaced with portable SQL: FEFO ordering
  uses `ORDER BY (expiry_date IS NULL), expiry_date ASC`, and
  latest-price-per-barcode uses a correlated subquery
  (`ORDER BY date_purchased DESC, id DESC LIMIT 1`). The rewrite also
  fixes a latent double-count when two purchases share the same
  `date_purchased`. A new compatibility test scans `lib/` for the banned
  syntax so it cannot be reintroduced.
  (`lib/database/database_helper.dart`, `lib/providers/recipe_provider.dart`,
  `lib/database/price_dao.dart`, `test/database/price_dao_test.dart`,
  `test/database/database_helper_test.dart`,
  `test/database/sqlite_compatibility_test.dart`)

- **deleteInventory orphaned shopping list items**: with foreign-key
  enforcement disabled during the delete, the `ON DELETE SET NULL` on
  `shopping_list.inventory_id` never fired, leaving items dangling on a
  deleted inventory. The delete now nulls those references explicitly and
  runs all deletions inside a single transaction.
  (`lib/database/inventories_dao.dart`,
  `test/database/database_helper_test.dart`)

- **Failed migrations are no longer silently skipped**: the migration
  runner now rethrows the first failing migration so sqflite rolls back
  the whole upgrade and retries on the next launch, instead of committing
  version 38 with an incomplete schema.
  (`lib/database/migrations/migration_runner.dart`,
  `lib/database/database_helper.dart`,
  `test/database/migrations/migration_runner_test.dart`,
  `test/database/database_helper_test.dart`)

- **Index optimizations (v38)**: dropped the redundant `idx_barcode`
  (products PK is auto-indexed) and `idx_inventory_barcode` (covered by
  the composite), and added `idx_prices_barcode_inventory_date`,
  `idx_recipes_inventory_updated`, and `idx_products_source` to serve the
  hot queries.
  (`lib/database/migrations/v38_index_optimizations.dart`,
  `lib/database/database_helper.dart`,
  `test/database/migrations/v38_index_optimizations_test.dart`)

- **Corrupt `categories_hierarchy` JSON no longer crashes product reads**:
  the column is now decoded defensively like `additional_nutrients`.
  (`lib/database/product_dao.dart`,
  `test/database/product_dao_test.dart`)

- **Database maintenance**: `PRAGMA quick_check` now runs only after
  schema upgrades instead of on every open, and `PRAGMA optimize` runs on
  open and after `cleanupOldEntries`.
  (`lib/database/database_helper.dart`)

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

- **Crop and rotate product photos**: the photo preview
  (`lib/widgets/product_photo_preview.dart`) gains a crop action that opens a
  full-screen crop editor (`lib/widgets/photo_crop_screen.dart`) with a
  resizable crop grid and rotate-left/rotate-right controls. Applying crops
  through `ProductPhotoCropper` (`lib/services/product_photo_cropper.dart`),
  which reuses `crop_image`'s grid math so the output matches what was shown,
  downscales to at most 1600 px, and encodes JPEG in a background isolate.
  Both the detail-screen photo manager
  (`lib/widgets/product_photo_management.dart`) and the manual product form
  (`lib/screens/add_product_screen.dart`) replace the slot with the cropped
  file. Crops smaller than the OFF minimum (640 px) are rejected with a
  localized warning, the crop is non-destructive (the source is never
  touched), and cancelling keeps the original photo.
  (`lib/l10n/app_en.arb`)

- **Package size on price records (issue #308)**: `Price` now carries
  `packageQuantity` and `packageUnit` so a recorded price knows how much
  product it covers. A v37 migration adds `package_quantity REAL` and
  `package_unit TEXT` to the `prices` table, and `PriceDao` table creation,
  `toMap`, and `fromMap` round-trip the new columns. The price entry sheet
  gains optional package quantity + unit fields (validated to be positive)
  and pre-fills them in edit mode.
  (`lib/models/price.dart`, `lib/database/price_dao.dart`,
  `lib/database/migrations/v37_prices_package.dart`,
  `lib/widgets/price_entry_sheet.dart`)

- **Product packaging quantity persisted (issue #308)**: the `products`
  table gains `quantity TEXT` and `product_quantity REAL` in the same v37
  migration; `ProductDao` round-trips them, and the off product adapter and
  quantity parser handle multi-pack strings like "3 x 150 g", using the
  per-unit value for scaling.
  (`lib/database/product_dao.dart`, `lib/models/product.dart`,
  `lib/utils/quantity_parser.dart`)

- **Price calculator (issue #308)**: new pure helpers
  (`lib/utils/price_calculator.dart`): `scaledIngredientCost` computes the
  cost of the amount of a packaged product actually used, and `unitPrice`
  derives the per-piece / per-100 g / per-kg / per-L / per-100 ml unit value
  from the package size. Both return null on missing, zero, or non-finite
  sizes and on incompatible units, avoiding any division by zero or invented
  density (there is no g-to-pieces conversion).

- **Per-unit price labels (issue #308)**: `PriceRepository.unitPriceLabel`
  builds labels like "R$ 0,83/unit" ("/100 g", "/kg", "/L", "/100 ml")
  from `PriceCalculator.unitPrice`, or null when no usable package size
  exists. The inventory card and price-history tiles render the per-unit
  price under the flat price via `UnitPriceLabel`, hidden when unresolvable
  and masked by `PriceMask` when prices are hidden.
  (`lib/services/price_repository.dart`, `lib/widgets/unit_price_label.dart`,
  `lib/widgets/inventory_card.dart`, `lib/screens/price_history_screen.dart`)

- **Open Prices price_per (issue #308, partial)**: the intended
  `OpenPricesApiClient.submitPrice` change to send the derived `price_per`
  field (UNIT or KILOGRAM per the package unit), and for `RemotePrice` to
  parse `price_per` plus the product quantity, is **not yet implemented** --
  `submitPrice` still sends no `price_per` and `RemotePrice` parses only the
  basic fields. The package-size plumbing (model, v37 migration, recipe cost
  scaling, per-unit labels) landed under issue #309. See
  `ARCHITECTURE/PRICE_TRACKING.md`.
  (`lib/services/open_prices_api_client.dart`)

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

- **Recipe costs scale by package usage (issue #308)**:
  `calculateIngredientCost` now scales each ingredient's cost by the
  fraction of the package actually used. The package size is resolved in
  order: the price row's own package size, the product's packaging quantity
  (multi-pack strings parsed per-unit), then an inventory row for the
  barcode. When no size resolves or the units are incompatible, the full
  price is charged (legacy behavior). Cook-history costs use the same
  scoring path so detail, list, and cook views stay consistent.
  (`lib/providers/recipe_provider.dart`)

- **Statistics weight by held quantity (issue #308)**: total inventory
  value, average item price, and the DAO-level monthly-expenditure and
  store-spending queries multiply each latest price by the total quantity
  held, so mixed-currency inventories and multi-unit holdings reflect real
  stock.
  (`lib/database/price_dao.dart`)

### Fixed

- **Quick-add of the same product with a different expiry date (issue #296)**:
  adding a second instance with a different expiry date now creates a new
  inventory row instead of merging into the existing one and discarding the
  new expiry. `InventoryDao.insertOrMergeByBarcode` now merges only when the
  existing row is the same batch (same barcode, inventory, expiry date, unit,
  and location), using NULL-safe comparisons so items without an expiry still
  merge together but stay separate from dated batches. The add-to-pantry paths
  that bypassed the merge (product detail screen and search swipe-to-add) now
  go through the batch-aware merge via a new
  `ProductRepository.addOrMergeInventoryItem`, and the move-to-inventory flow
  in `ShoppingListProvider` merges only into undated rows. A new v36 migration
  replaces the unique index on `inventory(barcode, inventory_id)` with a
  non-unique index (kept for query performance), since the unique constraint
  made multiple batches per barcode impossible.
  (`lib/database/inventory_dao.dart`,
  `lib/database/migrations/v36_nonunique_inventory_index.dart`,
  `lib/services/product_repository.dart`,
  `lib/screens/product_detail_screen.dart`,
  `lib/widgets/search_panel.dart`,
  `lib/providers/shopping_list_provider.dart`)

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

- Price calculator formatter leading-zero fix; bottom-sheet safe-area and
  keyboard handling; unified price input formatter for new and edit modes.

## [0.0.6]

- Expiry notifications show the product name (fixes #125); "from your pantry"
  quick-pick suggestions (fixes #68); monthly spending, spending-by-store and
  Nutri-Score-by-store charts (fixes #33); barcode-less produce with PLU entry,
  USDA fallback and quick-add carousel (fixes #113); per-inventory shopping
  list (fixes #111); price tracking and move-to-inventory on the shopping list
  (fixes #36, #38); persistent store autocomplete (fixes #69).

## [0.0.5]

- Early-release polish and fixes: translation leak on product detail
  (fixes #87), camera scanner error loop and permission handling, torch /
  zoom / tap-to-focus, lifecycle-aware scanner overlay, thumbnail-driven
  search results, category-based expiry suggestions, OFF product submission,
  CSV export/import, multi-inventory, accessibility, and code-health work.

## [0.1.0] — Initial release (MVP)

- Barcode scanning, Open Food Facts v3 lookup, offline-first SQLite caching,
  expiry tracking with local notifications, nutrition tables and ingredients;
  product management with manual entry and OFF submission; dark mode,
  settings, and CSV export/import; three-table schema with DAOs and
  configurable stale-entry cleanup.
