# Pantry App

An offline-first Flutter application to manage your pantry inventory and track
expiration dates. Scan barcodes, look up products via Open Food Facts, and
never waste food again.

[![CI](https://github.com/Thigas-Tech/pantry_app/actions/workflows/ci.yml/badge.svg)](https://github.com/Thigas-Tech/pantry_app/actions/workflows/ci.yml)
[![Build](https://github.com/Thigas-Tech/pantry_app/actions/workflows/build.yml/badge.svg)](https://github.com/Thigas-Tech/pantry_app/actions/workflows/build.yml)

## Features

- **Barcode scanning** — camera-based via Google ML Kit (`mobile_scanner`) or manual text entry
- **Product lookup** — fetches name, brand, nutrition, ingredients from Open Food Facts
- **Local database** — products are cached locally in SQLite; works without internet for known items
- **Cloud product cache** — Firestore-backed 180-day rolling cache for OFF barcoded and USDA produce products with offline-first fallback
- **Multiple pantries** — create, rename, and delete named inventories (e.g. Home, Work)
- **Expiry tracking** — items grouped into Expired / Expiring Soon / Good on the home screen
- **Local notifications** — two reminders per item: one day before expiry and on expiry day
- **Custom units & locations** — pieces / g / kg / ml / L + pantry / fridge / freezer, with custom options
- **Nutrition table** — energy, protein, carbs, fat, fiber, salt per 100 g / 100 ml
- **Material You** — dynamic colours from your device wallpaper, light/dark/system theme
- **Undo delete** — restore an accidentally deleted inventory item with a snackbar action
- **Offline-first** — connectivity detection skips API when offline, warns the user, and uses cached data
- **Pull-to-refresh** — updates cached product data from Open Food Facts when online
- **Nutri-Score** — A–E badges on the home screen and product detail, with average per pantry and grey dash for non-applicable products
- **Manual product entry** — full form with nutrition table and camera capture when a barcode is unknown or you're offline
- **Price tracking** — record purchase prices with store, date, and currency; view price history and total inventory value
- **Shopping list** — add items from cached products or free-text, mark as purchased, batch-move to pantry
- **Store autocomplete** — saved store names persist across uses, suggested in the price entry sheet
- **Barcode history** — the last 50 scanned barcodes are kept locally and shown as a "Recent scans" strip on the home screen, with one-tap quick-add straight to your pantry

## Screenshots

Screenshots will be added here: Home, Scanner, Product Detail, Settings.

## Getting started

### Prerequisites

- Flutter SDK (stable channel)
- Android SDK / Xcode (for iOS)
- A device or emulator with a camera for barcode scanning

### Setup

```bash
git clone https://github.com/your-org/pantry_app.git
cd pantry_app
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter gen-l10n
```

### Configure Open Food Facts credentials

Copy the environment template and fill in your credentials:

```bash
cp .env.example .env
```

Then edit `.env`:

```env
OFF_USER_ID=your_off_user_id_here
OFF_PASSWORD=your_off_password_here
CONTACT_EMAIL=you@example.com
USE_OFF_STAGING=false
```

Leave `OFF_USER_ID` and `OFF_PASSWORD` empty if you don't plan to submit products.
The `.env` file is **never** committed to git — it is listed in `.gitignore`.

### Run

```bash
flutter run
```

### Build

```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk

# Release App Bundle (Play Store)
flutter build appbundle

# Debug App Bundle
flutter build appbundle --debug
```

## Project structure

```
lib/
  config.dart          # API credentials and flags
  main.dart            # Entry point
  database/
    database_helper.dart   # Singleton, schema, migrations
    product_dao.dart       # Product table CRUD
    inventory_dao.dart       # Inventory items CRUD + joins
    inventories_dao.dart     # Named pantries CRUD
    feedback_queue_dao.dart  # Offline feedback submission queue
    price_dao.dart           # Price observations CRUD + aggregation
    shopping_list_dao.dart   # Shopping list CRUD (per-inventory)
    store_dao.dart           # Saved store names CRUD
    product_submission_queue_dao.dart  # OFF submission queue
    firebase_cache_meta_dao.dart  # Firestore cache sync metadata
  l10n/                # App translations (English ARB)
  models/              # Freezed data models
  providers/           # Riverpod state & dependency injection
  screens/             # UI pages
  services/            # Business logic
    product_repository.dart   # Offline-first product cache + API
    off_adapter.dart          # Open Food Facts API wrapper
    firebase_cache_client.dart  # Firestore read/write client
    firebase_cache_service.dart  # 180-day Firestore cache coordinator
    firebase_firestore_client_adapter.dart  # Serialization adapter
    auth_service.dart         # Firebase Auth / no-op
    firebase_auth_service.dart   # Firebase anonymous auth
    notification_service.dart  # Expiry reminder scheduling
    image_cache_service.dart   # WebP image download & cache
    price_repository.dart      # Price CRUD + Open Prices sync
    currency_service.dart      # Exchange rate conversion
    open_prices_api_client.dart  # Open Prices API HTTP client
    open_prices_service.dart     # Open Prices sync coordinator
    github_issue_service.dart    # GitHub Issues API wrapper
    photo_service.dart           # Price tag photo cleanup for shopping items
    plu_service.dart             # PLU code lookup for produce
    product_submission_service.dart  # OFF offline submission queue
  utils/               # Logger, snackbar helpers
  widgets/             # Reusable components
test/                  # Unit and widget tests
```

For a deep dive into the architecture, see [ARCHITECTURE/INDEX.md](https://github.com/Thigas-Tech/pantry_app/blob/main/ARCHITECTURE/INDEX.md).

## Contributing

See [ARCHITECTURE/INDEX.md](https://github.com/Thigas-Tech/pantry_app/blob/main/ARCHITECTURE/INDEX.md) for the full architecture overview.

### Quick rules

1. **Doc comments** — every public class, constructor, field, and method must have `///` docs
2. **Tests** — add tests for ALL new code using `mocktail`
3. **Localization** — all user-visible strings go in `lib/l10n/app_en.arb`
4. **Code generation** — after changing models or ARB files, run `build_runner` and `flutter gen-l10n`
5. **Zero lint issues** — `dart analyze` must report zero issues before committing
6. **All tests pass** — `flutter test --concurrency=2` must pass before committing

### Running checks

```bash
dart analyze                         # Lint + static analysis
flutter test --concurrency=2         # All tests
flutter test --concurrency=2 --coverage  # With coverage
```

## Tech stack

| Category           | Technology                       |
|---|---|---|
| Framework          | Flutter (stable)                 |
| Language           | Dart 3.12+                      |
| State management   | Riverpod 3.x                    |
| Local database     | SQLite (sqflite)                |
| Cloud database     | Cloud Firestore                  |
| HTTP client        | http                             |
| OFF SDK            | openfoodfacts                   |
| Code generation    | freezed, json_serializable      |
| Barcode scanning   | mobile_scanner (Google ML Kit)  |
| Image capture      | image_picker                    |
| Notifications      | flutter_local_notifications     |
| Connectivity       | internet_connection_checker     |
| Testing            | flutter_test + mocktail         |
| Linting            | very_good_analysis, lint/strict |
| Theming            | dynamic_color (Material You)    |

## License

MIT

## API documentation

`dart doc` generates HTML API reference from Dart source code using `///`
doc comments. It ships with the Dart SDK — no extra install required.

### Generating

```bash
dart doc .                     # output → doc/api
dart doc --dry-run .            # check for issues without writing files
```

### Viewing locally

The HTML uses JavaScript for search; serve it through an HTTP server:

```bash
dart pub global activate dhttpd
dart pub global run dhttpd --path doc/api
# Open http://localhost:8080
```

Opening the files directly in a browser will break search and the sidebar.

### Troubleshooting

- **Search / sidebar broken** — not served via HTTP, or `index.json` missing.
- **Missing API docs** — `dart doc` only generates for **public** libraries and members.
- **Icons as text** — browser failed to load Material Symbols font; proxy or use a local copy.
