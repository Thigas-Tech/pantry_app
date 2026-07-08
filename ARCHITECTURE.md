# Architecture — Pantry App

An offline-first Flutter application for managing pantry inventory and expiry dates.
This document describes the architecture, patterns, and design decisions.

---

## 1. High‑level overview

```
┌─────────────────────────────────────────────────────────────┐
│                         UI Layer                             │
│  screens/          widgets/          utils/                  │
│  HomeScreen        InventoryCard     logger                  │
│  ScannerScreen     EmptyPantry       snackbar_helper         │
│  ProductDetail     NutritionTable                            │
│  AddToInventory    ScannerOverlay                            │
│  Settings / Stats  ...                                       │
└─────────┬────────────────────────────────────────────────────┘
          │  watches / reads Riverpod providers
┌─────────▼────────────────────────────────────────────────────┐
│                     State / DI Layer                          │
│  providers/                                                   │
│  activeInventoryProvider   inventoryWithProductProvider       │
│  settingsProvider          themeModeProvider                  │
│  productRepositoryProvider statsProvider                      │
│  imageCacheProvider        notificationServiceProvider        │
│  connectivityProvider      githubIssueServiceProvider         │
│  apiServiceProvider        inventoryCountProvider             │
└─────────┬────────────────────────────────────────────────────┘
          │  calls
┌─────────▼────────────────────────────────────────────────────┐
│                    Business Logic Layer                        │
│  services/                                                    │
│  ProductRepository    OffAdapter    NotificationService       │
│  ImageCacheService    GithubIssueService  AdService           │
│  DonationService      CloudBackupService FirebaseService      │
└─────────┬──────────────┬──────────────────┬─────────────────┘
          │              │                  │
┌─────────▼────┐  ┌─────▼──────────────┐   │
│  Local DB    │  │  Remote API        │   │
│  database/   │  │  services/         │   │
│  SQLite      │  │  Open Food Facts   │   │
│  DAO pattern │  │  v3 REST (SDK) │   │
└──────────────┘  └────────────────────┘   │
                                            │
                               ┌───────────────────────────────┐
                               │  [Planned] Firebase Services   │
                               │  Auth (Google Sign-In)        │
                               │  Storage (cloud backup)       │
                               │  AdMob (ads)                  │
                               │  Play Billing (IAP)           │
                               └───────────────────────────────┘
```

---

## 2. Database layer (`lib/database/`)

### 2.1 Schema (version 11)

Three tables:

| Table         | Purpose                                                  |
|---------------|----------------------------------------------------------|
| `products`    | Cached product data from Open Food Facts. PK = barcode.  Includes `source` column: `'api'` (OFF‑fetched, flushable) or `'manual'` (user‑entered, protected). |
| `inventories` | Named pantries (e.g. "Home", "Work"). PK = id            |
| `inventory`   | Instances of products in a pantry. FK → products, inventories |

### 2.2 DAO pattern

Each table has a dedicated Data Access Object:

| DAO                    | Responsibility                            |
|------------------------|-------------------------------------------|
| `ProductDao`           | Upsert / lookup products, count, source‑aware queries |
| `InventoryDao`         | CRUD items, joined queries                |
| `InventoriesDao`       | CRUD named pantries, migrations           |

Every DAO method receives a `Database` instance so it can be tested independently.

`DatabaseHelper` is the singleton that owns the connection, runs schema
migrations, and delegates CRUD to the DAOs.  It is the **only public entry
point** for database access in production code.

**Null safety rule**: All row value access MUST use null-coalescing
(`as T? ?? defaultValue`) instead of the null-check operator (`!`).
Aggregate functions (SUM, AVG) return NULL when the result set is empty,
and schema columns without NOT NULL constraints can contain NULL values.
The `count()` methods set the precedent with
`Sqflite.firstIntValue(...) ?? 0`.

### 2.3 Migration strategy

- `_onCreate` runs when the database file is first created.
- `_onUpgrade` handles version bumps (currently v1 → v11).
- The `version` integer in `openDatabase` triggers the upgrade automatically.

