# TODO.md — Pantry App Roadmap

Open work only. Shipped work is documented in [CHANGELOG.md](CHANGELOG.md);
architecture and guides live under [docs/INDEX.md](docs/INDEX.md).

Items ordered: CI/CD first, then code health and features, then the deferred
monetization and paid-infrastructure work.

---

## CI/CD & DevOps

- [ ] **Kotlin Gradle Plugin (KGP) warning** — plugins `dynamic_color` and
  `mobile_scanner` apply KGP directly. Future Flutter versions will fail if
  plugins use KGP instead of Built-in Kotlin. Check each plugin's changelog
  for a version that supports Built-in Kotlin. If no such version exists,
  report the issue to the plugin authors.
- [ ] **Impeller EGL warnings** — `[ERROR:flutter/impeller/toolkit/egl/
  egl.cc(56)] EGL Error: Success (12288) in display.cc:161`. Research whether
  they indicate a misconfiguration or can be safely ignored, then document
  the conclusion in `docs/architecture/PERFORMANCE.md` section 11.7.
- [ ] **Skipped 35 frames on startup** — `[INFO] Skipped 35 frames! The
  application may be doing too much work on its main thread.` Expected on
  debug builds during first launch (DB init + product refresh). Verify on a
  release build; if it persists, investigate `_runDatabaseCleanup` and
  `main.dart` init ordering.

## Code health & performance

- [ ] **Thread strategy audit** — identify heavy work that blocks the UI
  thread: OFF API JSON parsing, image encoding. Offload to `Isolate` /
  `compute()` where beneficial. sqflite already runs on a background isolate
  internally.
- [ ] **NavigationRail** — adaptive sidebar layout for tablets/desktop
  alongside `NavigationBar`.
- [ ] **Repaint boundary enforcement** — add a lint rule or architecture doc
  requiring `RepaintBoundary` on widget subtrees that scroll independently,
  animate repeatedly, or sit inside `ListView`/`GridView` with many items.
  Never wrap entire screens.
- [ ] **Empty-pantry onboarding** — when inventory is empty, show a guided
  "scan your first item" flow instead of just the empty state widget.
- [ ] **Widget test → golden coverage** — product detail and settings screens
  (home and stats already have golden tests).
- [ ] **Remove functional debt** — audit for features that have been
  superseded, unused code paths (dead code after refactors), and outdated API
  endpoints. Older app versions with unused features cost server-side (API
  calls from orphaned clients) and client-side (larger APK, more rebuilds).
