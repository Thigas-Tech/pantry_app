# AGENTS.md — Pantry App

An offline-first Flutter application for managing pantry inventory and expiry dates.

## Project overview

- **Stack:** Flutter (stable), Dart 3.12+, Riverpod 3.x, SQLite (sqflite)
- **Platforms:** Android (primary), iOS, Linux, macOS, Web, Windows
- **State management:** Riverpod (`flutter_riverpod`)
- **Database:** SQLite via `sqflite` with DAO pattern (see `lib/database/`)
- **API:** Open Food Facts v3 REST API via `dio`
- **Code generation:** freezed, json_serializable (via `build_runner`)
- **Linting:** `very_good_analysis`, `lint/strict`, `flutter_lints`
- **Testing:** `flutter_test` + `mocktail`
- **Localization:** ARB files in `lib/l10n/`, code-generated via `flutter gen-l10n`

## Commands

```bash
# Run all generators (always do this after changing models or l10n)
dart run build_runner build --delete-conflicting-outputs
flutter gen-l10n

# Analyze
flutter analyze

# Test (all)
flutter test --concurrency=8

# Test with coverage
flutter test --concurrency=8 --coverage

# Build
flutter build apk --debug          # debug APK
flutter build apk                   # release APK
flutter build appbundle --debug    # debug AAB
flutter build appbundle            # release AAB
```

## Rules for contributions

### Always
0. **Check TODO.md** — before starting new work, consult `TODO.md` for the current roadmap and pick an item at the appropriate effort/importance level.
1. **Doc comments** — every public class, constructor, field, and method must have a `///` doc comment. Run `flutter analyze` to verify (zero issues required).
2. **Tests** — add tests for ALL new code. Use `mocktail` for mocks. Place tests in the corresponding `test/` subdirectory. New screens/services need new test files.
3. **Update generated code** — after changing models (freezed) or ARB files (l10n), run `dart run build_runner build --delete-conflicting-outputs` AND `flutter gen-l10n`.
4. **Localize** — all user-visible strings go in `lib/l10n/app_en.arb`. Never hardcode English strings in widgets or services (except in doc comments).
5. **Run the full suite** — before committing: `flutter analyze && flutter test --concurrency=8`. Zero issues, all tests passing.
6. **Update documentation** — after making changes, update `CHANGELOG.md`, `README.md`, `ARCHITECTURE.md`, and/or `AGENTS.md` to reflect new features, structure changes, or updated commands. Always generate fresh API docs with `dart doc .`.
7. **Update CHANGELOG.md** — after every feature addition, bugfix, or significant change, add an entry under `[Unreleased]` grouped by category. Keep entries concise and user-facing. This is the canonical record of what ships in each release.
8. **Set Product.source** — every `Product()` constructor call MUST pass `source`. Use `'api'` for OFF‑fetched data and `'manual'` for user‑entered or CSV‑imported data. The default is `'api'`. Never omit this field — it protects manual products from being deleted by `clearCachedProducts()` during cache flushes.

### Code style
- 80-character line limit (enforced by lint)
- Single quotes for strings
- Explicit return types on all public methods
- Use `const` constructors where possible
- Prefer Riverpod `Provider`/`NotifierProvider` for state
- Use `unawaited()` for fire-and-forget futures (import `dart:async`)

### Architecture
```
lib/
  config.dart          # App-wide configuration (credentials, flags)
  main.dart            # Entry point, ProviderScope, DynamicColorBuilder
  database/
    database_helper.dart  # Singleton, schema/migrations, public API
    product_dao.dart      # Product table CRUD
    inventory_dao.dart    # Inventory items CRUD + join queries
    inventories_dao.dart  # Named pantries CRUD
  l10n/                  # ARB files + generated Dart localizations
  models/                # Freezed models (Product, InventoryItem, InventoryWithProduct)
  providers/             # Riverpod providers (state, DI)
  screens/               # UI pages
  services/              # Business logic (API, repository, CSV, notifications)
  utils/                 # Helpers (logger, snackbar)
  widgets/               # Reusable widgets
test/
  helpers/pump_app.dart  # Widget test harness
  database/              # Database tests
  models/                # Model tests
  providers/             # Provider tests
  screens/               # Screen/widget tests
  services/              # Service tests
  utils/                 # Utility tests
  widgets/               # Widget tests
```

### Credentials & security
- API credentials are stored in `.env` (loaded by `flutter_dotenv` — see `lib/config.dart`)
- **Never commit `.env`** — it is excluded via `.gitignore`
- `.env.example` is committed as a template with placeholder values
- For release, set `OFF_USER_ID` and `OFF_PASSWORD` in `.env`
- `CONTACT_EMAIL` is used in the User-Agent header

### Testing notes
- Use `pumpApp()` from `test/helpers/pump_app.dart` for widget tests — it provides Riverpod scope, l10n, and a stubbed image cache
- Database tests use `DatabaseHelper.withPath(':memory:')` with `sqflite_common_ffi`
- For screens with MobileScanner, use `settle: false` and manual `pump()` — perpetual animations prevent `pumpAndSettle`
- Mock `NotificationService`, `ProductRepository`, and `ImageCacheService` with mocktail

## API documentation (`dart doc`)

`dart doc` generates HTML API reference from Dart source code using `///`
doc comments.  It is part of the Dart SDK — no extra install needed.

### Writing docs

Use `///` (or `/** ... */`) documentation comments.  They support **Markdown**.
Follow the [Effective Dart: Documentation](https://dart.dev/effective-dart/documentation) guide.

### Generating

```bash
dart doc .                     # output → doc/api
dart doc --output=api_docs .   # custom output dir
dart doc --dry-run .            # check for issues without writing files
```

### Configuring

Create `dartdoc_options.yaml` in the project root to customize generation.
See [dart.dev/go/dartdoc-options-file](https://dart.dev/go/dartdoc-options-file).

### Viewing locally

The generated HTML uses JavaScript for search/sidebar and must be served
through an HTTP server:

```bash
dart pub global activate dhttpd
dart pub global run dhttpd --path doc/api
# Open http://localhost:8080
```

### Troubleshooting

- **Search / sidebar broken** — docs are not served via HTTP, or `index.json` is missing.
- **Missing API docs** — `dart doc` only generates for **public** libraries and members. Check your package's public exports.
- **Case‑sensitive URLs** — file names match source declarations exactly and end with `.html`.
- **Icons as text** — browser failed to load Material Symbols font. Proxy Google Fonts or use a local copy.

### Core library docs

The official Dart core library API reference at [api.dart.dev](https://api.dart.dev) is also built with `dart doc`.
