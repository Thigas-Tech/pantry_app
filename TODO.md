# TODO.md — Pantry App Roadmap

Items are organised by effort (low → high) and importance (critical → nice-to-have).

---

## Quick Wins (low effort, high impact)

- [x] **Batch delete** — multi-select items via checkboxes, delete all selected. Reuses existing `deleteInventoryItem` + undo snackbar.
- [x] **Expiry date guard** — date picker already uses `firstDate: DateTime.now()`. Verified correct.
- [x] **Quick quantity adjustment** — `+/−` buttons on each inventory tile in `ProductDetailScreen`. Tap quantity to type a number directly. Decrementing to 0 deletes the item with confirmation + undo. Re-schedules notifications on restore.
- [x] **Coverage: `stats_screen.dart`** (83.6%) — test export + import button flows.
- [x] **Coverage: `home_screen.dart`** (72.2%) — test create-pantry dialog, batch delete.
- [x] **Coverage: `add_product_screen.dart`** (85.3%) — test form validation + save-and-pop.
- [x] **Coverage: `add_to_inventory_screen.dart`** (94.0%) — test custom unit/location dialogs.
- [x] **Coverage: `inventory_card.dart`** (87.7%) — test tap navigation, image cache miss.
- [x] **Coverage: `connectivity_provider.dart`** (33.3%) — stream emission test.

## Code Health (low/medium effort)

- [x] **Extract expiry-date parsing** — duplicated in `home_screen.dart`, `product_detail_screen.dart`, `inventory_card.dart`. Extracted to `utils/date_helpers.dart`: `parseExpiryDate()`, `isExpired()`, `isExpiringSoon()`.
- [x] **Deduplicate custom picker dialogs** — extracted `_showCustomInput(title, onPicked)` shared by both.
- [x] **Deduplicate settings dialogs** — extracted `_showDaysDialog(title, initialValue)` shared by both.
- [x] **Screenshots section** — removed placeholder table; added single‑line placeholder.
- [x] **Remove unused `product_api_service.dart`** — removed; `ProductRepository` now uses `OpenFoodFactsApi` directly. `close()` method removed from `OpenFoodFactsApi`.
- [x] **Golden tests for `NutriScoreBadge`** — verify A–E colours render correctly via `matchesGoldenFile`.
- [x] **Accessibility audit** — added Semantics label to NutriScoreBadge; 5 semantics tests verify labels for grades a–e, null, and invalid.
- [x] **Flutter widget catalog review** — audited Material 3 widgets. New candidates added below.
- [ ] **SearchBar/SearchAnchor upgrade** — replace manual `TextField` in SearchScreen and HomeScreen with M3 `SearchBar`/`SearchAnchor` for native autocomplete and animation. Effort: medium.
- [ ] **SegmentedButton** — replace `FilterChip` row on home screen with `SegmentedButton` for multi-category selection. More compact on small screens. Effort: low.
- [ ] **Autocomplete** — add autocomplete suggestions to the home screen search bar based on cached product names. Effort: low.
- [ ] **NavigationRail** — adaptive sidebar layout for tablets/desktop alongside `NavigationBar`. Effort: medium.
- [ ] **InteractiveViewer** — enable pinch-to-zoom on product nutrition/ingredient photos. Effort: low.
- [ ] **ExpansionTile in settings** — group related settings (notifications, data retention) under `ExpansionTile` for a cleaner settings screen. Effort: low.
- [ ] **DropdownMenu** — replace `PopupMenuButton` for inventory switcher with M3 `DropdownMenu`. Effort: low.

## Features (medium effort)

- [ ] **Changelog at startup** — detect app update via existing `_handleAppUpdate()` scaffolding (`package_info_plus` + `SharedPreferences` `app_version` key). On first launch after update, show a `WhatsNewDialog` or bottom sheet with new entries from `CHANGELOG.md`.

  **Implementation**:
  1. Create `lib/widgets/whats_new_dialog.dart` — reads CHANGELOG.md, parses entries by version, filters to unseen versions.
  2. Modify `main.dart` to set `changelog_last_seen` SharedPreferences key separate from `app_version`.
  3. In `PantryShell` init, check flag and show dialog once.
  4. New ARB strings: `whatsNew`, `dismiss`.
  5. Tests: verify dialog appears on version change, doesn't on same version, doesn't on first install.

  **Pitfalls & edge cases**:
  - **Missing file**: `rootBundle.loadString('CHANGELOG.md')` throws `FlutterError`. Use `await File('CHANGELOG.md').exists()` first, or bundle a fallback JSON file instead of parsing markdown.
  - **`flutter_markdown` discontinued**: Official package last updated at 0.7.x; community forks exist (`flutter_markdown_plus`, `flutter_markdown_community`). Consider using a simple line‑based parser for version extraction instead of a full markdown renderer.
  - **Markdown parser crashes**: Known assertion failures in `flutter_markdown` with malformed inline elements (`'_inlines.isEmpty': is not true.`). Always wrap in `FlutterError` boundary.
  - **Memory on large CHANGELOG**: Full markdown builds a complete AST in memory. Keep displayed content short (last 2–3 versions max). Truncate the input string before parsing.
  - **First install**: Don't show changelog on first install (no `app_version` in prefs). Only show on detected version change.
  - **Accumulated versions**: User may skip multiple releases. Show all entries from `last_seen` → `current`, not just the latest.
  - **Inline HTML**: `flutter_markdown` does **not** support inline HTML (`<br/>`, `<div>`). Strip or escape before rendering.
  - **No `CHANGELOG.md` in release bundle**: Ensure `pubspec.yaml` includes `assets: [CHANGELOG.md]` or switch to a bundled JSON release‑notes file.