- [ ] **Low-end device testing program** — test the app on a physical
  low-end Android device (Samsung A10s or equivalent, 2 GB RAM) after every
  major feature. Dev machines are 10x+ faster than real user devices.
  Document baseline metrics: home screen scroll fps, product detail open
  time, search result render time, barcode scan init time. Reference:
  [Flutter Performance Best Practices](https://docs.flutter.dev/perf).
- [ ] **EcoCode Flutter rules contribution** — create Flutter-specific
  EcoCode rules based on the [ecoCode project](https://github.com/cnumr/ecoCode).
  Publish as a standalone ruleset. Rules would cover: `ListView()` vs
  `ListView.builder`, `setState` scope, `ShaderMask` grouping, `compute()`
  for heavy parsing, and image resolution checking.

## Features

- [ ] **Text extraction from product photos (OCR)** — let users take a photo
  of a product's nutrition facts table, ingredients list, or barcode and
  automatically extract text using on-device OCR. Pre-fill the registration
  form fields from the extracted text.

  **Implementation (Phase 1 — barcode + nutrition OCR)**:
  1. Add an ML Kit text-recognition Flutter plugin for on-device text
     recognition (no network required).
  2. On `AddProductScreen`, add a "Scan nutrition facts" button next to the
     nutrition photo field. Use OCR to extract energy, protein, carbs, fat,
     fiber, and salt values.
  3. Parse numerical values with regex patterns like
     `(\d+[,.]?\d*)\s*(kcal|kJ|g|mg)` and a mapping of known nutrient names
     in multiple languages (EN, PT to start).
  4. Pre-fill the corresponding form fields after a confirmation dialog
     ("Extracted values: ... Apply?").
  5. Extract the barcode from a photo via ML Kit barcode detection.
  6. New ARB strings: `scanNutrition`, `extractFromPhoto`,
     `extractedValues`, `applyExtracted`, `ocrFailed`, `ocrRetry`.

  **Pitfalls & edge cases**:
  - OCR accuracy varies: misread `0`/`O`, `1`/`l`, and decimal separators.
    Always show extracted values for confirmation — never silently fill.
  - Multi-language nutrient names (EN, PT, FR, ES, DE, IT, NL, PL, SV, DA).
  - Android/iOS only — gate behind a platform check and show a fallback on
    unsupported platforms.
  - APK size: ML Kit adds ~5-8 MB. Consider on-demand model download.
  - Handle horizontal and vertical nutrition table layouts; start with the
    most common orientation.
  - Warn on dark or blurry photos before running OCR.
  - Offline-first: ML Kit runs entirely on-device.
  - Run OCR through `compute()` and show a loading indicator.
  - Defer ingredient-list OCR (free-form, multi-language) to Phase 2.

- [ ] **Brand name aliases** — brands are never translated (proper nouns).
  Add a `brand_name_overrides` alias map for edge cases (for example
  Hungry Jack's to Burger King in Australia), plus a display helper to
  resolve them.

- [ ] **Allergen highlighting and "show original" toggle** — OFF provides
  `ingredients_text_with_allergens_XX` for some products. Render allergens
  in bold or colour when available, and add a toggle to show the original
  language text next to the localized ingredients.

  **Pitfalls**:
  - Allergen mistranslation is a safety hazard. Always show the disclaimer
    that the ingredients list is user-contributed and packaging must be
    checked.
  - `ingredients_text_with_allergens_XX` is not always available — fall back
    to plain text without highlighting. Never parse allergens manually.
  - The toggle switches the entire text block, not per-segment.
  - Request translation fields only on the detail screen to avoid payload
    bloat in search results.

- [ ] **Custom eco-mode** — implement `EcoModeNotifier` (similar to
  `ThemeModeNotifier`) with a toggle in Settings. When enabled: reduce
  animation complexity, throttle the network refresh interval, and disable
  non-essential haptic feedback. Detect battery level via `battery_plus`
  and suggest eco-mode when low. New ARB strings: `ecoMode`,
  `ecoModeDescription`, `ecoModeBatteryTip`.

- [ ] **Deferred components (Android dynamic features)** — split the app
  into on-demand APK modules: (1) scanner, (2) OFF API + search, (3)
  import/export. Users only download modules they use. Requires
  `dynamicFeature` in `build.gradle` and `split` attributes in
  `AndroidManifest.xml`. Reference:
  [Flutter Deferred Components](https://docs.flutter.dev/perf/deferred-components).

- [ ] **Multi-language support** — ARB infrastructure exists; add
  translations (fr, es, de). Contribute via community PRs.

- [ ] **Rebuild import/export** — export cached (API-fetched) products,
  export a specific inventory, and import via a platform file picker with
  format detection and error recovery.

- [ ] **Recipe suggestions (full UI)** — the weekly recipe notification from
  pantry inventory shipped. Add a richer recipe suggestions UI with
  filtering, saving, and meal planning that uses the same recipe API.

## Monetization (Play Store launch)

- [ ] **AdMob integration** — add `google_mobile_ads`, create an `AdService`
  (init, load banners/native ads, dispose), an `AdBanner` widget, and a
  `SearchNativeAd` widget. Banner on Home, Product Detail, Settings, Stats.
  Native ad in Search results (every 5th).
- [ ] **GDPR/LGPD consent flow** — UMP SDK consent on first launch,
  "Ad Preferences" toggle in Settings, privacy policy link.
- [ ] **Donation IAP** — add `in_app_purchase`, create a `DonationService`
  wrapping Play Billing. Three consumable tiers ($2.99, $4.99, $9.99).
  "Support Development" section in Settings.
- [ ] **Pro subscription** — monthly ($0.99) and yearly ($9.99)
  auto-renewing subscription. Removes all ads when active. Tied to the
  cloud backup feature below.

## Server-dependent / paid services

- [ ] **Cloud backup** — optional cloud sync/backup: upload the database to
  a cloud storage provider and restore it on a new device. Pending provider
  choice; includes last-backup metadata display and is gated behind the Pro
  subscription. **Costs**: S3 ($0.023/GB stored) or similar.
- [ ] **Backend for Frontend (BFF) evaluation** — evaluate offloading OFF
  API response transformation (JSON to model mapping) to a lightweight
  backend service. Tradeoff: reduces client CPU but adds server cost,
  deploy complexity, and latency. Only worthwhile when combined with other
  BFF benefits (API key hiding, response caching, multi-source aggregation).
  Defer the final decision to post-MVP.