Version history:
| Version | Change |
|---------|--------|
| v1 → v2 | Added `inventories` table, `inventory_id` column |
| v2 → v3 | Default unit `pcs` → `pieces`, migration of existing data |
| v3 → v4 | Added `nutriscore_grade TEXT` column to `products` |
| v4 → v5 | Added `nutriscore_not_applicable_category TEXT` column |
| v5 → v6 | Added `source TEXT NOT NULL DEFAULT 'api'` column |
| v6 → v7 | Added photo path columns for manual products |
| v7 → v8 | Added `submission_status` column for OFF product submission |
| v8 → v9 | Added 3 OFF image URL columns for photo‑completeness |
| v9 → v10 | Added `categories_hierarchy` column |
| v10 → v11 | Added `feedback_queue` table for offline issue reporting |

### 2.4 Connectivity layer

`InternetConnectionChecker` monitors device connectivity via a
`StreamProvider<bool>` (`connectivityProvider`). The app uses this to:

- Refresh cached product data on startup and pull-to-refresh (online only).
- Skip the Open Food Facts API lookup when offline — going directly to
  manual product entry with a warning snackbar.
- Guard any network-dependent operation with a connectivity check.

---

## 3. Service layer (`lib/services/`)

### 3.1 Offline-first repository pattern

`ProductRepository` implements the offline-first strategy:

```
User scans barcode
           │
      ┌────▼────┐  no     ┌─────────────────┐
      │ Online? ├────────►│ Manual entry     │
      └────┬────┘         │ (AddProductScreen)│
           │ yes          └────────┬─────────┘
      ┌────▼────┐                 │
      │ OFF API │                 │
      └────┬────┘                 │
           │                      │
      ┌────▼──────────┐          │
      │ Cache in DB   │◄─────────┘
      │ (upsertProduct)│
      └────┬──────────┘
           │
      ┌────▼────┐
      │ Return  │
      │ Product │
      └─────────┘
```

1. **Check local cache** — if the product exists in SQLite, return it immediately.
2. **Call primary API** — if not cached, fetch from Open Food Facts and store locally.
3. **Fallback (offline)** — if no connectivity, skip API and go directly to manual entry form.

**Exception hierarchy:**

| Exception                      | Meaning                             | UI reaction                       |
|--------------------------------|-------------------------------------|-----------------------------------|
| `ProductNotFoundException`     | Barcode unknown to all sources      | Bottom sheet: add manually / contribute |
| `FetchFailedException`         | Network error, no cache             | Error snackbar                    |

### 3.2 Open Food Facts API

- **Endpoint**: `https://world.openfoodfacts.org/api/v3/product/{barcode}.json`
- **Staging**: `https://world.openfoodfacts.net`
- **Config**: `lib/config.dart` (credentials, email, staging flag)
- **Submission**: Legacy `/cgi/product_jqm2.pl` and v3 PATCH endpoints available

### 3.3 Notification service

- Uses `flutter_local_notifications` + `flutter_timezone` + `timezone` for
  timezone-aware local scheduling on Android.
- **Two reminders per item**: "Expiring soon" (1 day before) and
  "Expiring today" (on the expiry day).
- **Notification IDs**: `itemId * 2` (expiring soon) and `itemId * 2 + 1`
  (expiring today). Guaranteed positive and collision‑free.
- **Time-of-day**: All notifications fire at **9:00 AM** local time
  (`_toMorningTZDateTime()`), not at midnight.
- **Channel**: `'expiry_channel'` is created explicitly during
  `ensureNotificationChannel()` with `Importance.high` and
  `AndroidNotificationCategory.reminder`.
- **Tap handling**: `onDidReceiveResponse` (main isolate) and
  `onDidReceiveBackgroundResponse` (background isolate) are wired during
  `initialize()`. The payload is the item's barcode for deep‑linking to
  [ProductDetailScreen].
- **Boot recovery**: `rescheduleAllItems()` cancels all pending alarms and
  re‑schedules them from the current DB contents. Called in `main.dart`
  after initialization.
- **Permission**: `requestPermission()` requests `POST_NOTIFICATIONS` on
  Android 13+. Returns `bool` — the settings screen reacts accordingly.
- **Background handler**: Separated into
  `notification_background_handler.dart` (top-level
  `@pragma('vm:entry-point')`) to avoid the `unreachable_from_main` lint.
- **Logging**: Every `zonedSchedule` call is logged with ID, time, and
  channel. Channel creation warnings are logged at `logWarning`.
- All notification strings are passed in by callers (as function callbacks)
  so they can be localized via ARB.

### 3.4 Ad service (AdMob) — [Planned]

> **Not yet implemented.** See `agents_docs/monetization.md` for the full
> deferred implementation plan.

