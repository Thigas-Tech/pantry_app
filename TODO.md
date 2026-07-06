# TODO.md — Pantry App Roadmap

Items ordered: CI/CD first, then low-to-high effort. Features requiring paid
infrastructure or external server hosting are listed last.

---

## CI/CD & DevOps (top priority)

- [ ] **GitHub Actions — CI pipeline** — on every PR and push to `main`:
  - `flutter analyze` (lint check)
  - `dart format --set-exit-if-changed .` (formatting check)
  - `flutter test --concurrency=8 --coverage` (tests + coverage report)
  - Upload coverage artifact, fail if tests fail.
- [ ] **GitHub Actions — Play Store deployment** — on new tag (`v*`):
  - `flutter build appbundle` + `flutter build apk` (release)
  - Upload both to Google Play Console via `r0adkll/upload-google-play`
  - Requires Play Store service account JSON stored as a GitHub secret.
- [ ] **GitHub Actions — Patrol E2E on schedule** — weekly run of the Patrol
  test suite on a real Android emulator (GitHub‑hosted runner).
- [ ] **GitHub Actions — Flashlight performance regression** — run
  [Flashlight](https://github.com/bamlab/flashlight) on a physical device or
  emulator in CI. Store baseline scores (FPS, CPU, GPU, memory) as CI
  artifacts. Compare PR scores against main branch. Block merging if scores
  degrade >10%.
- [ ] **GitHub Actions — Perfetto trace analysis** — collect Perfetto traces
  during key user flows (home screen scroll, product detail navigation,
  scanner start). Parse with `perfetto` CLI for frame timing violations,
  jank metrics, and CPU scheduling patterns. Fail CI if metrics degrade below
  baseline. Reference: [Flutter performance profiling](https://docs.flutter.dev/perf/ui-performance).

---

## Low Effort

- [x] **Batch delete** — multi-select items via checkboxes, delete all
  selected. Reuses existing `deleteInventoryItem` + undo snackbar.
- [x] **Expiry date guard** — date picker already uses
  `firstDate: DateTime.now()`. Verified correct.
- [x] **Quick quantity adjustment** — `+/−` buttons on each inventory tile in
  `ProductDetailScreen`. Tap quantity to type a number directly. Decrementing
  to 0 deletes the item with confirmation + undo. Re-schedules notifications
  on restore.
- [x] **Coverage: `stats_screen.dart`** (83.6%) — test export + import button
  flows.
- [x] **Coverage: `home_screen.dart`** (72.2%) — test create-pantry dialog,
  batch delete.
- [x] **Coverage: `add_product_screen.dart`** (85.3%) — test form validation +
  save-and-pop.
- [x] **Coverage: `add_to_inventory_screen.dart`** (94.0%) — test custom
  unit/location dialogs.
- [x] **Coverage: `inventory_card.dart`** (87.7%) — test tap navigation, image
  cache miss.
- [x] **Coverage: `connectivity_provider.dart`** (33.3%) — stream emission
  test.
- [x] **Extract expiry-date parsing** — duplicated in `home_screen.dart`,
  `product_detail_screen.dart`, `inventory_card.dart`. Extracted to
  `utils/date_helpers.dart`: `parseExpiryDate()`, `isExpired()`,
  `isExpiringSoon()`.
- [x] **Deduplicate custom picker dialogs** — extracted
  `_showCustomInput(title, onPicked)` shared by both.
- [x] **Deduplicate settings dialogs** — extracted
  `_showDaysDialog(title, initialValue)` shared by both.
- [x] **Screenshots section** — removed placeholder table; added single‑line
  placeholder.
- [x] **Remove unused `product_api_service.dart`** — removed;
  `ProductRepository` now uses `OpenFoodFactsApi` directly. `close()` method
  removed from `OpenFoodFactsApi`.
- [x] **Golden tests for `NutriScoreBadge`** — verify A–E colours render
  correctly via `matchesGoldenFile`.
- [x] **Accessibility audit** — added Semantics label to NutriScoreBadge; 5
  semantics tests verify labels for grades a–e, null, and invalid.
- [x] **Flutter widget catalog review** — audited Material 3 widgets. New
  candidates added below.
- [x] **Performance optimization reference doc** — added section 11 to
  `ARCHITECTURE.md` documenting: dark mode energy savings, image caching
  rationale, offline-first, `RepaintBoundary` strategy, thread strategy,
  AAB/deferred components, eco-mode pattern, and performance measurement.

### Performance audits

- [x] **Repaint boundaries audit** — wrap animated or independently-scrolling
  widget subtrees with `RepaintBoundary`. Audit `HomeScreen._InventoryList`
  (scroll), `SearchScreen` results list, `StatsScreen` charts. Reference:
  [Flutter Performance Best Practices](https://docs.flutter.dev/perf/best-practices).
- [x] **`ListView.builder` audit** — audit all uses of `ListView()` across
  screens. The default `ListView(children: [])` builds ALL children at once
  (O(n) build cost), causing jank on large lists. Convert to
  `ListView.builder` or `ListView.separated` where item count exceeds ~10 or
  is dynamic. Priority: `home_screen.dart` inventory list,
  `product_detail_screen.dart` inventory tiles, `stats_screen.dart` stat
  rows. `search_screen.dart` already uses `ListView.separated`.
- [x] **Confine setState audit** — extract stateful logic into small isolated
  widgets so `setState` does not rebuild the entire parent screen. Audit 32
  `setState` calls; highest impact: `PantryShell._onPageChanged` (rebuilds
  entire PageView on every swipe), `HomeScreen._searchQuery`,
  `HomeScreen._selectedItems`, `StatsScreen._refreshKey`. Pattern: extract
  `ScrollToTopButton`-style widgets that call their own `setState` only when
  visibility actually changes.
- [x] **Image resolution audit** — check network images are requested at
  display resolution, not full size. OFF CDN images are loaded at full
  resolution (~200 KB) and scaled to 40x40 dp on cards or full-width on
  detail screens, wasting memory and decode time. Check if OFF API supports
  resize parameters.
- [x] **Impeller usage check** — verify Impeller is enabled for release
  builds (`--enable-impeller`). Impeller is default on Android API 29+;
  verify it is not disabled in `AndroidManifest.xml`.
- [x] **Tree shaking audit** — run `flutter build apk --analyze-size` and
  inspect the app size breakdown. Verify unused packages, assets, and fonts
  are stripped. Remove any dead dependency imports.
- [x] **Asset optimization audit** — convert remaining PNG assets to WebP
  with lossless encoding. Check if bundled fonts can be subsetted to only
  used glyphs. Verify `pubspec.yaml` font declarations are minimal.
- [x] **Expensive raster ops audit** — check for widgets that trigger
  `saveLayer` on the raster thread: `ShaderMask`, `Opacity` (alpha < 1.0),
  `ClipPath`, `ColorFiltered`, multiple `ClipRRect` instances. Only 1
  `ClipRRect` found (`add_product_screen.dart`) — low priority but verify.
  Reference: [Flutter Performance Best Practices](https://docs.flutter.dev/perf/best-practices#minimize-use-of-opacity-and-clipping).

### UI polish

- [ ] **Dark mode nudge for AMOLED** — show a one-time prompt to AMOLED
  users suggesting dark mode (up to 60% less power with black pixels).
  Detect via `MediaQuery.platformBrightness` at launch.
- [ ] **SegmentedButton** — replace `FilterChip` row on home screen with
  `SegmentedButton` for multi-category selection.
- [x] **Autocomplete** — add autocomplete suggestions to the home screen
  search bar based on cached product names.
- [x] **InteractiveViewer** — enable pinch-to-zoom on product
  nutrition/ingredient photos.
- [x] **ExpansionTile in settings** — group related settings (notifications,
  data retention) under `ExpansionTile`.
- [ ] **DropdownMenu** — replace `PopupMenuButton` for inventory switcher
  with M3 `DropdownMenu`.

### Documentation

- [x] `ARCHITECTURE.md` — add security section.
- [x] `ARCHITECTURE.md` — add offline-first pattern diagram.
- [x] `AGENTS.md` — add "always check TODO.md before starting new work".
- [ ] **Small-screen golden tests** — add golden tests for screens rendered
  at 360dp and with large accessibility font sizes. Verify no overflow on:
  `ProductDetailScreen`, `HomeScreen`, `SettingsScreen`, `StatsScreen`.
  Reuse pattern from `nutriscore_badge_golden_test.dart`.
- [ ] **NFC‑e reference doc** — create `lib/docs/nfce_reference.md` with
  complete technical reference (QR code URL formats, state variations,
  v2 vs v3, parsing approach, open‑source tools).

---

## Medium Effort

### Code health

- [ ] **SearchBar/SearchAnchor upgrade** — replace manual `TextField` in
  SearchScreen and HomeScreen with M3 `SearchBar`/`SearchAnchor` for native
  autocomplete and animation.
- [ ] **Thread strategy audit** — identify heavy work that blocks the UI
  thread: OFF API JSON parsing, CSV import/export processing, image
  encoding. Offload to `Isolate` / `compute()` where beneficial. sqflite
  already runs on a background isolate internally.
- [ ] **NavigationRail** — adaptive sidebar layout for tablets/desktop
  alongside `NavigationBar`.
- [ ] **Repaint boundary enforcement** — add a lint rule or architecture doc
  requiring `RepaintBoundary` on widget subtrees that scroll independently,
  animate repeatedly, or sit inside `ListView`/`GridView` with many items.
  Never wrap entire screens.

### Feature development

- [x] **Changelog at startup** — detect app update via existing
  `_handleAppUpdate()` scaffolding (`package_info_plus` +
  `SharedPreferences` `app_version` key). On first launch after update, show
  a `WhatsNewDialog` or bottom sheet with new entries from `CHANGELOG.md`.

  **Implementation**:
  1. Create `lib/widgets/whats_new_dialog.dart` — reads CHANGELOG.md, parses
     entries by version, filters to unseen versions.
  2. Modify `main.dart` to set `changelog_last_seen` SharedPreferences key
     separate from `app_version`.
  3. In `PantryShell` init, check flag and show dialog once.
  4. New ARB strings: `whatsNew`, `dismiss`.
  5. Tests: verify dialog appears on version change, doesn't on same
     version, doesn't on first install.

  **Pitfalls & edge cases**:
  - **Missing file**: `rootBundle.loadString('CHANGELOG.md')` throws
    `FlutterError`. Bundle a fallback JSON file instead of parsing
    markdown, or check `File.exists()` first.
  - **`flutter_markdown` discontinued**: Official package last updated at
    0.7.x; community forks exist (`flutter_markdown_plus`). Consider a
    simple line‑based parser for version extraction instead of a full
    markdown renderer.
  - **Markdown parser crashes**: Known assertion failures with malformed
    inline elements. Always wrap in `FlutterError` boundary.
  - **Memory on large CHANGELOG**: Full markdown builds a complete AST in
    memory. Keep displayed content short (last 2–3 versions max).
  - **First install**: Don't show changelog on first install (no
    `app_version` in prefs). Only show on detected version change.
  - **Accumulated versions**: User may skip multiple releases. Show all
    entries from `last_seen` to `current`, not just the latest.
  - **Inline HTML**: `flutter_markdown` does not support inline HTML
    (`<br/>`, `<div>`). Strip or escape before rendering.
  - **No `CHANGELOG.md` in release bundle**: Ensure `pubspec.yaml` includes
    `assets: [CHANGELOG.md]` or switch to a bundled JSON release‑notes file.

- [ ] **Product name translations** — pass `lc=<app_locale>` to OFF API v3.
  `product_name` and `ingredients_text` return in the user's locale. Brands
  are **never translated** (proper nouns/trademarks). Add
  `brand_name_overrides` alias map for edge cases.

  **Implementation**:
  1. Add `lc` and `tags_lc` query parameters to
     `OpenFoodFactsApi.getByBarcode()` and `searchProducts()`.
  2. Extract locale from `Localizations.localeOf(context).languageCode` (or
     `PlatformDispatcher.instance.locale.languageCode` for non‑widget code).
  3. Add `lang` field to `Product` model (persisted in DB).
  4. Add `brand_name_overrides` JSON map to `Product` model + seed data in
     `ProductDao`.
  5. Add display helper `resolveBrandName()` in `Product` extension.
  6. DB migration: add `products.lang` column (bundle with version 9).
  7. Tests: mock API responses with `lc=fr`, verify French name returned;
     verify brand names preserved.

  **Pitfalls & edge cases**:
  - **Silent fallback**: If no translation exists for the requested `lc`,
    OFF silently returns the product's default language. Always display the
    returned value — it may be in a different language.
  - **`Platform.localeName` is unreliable**: Returns `null` on iOS first
    launch; never updates on Android at runtime. Use
    `Localizations.localeOf(context).languageCode` instead.
  - **Locale string mismatch**: Dart `Locale.languageCode` returns ISO
    639-1 (`"en"`). This is correct for OFF. But `locale.toString()` gives
    `"en_US"` which OFF doesn't understand. Always use `.languageCode`.
  - **`und` locale**: `PlatformDispatcher.locale` returns
    `Locale.fromSubtags(languageCode: "und")` when the device locale list is
    empty. Validate: `if (code.isEmpty || code == 'und') code = 'en'`.
  - **`lc` without `tags_lc`**: Product name may come in the right language
    but category/label taxonomy names remain in default language. Always
    pass both: `{'lc': lang, 'tags_lc': lang}`.
  - **Empty product name**: Fall back to product's `_id` (barcode).
  - **Search API legacy endpoint**: `cgi/search.pl` may not support `lc`
    identically to v3. Test before deploying. Accept mixed-language search
    results if needed.
  - **Brand alias map maintenance**: Add mechanism to update without app
    updates (remote config, or seed file in assets). Start with known cases
    (Hungry Jack's → Burger King in Australia, Quick → Burger King in
    Belgium).
  - **CORS on Flutter Web**: Open bug #1089 — OFF API lacks CORS headers.
    Blocked on web irrespective of `lc`. Not actionable here.
  - **iOS unsupported locale**: `PlatformDispatcher.locale` on iOS returns
    the OS language even when not in `supportedLocales`. Handle silently.

- [ ] **Ingredients translations + allergen localization** — same `lc`
  parameter renders `ingredients_text` in the user's locale. Show allergen
  highlighting via `ingredients_text_with_allergens_XX` when available. Add
  "show original" toggle.

  **Implementation**:
  1. Extend `OpenFoodFactsApi._parseProduct()` to extract
     `ingredients_text_with_allergens_XX` and `ingredients_text_languages`
     (requires `fields=ingredients_text_languages` in API call).
  2. Add `ingredientsTextLanguages` field to `Product` model
     (`Map<String, String>?`).
  3. DB migration: add `products.ingredients_text_languages` JSON column
     (version 9, bundled).
  4. On `ProductDetailScreen`, display ingredients in app's locale. Add
     toggle button "show original".
  5. When `ingredients_text_with_allergens_XX` is available, render
     allergens in bold/coloured.
  6. New ARB strings: `showOriginal`, `showTranslated`,
     `ingredientsInLanguage`.
  7. Tests: model, DAO, widget tests for language toggle and allergen
     highlighting.

  **Pitfalls & edge cases**:
  - **Allergen mistranslation is a safety hazard**: Display disclaimer —
    "Ingredients list is user‑contributed. Always check the product
    packaging for allergens."
  - **`ingredients_text_with_allergens_XX` is not always available**: Many
    products only have `ingredients_text`. When unavailable, fall back with
    no highlighting. Do not attempt to parse allergens yourself.
  - **Ingredients formatting varies by language**: The "show original"
    toggle must switch the entire text block, not per‑segment comparison.
  - **`ingredients_text_languages` field may be large**: 10+ language
    translations on some products. Store as JSON map in SQLite for now
    (<5 KB typical); consider separate `product_translations` table if
    >100 KB becomes common.
  - **"Show original" needs the product's `lang`**: If `lang` is `null` or
    empty, fall back to first non‑empty language in
    `ingredients_text_languages`, then English, then raw text.
  - **Only request translations on detail screen**: `fields` adds payload
    size. Do not request during search/list views.
  - **Allergen formatting varies**: Use lightweight parser for basic
    bold/color markup; avoid heavyweight `flutter_html` if possible.

- [ ] **Shopping list** — tab or separate screen; mark items as "to buy"
  with a toggle. Items appear in a dedicated list until purchased (then
  move to inventory).
- [ ] **Barcode history** — show the last N scanned barcodes with quick-add
  button. Persist to SQLite.
- [ ] **Empty-pantry onboarding** — when inventory is empty, show a guided
  "scan your first item" flow instead of just the empty state widget.
- [ ] **Offline-first product submission queue** — queue `submitProduct`
  calls when offline; flush when `connectivityProvider` emits `true`.
- [ ] **WHO-based food quality recommendations** — research complete:
  ADI-based additive safety warnings, non‑sugar sweetener health guidance,
  free‑sugar threshold alerts (5 g per 100 g), sodium level awareness labels
  (low/medium/high per WHO thresholds), balanced diet prompts, and Five
  Keys to Safer Food tips.
- [ ] **Cosmetics & toiletries support** — extend OFF API integration to
  query Open Beauty Facts (`openbeautyfacts.org`), add `productType` to the
  `Product` model (`'food'` / `'beauty'` / `'petfood'`), add
  cosmetic‑specific fields (periodAfterOpening, beauty category), hide
  nutrition/Nutri‑Score for non‑food items, and add filter chips on the
  home screen.
- [ ] **Custom eco-mode** — implement `EcoModeNotifier` (similar to
  `ThemeModeNotifier`) with a toggle in Settings. When enabled: reduce
  animation complexity, throttle network refresh interval, disable
  non-essential haptic feedback. Detect battery level via `battery_plus`
  and suggest eco-mode when low. New ARB strings: `ecoMode`,
  `ecoModeDescription`, `ecoModeBatteryTip`.
- [ ] **Flashlight local development setup** — install and configure
  [Flashlight](https://github.com/bamlab/flashlight) CLI for local
  performance testing. Run baseline tests and store results in
  `test/performance/`. Document compare workflow
  (`flashlight report bad.json good.json`). Reference: Flutter Heroes
  2025 talk (Alexandre Moureaux, BAM).
- [ ] **Deferred components (Android dynamic features)** — split the app
  into on-demand APK modules: (1) scanner, (2) OFF API + search, (3)
  import/export. Users only download modules they use. Requires
  `dynamicFeature` in `build.gradle` and `split` attributes in
  `AndroidManifest.xml`. Reference: [Flutter Deferred Components](https://docs.flutter.dev/perf/deferred-components).

### Database migrations

- [ ] **DB version 9: prices table + lang and multilingual fields** — bundle
  into a single migration:
  - New table: `prices`
  - New columns on `products`: `lang TEXT`, `product_name_languages TEXT`
    (JSON), `ingredients_text_languages TEXT` (JSON)
  - Migration must handle: existing rows get `NULL` for new columns (safe
    defaults), `prices` table created fresh.
  - Rollback: keep old column defaults so downgrade doesn't crash (code
    should handle `NULL`).

  **Pitfall**: Schema changes for products table must not disrupt existing
  data. All new columns are nullable — no `NOT NULL` or `DEFAULT` on
  existing rows. `_onUpgrade` runs in a transaction; test on a copy of a
  real database.

---

## High Effort — Free

- [ ] **Multi‑language support** — ARB infrastructure exists; add
  translations (pt, fr, es, de). Contribute via community PRs.
- [ ] **Widget test → golden coverage** — product detail, settings, stats
  screens.
- [ ] **Remake notification feature from scratch** — rewrite
  `NotificationService` for reliability: precise expiry‑day‑at‑morning and
  expiry‑soon (N days before) scheduling, multi‑item grouping,
  per‑inventory notification channels, proper timezone handling, and
  resilient rescheduling on app boot.
- [ ] **Remake import/export from scratch** — rewrite `CsvService` to
  support: export only cached (API-fetched) products, export a specific
  inventory, export products from a specific inventory, and import via
  `filegate` (platform file picker). Replace the stats-screen picker with a
  streamlined FileGate-based flow.
- [ ] **Recipe suggestions** — call a recipe API with items expiring this
  week; suggest meals that use them. Coordinate with Samsung Food meal
  planning integration below — if both are implemented, Samsung Food can
  serve as the meal planning UI layer and recipe source, while the generic
  recipe API provides wider coverage in regions where Samsung Food is
  unavailable.
- [ ] **Patrol E2E tests** — real‑device integration tests via
  [Patrol](https://patrol.leancode.co). Uses `patrol_cli` and `patrol`
  dev-dependency. Replace the generic `integration_test/` with
  `patrol_test/` directory.

  **Test scenarios**:
  1. **Setup** — install `patrol_cli`, add `patrol` to `dev_dependencies`,
     configure `pubspec.yaml`, create `patrol_test/`.
  2. **Scan → add to inventory** — tap FAB, simulate barcode scan, verify
     product detail appears, add item, verify home screen shows it.
  3. **Offline scan → manual entry** — simulate offline, scan barcode,
     verify manual entry screen opens, fill form, save, verify cached.
  4. **Quantity adjustment flow** — open product detail, tap + 3x, verify
     quantity, tap - to 0, confirm delete, verify item gone.
  5. **Notification flow** — add item with expiry tomorrow, background
     the app, advance time, verify notification appears.
  6. **Inventory switch** — tap dropdown, select different pantry, verify
     items change.
  7. **CSV export → import round‑trip** — export inventory, import the
     same CSV, verify item count.

- [ ] **Low-end device testing program** — test the app on a physical
  low‑end Android device (Samsung A10s or equivalent, 2 GB RAM) after
  every major feature. Dev machines (M2 Pro, 32 GB RAM) are 10x+ faster
  than real user devices. Document baseline metrics: home screen scroll
  fps, product detail open time, search result render time, barcode scan
  init time. Reference: [Flutter Performance Best Practices](https://docs.flutter.dev/perf).
- [ ] **Remove functional debt** — audit for features that have been
  superseded, unused code paths (dead code after refactors), outdated API
  endpoints. Older app versions with unused features cost server-side (API
  calls from orphaned clients) and client-side (larger APK, more rebuilds).
- [ ] **EcoCode Flutter rules contribution** — create Flutter-specific
  EcoCode rules based on the [ecoCode project](https://github.com/cnumr/ecoCode).
  Publish as a standalone ruleset. Rules would cover: `ListView()` vs
  `ListView.builder`, `setState` scope, `ShaderMask` grouping, `compute()`
  for heavy parsing, and image resolution checking.

---

## Health Platform Integrations

- [ ] **Health Connect (Android) — nutrition read/write** — integrate
  Android Health Connect Jetpack (`v1.1.0+`) via
  `androidx.health.connect:connect-client`. Read/write `NutritionRecord`
  (calories, macros). Universal Android coverage (API 28+).

  **Implementation (Phase 1 — foundation)**:
  1. Add `health-connect-client` Flutter plugin or write platform channel
     in `android/app/src/main/kotlin/`. Audit pub.dev packages first.
  2. Create `lib/services/health_connect_service.dart` — wraps
     `HealthConnectClient` init, permission requests, CRUD operations.
  3. Define `HealthNutritionData` model (calories_kcal, protein_g, carbs_g,
     fat_g, fiber_g, timestamp, meal_type).
  4. Add `NutritionRecord` write — triggered when user logs a meal or adds
     an item to inventory with known nutrition data.
  5. Add `NutritionRecord` read — fetch today's totals from Health Connect
     for a nutrition dashboard.
  6. Request permissions on first write attempt (lazy permission model).
  7. New ARB strings: `healthConnectPermission`, `nutritionSynced`,
     `nutritionSyncFailed`, `todayCalories`.

  **Implementation (Phase 2 — meal logging)**:
  1. Add "Log Meal" button on `ProductDetailScreen`.
  2. Add "Today's Nutrition" summary card on `StatsScreen` or `HomeScreen`.
  3. Background sync: flush pending nutrition records when connectivity
     permits.

  **Pitfalls & edge cases**:
  - **Flutter plugin maturity**: The `health_connect` package on pub.dev
    may have incomplete `NutritionRecord` support. Audit source before
    committing. Be prepared to write a custom platform channel in Kotlin.
  - **Health Connect must be installed separately**: Not built into
    Android. `HealthConnectClient.getSdkStatus()` returns
    `SdkStatus.AVAILABLE` only when "Health Connect by Google" is installed
    from Play Store. If unavailable, show setup prompt with Play Store deep
    link. Do not crash.
  - **System permission sheet UX**: Health Connect uses a system-level
    permission sheet, NOT standard Android runtime permissions. User grants
    per-data-type access. This sheet cannot be styled. If user denies a
    type, writes to that type fail silently — always check
    `getGrantedPermissions()` before writing.
  - **No aggregation — raw records**: Writing breakfast and lunch produces
    two separate records. Implement idempotency: generate a deterministic
    `uid` from `product_barcode + timestamp + meal_type` and check for
    existing records before inserting.
  - **Uninstall = permanent data loss**: ALL stored data across all apps is
    deleted if user uninstalls Health Connect. Detect uninstall between
    launches and warn. Keep your own sync log in SQLite.
  - **Android backup excludes Health Connect**: After device restore,
    Health Connect starts empty. Detect "first launch after restore" and
    offer to re-sync.
  - **API 28 minimum**: Health Connect requires Android 9+. On API 27 and
    below, hide all Health Connect UI. SDK methods throw
    `UnsupportedOperationException` if called.
  - **Permission revocation at any time**: Before every write, re-check
    `getGrantedPermissions()`. Show snackbar with "Fix" button to open
    permission settings.
  - **Background sync restrictions**: Android 14+ limits background work.
    Use `WorkManager` with `PeriodicWorkRequest` (minimum 15‑minute
    interval). Test on Android 14+.
  - **Testing without physical device**: CI emulators (GitHub Actions)
    generally don't have Health Connect. Mock `HealthConnectClient` with
    `mocktail` in unit tests.
  - **NutritionRecord data model mismatch**: Health Connect uses `Energy`
    (kcal), `Mass` (g) for macros, and `MealType` enum. Map cleanly to
    `HealthNutritionData`. Use `MEAL_UNKNOWN` as fallback.

- [ ] **Samsung Health Data SDK — nutrition sync** — integrate Samsung's
  active Health Data SDK (NOT the deprecated SDK). Write
  `HealthConstants.Food` (calories) and `HealthConstants.Nutrition`
  (macros) to Samsung Health. Works on all Android phones with Samsung
  Health app 6.30.2+.

  **Implementation**:
  1. Create Android platform channel or use community Flutter plugin for
     Samsung Health Data SDK.
  2. Implement `HealthDataStore` connection lifecycle.
  3. Request permissions via `HealthPermissionManager` per data type.
  4. Build `InsertRequest` with `HealthDataResolver` to write food intake.
  5. Align with Health Connect abstraction: write to both platforms via the
     same `HealthNutritionData` model.
  6. New ARB strings: `samsungHealthPermission`, `samsungHealthConnected`.

  **Pitfalls & edge cases**:
  - **Deprecated SDK cut-off**: Old "Samsung Health SDK for Android" was
    deprecated as of 31 July 2025. Verify integration uses **Samsung Health
    Data SDK** (new). Migration guide: [developer.samsung.com](https://developer.samsung.com/health/data/migration-guide/overview.html).
  - **Samsung Health app must be installed AND at v6.30.2+**: If missing or
    outdated, `HealthDataStore.connectService()` fails. Show Play Store
    deep link.
  - **SI units only — no imperial**: `CALORIE` is in kcal (not cal),
    `WEIGHT` in kg (not lb). Convert before writing if app allows imperial
    display.
  - **Partner registration for write access**: Some data types require a
    [Partner Request](https://developer.samsung.com/SHealth/business-partner/m48wvqi1mt9w2w4c).
    Food/Nutrition may be restricted. Register early — approval can take
    weeks.
  - **Connection lifecycle is fragile**: Register a strong
    `HealthDataStore.ConnectionListener` that reconnects automatically.
    Test by force-stopping Samsung Health from Settings.
  - **Non-Samsung devices work too**: SDK works on any Android phone
    (Marshmallow+) with Samsung Health installed. Do not gate behind
    `Build.MANUFACTURER == "samsung"`.
  - **Disconnection on app background**: SDK auto-disconnects. Reconnect
    in `onResume()` or `onForeground()`.
  - **Threading**: All SDK callbacks run on a binder thread. Post results
    to main thread before updating UI. Failure causes
    `CalledFromWrongThreadException`.
  - **Data deduplication across platforms**: If Samsung Health syncs to
    Health Connect, writing to both creates duplicates. Check "Sync with
    Health Connect" setting before writing.
  - **Official docs links**:
    - [Health Data Store Guide](https://developer.samsung.com/health/android/data/guide/health-data-store.html)
    - [API Reference 1.5.1](https://developer.samsung.com/health/android/data/api-reference/overview-summary.html)
    - [Programming Guide](https://developer.samsung.com/health/android/data/guide/intro.html)
    - [FoodNote Sample](https://developer.samsung.com/health/data/sample/foodnote.html)

- [ ] **Samsung Food (formerly Whisk) — meal planning UX** — integrate
  Samsung Food's meal planning pattern (recipe saving, drag-and-drop weekly
  planner, auto-generated grocery lists). Uses Samsung Health Data SDK
  underneath for nutrition sync.

  **Implementation**:
  1. Research Samsung Food public API / integration points.
  2. Implement meal suggestion from expiring items (coordinate with Recipe
     suggestions item above).
  3. Add weekly meal plan UI: drag-and-drop items into day slots,
     auto-generate grocery list from planned meals.
  4. Write planned meals' nutrition data to Samsung Health via the SDK.
  5. New ARB strings: `mealPlan`, `weeklyPlanner`, `groceryList`,
     `addToPlan`.

  **Pitfalls & edge cases**:
  - **API access may require partnership**: Samsung Food's integration API
    may require business partnership. Research access requirements before
    scoping.
  - **Regional availability**: Not available in all countries. Check
    [samsungfood.com](https://samsungfood.com/). If unavailable, hide meal
    planning UI with "Not available in your region" message.
  - **Recipe suggestions overlap**: Decide whether to use Samsung Food as
    the recipe source or keep a generic recipe API for wider coverage.
  - **Data portability lock-in**: If user builds their weekly meal plan in
    Samsung Food, they cannot export. Consider export-to-SQLite option.
  - **Meal plan → grocery list → inventory conflict**: Samsung Food
    auto-generates grocery lists. Implement "mark as purchased" flow that
    cross-references with existing inventory items.
  - **Official docs links**:
    - [Samsung Food](https://samsungfood.com/)
    - [FoodNote Sample](https://developer.samsung.com/health/data/sample/foodnote.html)

- [ ] **Apple HealthKit (future iOS version)** — integrate HealthKit via
  `HKHealthStore` for reading/writing `HKQuantitySample` with
  `HKQuantityTypeIdentifier.dietaryEnergyConsumed` and related nutrition
  types. Minimum iOS 8.0+.

  **Implementation**:
  1. Add HealthKit capability in Xcode when building iOS.
  2. Use `health` Flutter package or platform channel for `HKHealthStore`.
  3. Request per-type permissions.
  4. Write nutrition records using same `HealthNutritionData` model.
  5. New ARB strings: `appleHealthPermission`, `healthKitSynced`.

  **Pitfalls & edge cases**:
  - **iOS-only**: Gate all HealthKit code behind
    `defaultTargetPlatform == TargetPlatform.iOS`.
  - **Entitlement provisioning**: Requires Apple Developer account (paid).
    Missing entitlement → `HKHealthStore.isHealthDataAvailable()` returns
    `false`.
  - **Per-type permission granularity — no bulk requests**: Request
    read/write for EACH data type individually. Maintain list and verify
    each is granted before writing.
  - **No cross-device sync without iCloud**: Detect iCloud Health sync
    status and surface in UI.
  - **Private medical data — no server transmission**: Apple guidelines
    prohibit transmitting to third-party servers without explicit consent.
  - **Simulator limitations**: Works on simulator but with restrictions.
    End-to-end testing requires physical device.
  - **Background delivery**: iOS may delay delivery for power management.
    Use foreground queries for dashboard.
  - **User can delete records from Health app**: Implement periodic
    reconciliation between SQLite log and HealthKit records.
  - **HealthKit data deletion on app uninstall**: All records written by
    your app are deleted per Apple's privacy model. Warn user.
  - **Official docs links**:
    - [HealthKit Framework](https://developer.apple.com/documentation/healthkit)

### Health platform abstraction layer

- [ ] **Health platform abstraction layer** — create a unified Dart
  interface `HealthService` with methods `writeNutrition()`,
  `readNutrition()`, `requestPermissions()`, `isAvailable()`. Implement for
  each platform: `HealthConnectService`, `SamsungHealthService`,
  `AppleHealthService`. Makes adding OEM platforms (Huawei Health Kit,
  Xiaomi Health Cloud, etc.) a matter of writing a new implementation
  class.

  **Reference architecture**:
  ```
  Your Pantry App
        │
        ▼
  HealthService (abstract interface)
        │
        ├── HealthConnectService (Android — universal)
        ├── SamsungHealthService (Android — Samsung Health app)
        └── AppleHealthService (iOS — future)
              │
              ▼
        Health platform's native SDK
  ```

  **Pitfalls & edge cases**:
  - **Platform channel complexity multiplies**: Each health SDK requires
    its own platform channel code. Use separate `MethodChannel` per service.
    Do NOT share a single channel for all health operations.
  - **Testing across platforms is hard**: Unit tests can mock the
    `HealthService` interface. Integration tests require real devices with
    Health Connect / Samsung Health / HealthKit installed. Keep in a
    separate `health_integration_test/` directory run manually.
  - **Cross-platform data deduplication**: If both Health Connect and
    Samsung Health are active AND Samsung Health syncs to Health Connect,
    writing to both creates duplicates. Detect cross-sync before writing.
  - **User consent fatigue**: Up to 3 permission sheets on first use.
    Stagger requests: Health Connect on first nutrition write, Samsung
    Health when user opens Samsung Health settings, HealthKit on first
    iOS nutrition dashboard visit.
  - **Privacy regulations (LGPD/GDPR)**: Health data is sensitive personal
    data. Get explicit consent, provide deletion mechanism, include in
    privacy policy.
  - **App store scrutiny**: Additional review requirements on Google Play
    and Apple App Store. Prepare documents before release.
  - **Error aggregation**: Create typed error classes per platform with
    clear user-facing messages. Never show raw SDK errors in UI.
  - **Feature flagging**: Each health platform integration should be behind
    a feature flag that can be disabled remotely or via debug menu.

### Quick-reference table

```
| Platform | Write | Nutrition | Meal Plan | Docs |
|----------|-------|-----------|-----------|------|
| Health Connect (Android) | Yes | Yes NutritionRecord | No | [developer.android.com](https://developer.android.com/health-and-fitness/health-connect) |
| Samsung Health Data SDK | Yes | Yes Food/Nutrition | Yes via Samsung Food | [developer.samsung.com](https://developer.samsung.com/health) |
| Samsung Food | N/A (via SDK) | Yes | Yes meal planner | [samsungfood.com](https://samsungfood.com/) |
| Apple HealthKit | Yes (future) | Yes dietary energy | No | [developer.apple.com](https://developer.apple.com/documentation/healthkit) |
| Huawei Health Kit | Yes | Yes limited | No | [developer.huawei.com](https://developer.huawei.com/consumer/en/hms/huawei-healthkit) |
| Xiaomi Health Cloud | Yes | limited | No | [dev.mi.com](http://developer.mi.com) |
| OPPO Health | Yes | limited | No | [open.oppomobile.com](https://open.oppomobile.com/) |
| vivo Health Kit | Yes | limited | No | [developers.vivo.com](https://developers.vivo.com/) |
| Honor Health Kit | Yes | limited | No | [developer.honor.com](https://developer.honor.com/) |
```

---

## Server-Dependent / Paid Services (last)

Items that require paid hosting, external server infrastructure, or cloud
storage costs.

- [ ] **Product prices + inventory total value** — new `prices` SQLite
  table, `PriceDao`, `Price` freezed model. Dual-source: local user‑entered
  prices and Open Prices API (`prices.openfoodfacts.org`). Price badge on
  `InventoryCard` (unit price), `InventoryTile` (price + store), total
  value in `StatsScreen`. Price editing via bottom sheet. Open Prices
  submissions upload proof photo.

  **Implementation (Phase 1 — local‑first)**:
  1. Create `Price` model (`lib/models/price.dart`).
  2. Create `prices` table schema: `id INTEGER PK`, `barcode TEXT FK
     products`, `price REAL`, `store TEXT`, `date INTEGER`, `currency
     TEXT`, `proof_image_path TEXT`, `source TEXT` (`'local'` /
     `'open_prices'`).
  3. Create `PriceDao` with CRUD.
  4. Add unit‑price badge to `InventoryCard`.
  5. Add price + store display on `ProductDetailScreen._InventoryTile`.
  6. Add total inventory value to `StatsScreen`.
  7. Price editing bottom sheet (long‑press on inventory tile).
  8. DB migration version 9 (bundled with other schema changes).

  **Implementation (Phase 2 — Open Prices API)**:
  1. Create `lib/services/open_prices_api.dart` — HTTP client.
  2. Fetch prices by barcode: `GET /api/v1/prices?barcode={barcode}`.
  3. Submit prices: `POST /api/v1/prices` with proof photo and Bearer
     token.
  4. Create `PriceService` combining local DB + API (local wins).
  5. Queue offline price submissions; flush when connectivity returns.
  6. Tests: model, DAO, service, widget tests.

  **Pitfalls & edge cases**:
  - **Open Prices has NO documented rate limits**: Assume ~15 req/min.
    Always set `User-Agent` header: `AppName/Version (contact@email)`.
  - **Photo proof is MANDATORY**: Every submission requires a photo of the
    price tag/receipt. Adds camera permission, storage, and network
    overhead.
  - **Environment‑specific tokens**: Auth tokens differ between
    `prices.openfoodfacts.org` (prod) and `prices.openfoodfacts.net`
    (pre‑prod). Use `--dart-define` flavors.
  - **License obligations**: Open Prices data is OdBL-licensed. Must
    attribute Open Food Facts. User contributions must be contributed back
    under OdBL. Cannot mix with proprietary price databases.
  - **Data quality**: "No guarantees for accuracy." Display disclaimer.
  - **Currency handling**: Default to `BRL` for Brazilian users, `USD`
    otherwise. No currency conversion — display in original.
  - **Multiple prices for same product**: Show most recent local price;
    fall back to most recent from Open Prices.
  - **Decimal precision**: Store as `double` but format with locale‑aware
    `NumberFormat.currency()`.
  - **Offline submission queue**: Proof photos can be large (MBs). Queue
    with `connectivityProvider`. Handle retry.
  - **Privacy**: Open Prices opt‑in with explicit consent dialog.
    Local‑only prices work offline and never leave the device.
  - **Proof photo storage**: Store in app‑local directory; delete after
    successful upload.
  - **HTTP 503 from infra**: Implement exponential backoff with jitter (1s,
    2s, 4s, max 60s). Distinguish from service downtime via
    `status.openfoodfacts.org`.
  - **User‑entered vs API conflict resolution**: Local wins. Show both in
    detail view: "Your price: $4.99 | Store average: $5.20."

- [ ] **NFC‑e importing from QR code** — detect NFC‑e QR URLs on the
  scanner screen (pattern `fazenda.*/nfce/qrcode`). Fetch SEFAZ page via
  HTTP GET. Parse product items from DANFE HTML using `package:html`. Map
  items to `Product` + `InventoryItem`. Show review screen with checkboxes
  and quantity edits before importing. Phase 2: dedicated backend service
  (nfce-scraper Docker).

  **Implementation (Phase 1 — in‑app scraping)**:
  1. Add `html` package to `pubspec.yaml`.
  2. Create `lib/services/nfce_service.dart` — validate NFC‑e URL, HTTP
     GET SEFAZ page, parse DANFE HTML table rows.
  3. Create `NfceItem` model (description, quantity, unit, unit_price,
     total).
  4. Detect NFC‑e QR code on `ScannerScreen` or add "Import NFC‑e" button
     on home screen.
  5. Show review screen: list of parsed items with checkboxes +
     quantity/price edits.
  6. On confirm: `upsertProduct` + `addInventoryItem` for each checked
     item.
  7. New ARB strings: `importNfce`, `nfceItemCount`, `nfceImportSuccess`,
     `nfceImportFailed`, `nfceParseError`.
  8. Create `lib/docs/nfce_reference.md`.

  **Implementation (Phase 2 — backend service, costs hosting)**:
  - Deploy `nfce-scraper` (Python FastAPI) as Docker service.
  - Flutter sends QR URL → backend returns JSON.
  - Backend handles multi‑state HTML variations.

  **Pitfalls & edge cases**:
  - **25+ Brazilian states, each with unique HTML structure**: Build
    state‑detection layer and route to state‑specific parsers. Start with
    the most common states.
  - **SEFAZ can change HTML structure at any time**: Scraping is
    inherently fragile. Implement `version` field in parser; log raw HTML
    on failure.
  - **`package:html` O(n²) tokenizer on large invoices**: Confirmed open
    issue (`dart-lang/html#18`). Use `parseFragment()` instead of
    `parse()`. Consider chunk‑based processing.
  - **QR code v2 vs v3 format**: v3 mandatory from Sep 2025. Parse URL
    parameters to determine version.
  - **Offline contingency QR codes** (`tpEmis=9`): Extra fields, different
    content/layout. Handle gracefully.
  - **No barcode on NFC‑e items**: Map to `Product` with
    `source: 'manual'` and generated ID. Cache by description hash.
  - **Duplicate detection**: Show warning in review screen. Let user
    choose: skip, add as new, or increment quantity.
  - **Network errors fetching SEFAZ page**: Show loading with 10s timeout.
    Retry once, then show error with "Try again" button.
  - **Encoding**: Brazilian Portuguese uses ISO‑8859-1 / Latin-1 in some
    SEFAZ pages. Detect charset from HTML `<meta>` tag or Content-Type
    header. Convert to UTF‑8 before parsing.
  - **Privacy**: NFC‑e URLs may encode consumer's CPF. Warn user before
    fetching. Never cache raw HTML.
  - **Large invoices (50+ items)**: Use `ListView.builder` on review
    screen. Show progress indicator during parsing.
  - **HTML5 "error recovery"**: `package:html` silently "fixes" malformed
    HTML (auto‑closes tags, injects `<tbody>`). Test against real SEFAZ
    pages with fixture files.
  - **State‑specific error pages**: Detect error keywords in response.
    Show descriptive error in user's language.
  - **Rate limiting by SEFAZ**: Add 1‑second delay between fetch and
    retry.

- [ ] **Cloud backup** — upload DB to Firebase Storage / S3. Restore on a
  new device. **Costs**: Firebase Storage ($0.026/GB stored, $0.12/GB
  transferred) or S3 ($0.023/GB). Ongoing hosting expense.
- [ ] **Backend for Frontend (BFF) evaluation** — evaluate offloading OFF
  API response transformation (JSON → freezed model mapping) to a
  lightweight backend service. Tradeoff: reduces client CPU but adds
  **server cost**, deploy complexity, and latency. Only worthwhile when
  combined with other BFF benefits (API key hiding, response caching,
  multi-source aggregation). Defer final decision to post‑MVP.

### Documentation tied to paid features

- [ ] **Price tracking doc** — add section to `ARCHITECTURE.md`
  documenting local + Open Prices API data flow, conflict resolution, and
  proof‑photo requirement.

---

## Effort × Impact Matrix

```
                     Low effort ─────────── High effort
                     ─────────────────────────────────────
High impact      │ Batch delete            │ Shopping list
                 │ Quick quantity adjust   │ Offline submission queue
                 │ Expiry date guard       │ Changelog at startup
                 │ Expiry parsing extract  │ Product name translations
                 │ GitHub CI pipeline      │ Ingredients translations
                 │ Repaint boundaries      │ Health Connect nutrition sync
                 │ ListView.builder audit  │ Samsung Health Data SDK
                 │ Confine setState audit  │ Samsung Food meal planning
                 │ Image resolution audit  │ Health abstraction layer
                 │ Impeller check          │ Custom eco-mode
                 │ Tree shaking audit      │ Deferred components
                 │ Dark mode nudge         │ Patrol E2E tests
                 │ Thread strategy audit   │ Low-end device testing
                 │ Flashlight local setup  │ Remake notifications
                 │─────────────────────────│──────────────────────────
                 │ Golden tests            │ Multi-language support
                 │ Accessibility audit     │ Recipe suggestions
                 │ SearchBar upgrade       │ Widget golden coverage
                 │ Screenshots             │ Remake import/export
                 │ Empty-pantry onboarding │ Barcode history
                 │ Asset optimization      │ Cloud backup (paid)
                 │ Expensive raster ops    │ Product prices (paid)
                 │ EcoCode contribution    │ NFC-e importing (paid)
                 │ Small-screen golden     │ WHO food recommendations
 Low impact      │ Performance docs        │ Cosmetics/toiletries
                 │ NavigationRail          │ Apple HealthKit (future)
                 │                         │ Remove functional debt
                 │                         │ BFF evaluation (paid)
                 │                         │ OEM platforms (Xiaomi, etc.)
                 │                         │ Flashlight CI baseline
                 │                         │ Perfetto CI trace analysis
                 │                         │ Play Store CI deploy
```

---

## Summary of pitfalls documentation

Every feature item with an implementation plan includes a **Pitfalls & edge
cases** section covering:

| Category | Common examples |
|---|---|
| **API limitations** | Rate limits, silent fallbacks, undocumented behaviour, CORS |
| **Platform quirks** | iOS locale differences, Android background isolates, Windows locale bugs |
| **Data quality** | Missing translations, no accuracy guarantees, stale prices, different HTML structures |
| **Security/privacy** | NFC-e URLs with CPF, proof photos as PII, offline submission queuing |
| **Performance** | HTML parser O(n²), large markdown ASTs, DB size for multilingual fields |
| **UX edge cases** | First install vs update, accumulated version skips, partial imports, mixed-language results |
| **Dependency risk** | Discontinued packages (`flutter_markdown`), fragile scraping (SEFAZ), license obligations (OdBL) |
| **Safety** | Allergen mistranslation, dietary restriction implications, no authoritative translation claims |
