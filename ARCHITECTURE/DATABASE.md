## 2. Database layer (`lib/database/`)

### 2.1 Schema (version 24)

Nine tables:

| Table | Purpose |
|---|---|
| `products` | Cached product data from Open Food Facts. PK = barcode. Includes `source` column: `'api'` (OFF-fetched, flushable) or `'manual'` (user-entered, protected). |
| `inventories` | Named pantries (e.g. "Home", "Work"). PK = id |
| `inventory` | Instances of products in a pantry. FK -> products, inventories |
| `feedback_queue` | Offline queue for GitHub issue reports |
| `product_submission_queue` | Offline queue for OFF product submissions |
| `prices` | Purchase price observations per barcode |
| `shopping_list` | Items the user intends to buy |
| `stores` | Saved store names for autocomplete on price entry |
| `firebase_cache_meta` | Tracks last-refresh timestamps for product cache entries synced to Firestore |

### 2.2 DAO pattern

Each table has a dedicated Data Access Object:

| DAO | Responsibility |
|---|---|
| `ProductDao` | Upsert / lookup products, count, source-aware queries |
| `InventoryDao` | CRUD items, joined queries |
| `InventoriesDao` | CRUD named pantries, migrations |
| `FeedbackQueueDao` | CRUD offline feedback queue |
| `ProductSubmissionQueueDao` | CRUD offline submission queue |
| `PriceDao` | CRUD prices, aggregation queries (total value, average) |
| `ShoppingListDao` | CRUD shopping list items, per-inventory scoped |
| `StoreDao` | CRUD saved store names, case-insensitive lookup |
| `FirebaseCacheMetaDao` | CRUD Firestore cache sync metadata, next-refresh tracking |

Every DAO method receives a `Database` instance so it can be tested independently.

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
- `_onUpgrade` handles version bumps (currently v1 -> v24).
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
| v10 -> v11 | Added `feedback_queue` table for offline issue reporting |
| v11 -> v12 | Added `prices` table for purchase price observations |
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
| v23 -> v24 | Added `firebase_cache_meta` table for Firestore cache sync tracking |

### 2.4 Connectivity layer

`InternetConnectionChecker` monitors device connectivity via a
`StreamProvider<bool>` (`connectivityProvider`). The app uses this to:

- Refresh cached product data on startup and pull-to-refresh (online only).
- Skip the Open Food Facts API lookup when offline -- going directly to
  manual product entry with a warning snackbar.
- Guard any network-dependent operation with a connectivity check.