- Planned: `google_mobile_ads` for banner and native ads across free tier screens.
- Consent managed via UMP SDK (GDPR/LGPD) on first launch.
- Ad unit IDs read from `.env`, using test IDs in debug mode and production IDs in release.

### 3.5 Donation and subscription service (Play Billing) — [Planned]

> **Not yet implemented.** See `agents_docs/monetization.md` for the full
> deferred implementation plan.

- Planned: `in_app_purchase` plugin wrapping Google Play Billing.
- Donation products: three consumable tiers ($2.99, $4.99, $9.99).
- Pro subscription: auto-renewing, monthly ($0.99) and yearly ($9.99).
- `isPro` flag derived from `queryPastPurchases()` — checked before showing ads and enabling cloud backup.

### 3.6 Firebase integration — [Planned]

> **Not yet implemented.** See `agents_docs/monetization.md` for the full
> deferred implementation plan.

- Planned: `FirebaseService` initialising `firebase_core`, `FirebaseAuth` and `FirebaseStorage`.
- Planned: `CloudBackupService` exporting SQLite to Firebase Storage at `users/{uid}/pantry_backup.db`.
- Planned: Google Sign-In via `google_sign_in` + `firebase_auth`.

### 3.7 Feedback service (GitHub Issues)

- `GithubIssueService` — HTTP POST to GitHub Issues API with PAT from
  `.env` (`GITHUB_FEEDBACK_TOKEN`), never committed.
- Offline queue: unresolved issues stored in `feedback_queue` SQLite table
  (version 11 migration). Flushed when `connectivityProvider` emits `true`
  via listener in `PantryShell` and at app startup.
- Screenshots: user attaches from gallery or camera via `image_picker`,
  encoded as PNG base64, embedded as data URI in issue body (no external
  CDN needed — GitHub renders data URIs natively).
- Rate limiting: max 1 issue per 60 seconds, max 5 per 24h per device
  (via `SharedPreferences` counters).
- Duplicate detection: hash of title+body, skipped if submitted within 24h.
- Platform gating: on web/mobile the feedback from opens the `FeedbackScreen`;
  screenshot attachment hidden on web and desktop platforms.

---

## 4. Provider layer (`lib/providers/`)

| Provider                        | Type              | Purpose                            |
|---------------------------------|-------------------|------------------------------------|
| `databaseProvider`              | `Provider`        | Singleton `DatabaseHelper`         |
| `apiServiceProvider`            | `Provider`        | Configured `OffAdapter`            |
| `productRepositoryProvider`     | `Provider`        | Repository (DB + API)              |
| `imageCacheProvider`            | `Provider`        | Image download/cache (WebP)        |
| `notificationServiceProvider`   | `Provider`        | Expiry reminder scheduling         |
| `statsProvider`                 | `FutureProvider`  | Aggregated pantry statistics       |
| `activeInventoryProvider`       | `NotifierProvider`| Current pantry ID (default 1)      |
| `inventoryWithProductProvider`  | `FutureProvider`  | Joined inventory list for home     |
| `inventoryListProvider`         | `FutureProvider`  | All pantries (id, name)            |
| `inventoryCountProvider`        | `FutureProvider`  | Item count for active inventory    |
| `averageNutriscoreProvider`     | `FutureProvider`  | Average Nutri-Score for inventory  |
| `connectivityProvider`          | `StreamProvider`  | Internet connectivity status       |
| `hasConnectionProvider`         | `Provider`        | Cached connectivity boolean        |
| `settingsProvider`              | `NotifierProvider`| Notifications, retention, threshold|
| `themeModeProvider`             | `NotifierProvider`| Light / dark / system theme        |
| `productSubmissionServiceProvider` | `Provider`     | OFF product submission             |
| `githubIssueServiceProvider`    | `Provider`        | GitHub Issues API wrapper          |

---

## 5. Screen / widget structure

