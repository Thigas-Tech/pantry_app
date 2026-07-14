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

- `GithubIssueService` -- HTTP POST to GitHub Issues API with PAT from
  `.env` (`GITHUB_FEEDBACK_TOKEN`), never committed.
- Offline queue: unresolved issues stored in `feedback_queue` SQLite table
  (version 11 migration). Flushed when `connectivityProvider` emits `true`
  via listener in `PantryShell` and at app startup.
- Screenshots: user attaches from gallery or camera via `image_picker`,
  encoded as PNG base64, embedded as data URI in issue body (no external
  CDN needed -- GitHub renders data URIs natively).
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

- `PhotoService` -- wraps `image_picker` for camera and gallery capture.
  Used by the price entry sheet and product submission flow to attach proof
  photos and product images.

### 3.13 Store persistence

- `StoreDao` -- stores saved store names in the `stores` table (version 19
  migration). `insert` is case-insensitive and deduplicates. `getAll` returns
  stores ordered alphabetically.
- The price entry sheet uses `storesProvider` (FutureProvider) to power an
  `Autocomplete<String>` dropdown with a "+" add-new button.
- New store names submitted through the price entry sheet are automatically
  persisted to the `stores` table.
