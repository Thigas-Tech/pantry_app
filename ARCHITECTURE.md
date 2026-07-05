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
│  apiServiceProvider        dioProvider                        │
│  productRepositoryProvider csvServiceProvider                 │
│  imageCacheProvider        notificationServiceProvider        │
└─────────┬────────────────────────────────────────────────────┘
          │  calls
┌─────────▼────────────────────────────────────────────────────┐
│                    Business Logic Layer                        │
│  services/                                                    │
│  ProductRepository    OpenFoodFactsApi    NotificationService │
│  CsvService           ImageCacheService                      │
└─────────┬──────────────┬──────────────────────────────────┘
          │              │
┌─────────▼────┐  ┌─────▼──────────────┐
│  Local DB    │  │  Remote API        │
│  database/   │  │  services/         │
│  SQLite      │  │  Open Food Facts   │
│  DAO pattern │  │  v3 REST (dio)     │
└──────────────┘  └────────────────────┘
```

---

## 2. Database layer (`lib/database/`)

### 2.1 Schema (version 2)

Three tables:

| Table         | Purpose                                                  |
|---------------|----------------------------------------------------------|
| `products`    | Cached product data from Open Food Facts. PK = barcode   |
| `inventories` | Named pantries (e.g. "Home", "Work"). PK = id            |
| `inventory`   | Instances of products in a pantry. FK → products, inventories |

### 2.2 DAO pattern

Each table has a dedicated Data Access Object:

| DAO                    | Responsibility                            |
|------------------------|-------------------------------------------|
| `ProductDao`           | Upsert / lookup products, count           |
| `InventoryDao`         | CRUD items, joined queries, export data   |
| `InventoriesDao`       | CRUD named pantries, migrations           |

Every DAO method receives a `Database` instance so it can be tested independently.

`DatabaseHelper` is the singleton that owns the connection, runs schema
migrations, and delegates CRUD to the DAOs.  It is the **only public entry
point** for database access in production code.

### 2.3 Migration strategy

- `_onCreate` runs when the database file is first created.
- `_onUpgrade` handles version bumps (currently v1 → v4).
- The `version` integer in `openDatabase` triggers the upgrade automatically.

Version history:
| Version | Change |
|---------|--------|
| v1 → v2 | Added `inventories` table, `inventory_id` column |
| v2 → v3 | Default unit `pcs` → `pieces`, migration of existing data |
| v3 → v4 | Added `nutriscore_grade TEXT` column to `products` |

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

- Uses `flutter_local_notifications` + `timezone` for timezone-aware scheduling.
- Two reminders per item: "Expiring soon" (1 day before) and "Expiring today".
- Notification IDs: `item.id.hashCode` and `item.id.hashCode + 1`.
- All notification strings are passed in by callers so they can be localized.

### 3.4 CSV import/export

- Export: generates a 17-column CSV joined with product nutrition, shared via `share_plus`.
- Import: picks a `.csv` file via `filegate`, parses it row-by-row, resumes on errors.

---

## 4. Provider layer (`lib/providers/`)

| Provider                        | Type              | Purpose                            |
|---------------------------------|-------------------|------------------------------------|
| `databaseProvider`              | `Provider`        | Singleton `DatabaseHelper`         |
| `dioProvider`                   | `Provider`        | Shared `Dio` HTTP client           |
| `apiServiceProvider`            | `Provider`        | Configured `OpenFoodFactsApi`      |
| `productRepositoryProvider`     | `Provider`        | Repository (DB + API)              |
| `csvServiceProvider`            | `Provider`        | CSV import/export                  |
| `imageCacheProvider`            | `Provider`        | Image download/cache (WebP)        |
| `notificationServiceProvider`   | `Provider`        | Expiry reminder scheduling         |
| `filegateProvider`              | `Provider`        | File picker (overridable in tests) |
| `activeInventoryProvider`       | `NotifierProvider`| Current pantry ID (default 1)      |
| `inventoryWithProductProvider`  | `FutureProvider`  | Joined inventory list for home     |
| `inventoryListProvider`         | `FutureProvider`  | All pantries (id, name)            |
| `averageNutriscoreProvider`     | `FutureProvider`  | Average Nutri-Score for inventory  |
| `connectivityProvider`          | `StreamProvider`  | Internet connectivity status       |
| `settingsProvider`              | `NotifierProvider`| Notifications, retention, threshold|

---

## 5. Screen / widget structure

```
HomeScreen
├── AppBar (title, switcher, stats, settings)
├── ErrorView (loading/error states)
├── EmptyPantry (empty state with scan prompt)
└── _InventoryList
    ├── SearchBar
    ├── RefreshIndicator (pull-to-refresh)
    └── ListView
        ├── SectionHeader (expired / expiring soon / good)
        └── InventoryCard (tappable, image, NutriScoreBadge, expiry dot + label)

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

ScannerScreen
├── PopScope (confirmation dialog on back)
├── _MobileScannerView (camera + ScannerOverlayPainter)
└── _ManualEntryView (text field + submit button)

SettingsScreen
├── Theme dialog (RadioGroup: system/light/dark)
├── Notifications switch
├── Data retention dialog (days input)
├── Expiring-soon threshold dialog
└── Manage Inventories link
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
2. **Product database** — `DatabaseHelper.clearProducts()` deletes all
   rows from the `products` table. On next startup, the background refresh
   in `main()` re-fetches every product from Open Food Facts with current
   data (including fields added in newer versions, e.g. `nutriscore_grade`).

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
