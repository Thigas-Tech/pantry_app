## 2. Database layer (`lib/database/`)

### 2.1 Schema (version 41)

Twelve tables:

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

- `_onCreate` runs when the database file is first created.
- `_onUpgrade` handles version bumps (currently v1 -> v41).
- The `version` integer in `openDatabase` triggers the upgrade automatically.

Version history:
| Version | Change |
|---|---|
| v1 -> v2 | Added `inventories` table, `inventory_id` column |
| v2 -> v3 | Default unit `pcs` -> `pieces`, migration of existing data |
| v3 -> v4 | Added `nutriscore_grade TEXT` column to `products` |
| v4 -> v5 | Added `nutriscore_not_applicable_category TEXT` column |
| v5 -> v6 | Added `source TEXT NOT NULL DEFAULT 'api'` column |
| v6 -> v7 | Added photo path columns for manual products |
| v7 -> v8 | Added `submission_status` column for OFF product submission |
| v8 -> v9 | Added 3 OFF image URL columns for photo-completeness |
| v9 -> v10 | Added `categories_hierarchy` column |
| v10 -> v12 | Added `prices` table for purchase price observations (v11 was the removed `feedback_queue` migration) |
| v12 -> v13 | Added `shopping_list` table |
| v13 -> v14 | Added `idx_inventory_date_added` index on `inventory` |
| v14 -> v15 | Added `language_code TEXT` column to `products` |
| v15 -> v16 | Added `product_submission_queue` table |
| v16 -> v17 | Added `search_text` column and index on `products` |
| v17 -> v18 | Added price columns to `shopping_list` (price_amount, price_currency, price_store, price_photo_path) + `idx_shopping_inventory_id` |
| v18 -> v19 | Added `stores` table + seed from existing `prices.store` and `shopping_list.price_store` |
| v19 -> v20 | Backfill null `inventory_id` in `shopping_list` to default inventory |
| v20 -> v21 | Added `plu_code TEXT` and `product_type TEXT NOT NULL DEFAULT 'barcoded'` to `products` |
| v21 -> v22 | Added `serving_weight_g REAL` to `inventory` for produce serving sizes |
| v22 -> v23 | Backfill `category` for produce items with default "Fruits and vegetables based foods" |
| v23 -> v24 | Added `firebase_cache_meta` table (dropped in v42) |
| v24 -> v25 | Added `recipes` and `recipe_ingredients` tables |
| v25 -> v26 | Added `recipe_history` table |
| v26 -> v27 | Skipped (intended columns already present in v25 CREATE TABLE) |
| v27 -> v28 | Normalize produce barcodes (lowercase, trim, spaces to underscores) across all tables |
| v28 -> v29 | Added unique index on `inventory(barcode, inventory_id)`, deduplicated existing rows |
| v29 -> v30 | Added `search_text` column on `recipes` + indexes on name/created_at/updated_at |
| v30 -> v31 | Added `serving_quantity REAL` column to `products` |
| v31 -> v32 | Added `scan_history` table with indexes on scanned_at and barcode |
| v32 -> v33 | Added `inventory_id` column on `recipes` (backfilled to first inventory) + `idx_recipes_inventory_id` index |
| v33 -> v34 | Added `inventory_id` column on `prices` (backfilled to first inventory) + `idx_prices_inventory_id` index |
| v34 -> v35 | Added `additional_nutrients` column on `products` |
| v35 -> v36 | Replaced the unique index on `inventory(barcode, inventory_id)` with a non-unique index so distinct expiry batches can coexist |
| v36 -> v37 | Added `package_quantity` / `package_unit` to `prices` and `quantity` / `product_quantity` to `products` for unit-aware price math |
| v37 -> v38 | Dropped redundant indexes (`idx_barcode` on the products PK, `idx_inventory_barcode` covered by the composite); added `idx_prices_barcode_inventory_date`, `idx_recipes_inventory_updated`, `idx_products_source` |
| v38 -> v39 | Added `idx_inventory_inventory_expiry` on `inventory(inventory_id, expiry_date)` and `idx_shopping_list_inventory_purchased_date` on `shopping_list(inventory_id, is_purchased, date_added)` |
| v39 -> v40 | Added `shared_recipe_id TEXT NOT NULL DEFAULT ''` column on `recipes` (dropped in v43) |
| v40 -> v41 | Added `sort_order REAL NOT NULL DEFAULT 0` column on `shopping_list`; pending items backfilled to keep current date-added order |
| v41 -> v42 | Dropped the `firebase_cache_meta` table (Firebase cache removed) |
| v42 -> v43 | Dropped the `shared_recipe_id` column on `recipes` (shared-recipe cache removed) |

**Migration v30 search_text backfill**: the recipe `search_text` backfill
intentionally runs in Dart via `normalizeForSearch()` instead of raw SQL.
SQLite's built-in string functions cannot strip diacritics (accents,
eszett, Latin Extended-A), and the performance gain of a raw-SQL backfill
is marginal for typical recipe counts. Correctness is prioritized over
that optimization; regression tests lock in diacritic removal, case and
whitespace normalization, and idempotency.

### 2.3a PRAGMA configuration

`DatabaseHelper` applies the following PRAGMAs when opening the database:

| PRAGMA | Value | Rationale |
|---|---|---|
| `foreign_keys` | ON | Enforces referential integrity (children are never orphaned by parent deletes). |
| `journal_mode` | WAL | Better read/write concurrency and crash safety than the default DELETE journal. |
| `synchronous` | FULL | Safest durability guarantee; with WAL it syncs on every commit. Slightly slower than NORMAL, chosen for correctness. |
| `cache_size` | -2000 (2 MB) | SQLite default page cache, tuned down for mobile memory constraints. |
| `mmap_size` | 268435456 (256 MB) | Cap for memory-mapped I/O; pages are mapped on demand, so the cap is a limit, not an allocation. |

`PRAGMA quick_check` runs only after a schema upgrade (not on every open,
to keep startup fast on large databases). `PRAGMA optimize` runs on every
open and after `cleanupOldEntries` to refresh query-planner statistics.

**SQLite version compatibility**: the app targets `minSdk 24` (Android
7.0, system SQLite 3.9.2). All SQL must therefore stay within SQLite
3.9.2 syntax — notably no `NULLS LAST` (3.30+) and no window functions
like `ROW_NUMBER() OVER` (3.25+). `test/database/sqlite_compatibility_test.dart`
scans `lib/` and fails if either syntax is reintroduced. FEFO ordering
uses the portable `ORDER BY (expiry_date IS NULL), expiry_date ASC`, and
"latest price per barcode" uses a correlated subquery
(`ORDER BY date_purchased DESC, id DESC LIMIT 1`).

### 2.4 Connectivity layer

`InternetConnectionChecker` monitors device connectivity via a
`StreamProvider<bool>` (`connectivityProvider`). The app uses this to:

- Refresh cached product data on startup and pull-to-refresh (online only).
- Skip the Open Food Facts API lookup when offline -- going directly to
  manual product entry with a warning snackbar.
- Guard any network-dependent operation with a connectivity check.
