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