```
HomeScreen
├── AppBar (title, switcher, settings)
├── ErrorView (loading/error states)
├── EmptyPantry (empty state with scan prompt)
└── _InventoryList
    ├── SearchBar (Autocomplete with image thumbnails)
    ├── StockCountBadges (horizontal ListView.builder)
    ├── CategoryFilterChips (horizontal ListView.builder)
    ├── RefreshIndicator (pull-to-refresh)
    └── ListView.builder (RepaintBoundary on each card)
        ├── SectionHeader (expired / expiring soon / good)
        └── InventoryCard (tappable, image, NutriScoreBadge, expiry dot)

ProductDetailScreen
├── AppBar (name, OFF link)
├── Hero → CachedImage (FutureBuilder → cached WebP or network)
├── NutriScoreBadge + tooltip (A–E grade)
├── InfoRows (barcode, brand, category, serving size)
├── NutritionTable (energy, protein, carbs, fat, fiber, salt)
├── Ingredients (ExpansionTile)
├── InventoryTiles (location icon, qty, expiry, edit/delete)
└── "Add to Inventory" button

AddProductScreen (manual entry when offline or barcode not found)
├── Product name, brand, category, serving size
├── Nutrition table (6 fields, per 100g/ml)
├── Ingredients (multi-line)
└── Image capture (nutrition table, ingredients, product photos)

SearchScreen
├── SearchBar (300ms debounce timer)
├── ResultTile (product image or CircleAvatar fallback)
├── Swipe-to-add (Dismissible, start-to-end)
└── Long-press menu (add to inventory, copy barcode)

StatsScreen
├── Summary cards (total products, items, added this week/month)
├── NutriScoreBar (fl_chart BarChart by grade A–E)
├── CategoryChart (fl_chart BarChart by category)
├── LocationChart (fl_chart BarChart by storage location)
├── Photo completeness (local vs OFF photos)
├── ComingSoonView (price tracking — placeholder)
├── ComingSoonView (NFC-e receipts — placeholder)
└── RefreshIndicator (pull-to-refresh)

ScannerScreen
├── PopScope (confirmation dialog on back)
├── _MobileScannerView (camera + ScannerOverlayPainter)
└── _ManualEntryView (text field + submit button)

SettingsScreen
├── Theme dialog (RadioGroup: system/light/dark)
├── Notifications switch
├── Data retention dialog (days input)
├── Expiring-soon threshold dialog
├── Manage Inventories link
├── Flush cache (API products + image cache)
└── About (What's New changelog sheet)
```

---

## 6. Models (`lib/models/`)

All models use **freezed** for immutable value types and **json_serializable**
for JSON deserialization from the Open Food Facts API.

| Model                 | Source     | Notes                           |
|-----------------------|------------|---------------------------------|
| `Product`             | freezed    | Cached OFF product data         |
| `InventoryItem`       | freezed    | An instance of a product in a pantry |
| `InventoryWithProduct`| plain Dart | Join from `getInventoryWithProduct` |

---

## 7. Localization (`lib/l10n/`)

- Source: `app_en.arb` (English).
- Generated code in `lib/l10n/app_localizations*.dart`.
- **All user-visible strings** must be in `app_en.arb` — never hardcoded.
- After changing ARB files, run `flutter gen-l10n`.

---

## 8. Testing strategy

| Layer    | Tooling                              | Approach                                  |
|----------|--------------------------------------|-------------------------------------------|
| Database | `sqflite_common_ffi`, in-memory DB   | Full CRUD, migration, cleanup tests       |
| Services | `mocktail` mocks for Dio, plugins    | Isolated unit tests with stubbed I/O      |
| Providers| `ProviderContainer`                  | Test provider wiring and defaults         |
| Screens  | `pumpApp()` helper + mocks           | Widget tests with Riverpod scope + l10n   |
| Widgets  | `pumpApp()` helper                   | Visual assertions on cards, error states  |
  | Utils    | Pure Dart                            | Logger output capture, snackbar styling   |
| Golden  | `matchesGoldenFile`                  | Visual regression for badges, screens     |

---

## 9. Cache flush on app update

When the app version changes (detected via `package_info_plus` and
`shared_preferences`), the following caches are cleared:

1. **Image cache** — `ImageCacheService.clearCache()` deletes the
   entire `image_cache/` directory, forcing re-download of product images.
   The image cache only stores images downloaded from OFF CDN URLs —
   manually captured photos and other user data are never kept here.

2. **Product cache** — `DatabaseHelper.clearCachedProducts()` deletes
   only rows where `source = 'api'` from the `products` table. Products
   the user entered manually (`source = 'manual'`) and all inventory
   items are preserved. On next startup, the background refresh in
   `main()` re-fetches the remaining cached products from OFF with
   current data (including fields added in newer versions).

A manual flush button is also available in the settings screen.

---

## 10. Key design decisions

