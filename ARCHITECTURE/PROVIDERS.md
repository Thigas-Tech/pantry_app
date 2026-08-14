## 4. Provider layer (`lib/providers/`)

### 4.0 Provider declaration convention

All providers MUST be declared with `@riverpod` code generation
(`riverpod_annotation` + `riverpod_generator`, see the Riverpod docs on
code generation). Hand-written `final xxxProvider = ...` declarations are
banned in new code; every provider file carries a `part 'xxx.g.dart'`
directive and its generated file is committed.

Lifecycle rules (preserve the manual semantics exactly when migrating):

| Manual form | Codegen form |
|---|---|
| `Provider` (keepAlive) | `@Riverpod(keepAlive: true)` on the function |
| `FutureProvider` / `StreamProvider` (keepAlive) | `@Riverpod(keepAlive: true)` with an `async`/`async*` function |
| `.autoDispose` variants and families | plain `@riverpod` (autoDispose is the default) |
| `Notifier` / `AsyncNotifier` | `@Riverpod(keepAlive: true)` class extending `_$X` |

Function-based providers take a plain `Ref` parameter (this generator
version does not emit per-provider `XxxRef` classes). Class-based
notifiers keep their public methods; the generated provider name is the
function/class name with the `Provider` suffix, so call sites and test
overrides never change.

The `select` extension lives in `flutter_riverpod` — import it where
`ref.watch(someProvider.select(...))` or provider-type doc references
(`[Provider]`, `[StreamProvider]`, ...) are used.

State that loads asynchronously (persisted prefs, DB validation) uses
`AsyncNotifier` with the load inside `build()` — never a sync notifier
that returns a placeholder and patches state later, which flashes wrong
UI for a frame. Consumers unwrap with `provider.future` (await) in async
paths and `.value ?? default` in build.

Once the migration is complete, `riverpod_lint`'s
`avoid_manual_providers` rule can be enabled in `analysis_options.yaml`
to enforce the convention mechanically.

| Provider | Type | Purpose |
|---|---|---|
| `databaseProvider` | `Provider` | Singleton `DatabaseHelper` |
| `apiServiceProvider` | `Provider` | Configured `OffAdapter` |
| `productRepositoryProvider` | `Provider` | Repository (DB + API) |
| `imageCacheProvider` | `Provider` | Image download/cache (WebP) |
| `notificationServiceProvider` | `Provider` | Expiry reminder scheduling |
| `statsProvider` | `FutureProvider` | Aggregated pantry statistics |
| `activeInventoryProvider` | `AsyncNotifierProvider` | Current pantry ID, persisted + DB-validated in build |
| `inventoryWithProductProvider` | `FutureProvider` | Joined inventory list for home |
| `inventoryListProvider` | `FutureProvider` | All pantries (id, name) |
| `inventoryCountProvider` | `FutureProvider` | Item count for active inventory |
| `averageNutriscoreProvider` | `FutureProvider` | Average Nutri-Score for inventory |
| `connectivityProvider` | `StreamProvider` | Internet connectivity status |
| `hasConnectionProvider` | `Provider` | Cached connectivity boolean |
| `settingsProvider` | `AsyncNotifierProvider` | Notifications, retention, threshold (loaded from prefs in build) |
| `themeModeProvider` | `AsyncNotifierProvider` | Light / dark / system theme (loaded from prefs in build) |
| `productSubmissionServiceProvider` | `Provider` | OFF product submission |
| `githubIssueServiceProvider` | `Provider` | GitHub Issues API wrapper |
| `priceRepositoryProvider` | `Provider` | Price CRUD + Open Prices sync |
| `priceHistoryProvider` | `FutureProvider.family` | Price history for (barcode, inventoryId) |
| `latestPriceProvider` | `FutureProvider.family` | Latest price for (barcode, inventoryId) |
| `pricesHiddenProvider` | `Provider<bool>` | Price visibility toggle (privacy mask) |
| `inventoryValueProvider` | `FutureProvider` | Total inventory value |
| `averagePriceProvider` | `FutureProvider` | Average item price |
| `pricedItemCountProvider` | `FutureProvider` | Count of priced items |
| `pendingSyncCountProvider` | `FutureProvider` | Open Prices pending sync count |
| `currencyServiceProvider` | `Provider` | Exchange rate conversion |
| `shoppingListProvider` | `FutureProvider` | Shopping list for active inventory |
| `pendingShoppingListProvider` | `FutureProvider` | Pending (not purchased) items |
| `purchasedShoppingListProvider` | `FutureProvider` | Purchased items |
| `pendingShoppingCountProvider` | `FutureProvider` | Pending item count |
| `storesProvider` | `FutureProvider` | Saved store names for autocomplete |
| `firebaseCacheProvider` | `Provider` | Singleton `FirebaseCacheService` |
| `inventoryProductsProvider` | `FutureProvider` | Distinct products from active inventory |
| `authServiceProvider` | `Provider` | `AuthService` (FirebaseAuth or no-op) |
| `authStateProvider` | `StreamProvider` | Reactive `AuthUser` stream |
| `searchPanelControllerProvider` | `NotifierProvider.family` | Async search state for SearchPanel (debounced query, source, in-pantry filter) |
