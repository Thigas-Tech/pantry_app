## 2. Database layer (`lib/database/`)

### 2.1 Schema (version 1)

Eleven tables:

| Table | Purpose |
|---|---|
| `products` | Cached product data from Open Food Facts. PK = barcode. Includes `source` column: `'api'` (OFF-fetched, flushable) or `'manual'` (user-entered, protected). |
| `inventories` | Named pantries (e.g. "Home", "Work"). PK = id |
| `inventory` | Instances of products in a pantry. FK -> products, inventories |
| `product_submission_queue` | Offline queue for OFF product submissions |
| `prices` | Purchase price observations per barcode, scoped to their owning inventory via `inventory_id`, with optional package size for per-unit pricing |
| `shopping_list` | Items the user intends to buy |
| `stores` | Saved store names for autocomplete on price entry |
| `recipes` | User-created recipes, scoped to their owning inventory via `inventory_id` |
| `recipe_ingredients` | Ingredients linked to a recipe |
| `recipe_history` | Audit log of recipes marked as made |
| `scan_history` | Self-contained snapshots of the latest successful scans (capped at 50) |

### 2.2 DAO pattern

Each table has a dedicated Data Access Object:

| DAO | Responsibility |
|---|---|
| `ProductDao` | Upsert / lookup products, count, source-aware queries |
| `InventoryDao` | CRUD items, joined queries |
| `InventoriesDao` | CRUD named pantries, migrations |
| `ProductSubmissionQueueDao` | CRUD offline submission queue |
| `PriceDao` | CRUD prices, quantity-scaled aggregation queries (total value, average, monthly/store spending) |
| `ShoppingListDao` | CRUD shopping list items, per-inventory scoped |
| `StoreDao` | CRUD saved store names, case-insensitive lookup |
| `RecipeDao` | CRUD recipes |
| `RecipeIngredientDao` | CRUD recipe ingredients |
| `RecipeHistoryDao` | CRUD recipe history entries |
| `ScanHistoryDao` | CRUD scan history, bounded pruning (keep newest 50) |

Every DAO method receives a `Database` instance so it can be tested
independently. DAOs that must compose inside transactions (such as
`ScanHistoryDao`) accept a `DatabaseExecutor` instead, which covers both a
`Database` and a `Transaction`.

**Atomic multi-step writes**: `DatabaseHelper` wraps multi-statement
destructive operations (`clearCachedProducts`,
`flushExpiredCachedProducts`, `cleanupOldEntries`) in a `db.transaction` so
a mid-operation failure rolls back every earlier write. Because
`PRAGMA foreign_keys` is a no-op inside a transaction, the FK toggle stays
outside the transaction boundary; `cleanupOldEntries` runs its own deletes
in one transaction and then calls the self-contained
`flushExpiredCachedProducts` afterwards to avoid nesting transactions.

`DatabaseHelper` is the singleton that owns the connection, runs schema
migrations, and delegates CRUD to the DAOs.  It is the **only public entry
point** for database access in production code.

**Null safety rule**: All row value access MUST use null-coalescing
(`as T? ?? defaultValue`) instead of the null-check operator (`!`).
Aggregate functions (SUM, AVG) return NULL when the result set is empty,
and schema columns without NOT NULL constraints can contain NULL values.
The `count()` methods set the precedent with
`Sqflite.firstIntValue(...) ?? 0`.

### 2.3 Migration strategy

The schema lives in a single frozen baseline migration,
`lib/database/migrations/v1_baseline_schema.dart`:

- `up` creates the eleven tables, twenty-nine indexes, and the default
  "Home" inventory.
- `down` drops every table in reverse foreign-key dependency order.

Both `_onCreate` and `_onUpgrade` delegate to
`MigrationRunner(allMigrations())`. `_onUpgrade` additionally drops any
known tables when the file reports `user_version` 0 (a database created
outside this helper), then rebuilds from the baseline.

The baseline is frozen: it must never be edited. Every later schema change
is a new numbered migration implementing `up` and `down`.
`DatabaseHelper.databaseVersion` must match the highest declared migration;
`test/database/baseline_schema_test.dart` fails if the frozen schema
drifts.