1. **Singleton DatabaseHelper** — avoids multiple connections and locking issues.
2. **DAO pattern** — separates schema/migrations from CRUD, making the codebase testable and maintainable.
3. **Offline-first** — cache products locally; only call the API on cache miss.
4. **Riverpod for DI** — all services are provided through Riverpod, making them easily overridable in tests.
5. **Freezed models** — immutable, with generated `copyWith`, `==`, `hashCode`, and JSON serialization.
6. **No `ignore:` comments** — all lint rules are followed; deprecations are addressed rather than suppressed.
7. **ANSI-coloured logging** — `logInfo` (blue), `logWarning` (yellow), `logError` (red) for terminal visibility.
8. **Environment‑based config** — credentials loaded via `flutter_dotenv` from `.env` (never committed). `.env.example` is the documented template. `AppConfig` class provides typed accessors.
9. **Batch delete with undo** — selection mode replaces the app bar actions and FAB with a delete button and close button. Checkboxes replace card images. Undo restores all deleted items via `SnackbarHelper.showUndo`.
10. **Quick quantity adjustment** — `+/−` buttons on inventory tiles call `_updateQuantity`, which persists the change and re-schedules notifications. Tap the quantity to type a number directly. Decrementing to 0 triggers delete.
11. **Nutri-Score fallback** — when the API returns `nutriscore_grade: "not-applicable"` (e.g. for food additives), the badge renders a grey dash. A tooltip explains the reason using the category from `nutriscore_data.nutriscore_not_applicable_for_category` (e.g. `en:food-additives` → "food additives"). This is stored as `nutriscore_not_applicable_category` on the product and surfaced through the `InventoryWithProduct` join.
12. **Source column protects manual products** — every row in the `products` table carries a `source` column (`'api'` for OFF‑fetched data, `'manual'` for user‑entered data). Cache flush (`clearCachedProducts`) deletes only API‑sourced products; manual products and all inventory items survive across app updates. The image cache is inherently separated (stores only downloaded OFF CDN images) and safe to clear.
13. **Monetization (planned)** — AdMob, IAP donations, Pro subscription,
    and Firebase cloud backup are deferred pending legal and accounting
    review. See `agents_docs/monetization.md` for the full implementation
    plan. All on-device features will remain free forever.

---

## 11. Carbon footprint design decisions

### 11.1 Dark mode (OLED/AMOLED energy savings)

The app supports `ThemeMode.system` (default), `ThemeMode.light`, and
`ThemeMode.dark` via `ThemeModeNotifier`. On AMOLED displays, dark mode
consumes up to 60% less power because black pixels are physically turned
off. A future enhancement will detect AMOLED devices at launch and nudge
the user toward dark mode with a one-time prompt.

### 11.2 Image caching (WebP)

`ImageCacheService` downloads product images in WebP format from the Open
Food Facts CDN and stores them in the app's local documents directory. WebP
is ~30% smaller than JPEG at equivalent quality, reducing network transfer
and storage footprint. Cached images are served instantly — no network calls
on subsequent views.

All `Image.network` calls set `cacheWidth` and `cacheHeight` at display
resolution (display dp × `devicePixelRatio`) to prevent full-resolution
decode. Inventory card and search thumbnails are 40×40 dp; product detail
photos are 200 dp tall × screen-width wide.

### 11.3 Offline-first architecture

`ProductRepository` implements offline-first: always return cached data
first, fetch from API only on cache miss. This dramatically reduces API
calls — a product viewed twice generates one network call, not two. The
background cache refresh is throttled (5+ days overdue, connectivity
required), and only API‑sourced products are refreshed — user‑entered
products are never re‑fetched.

### 11.4 RepaintBoundary placement

`RepaintBoundary` should be applied to widget subtrees that:
- Scroll independently (e.g., items inside `ListView.builder`)
- Animate repeatedly (e.g., badge transitions, progress indicators)
- Are embedded in a scrolling parent but have static content

In v1.0.0 each `InventoryCard` in the main inventory `ListView.builder` is
wrapped in `RepaintBoundary` with `ValueKey(item.id)`. This prevents parent
scroll events from triggering card repaints and enables efficient widget
recycling. Cards that load network images or toggle selection do not
force their siblings to repaint.

### 11.5 Thread strategy

sqflite already executes SQL on a background isolate internally. The
following operations are candidates for `Isolate` / `compute()` offloading:
- Open Food Facts API response parsing (`json.decode` of large payloads)
- Image encoding (camera capture → WebP conversion in `ImageCacheService`)

`compute()` from `package:flutter/foundation.dart` is preferred over raw
`Isolate` for fire-and-forget tasks. Use `SendPort` messaging for
long-running workers.