- [ ] **Product name translations** — pass `lc=<app_locale>` to OFF API v3. `product_name` and `ingredients_text` return in the user's locale. Brands are **never translated** (proper nouns/trademarks). Add `brand_name_overrides` alias map for edge cases like `"Hungry Jack's"` → `"Burger King"` in Australia.

  **Implementation**:
  1. Add `lc` and `tags_lc` query parameters to `OpenFoodFactsApi.getByBarcode()` and `searchProducts()`.
  2. Extract locale from `Localizations.localeOf(context).languageCode` (or `PlatformDispatcher.instance.locale.languageCode` for non‑widget code).
  3. Add `lang` field to `Product` model (persisted in DB).
  4. Add `brand_name_overrides` JSON map to `Product` model + seed data in `ProductDao`.
  5. Add display helper `resolveBrandName()` in `Product` extension.
  6. Update `ProductMerge.mergeFromApi` to preserve `lang`.
  7. DB migration: add `products.lang` column (bundle with version 9).
  8. Tests: mock API responses with `lc=fr`, verify French name returned; verify brand names preserved.

  **Pitfalls & edge cases**:
  - **Silent fallback**: If no translation exists for the requested `lc`, OFF silently returns the product's default `lang`. You cannot distinguish "translation missing" from "product's default matches the requested locale". Always display the returned value — it may be in a different language.
  - **`Platform.localeName` is unreliable**: Returns `null` on iOS first launch; returns `"en_US"` in test env; never updates on Android at runtime. Use `Localizations.localeOf(context).languageCode` or `PlatformDispatcher.instance.locale.languageCode` instead.
  - **Locale string mismatch**: Dart `Locale.languageCode` returns ISO 639-1 (`"en"`). This is correct for OFF. But if someone uses `locale.toString()` you get `"en_US"` (OFF doesn't understand). Always use `.languageCode`.
  - **`und` locale**: `PlatformDispatcher.locale` returns `Locale.fromSubtags(languageCode: "und")` when the device locale list is empty. Validate: `if (code.isEmpty || code == 'und') code = 'en'`.
  - **`lc` without `tags_lc`**: product name may be German but category/label taxonomy names remain in the product's default language. Always pass both: `{'lc': lang, 'tags_lc': lang}`.
  - **Empty product name**: Some products have `product_name: ""` in a language. Handle `null`/empty in `_parseProduct`; fall back to product's `_id` (barcode).
  - **Search API (`cgi/search.pl`)**: The legacy search endpoint may not support `lc` identically to v3. Test before deploying. If it doesn't work, accept that search results may be in mixed languages.
  - **Brand alias map maintenance**: Brand overrides are a curated list. Add a mechanism to update it without app updates (remote config, or seed file in assets). Start with known cases (Hungry Jack's → Burger King, Quick → Burger King in Belgium).
  - **CORS on Flutter Web**: Open bug #1089 — OFF API lacks CORS headers. Blocked on web irrespective of `lc`. Not actionable here but good to know.
  - **iOS unsupported locale**: `PlatformDispatcher.locale` on iOS returns the OS language even when not in `supportedLocales`. If user has system language set to `th` (Thai) and app only supports `en`/`pt`/`fr`, `lc=th` will return English fallback silently.

## Larger Projects (high effort)

- [ ] **Product prices + inventory total value** — new `prices` SQLite table, `PriceDao`, `Price` freezed model. Dual-source: local user‑entered prices and Open Prices API (`prices.openfoodfacts.org`). Price badge on `InventoryCard` (unit price), `InventoryTile` (price + store), total value in `StatsScreen`. Price editing via bottom sheet. Open Prices submissions upload proof photo.

  **Implementation (Phase 1 — local‑first)**:
  1. Create `Price` model (`lib/models/price.dart`).
  2. Create `prices` table schema: `id INTEGER PK`, `barcode TEXT FK products`, `price REAL`, `store TEXT`, `date INTEGER`, `currency TEXT`, `proof_image_path TEXT`, `source TEXT` (`'local'` / `'open_prices'`).
  3. Create `PriceDao` with CRUD.
  4. Add unit‑price badge to `InventoryCard` (similar to NutriScoreBadge).
  5. Add price + store display on `ProductDetailScreen._InventoryTile`.
  6. Add total inventory value to `StatsScreen`.
  7. Price editing bottom sheet (long‑press on inventory tile, enter price/store).
  8. DB migration version 9 (bundled with other schema changes).

  **Implementation (Phase 2 — Open Prices API)**:
  1. Create `lib/services/open_prices_api.dart` — HTTP client for `prices.openfoodfacts.org/api/`.
  2. Fetch prices by barcode: `GET /api/v1/prices?barcode={barcode}`.
  3. Submit prices: `POST /api/v1/prices` with proof photo and Bearer token.
  4. Create `PriceService` combining local DB + API (local wins on conflict, API as fallback).
  5. Queue offline price submissions; flush when connectivity returns.
  6. Tests: model, DAO, service, widget tests.

  **Pitfalls & edge cases**:
  - **Open Prices has NO documented rate limits**: The OFF rate limits page says "we currently don't have any rate limit policy" (GitHub issue #8818). Real risk of IP bans for aggressive requests. Assume ~15 req/min. Always set `User-Agent` header in the format `AppName/Version (contact@example.com)`.
  - **Photo proof is MANDATORY**: Every Open Prices submission requires a photo of the price tag/receipt. No way to submit a price without one. This adds camera permission handling, storage, and network overhead. Design the UI to support photo capture gracefully.
  - **Environment‑specific tokens**: Auth tokens differ between `prices.openfoodfacts.org` (prod) and `prices.openfoodfacts.net` (pre‑prod). Use `--dart-define` flavors to keep them separate. No documented token refresh — handle expiry with re‑authentication.
  - **License obligations**: Open Prices data is OdBL-licensed. You must attribute Open Food Facts as source. Any prices your users contribute must be contributed back under OdBL. You cannot mix with proprietary price databases.
  - **Data quality**: "No guarantees for accuracy, completeness, or reliability." Display a disclaimer: prices are community‑contributed and may be stale/incorrect.
  - **Currency handling**: Decide on default currency (`BRL` for Brazilian users, `USD` otherwise). Allow user override. No currency conversion — display in original currency.
  - **Multiple prices for same product**: Different stores, different dates. Show the most recent local price; if none, show the most recent from Open Prices. Let user choose which to display.
  - **Decimal precision**: Prices have varying decimal places (`R$ 1,99` vs `$ 1.999`). Store as `double` but format with locale‑aware `NumberFormat.currency()`.
  - **Offline submission queue**: Proof photos can be large (multiple MB). Queue submissions with `connectivityProvider`. Show pending count in UI. Handle submission failures with retry.
  - **Privacy**: User may not want to share their prices or receipts. Make Open Prices opt‑in with explicit consent dialog. Local‑only prices work offline and never leave the device.
  - **Proof photo storage**: Photos should be stored in app‑local directory and deleted after successful upload. Implement periodic cleanup for failed uploads.
  - **HTTP 503 from infra**: "503 Service Unavailable" is returned indiscriminately when global limits are exceeded. Implement exponential backoff with jitter (1s, 2s, 4s, max 60s). Distinguish from actual service downtime via `status.openfoodfacts.org`.
  - **User‑entered vs API conflict resolution**: If user enters a price manually and Open Prices has a different one, local wins. Show both in detail view: "Your price: $4.99 | Store average: $5.20."

- [ ] **NFC‑e importing from QR code** — detect NFC‑e QR URLs on the scanner screen (pattern `fazenda.*/nfce/qrcode`). Fetch SEFAZ page via HTTP GET. Parse product items from DANFE HTML using `package:html`. Map items to `Product` (create if new) + `InventoryItem` (add to active inventory). Show review screen with checkboxes and quantity edits before importing. Future: dedicated backend service (nfce-scraper Docker).

  **Implementation (Phase 1 — in‑app scraping)**:
  1. Add `html` package to `pubspec.yaml`.
  2. Create `lib/services/nfce_service.dart` — validate NFC‑e URL, HTTP GET SEFAZ page, parse DANFE HTML table rows.
  3. Create `NfceItem` model (description, quantity, unit, unit_price, total).
  4. Detect NFC‑e QR code on `ScannerScreen` or add "Import NFC‑e" button on home screen.
  5. Show review screen: list of parsed items with checkboxes + quantity/price edits.
  6. On confirm: `upsertProduct` + `addInventoryItem` for each checked item.
  7. New ARB strings: `importNfce`, `nfceItemCount`, `nfceImportSuccess`, `nfceImportFailed`, `nfceParseError`.
  8. Create `lib/docs/nfce_reference.md` — full NFC‑e technical reference from project documentation.

  **Implementation (Phase 2 — backend service)**:
  - Separate TODO item: deploy `nfce-scraper` (Python FastAPI) as Docker service.
  - Flutter sends QR URL → backend returns JSON.
  - Backend handles multi‑state HTML variations.

  **Pitfalls & edge cases**:
  - **25+ Brazilian states, each with unique HTML structure**: SEFAZ pages differ by state (SP, PR, RS, etc.). A parser that works for São Paulo may fail for Paraná. Build a state‑detection layer (from URL domain + QR code params) and route to state‑specific parsers. Start with the most common states.
  - **SEFAZ can change HTML structure at any time**: Scraping is inherently fragile. The pages are government systems that update unpredictably. Implement a `version` field in the parser; when a parse fails, log the raw HTML for debugging. The future backend service with a parser‑per‑state architecture mitigates this.
  - **`package:html` O(n²) tokenizer on large invoices**: Confirmed open issue (`dart-lang/html#18`) where string interpolation creates O(n²) behavior on long strings. Invoices with 50+ items may be slow. Use `parseFragment()` instead of `parse()` to avoid full document wrapper overhead. Consider chunk‑based processing for very large documents.
  - **QR code v2 vs v3 format**: v2 includes CSC hash fields; v3 (mandatory from Sep 2025) removes CSC. Parse the URL parameters to determine version. The extraction flow (HTTP GET → HTML parse) is identical for both — only the URL structure differs.
  - **Offline contingency QR codes** (`tpEmis=9`): Extra fields in the QR code URL (`day`, `total`). The SEFAZ page may have different content/layout for contingency invoices. Handle gracefully — if parse fails, show raw error and suggest manual entry.
  - **No barcode on NFC‑e items**: Many items lack EAN barcodes. Map to `Product` with `source: 'manual'` and a generated ID. The item description becomes the product name. Cache by description hash to avoid duplicates in the same import batch.
  - **Duplicate detection**: Item already exists in active inventory. Show a warning in the review screen. Let user choose: skip, add as new (duplicate), or increment quantity.
  - **Network errors fetching SEFAZ page**: SEFAZ servers can be slow/unavailable. Show loading with timeout (10s default). On failure, retry once, then show error with "Try again" button.
  - **Encoding**: Brazilian Portuguese uses ISO‑8859-1 / Latin-1 encoding in some SEFAZ pages. Detect charset from HTML `<meta>` tag or Content-Type header. Convert to UTF‑8 before parsing. `package:html` expects UTF‑8 input.
  - **Privacy**: NFC‑e URLs may encode the consumer's CPF (tax ID) in some states. Warn the user before fetching: "The QR code may contain personal information. The page will be fetched but not stored." Never cache the raw HTML.
  - **Large invoices (50+ items)**: Memory concern. The review screen builds a widget per item. Use `ListView.builder` with lazy loading. Show a progress indicator during parsing with item count.
  - **HTML5 "error recovery"**: `package:html` follows HTML5 spec and silently "fixes" malformed HTML (auto‑closes tags, injects `<tbody>`, etc.). The DOM you query may differ from the raw HTML structure. Test against real SEFAZ pages during development — include fixture files in tests.
  - **Partial import**: User unchecks some items. Only process checked items. If none checked, show "No items selected" snackbar.
  - **State‑specific error pages**: SEFAZ sometimes returns an HTML error page instead of the invoice (expired key, not found). Detect by checking for error keywords (`"não encontrada"`, `"inválida"`) in the response. Show descriptive error in user's language.
  - **Rate limiting by SEFAZ**: Government servers may throttle repeated requests from the same IP. Add a 1‑second delay between fetch and retry. The in‑app approach fetches from the user's device (one IP per user), which is less risky than a backend service.

- [ ] **Ingredients translations + allergen localization** — same `lc` parameter from product name translations renders `ingredients_text` in the user's locale. Show allergen highlighting via `ingredients_text_with_allergens_XX` when available. Add "show original" toggle to compare with the product's default language. Store `ingredients_text_languages` JSON on `Product` model for offline access in multiple languages.

  **Implementation**:
  1. Extend `OpenFoodFactsApi._parseProduct()` to extract `ingredients_text_with_allergens_XX` and `ingredients_text_languages` (requires `fields=ingredients_text_languages` in API call).
  2. Add `ingredientsTextLanguages` field to `Product` model (`Map<String, String>?`).
  3. Add `ingredientsTextWithAllergensLanguages` field (optional).
  4. DB migration: add `products.ingredients_text_languages` JSON column (version 9, bundled).
  5. Update `ProductMerge.mergeFromApi` to merge multilingual ingredient data.
  6. On `ProductDetailScreen`, display ingredients in app's locale. Add toggle button "show original" → switch to `lang` version.
  7. When `ingredients_text_with_allergens_XX` is available, render allergens in bold/coloured using a custom `IngredientText` widget.
  8. New ARB strings: `showOriginal`, `showTranslated`, `ingredientsInLanguage`.
  9. Tests: model, DAO, widget tests for language toggle and allergen highlighting.

  **Pitfalls & edge cases**:
  - **Allergen mistranslation is a safety hazard**: If the user reads ingredients in a translated language where allergens are misidentified or formatting is lost, they could consume a harmful product. Display a disclaimer: "Ingredients list is user‑contributed. Always check the product packaging for allergens." Never remove allergen information from display.
  - **`ingredients_text_with_allergens_XX` is not always available**: Many products only have `ingredients_text`. The allergen‑highlighted version is contributed by OFF community editors. When unavailable, fall back to `ingredients_text` with no highlighting. Do not attempt to parse allergens yourself — that's a complex NLP problem.
  - **Ingredients formatting varies by language**: Commas vs. bullets vs. numbered lists differ across locales. The `ingredients_text` field is raw text with locale‑specific formatting. A German ingredients list may look structurally different from an English one. The "show original" toggle must switch the entire text block, not attempt per‑segment comparison.
  - **`ingredients_text_languages` field may be large**: Some products have 10+ language translations. Storing these as a JSON map in SQLite is fine for typical sizes (<5 KB), but very large texts (>100 KB across all languages) could impact DB performance. Consider a separate `product_translations` table if this becomes a problem. Initial estimate: store JSON inline.
  - **"Show original" needs the product's `lang`**: The `lang` field from the API tells you which language the product's default data is in. The toggle should switch to that language. If `lang` is `null` or empty, fall back to the first non‑empty language in `ingredients_text_languages`, then to English, then display the raw text.
  - **Healthcare/religious implications**: A translated ingredient list could mislead users with dietary restrictions (halal, kosher, vegan). The toggle and disclaimer help mitigate this, but the app should never claim the translation is authoritative.
  - **`fields=ingredients_text_languages` adds API payload size**: Requesting the full languages map adds to the response size. For products with many translations, this could be significant. Only request this field when the product detail screen is opened (lazy fetch), not during search/list views.
  - **Allergen formatting in translated text**: The allergen‑highlighted version uses HTML-like markup or bold formatting depending on the language. `Package:html` can parse this, but displaying it in Flutter requires `flutter_html` or custom rendering. Simpler approach: display `ingredients_text_with_allergens_XX` (if available) with basic bold/color markup using a lightweight parser (regex for `**text**` or `<b>text</b>`).
  - **Fallback chain ambiguity**: The app's locale → product's `lang` → English → raw text. But "English" may not exist either. The final fallback should be the first non‑empty `ingredients_text_XX` found in the API response, regardless of language. Display a subtle indicator: "Ingredients shown in [language]."
  - **Search results can't show translated ingredients**: Search list results (`SearchScreen`, autocomplete) fetch minimal data. Only request `ingredients_text_languages` on the full product detail. This means search summaries are always in the product's default language — which is acceptable.

## Database migrations

- [ ] **DB version 9: prices table + lang and multilingual fields** — bundle into a single migration:
  - New table: `prices`
  - New columns on `products`: `lang TEXT`, `product_name_languages TEXT` (JSON), `ingredients_text_languages TEXT` (JSON)
  - Migration must handle: existing rows get `NULL` for new columns (safe defaults in app code), `prices` table created fresh.
  - Rollback: keep old column defaults so downgrade doesn't crash (code should handle `NULL`).

   **Pitfall**: Schema changes for products table must not disrupt existing data. All new columns are nullable — no `NOT NULL` or `DEFAULT` on existing rows. `_onUpgrade` runs in a transaction; test on a copy of a real database.

## Features (medium effort — from previous roadmap, still pending)

- [ ] **Shopping list** — tab or separate screen; mark items as "to buy" with a toggle. Items appear in a dedicated list until purchased (then move to inventory).
- [ ] **Barcode history** — show the last N scanned barcodes with quick-add button. Persist to SQLite.
- [ ] **Empty-pantry onboarding** — when inventory is empty, show a guided "scan your first item" flow instead of just the empty state widget.
- [ ] **Offline-first product submission queue** — queue `submitProduct` calls when offline; flush when `connectivityProvider` emits `true`.
- [ ] **Cloud backup** — upload DB to Firebase Storage / S3. Restore on a new device.
- [ ] **Cosmetics & toiletries support** — extend the OFF API integration to query Open Beauty Facts (`openbeautyfacts.org`), add `productType` to the `Product` model (`'food'` / `'beauty'` / `'petfood'`), add cosmetic‑specific fields (periodAfterOpening, beauty category), hide nutrition/Nutri‑Score for non‑food items, and add filter chips on the home screen.
- [ ] **WHO-based food quality recommendations** — research complete: ADI-based additive safety warnings, non‑sugar sweetener health guidance, free‑sugar threshold alerts (5 g per 100 g), sodium level awareness labels (low/medium/high per WHO thresholds), balanced diet prompts, and Five Keys to Safer Food tips.

## Health & Meal Tracking (high effort)

- [ ] **Health Connect (Android) — nutrition read/write** — integrate Android Health Connect Jetpack (`v1.1.0+`) via `androidx.health.connect:connect-client`. Read/write `NutritionRecord` (calories, macros) from the pantry app to the user's central health hub. Universal Android coverage (API 28+).

  **Implementation (Phase 1 — foundation)**:
  1. Add `health-connect-client` Flutter plugin or write platform channel in `android/app/src/main/kotlin/...`. Audit pub.dev packages first — prefer one with `NutritionRecord` write support.
  2. Create `lib/services/health_connect_service.dart` — wraps `HealthConnectClient` init, permission requests (`HealthPermission.getReadPermission(NutritionRecord)`, `HealthPermission.getWritePermission(NutritionRecord)`), CRUD operations.
  3. Define `HealthNutritionData` model (calories_kcal, protein_g, carbs_g, fat_g, fiber_g, timestamp, meal_type — breakfast/lunch/dinner/snack).
  4. Add `NutritionRecord` write — triggered when user logs a meal or adds an item to inventory with known nutrition data.
  5. Add `NutritionRecord` read — fetch today's totals from Health Connect to display in a nutrition dashboard.
  6. Request permissions on first write attempt (lazy permission model).
  7. New ARB strings: `healthConnectPermission`, `nutritionSynced`, `nutritionSyncFailed`, `todayCalories`.

  **Implementation (Phase 2 — meal logging)**:
  1. Add a "Log Meal" button on `ProductDetailScreen` — writes the product's nutrition data (+ quantity) to Health Connect as a `NutritionRecord`.
  2. Add a "Today's Nutrition" summary card on `StatsScreen` or `HomeScreen` that reads the day's aggregated nutrition from Health Connect.
  3. Background sync: when connectivity permits, sync any pending nutrition records queued while offline.

  **Pitfalls & edge cases**:
  - **Flutter plugin maturity**: The `health_connect` package on pub.dev may have incomplete `NutritionRecord` support or bugs. Audit the package source before committing. Be prepared to write a custom platform channel in Kotlin if the plugin lacks write support for `NutritionRecord` — Health Connect's Kotlin API is well-documented but the Flutter bridge may lag.
  - **Health Connect must be installed separately**: It is NOT built into Android. `HealthConnectClient.getSdkStatus()` returns `SdkStatus.AVAILABLE` only when "Health Connect by Google" is installed from Play Store. If unavailable, show a setup prompt with Play Store deep link. Do not crash.
  - **System permission sheet UX**: Health Connect uses a system-level permission sheet, NOT standard Android runtime permissions. The user grants per-data-type access (e.g., "Allow Nutrition read" + "Allow Nutrition write"). This sheet cannot be styled or customized. If the user denies a specific type, writes to that type fail silently — always check `getGrantedPermissions()` before writing and show a clear error if a required type was denied.
  - **No aggregation — raw records**: Health Connect stores individual records, not aggregates. Writing `NutritionRecord` for breakfast at 8 AM and lunch at 1 PM produces two separate records. If the user logs the same meal twice (e.g., via both product detail "Log Meal" and a future batch logger), you get duplicate records. Implement idempotency: generate a deterministic `uid` from `product_barcode + timestamp + meal_type` and check for existing records before inserting.
  - **Uninstall = permanent data loss**: If the user uninstalls Health Connect, ALL stored data across all apps is deleted. There is no cloud backup or restore. Detect Health Connect uninstall between app launches and warn the user. Keep your own sync log in SQLite to know what was written.
  - **Android backup excludes Health Connect**: Health Connect data is explicitly excluded from Android Auto-Backup. After a device restore or new device, Health Connect starts empty. Your app should detect a "first launch after restore" scenario (e.g., Health Connect is available but has zero prior records from this app) and offer to re-sync.
  - **API 28 minimum**: Health Connect requires Android 9+. On API 27 and below (Android 8.1), hide all Health Connect UI and assume no integration. The SDK methods will throw `UnsupportedOperationException` if called.
  - **Permission revocation at any time**: The user can go to Settings → Health Connect → App permissions and revoke any data type at any time. Your app will not be notified — the next write silently fails. Before every write, re-check `getGrantedPermissions()`. Handle revocation gracefully: show a snackbar "Nutrition write permission was revoked. Logging will not sync." with a "Fix" button that opens the permission settings.
  - **Background sync restrictions**: Android 14+ limits background work. `WorkManager` with a `PeriodicWorkRequest` (minimum 15-minute interval) is the recommended approach for background sync. Test on Android 14+ to ensure your sync worker actually fires.
  - **Testing without a physical device**: You need an Android device or emulator with Health Connect installed. The emulator must include Play Services. CI emulators (GitHub Actions) generally don't have Health Connect — you will need to mock `HealthConnectClient` in unit tests via `mocktail`.
  - **NutritionRecord data model mismatch**: Health Connect uses `Energy` (kcal), `Mass` (g) for macros, and `MealType` enum. Ensure your `HealthNutritionData` model maps cleanly. `MealType` supports: `MEAL_SNACK`, `MEAL_BREAKFAST`, `MEAL_LUNCH`, `MEAL_DINNER`. Also supports `MEAL_UNKNOWN` — use this as a fallback when the product has no category.
  - **User identity confusion**: If multiple profiles/users share the same Android device (work profile, multiple users), Health Connect data is per-Android-user. A nutrition record written under User A is NOT visible under User B. Your app runs in one user's context — this is fine, but be aware if you ever add multi-profile support.

- [ ] **Samsung Health Data SDK — nutrition sync** — integrate Samsung's active Health Data SDK (NOT the deprecated SDK). Write `HealthConstants.Food` (calories) and `HealthConstants.Nutrition` (macros) to Samsung Health. Works on all Android phones with Samsung Health app 6.30.2+.

  **Implementation**:
  1. Create Android platform channel or use community Flutter plugin for Samsung Health Data SDK (check pub.dev for availability; may require custom channel).
  2. Implement `HealthDataStore` connection lifecycle — `connectService()`, `disconnectService()`, listener for connection status.
  3. Request permissions via `HealthPermissionManager` per data type (CALORIE, FAT_TOTAL, PROTEIN, CARBOHYDRATE, FIBER).
  4. Build `InsertRequest` with `HealthDataResolver` to write food intake.
  5. Align with Health Connect abstraction: write to both platforms via the same `HealthNutritionData` model.
  6. New ARB strings: `samsungHealthPermission`, `samsungHealthConnected`.

  **Pitfalls & edge cases**:
  - **Deprecated SDK cut-off**: The old "Samsung Health SDK for Android" was deprecated as of 31 July 2025. Using it will fail for new users. Verify your integration uses the **Samsung Health Data SDK** (new). The migration guide is at [developer.samsung.com/health/data/migration-guide/overview.html](https://developer.samsung.com/health/data/migration-guide/overview.html). Check `build.gradle` dependencies — the old SDK has group `com.samsung.android.sdk:health`, the new one has group `com.samsung.android.sdk.healthdata`.
  - **Samsung Health app must be installed AND at v6.30.2+**: The SDK connects via the Samsung Health app. If the app is missing or outdated, `HealthDataStore.connectService()` fails with a connection error. Detect this in the connection listener callback and show a Play Store deep link to install/update Samsung Health. Example deep link: `market://details?id=com.samsung.android.app.health`
  - **SI units only — no imperial**: The SDK enforces SI units. `CALORIE` is in kcal (not cal), `WEIGHT` in kg (not lb), `HEIGHT` in cm (not ft/in). If your app allows imperial unit display, you must convert before writing. Failure to convert results in silently incorrect data (no error from the SDK).
  - **Partner registration for write access**: Some data types require a [Partner Request](https://developer.samsung.com/SHealth/business-partner/m48wvqi1mt9w2w4c) for write permissions. The `Food` and `Nutrition` data types may be restricted. Register early in development — Samsung's approval process can take weeks. Without it, writes fail with a permission error at runtime.
  - **Connection lifecycle is fragile**: `HealthDataStore` must be connected before any operation. The connection is asynchronous and may disconnect without warning (e.g., Samsung Health app crashes or gets killed by the OS). Register a strong `HealthDataStore.ConnectionListener` that reconnects automatically. Test by force-stopping Samsung Health from Settings while your app is running.
  - **Non-Samsung devices work too**: The SDK works on any Android phone (Marshmallow+) with Samsung Health installed — not just Galaxy devices. Do not gate the feature behind `Build.MANUFACTURER == "samsung"`. Test on a Pixel or Motorola device with Samsung Health installed.
  - **Disconnection on app background**: The SDK auto-disconnects when your app goes to background on some Android versions. Reconnect in `onResume()` or `onForeground()`. Do not assume the connection persists between activities.
  - **Threading**: All SDK callbacks run on a binder thread, NOT the main/UI thread. You must post results to the main thread before updating UI or notifying Flutter via platform channel. Failure to do so causes `CalledFromWrongThreadException`.
  - **Data deduplication across platforms**: If the user has both Health Connect and Samsung Health, writing the same meal to both will create duplicate entries if Samsung Health syncs to Health Connect (it does, on supported devices). Check Samsung Health's "Sync with Health Connect" setting before writing — write to only one platform if cross-sync is enabled, or accept deduplication in the consuming app.
  - **Official docs links**:
    - [Health Data Store Guide](https://developer.samsung.com/health/android/data/guide/health-data-store.html)
    - [API Reference 1.5.1](https://developer.samsung.com/health/android/data/api-reference/overview-summary.html)
    - [Programming Guide](https://developer.samsung.com/health/android/data/guide/intro.html)
    - [FoodNote Sample](https://developer.samsung.com/health/data/sample/foodnote.html)

- [ ] **Samsung Food (formerly Whisk) — meal planning UX** — integrate with Samsung Food's meal planning pattern (recipe saving, drag-and-drop weekly planner, auto-generated grocery lists). Uses Samsung Health Data SDK underneath for nutrition sync.

  **Implementation**:
  1. Research the Samsung Food public API / integration points. Samsung Food exposes `HealthConstants.Nutrition` read/write through the Health Data SDK (see FoodNote sample).
  2. Implement meal suggestion from expiring items (coordinate with the existing "Recipe suggestions" item below — merge efforts if both move forward).
  3. Add a weekly meal plan UI: drag-and-drop items into day slots, auto-generate grocery list from planned meals.
  4. Write planned meals' nutrition data to Samsung Health via the SDK from the previous item.
  5. New ARB strings: `mealPlan`, `weeklyPlanner`, `groceryList`, `addToPlan`.

  **Pitfalls & edge cases**:
  - **API access may require partnership**: Samsung Food's integration API may require a business partnership or specific credentials. The public documentation is limited. The FoodNote sample shows one-way nutrition write via Health Data SDK, but read/plan operations may use a different (possibly private) API. Research access requirements before scoping implementation time.
  - **Regional availability**: Samsung Food is not available in all countries. Check [samsungfood.com](https://samsungfood.com/) for regional restrictions. If unavailable in the user's country, hide the meal planning UI and show a "Not available in your region" message instead of crashing.
  - **Recipe suggestions overlap**: The existing "Recipe suggestions" TODO item (below) proposes calling a generic recipe API for expiring items. Samsung Food has its own recipe database and meal planner. Decide: use Samsung Food as the recipe source (requires their API) or keep a generic recipe API for wider coverage. If you use a generic API + Samsung Food, you get two recipe sources — merge them or let the user choose.
  - **Data portability lock-in**: If a user builds their weekly meal plan in Samsung Food, they cannot export it. Consider providing an export-to-SQLite option if your app acts as a layer on top. This avoids vendor lock-in.
  - **Whisk acquisition changes**: Samsung acquired Whisk (now Samsung Food) in 2019. The API and features have changed multiple times since. Expect ongoing changes. The FoodNote sample is the most stable integration point.
  - **Meal plan → grocery list → inventory conflict**: Samsung Food auto-generates grocery lists from meal plans. If the user buys those items and also adds them manually to your pantry app, you get duplicates. Implement a "mark as purchased" flow that cross-references with existing inventory items by barcode or name similarity.
  - **Official docs links**:
    - [Samsung Food](https://samsungfood.com/)
    - [FoodNote Sample](https://developer.samsung.com/health/data/sample/foodnote.html)
    - [Health Data Type – Food](https://developer.samsung.com/health/android/data/guide/health-data-type.html)

- [ ] **Apple HealthKit (future iOS version)** — integrate HealthKit via `HKHealthStore` for reading/writing `HKQuantitySample` with `HKQuantityTypeIdentifier.dietaryEnergyConsumed` and related nutrition types. Minimum iOS 8.0+.

  **Implementation**:
  1. Add HealthKit capability in Xcode when building the iOS version of the app.
  2. Use the `health` Flutter package or platform channel for `HKHealthStore`.
  3. Request per-type permissions (`HKObjectType.quantityType(forIdentifier:)`).
  4. Write nutrition records using the same `HealthNutritionData` model from the Health Connect abstraction layer.
  5. New ARB strings: `appleHealthPermission`, `healthKitSynced`.

  **Pitfalls & edge cases**:
  - **iOS-only, gated behind platform check**: HealthKit classes exist only on Apple platforms. Use `defaultTargetPlatform == TargetPlatform.iOS` to gate all HealthKit code. Accessing `HKHealthStore` on Android/macOS crashes.
  - **Entitlement provisioning in Xcode**: You must enable the HealthKit capability in Xcode under Signing & Capabilities. This requires an Apple Developer account (paid). The entitlement is checked at runtime — if missing, `HKHealthStore.isHealthDataAvailable()` returns `false`.
  - **Per-type permission granularity — no bulk requests**: HealthKit requires you to request read/write permission for EACH data type individually (`HKObjectType.quantityType(forIdentifier: .dietaryEnergyConsumed)`, `.dietaryFatTotal`, `.dietaryProtein`, `.dietaryCarbohydrates`, `.dietaryFiber`). You cannot request "all nutrition types". Missing one type means writes to that type fail silently. Maintain a list of requested types and verify each is granted before writing.
  - **No cross-device sync without iCloud**: HealthKit data is stored locally on each device. It only syncs across devices if the user has iCloud enabled with Health sync turned on. A user who logs meals on iPad will not see them on iPhone unless iCloud sync is active. Detect iCloud Health sync status and surface it in the UI: "Meal logs are stored on this device only."
  - **Private medical data — no server transmission**: HealthKit data is encrypted at rest and Apple's guidelines prohibit transmitting it to third-party servers without explicit user consent. Never send HealthKit nutrition data to your own backend unless you show a clear, separate consent dialog and document exactly what data is sent and why.
  - **Simulator limitations**: HealthKit works on iOS simulator, but with restrictions — no iCloud sync, no real Health data from other apps. You can write and read records for testing, but end-to-end testing with real data requires a physical device.
  - **Background delivery**: HealthKit supports background delivery via `HKObserverQuery`, but iOS may delay delivery for power management. Do not rely on real-time updates. Use foreground queries for the nutrition dashboard and background delivery only for badge/notification updates.
  - **User can delete records from Health app**: The user can open the Health app and delete any record, including those your app wrote. Your local cache will be stale. Implement periodic reconciliation: compare your SQLite log against HealthKit's records for the same period and flag discrepancies.
  - **WatchOS independence**: On Apple Watch, HealthKit runs independently. If the user logs a meal on Watch (e.g., via a future Watch companion app), the record appears in HealthKit but may not trigger your app's observer query until the Watch syncs to iPhone over Bluetooth. This can take minutes.
  - **HealthKit data deletion on app uninstall**: When your app is uninstalled, all HealthKit records written by your app are deleted (per Apple's privacy model). Re-installing the app won't recover them. Warn the user if they trigger an account deletion flow.
  - **Official docs links**:
    - [HealthKit Framework](https://developer.apple.com/documentation/healthkit)
    - [HealthKit Updates (WWDC25)](https://developer.apple.com/documentation/healthkit)

### Health platform abstraction layer

- [ ] **Health platform abstraction layer** — create a unified Dart interface `HealthService` with methods `writeNutrition(HealthNutritionData)`, `readNutrition(TimeRange) → List<HealthNutritionData>`, `requestPermissions()`, `isAvailable()`. Implement for each platform: `HealthConnectService`, `SamsungHealthService`, `AppleHealthService`. This keeps the app code platform-agnostic and makes adding OEM platforms (Huawei Health Kit, Xiaomi Health Cloud, OPPO Health, vivo Health Kit, Honor Health Kit) a matter of writing a new implementation class.

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
  - **Platform channel complexity multiplies**: Each health SDK requires its own Android/iOS platform channel code. Health Connect needs Kotlin (Android), Samsung Health Data SDK needs Kotlin (Android), HealthKit needs Swift (iOS). One buggy platform channel can crash the entire app. Use a separate `MethodChannel` per service with clear error handling. Do NOT share a single channel for all health operations.
  - **Testing across platforms is hard**: Unit tests can mock the `HealthService` interface, but integration tests require real devices with Health Connect / Samsung Health / HealthKit installed. CI pipelines generally don't support this. Keep integration tests in a separate `health_integration_test/` directory that is run manually, not in CI.
  - **Cross-platform data deduplication**: If Health Connect and Samsung Health are both active AND Samsung Health syncs to Health Connect (it does on supported devices), writing the same nutrition data through both services creates duplicate records in Health Connect. Detect cross-sync by querying Health Connect for records matching this app's `clientId` before writing to Samsung Health. Write to only one platform if cross-sync is detected.
  - **User consent fatigue**: Requesting permissions for multiple health platforms one after another creates a terrible UX (up to 3 permission sheets on first use: Health Connect + Samsung Health + camera/gallery for proof photos). Stagger permission requests: ask for Health Connect on first nutrition write, Samsung Health only when the user explicitly opens Samsung Health settings, HealthKit when the user visits the iOS nutrition dashboard.
  - **Privacy regulations (LGPD/GDPR)**: Health data is considered sensitive personal data under LGPD (Brazil) and GDPR (Europe). You must:
    - Document exactly what health data is collected and why
    - Get explicit consent before writing to any health platform
    - Provide a way for users to delete all health data (your local logs + trigger deletion on all connected platforms if possible)
    - Include health data processing in your privacy policy
  - **App store scrutiny**: Apps that read/write health data face additional review requirements on both Google Play and Apple App Store. Apple requires a clear explanation of why you need each HealthKit data type. Google Play requires the Health Connect permission declaration form. Prepare these documents before release — don't wait until submission.
  - **Error aggregation**: With multiple backends, error handling gets complex. A `ServiceUnavailableException` on Health Connect might be transient, but the same error on Samsung Health means Samsung Health is not installed. Create typed error classes per platform with clear user-facing messages. Never show raw SDK errors in the UI.
  - **Feature flagging**: Each health platform integration should be behind a feature flag (e.g., `HealthConnectFeature`, `SamsungHealthFeature`) that can be disabled remotely or via a debug menu. This allows you to ship an integration that isn't fully ready yet without blocking the release.

### Quick-reference table

```
| Platform | Write | Nutrition | Meal Plan | Docs |
|----------|-------|-----------|-----------|------|
| Health Connect (Android) | Yes | Yes NutritionRecord | No | [developer.android.com/health-and-fitness/health-connect](https://developer.android.com/health-and-fitness/health-connect) |
| Samsung Health Data SDK | Yes | Yes Food/Nutrition | Yes via Samsung Food | [developer.samsung.com/health](https://developer.samsung.com/health) |
| Samsung Food | N/A (via SDK) | Yes | Yes meal planner | [samsungfood.com](https://samsungfood.com/) |
| Apple HealthKit | Yes (future) | Yes dietary energy | No | [developer.apple.com/documentation/healthkit](https://developer.apple.com/documentation/healthkit) |
| Huawei Health Kit | Yes | Yes limited | No | [developer.huawei.com/consumer/en/hms/huawei-healthkit](https://developer.huawei.com/consumer/en/hms/huawei-healthkit) |
| Xiaomi Health Cloud | Yes | limited | No | [dev.mi.com](http://developer.mi.com) |
| OPPO Health | Yes | limited | No | [open.oppomobile.com](https://open.oppomobile.com/) |
| vivo Health Kit | Yes | limited | No | [developers.vivo.com](https://developers.vivo.com/) |
| Honor Health Kit | Yes | limited | No | [developer.honor.com](https://developer.honor.com/) |
```

## Larger Projects (high effort — from previous roadmap, still pending)

- [ ] **Multi‑language support** — ARB infrastructure exists; add translations (pt, fr, es, de). Contribute via community PRs.
- [ ] **Recipe suggestions** — call a recipe API with items expiring this week; suggest meals that use them. Coordinate with the Samsung Food meal planning integration above — if both are implemented, Samsung Food can serve as the meal planning UI layer and recipe source, while the generic recipe API provides wider coverage in regions where Samsung Food is unavailable.
- [ ] **Widget test → golden coverage** — product detail, settings, stats screens.
- [ ] **Remake notification feature from scratch** — rewrite `NotificationService` for reliability: precise expiry‑day‑at‑morning and expiry‑soon (N days before) scheduling, multi‑item grouping, per‑inventory notification channels, proper timezone handling, and resilient rescheduling on app boot.
- [ ] **Remake import/export from scratch** — rewrite `CsvService` to support: export only cached (API-fetched) products, export a specific inventory, export products from a specific inventory, and import via `filegate` (platform file picker). Replace the stats-screen picker with a streamlined FileGate-based flow.
- [ ] **Patrol E2E tests** — real‑device integration tests via [Patrol](https://patrol.leancode.co). Uses `patrol_cli` and `patrol` dev-dependency. Replace the generic `integration_test/` with `patrol_test/` directory.

### Patrol E2E test scenarios

- [ ] **Setup** — install `patrol_cli`, add `patrol` to `dev_dependencies`, configure `pubspec.yaml` (`pacakge_name`, `bundle_id`), create `patrol_test/`, gitignore `test_bundle.dart`.
- [ ] **Scan → add to inventory** — tap FAB, simulate barcode scan, verify product detail appears, add item, verify home screen shows it.
- [ ] **Offline scan → manual entry** — simulate offline, scan barcode, verify manual entry screen opens, fill form, save, verify product cached.
- [ ] **Quantity adjustment flow** — open product detail, tap + 3×, verify quantity, tap − to 0, confirm delete, verify item gone.
- [ ] **Notification flow** — add item with expiry tomorrow, background the app, advance time, verify notification appears.
- [ ] **Inventory switch** — tap dropdown, select different pantry, verify items change.
- [ ] **CSV export → import round‑trip** — export inventory, import the same CSV, verify item count.

## CI/CD & DevOps

- [ ] **GitHub Actions — CI pipeline** — on every PR and push to `main`:
  - `flutter analyze` (lint check)
  - `dart format --set-exit-if-changed .` (formatting check, not force‑format)
  - `flutter test --concurrency=8 --coverage` (tests + coverage report)
  - Upload coverage artifact, fail if tests fail.
- [ ] **GitHub Actions — Play Store deployment** — on new tag (`v*`):
  - `flutter build appbundle` + `flutter build apk` (release)
  - Upload both to Google Play Console via `r0adkll/upload-google-play`
  - Requires Play Store service account JSON stored as a GitHub secret.
- [ ] **GitHub Actions — Patrol E2E on schedule** — weekly run of the Patrol test suite on a real Android emulator (GitHub‑hosted runner).

## Documentation (quick wins)

- [x] `ARCHITECTURE.md` — add security section (dotenv env-var handling, no-committed-secrets rule).
- [x] `ARCHITECTURE.md` — add offline-first pattern diagram or ASCII flow.
- [x] `AGENTS.md` — add "always check TODO.md before starting new work" instruction.
- [ ] **NFC‑e reference doc** — create `lib/docs/nfce_reference.md` with complete technical reference (QR code URL formats, state‑specific variations, v2 vs v3, parsing approach, open‑source tools).
- [ ] **Price tracking doc** — add section to `ARCHITECTURE.md` documenting local + Open Prices API data flow, conflict resolution, and proof‑photo requirement.

---

## Effort × Importance Matrix

```
                     Low effort ─────────── High effort
                     ─────────────────────────────────────
High importance  │ Batch delete            │ Shopping list
                 │ Quick quantity adjust   │ Offline submission queue
                 │ Expiry date guard       │ Cloud backup
                 │ Expiry parsing extract  │ GitHub CI pipeline
                 │ Changelog at startup    │ Product prices (+ Open Prices)
                 │ Product name trans.     │ NFC-e importing
                 │                         │ Health Connect nutrition sync
                 │                         │ Samsung Health Data SDK
                 │                         │ Samsung Food meal planning
                 │                         │ Health abstraction layer
                 │─────────────────────────│──────────────────────────
                 │ Golden tests            │ Multi-language
                 │ Accessibility audit     │ Recipe suggestions (+ Samsung Food)
                 │ SearchBar upgrade       │ Patrol E2E tests
                 │ Screenshots             │ Play Store CI deploy
                 │ Empty-pantry onboarding │ Barcode history
 Low importance  │ NavigationRail          │ Ingredients translations
                 │                         │ Cosmetics/toiletries
                 │                         │ WHO food recommendations
                 │                         │ Apple HealthKit (future)
                 │                         │ OEM platforms (Xiaomi, Huawei, etc.)
```

---

## Summary of new pitfalls documentation

Every new feature item now includes a dedicated **Pitfalls & edge cases** section covering:

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
