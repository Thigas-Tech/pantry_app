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
| `currentLocaleProvider` | `Provider` | Current platform `Locale` (dart:ui dispatcher) |
| `settingsProvider` | `AsyncNotifierProvider` | Notifications, retention, threshold (loaded from prefs in build) |
| `themeModeProvider` | `AsyncNotifierProvider` | Light / dark / system theme (loaded from prefs in build) |
| `productSubmissionServiceProvider` | `Provider` | OFF product submission |
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
| `cacheStalenessStoreProvider` | `Provider` | SharedPreferences-backed last-refresh timestamp store |
| `inventoryProductsProvider` | `FutureProvider` | Distinct products from active inventory |
| `searchPanelControllerProvider` | `NotifierProvider.family` | Async search state for SearchPanel (debounced query, source, in-pantry filter) |
| `marketTripItemControllerProvider` | `NotifierProvider.family` | Adds a scanned/produce item to a market trip as purchased, applying optional price + expiry (autoDispose, keyed by trip inventory id) |
| `mobileScannerControllerProvider` | `Provider` | Auto-disposed `MobileScannerController` for the scanner camera |
| `scannerCameraProvider` | `NotifierProvider` | Scanner camera lifecycle + scan resolution |

### 4.1 Market trip item controller

`marketTripItemControllerProvider(tripId)` owns the single unit of work that
adds a scanned (or produce-searched) product to a trip: it marks a pending
row purchased, or merges into an existing purchased row by quantity, or
inserts a new purchased row, then writes an optional price and expiry and
invalidates the shopping list providers. The confirm screen keeps the
autoDispose notifier alive for the screen's lifetime by watching its
`.notifier` in `build`; when the screen pops the notifier is disposed.

**Async-gap safety**: the notifier is autoDispose, so if the confirm screen
is popped while `addScannedProduct` is in flight, the provider is disposed
and `ref`/`state` can no longer be used. Every `await` in the method is
followed by a `ref.mounted` guard (returning `null` early) and the `catch`/
`finally` state writes are guarded the same way, so a dispose mid-add
completes cleanly instead of throwing "Ref after it has been disposed". The
confirm screen also wraps itself in `PopScope(canPop: !_saving)` so the
system back button cannot pop it while the add is being persisted.

### 4.2 Deferred provider invalidations

Invalidating a provider during a widget build phase is not allowed by
Riverpod: if a provider whose `build` uses `ref.watch` is dirty when a route
pop resumes a paused subscriber (e.g. `Pantry` when the market trip pops
during its `TickerMode` rebuild), the refresh can be scheduled mid-build and
throws "setState() or markNeedsBuild() called during build" on the app's
`UncontrolledProviderScope`. Invalidations that can coincide with a route
transition therefore run through `afterFrame()` in
`lib/utils/deferred_refresh.dart`, which defers them to the end of the
current frame so the refresh flushes in a normal frame. Callers guard the
deferred callback with their own mounted checks (`State.mounted`,
`context.mounted`, or `Ref.mounted`); if the owning widget is disposed
before the callback fires, the refresh is skipped (pops animate over ~300 ms
and the home screen is keep-alive, so this is unreachable in practice).
