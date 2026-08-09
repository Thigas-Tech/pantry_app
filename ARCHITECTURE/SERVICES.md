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
      └────────┘
```

1. **Check local cache** — if the product exists in SQLite, return it immediately.
2. **Call primary API** — if not cached, fetch from Open Food Facts and store locally.
3. **Fallback (offline)** — if no connectivity, skip API and go directly to manual entry form.

**Exception hierarchy:**

| Exception                      | Meaning                             | UI reaction                       |
|--------------------------------|-------------------------------------|-----------------------------------|
| `ProductNotFoundException`     | Barcode unknown to all sources      | Scanner opens the contribution form |
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

> **Not yet implemented.** See `docs/superpowers/agents/monetization.md` for the full
> deferred implementation plan.

- Planned: `google_mobile_ads` for banner and native ads across free tier screens.
- Consent managed via UMP SDK (GDPR/LGPD) on first launch.
- Ad unit IDs read from `.env`, using test IDs in debug mode and production IDs in release.

### 3.5 Donation and subscription service (Play Billing) — [Planned]

> **Not yet implemented.** See `docs/superpowers/agents/monetization.md` for the full
> deferred implementation plan.

- Planned: `in_app_purchase` plugin wrapping Google Play Billing.
- Donation products: three consumable tiers ($2.99, $4.99, $9.99).
- Pro subscription: auto-renewing, monthly ($0.99) and yearly ($9.99).
- `isPro` flag derived from `queryPastPurchases()` — checked before showing ads and enabling cloud backup.

### 3.6 Firebase cache service

- `FirebaseCacheService` manages a **two-tier cache** for product data using
  Cloud Firestore as a persistent remote cache alongside the local SQLite DB.
- **Firestore collections**: `product_cache/{barcode}` for OFF barcoded items
  and `produce_cache/{name}` for USDA produce items.
- **Lookup chain**: SQLite → Firestore → OFF/USDA API → fallback. Firestore
  acts as a mid-tier cache that survives local cache flushes.
- **180-day rolling refresh**: Each cache entry stores a `lastRefreshedAt`
  timestamp. Entries are refreshed only after 180 days (configurable via
  `FirebaseCacheMetaDao`), respecting Firestore free-tier daily write limits.
- **Graceful degradation**: If Firebase is disabled, unavailable, or the
  project has no authentication configured, the cache service sets
  `isAvailable: false` and all operations become no-ops. No errors propagate
  to the UI.
- **Dependencies**: `firebase_core`, `cloud_firestore`, `firebase_auth`.
  All three are optional (`FIREBASE_ENABLED` flag in `.env`).
- **Auth requirement**: Firestore security rules require `request.auth != null`
  for writes. Anonymous Firebase Auth is enabled at app startup.

### 3.7 Feedback service (GitHub Issues)

- `GithubIssueService` -- HTTP POST to GitHub Issues API with PAT from
  `.env` (`FEEDBACK_TOKEN`), never committed.
- Offline queue: unresolved issues stored in `feedback_queue` SQLite table
  (version 11 migration). Flushed when `connectivityProvider` emits `true`
  via listener in `PantryShell` and at app startup.
- Screenshots: user attaches from gallery or camera via `image_picker`,
  encoded as WebP (800px max, compact) and uploaded to catbox.moe,
  producing rendered image URLs in GitHub issues. Falls back to a
  collapsible base64 block if the upload fails.
- Rate limiting: max 1 issue per 60 seconds, max 5 per 24h per device
  (via `SharedPreferences` counters).
- Duplicate detection: hash of title+body, skipped if submitted within 24h.
- Platform gating: on web/mobile the feedback from opens the `FeedbackScreen`;
  screenshot attachment hidden on web and desktop platforms.

### 3.8 Price repository

- `PriceRepository` -- wraps `File` (currently no proof upload; prices
  stored locally), `PriceDao`, `CurrencyService`, and `OpenPricesService`.
- All price CRUD delegates to `PriceDao`. The repository normalises currency
  via `CurrencyService` when displaying prices.
- `OpenPricesService.syncPendingPrices()` flushes pending prices (with proof
  photos) to the Open Prices API. Currently marks all pending prices as synced
  locally while proof upload is stubbed.
- `refreshInventoryPrices()` fetches fresh prices from the API for all
  products in a pantry, used by pull-to-refresh on the stats screen.

### 3.9 Currency service

- `CurrencyService` -- fetches exchange rates from
  [ExchangeRate-API](https://open.er-api.com/) (free, no key required).
- Caches rates locally in `SharedPreferences` with a 24h TTL.
- `convert(amount, from, to)` converts a monetary amount between ISO 4217
  currencies using the cached rate.

### 3.10 Open Prices API client

- `OpenPricesApiClient` -- HTTP client for
  [Open Prices API](https://prices.openfoodfacts.org/api/docs).
- `fetchPricesByBarcode(barcode)` returns `List<RemotePrice>`.
- `submitPrice(price, proofPhoto)` posts a new price observation (stub -- proof
  photo upload not yet wired).
- `validateToken(token)` checks whether an API token is valid.

### 3.11 Shopping list

- `ShoppingListDao` -- all shopping list CRUD scoped to the active inventory.
  Items can have optional barcode links to products, quantities, units, and
  price fields.
- `addShoppingItem` and other mutation functions in
  `providers/shopping_list_provider.dart` manage state invalidation and DB
  writes.

### 3.12 Photo service

- `PhotoService` -- manages price tag photos keyed by shopping item ID.
  `deletePhotoForItem` removes the photo when a shopping item is deleted.
  Used by the shopping list flow to clean up cached photos.

### 3.13 Store persistence

- `StoreDao` -- stores saved store names in the `stores` table (version 19
  migration). `insert` is case-insensitive and deduplicates. `getAll` returns
  stores ordered alphabetically.
- The price entry sheet uses `storesProvider` (FutureProvider) to power an
  `Autocomplete<String>` dropdown with a "+" add-new button.
- New store names submitted through the price entry sheet are automatically
  persisted to the `stores` table.

### 3.14 USDA API client

- `UsdaApiClient` -- HTTP client for the
  [USDA FoodData Central API](https://fdc.nal.usda.gov/).
  Used as a nutritional fallback when a produce item (PLU code) is not found
  in Open Food Facts.
- Fetches product data by PLU code via `GET /fdc/v1/foods/search`.
- API key is read from `.env` (`USDA_API_KEY`) and sent as a URL query
  parameter. Returns a distinct `usdaAuthFailed` message on 403.

### 3.15 Produce category mapper

- `ProduceCategoryMapper` -- maps PLU codes and produce names to OFF
  taxonomy categories with a fallback heuristic based on produce type
  (fruit, vegetable, herb, mushroom).

### 3.16 Produce nutrition fallback

- `ProduceNutritionFallback` -- hard-coded approximate nutrition values
  for ~70 common produce items (energy, protein, carbs, fat, fiber).
  Used when the USDA API is unreachable or the PLU code is not in the
  USDA database.

### 3.17 Produce serving presets

- `ProduceServingPresets` -- maps ~35 produce names to Small/Medium/Large
  serving sizes with `servingWeightG` defaults for the weight/unit toggle.

### 3.18 Produce purchase tracker

- `ProducePurchaseTracker` -- tracks how often the user buys each produce
  item via SharedPreferences. Used by the quick-add carousel to surface
  frequently-bought items.

### 3.19 PLU service

- `PluService` -- local lookup table of ~70 common PLU codes (e.g. 4011
  for Banana) mapped to produce names. Used for barcode-less produce
  entry on the scanner screen.

### 3.20 Changelog loader

- `ChangelogLoader` utility at `lib/utils/changelog_loader.dart` provides
  `loadLocalizedChangelog(Locale)` that resolves locale-specific
  `USER_CHANGELOG_*.md` asset paths with fallback to English. Used by
  the "What's New" sheet to display user-facing changelog in the app's
  current language.

### 3.21 Product photo picker

- `ProductPhotoPicker` (at `lib/services/product_photo_picker.dart`)
  picks product photos from the camera or the device gallery for the
  manual product form.
- Camera picks first request the camera permission; gallery picks go
  through the system picker and never request a permission. Both sources
  compress the result to 1600 x 1600 px at quality 85 so Open Food Facts
  uploads stay small.
- `ImagePicker` and the camera permission check are injectable for tests;
  the result is modeled by the sealed `PhotoPickResult` type
  (`PhotoPicked`, `PhotoPermissionDenied`, `PhotoPickCancelled`).
  Exposed to screens via `productPhotoPickerProvider`.
- Camera permission denials surface a dialog with an "Open Settings"
  action (`showCameraPermissionDialog` at
  `lib/utils/camera_permission_dialog.dart`).

### 3.22 Product image service

- `ProductImageService` (at `lib/services/product_image_service.dart`) is
  the testable boundary for product photo persistence in the manual form.
  It copies picked files into deterministic managed paths under
  `product_images` using the `<barcode>_<suffix>.jpg` convention, with the
  suffix (`nutrition`/`ingredients`/`product`) derived from `ImageField`.
- `assign` copies a picker file into its managed path immediately so the
  photo survives form validation failures and OS cache purges; replacing a
  slot overwrites the same managed file so no stale copies accumulate.
- `remove` only clears the slot. Physical deletion is deferred to `save` or
  `cleanupUncommitted` so the undo action can restore a live file while the
  form is still open.
- `save` persists every non-empty slot, deletes stale managed files for
  empty slots (never when another slot still references the path), and
  returns the three managed paths as `SavedProductPhotoPaths` for the
  `Product` model.
- `cleanupUncommitted` runs from `AddProductScreen.dispose()` (unawaited)
  and deletes managed files for a barcode that were never committed to a
  saved product, preserving paths listed in `committedPaths`. This keeps
  backing out of the form free of orphaned files.
- `deleteOrphanedFiles` runs from `ProductDetailScreen.dispose()`
  (unawaited) and removes managed files for a barcode that no currently
  referenced slot uses. Photos deleted from the detail screen keep their
  physical file so undo restores a live photo while the screen is open;
  this method cleans those files up when the screen is left, while paths
  in `referencedPaths` (the current non-null photo paths) are preserved.
- Barcodes are sanitized against path separators before forming file names.
  The image directory resolves to the application-documents `product_images`
  folder at runtime and is injectable for tests. Exposed to screens via
  `productImageServiceProvider` (`lib/providers/product_image_service_provider.dart`).
- The slot snapshot is modeled by the immutable `ProductPhotoSlots`
  (`lib/models/product_photo_slots.dart`).