### 11.6 AAB and deferred components (Android)

The app builds as an Android App Bundle (AAB) for Play Store distribution.
A future optimization will split into dynamic feature modules so users only
download the features they actually use:
- `scanner` — MobileScanner camera integration
- `search` — Open Food Facts SDK

This reduces the initial install size and download bandwidth, especially
for users on metered connections.

### 11.7 Eco-mode pattern

A planned `EcoModeNotifier` (mirrors `ThemeModeNotifier`) will let users
opt into reduced energy consumption. When enabled:
- Animations are simplified or disabled
- Network refresh intervals are doubled
- Non-essential haptic feedback is disabled

Designed to complement Android Battery Saver and iOS Low Power Mode.

### 11.8 CI/CD pipeline

The project uses GitHub Actions for continuous integration and delivery.
Workflows live in `.github/workflows/`:

| Workflow | Trigger | Purpose |
|---|---|---|---|
| `ci.yml` | Pull request to `main` | Format check, `flutter analyze`, unit + widget tests, coverage report with PR comment |
| `build.yml` | Push to `main` | Re-runs all checks, injects `.env` from secrets, builds debug APK + AAB + release APK + AAB, uploads artifacts (90-day retention), and creates a GitHub release via `gh release create` (publish job) |
| `patrol-e2e.yml` | Weekly (Sun 03:00 UTC) | Patrol integration test suite on Android emulator |
| `flashlight.yml` | Weekly (Sun 04:00 UTC) | Flashlight battery/CPU/GPU profiling on emulator |
| `perfetto.yml` | Weekly (Sun 05:00 UTC) | Perfetto startup trace collection and frame-timing analysis |
| `deploy-to-playstore.yml` | Workflow dispatch (tag trigger disabled) | Signed release AAB, upload to Play Console internal track via `r0adkll/upload-google-play`. Tag push trigger is commented out pending Play Console document verification. |

> **Note:** The `publish` job in `build.yml` creates a GitHub release using
> `gh release create` with artifacts attached.

All workflows use SHA-pinned actions for supply-chain security. Dependabot
updates GitHub Action versions monthly. Runner: `ubuntu-latest` for QA and
build, `macos-latest` for emulator-based workloads (E2E, Flashlight, Perfetto).

Helper script in `scripts/`:
- `inject_env.sh` — creates `.env` from GitHub secrets for build-time config injection

### 11.9 Performance measurement

The CI pipeline integrates automated performance profiling:
- **Flashlight** — weekly automated battery, CPU, GPU profiling on emulator.
  Reports stored as artifacts; baseline comparison planned for PR gating.
- **Perfetto** — weekly startup and frame timing traces. Open in `ui.perfetto.dev`
  or parse with `perfetto` CLI for jank metrics.
- **Dart DevTools** — manual profiling during development: Performance page
  (widget rebuilds, oversized images) and CPU Profiler (Flame Chart for
  UI-thread blocking).

Reference: Flutter Heroes 2025 performance talk by Alexandre Moureaux (BAM)
— [github.com/bamlab/flashlight](https://github.com/bamlab/flashlight).

---

## 12. Monetization architecture — [Planned]

> **Not yet implemented.** All monetization features are deferred
> pending legal and accounting review. See `agents_docs/monetization.md`
> for the full deferred implementation plan.

The planned model uses three revenue streams:

- **AdMob** — banner and native ads on the free tier, hidden for Pro subscribers.
- **In-App Purchases** — three consumable donation tiers ($2.99–$9.99).
- **Pro subscription** — monthly ($0.99) and yearly ($9.99) auto-renewing, removes all ads and enables Firebase cloud backup.

---

## 13. Cloud backup architecture — [Planned]

> **Not yet implemented.** See `agents_docs/monetization.md` for the full
> deferred implementation plan.

Planned flow:
1. Export SQLite DB to a temp file.
2. Upload to Firebase Storage at `users/{uid}/pantry_backup.db`.
3. Restore replaces the local DB and invalidates all Riverpod providers.

Firebase Storage security rules will restrict access to the user's own data
via `users/{uid}/*` matching the auth token.

---

## 14. Ad placement reference — [Planned]

> **Not yet implemented.** Reserved for when AdMob is integrated.

Planned placements: banners on Home, Product Detail, Settings, Stats;
native ads in Search (every 5th); no ads on Scanner, Add Product, or
Cloud Backup screens.