**Version restart and data loss**: the schema was restarted at version 1
after v46. Installs created before the restart report a higher
`user_version`, so sqflite invokes `onDatabaseDowngradeDelete`, which
deletes the database file (including the WAL and shared-memory sidecars)
and recreates it from the baseline. This is intentional for the
pre-release app: previously saved pantries, prices, recipes, and history
are discarded once.

**Reset**: `DatabaseHelper.resetDatabase()` runs `down` to version 0 and
`up` to `databaseVersion` inside a single transaction, so a failure leaves
the previous schema intact. It is exposed only through the debug-only
"Reset database" action in Settings, which also cancels scheduled
notifications and invalidates the database-backed providers.
`closeDatabase()` clears the cached connection future and is intended for
tests.

### 2.3a PRAGMA configuration

`DatabaseHelper` applies the following PRAGMAs when opening the database:

| PRAGMA | Value | Rationale |
|---|---|---|
| `foreign_keys` | ON | Enforces referential integrity (children are never orphaned by parent deletes). |
| `journal_mode` | WAL | Better read/write concurrency and crash safety than the default DELETE journal. Set via `Database.setJournalMode` (falls back to `rawQuery` on Android, whose `execSQL` rejects row-returning PRAGMAs) and enabled natively through the `com.tekartik.sqflite.wal_enabled` manifest flag. |
| `synchronous` | FULL | Safest durability guarantee; with WAL it syncs on every commit. Slightly slower than NORMAL, chosen for correctness. |
| `cache_size` | -2000 (2 MB) | SQLite default page cache, tuned down for mobile memory constraints. |
| `mmap_size` | 268435456 (256 MB) | Cap for memory-mapped I/O; pages are mapped on demand, so the cap is a limit, not an allocation. Run via `rawQuery` because the setter returns the new value as a row, which Android `execSQL` rejects. |

`PRAGMA quick_check` runs only after a schema upgrade (not on every open,
to keep startup fast on large databases). `PRAGMA optimize` runs on every
open and after `cleanupOldEntries` to refresh query-planner statistics.

**SQLite version compatibility**: the app targets `minSdk 24` (Android
7.0, system SQLite 3.9.2). All SQL must therefore stay within SQLite
3.9.2 syntax — notably no `NULLS LAST` (3.30+), no window functions
like `ROW_NUMBER() OVER` (3.25+), no `ALTER TABLE DROP COLUMN` /
`RENAME COLUMN` (3.35+/3.25+), no UPSERT `ON CONFLICT DO UPDATE`
(3.24+), and no `RETURNING` (3.35+).
`test/database/sqlite_compatibility_test.dart` scans `lib/` and fails if any
of these constructs are reintroduced (v43 is allowlisted because its
`DROP COLUMN` is guarded to skip on old engines). FEFO ordering
uses the portable `ORDER BY (expiry_date IS NULL), expiry_date ASC`, and
"latest price per barcode" uses a correlated subquery
(`ORDER BY date_purchased DESC, id DESC LIMIT 1`).

**Name-based FEFO fallback** (`getInventoryRowsByProductName` and the
recipe cook path) uses a leading-wildcard `LIKE` on `products.name`; the
`%` and `_` characters in the search term are escaped with
`ESCAPE '\'` (mirroring `ProductDao.search`) so they match literally.
"From your pantry" suggestions (`distinctProductsFromInventory`) select
`MAX(inventory.date_added) AS last_added` and `GROUP BY` barcode so the
"most recent" ordering is deterministic on all supported SQLite versions
(ordering a `SELECT DISTINCT` by a non-selected column is undefined and was
an error on SQLite 3.9.2).

### 2.4 Connectivity layer

`InternetConnectionChecker` monitors device connectivity via a
`StreamProvider<bool>` (`connectivityProvider`). The app uses this to:

- Refresh cached product data on startup and pull-to-refresh (online only).
- Skip the Open Food Facts API lookup when offline -- going directly to
  manual product entry with a warning snackbar.
- Guard any network-dependent operation with a connectivity check.
