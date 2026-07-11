## 2. Database layer (`lib/database/`)

### 2.1 Schema (version 11)

Three tables:

| Table         | Purpose                                                  |
|---------------|----------------------------------------------------------|
| `products`    | Cached product data from Open Food Facts. PK = barcode.  Includes `source` column: `'api'` (OFF‑fetched, flushable) or `'manual'` (user‑entered, protected). |
| `inventories` | Named pantries (e.g. "Home", "Work"). PK = id            |
| `inventory`   | Instances of products in a pantry. FK → products, inventories |

### 2.2 DAO pattern

Each table has a dedicated Data Access Object:

| DAO                    | Responsibility                            |
|------------------------|-------------------------------------------|
| `ProductDao`           | Upsert / lookup products, count, source‑aware queries |
| `InventoryDao`         | CRUD items, joined queries                |
| `InventoriesDao`       | CRUD named pantries, migrations           |

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
- `_onUpgrade` handles version bumps (currently v1 → v11).
- The `version` integer in `openDatabase` triggers the upgrade automatically.

Version history:
| Version | Change |
|---------|--------|
| v1 → v2 | Added `inventories` table, `inventory_id` column |
| v2 → v3 | Default unit `pcs` → `pieces`, migration of existing data |
| v3 → v4 | Added `nutriscore_grade TEXT` column to `products` |
| v4 → v5 | Added `nutriscore_not_applicable_category TEXT` column |
| v5 → v6 | Added `source TEXT NOT NULL DEFAULT 'api'` column |
| v6 → v7 | Added photo path columns for manual products |
| v7 → v8 | Added `submission_status` column for OFF product submission |
| v8 → v9 | Added 3 OFF image URL columns for photo‑completeness |
| v9 → v10 | Added `categories_hierarchy` column |
| v10 → v11 | Added `feedback_queue` table for offline issue reporting |

### 2.4 Connectivity layer

`InternetConnectionChecker` monitors device connectivity via a
`StreamProvider<bool>` (`connectivityProvider`). The app uses this to:

- Refresh cached product data on startup and pull-to-refresh (online only).
- Skip the Open Food Facts API lookup when offline — going directly to
  manual product entry with a warning snackbar.
- Guard any network-dependent operation with a connectivity check.
