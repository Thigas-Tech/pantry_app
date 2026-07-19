## 4. Provider layer (`lib/providers/`)

| Provider | Type | Purpose |
|---|---|---|
| `databaseProvider` | `Provider` | Singleton `DatabaseHelper` |
| `apiServiceProvider` | `Provider` | Configured `OffAdapter` |
| `productRepositoryProvider` | `Provider` | Repository (DB + API) |
| `imageCacheProvider` | `Provider` | Image download/cache (WebP) |
| `notificationServiceProvider` | `Provider` | Expiry reminder scheduling |
| `statsProvider` | `FutureProvider` | Aggregated pantry statistics |
| `activeInventoryProvider` | `NotifierProvider` | Current pantry ID (default 1) |
| `inventoryWithProductProvider` | `FutureProvider` | Joined inventory list for home |
| `inventoryListProvider` | `FutureProvider` | All pantries (id, name) |
| `inventoryCountProvider` | `FutureProvider` | Item count for active inventory |
| `averageNutriscoreProvider` | `FutureProvider` | Average Nutri-Score for inventory |
| `connectivityProvider` | `StreamProvider` | Internet connectivity status |
| `hasConnectionProvider` | `Provider` | Cached connectivity boolean |
| `settingsProvider` | `NotifierProvider` | Notifications, retention, threshold |
| `themeModeProvider` | `NotifierProvider` | Light / dark / system theme |
| `productSubmissionServiceProvider` | `Provider` | OFF product submission |
| `githubIssueServiceProvider` | `Provider` | GitHub Issues API wrapper |
| `priceRepositoryProvider` | `Provider` | Price CRUD + Open Prices sync |
| `priceHistoryProvider` | `FutureProvider.family` | Price history for a barcode |
| `latestPriceProvider` | `FutureProvider.family` | Latest price for a barcode |
| `pricesHiddenProvider` | `FutureProvider` | Price visibility toggle |
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
| `photoServiceProvider` | `Provider` | Camera/gallery photo capture |
| `firebaseCacheProvider` | `Provider` | Singleton `FirebaseCacheService` |
| `inventoryProductsProvider` | `FutureProvider` | Distinct products from active inventory |
| `authServiceProvider` | `Provider` | `AuthService` (FirebaseAuth or no-op) |
| `authStateProvider` | `StreamProvider` | Reactive `AuthUser` stream |
