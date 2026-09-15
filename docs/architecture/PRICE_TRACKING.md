# Price Tracking Architecture

Price tracking is a local-first feature: every price observation is stored in
the local SQLite `prices` table, optionally shared with the Open Prices
community database when the user opts in. All data is scoped to the active
inventory so each pantry keeps an independent price history.

```
 Price entry (bottom sheet)
        │  PriceEntrySheet.show(...)
        ▼
 Local SQLite (prices table)
        │  PriceDao CRUD        PriceRepository (format, convert, aggregate)
        ▼                        ▼
 priceHistoryProvider ──► PriceHistoryScreen
 latestPriceProvider ──► InventoryCard / InventoryTile (flat + per-unit price)
 inventoryValueProvider ─► StatsScreen total value / average / spending

 Open Prices contribution (opt-in, token required)
        │  OpenPricesApiClient.fetchPricesByBarcode   (read)
        │  OpenPricesApiClient.submitPrice + proof_id (write, placeholder)
        ▼
 Open Prices API  https://prices.openfoodfacts.org/api/v1
```

## 1. Local data model

### 1.1 `prices` table

Created by migration v12, extended by v37, and rebuilt by v46:

| Column | Type | Notes |
|---|---|---|
| `id` | INTEGER PK AUTOINCREMENT | Row id |
| `barcode` | TEXT NOT NULL | Product barcode (no FK — see below) |
| `price` | REAL NOT NULL | Monetary amount, taxes included |
| `currency` | TEXT NOT NULL | ISO 4217 code |
| `store` | TEXT | Free-form or autocompleted store name |
| `is_discounted` | INTEGER NOT NULL DEFAULT 0 | 0/1 flag |
| `regular_price` | REAL | Pre-discount price |
| `date_purchased` | INTEGER | Epoch ms of purchase (backfilled from `date_added` when null) |
| `sync_status` | TEXT NOT NULL DEFAULT 'local_only' | see lifecycle below |
| `open_prices_id` | INTEGER | Remote id after sync |
| `location_osm_id` / `location_osm_type` | TEXT | OSM location (NODE/WAY/RELATION) |
| `receipt_series` / `receipt_number` / `receipt_item_index` | TEXT/TEXT/INTEGER | Reserved (unused) |
| `notes` | TEXT | Free-form |
| `package_quantity` | REAL | Package size, e.g. 12 (eggs), 1 (1 L), 500 (500 g) |
| `package_unit` | TEXT | 'pieces', 'g', 'kg', 'ml', 'L', ... |
| `date_added` | INTEGER NOT NULL | Epoch ms when created locally |
| `inventory_id` | INTEGER NOT NULL DEFAULT 1 | Scoping pantry (no FK — see below) |

Indexes: `idx_prices_barcode`, `idx_prices_date`, `idx_prices_sync_status`,
`idx_prices_inventory_id`, `idx_prices_barcode_inventory_date`
(barcode, inventory_id, date_purchased, id).

Migration v46 removed the foreign keys on `barcode` and `inventory_id`:
price observations are the user's own records. They survive product cache
flushes, pantry deletion, and any cache maintenance, and a missing product
row never blocks a new price from being recorded. The same migration
backfilled NULL `date_purchased` values from `date_added` so ordering is
deterministic.

There is **no proof-photo column**. The original design planned
`proof_image_path`, but proof capture and upload are not implemented, so the
column was never added (see section 5).

### 1.2 `Price` model

`Price` (`lib/models/price.dart`) is a freezed, immutable model carrying every
column above. `packageQuantity` and `packageUnit` are optional: rows written
before v37 (or entered before package capture exists) have `NULL` and are
treated as legacy unscaled prices.

### 1.3 Sync-status lifecycle

| Status | Constant | Meaning |
|---|---|---|
| `local_only` | `priceSyncLocalOnly` | Not shared: no proof photo attached |
| `pending` | `priceSyncPending` | Queued for Open Prices sync |
| `synced` | `priceSyncSynced` | Successfully synced |
| `failed` | `priceSyncFailed` | Sync failed, retry possible |

`PriceDao.deleteStale` never deletes `pending` rows, so queued prices survive
retention pruning.

## 2. Local price entry flow

1. A price is added or edited through `PriceEntrySheet`
   (`lib/widgets/price_entry_sheet.dart`), a modal bottom sheet opened from
   `ProductDetailScreen` and `ShoppingListScreen`. Fields: amount
   (locale-aware decimal separator via `PriceCalculatorFormatter`), store
   (autocomplete over the `stores` table with an add-new action), purchase
   date, discounted toggle, notes, and package size + package unit. The
   package size is prefilled from the product's OFF packaging string when
   available, and is optional — prices left without one are stored as legacy
   unscaled observations.
2. The sheet returns a `Price`; the caller scopes it with the active
   `inventoryId` and saves it through `PriceRepository.addPrice` ->
   `PriceDao.insert`. New prices default to `sync_status = 'local_only'`.
3. Riverpod providers recompute: `latestPriceProvider`, `priceHistoryProvider`
   (both keyed by `(barcode, inventoryId)`), and the aggregate providers
   (`inventoryValueProvider`, `averagePriceProvider`,
   `pricedItemCountProvider`).
4. Display surfaces: inventory card and tile (flat price plus per-unit
   label), the `PriceHistoryScreen` (line chart at the top plus a
   chronological list with sync-status), and the stats screen (total value,
   average, monthly expenditure, store spending). The product detail screen
   embeds the same full-history chart above its recent-price rows and shows
   a localized error row with retry when price data cannot be loaded
   instead of hiding the section.

Privacy hiding (`pricesHiddenProvider`) replaces every monetary value on
cards, history rows, and per-unit labels with a fixed-width mask via
`PriceMask`; the history chart is replaced by a masked placeholder so no
value leaks through axis labels or tooltips.

### 2.1 Price history chart

`PriceHistoryChart` (`lib/widgets/price_history_chart.dart`) renders the
full history with fl_chart. Points are produced by
`PriceRepository.priceHistoryPoints` (each converted to the user's base
currency and sorted oldest first) through `priceChartPointsProvider`,
keyed by (barcode, inventoryId, baseCurrency). Observations are spaced
equally along the X axis with the purchase date as each label; touch shows
a built-in tooltip (date, price, store) built by `priceChartTooltipText`,
and a single point renders as a visible dot. The widget is wrapped in a
RepaintBoundary and keeps no touch state of its own, so scrolling lists
around it are not invalidated.

Screens gate the chart to at least two points: with exactly one recorded
price they render a localized hint (`priceTrendHint`) prompting for a
second observation instead. Every price mutation — adding from the product
detail price section or the history screen app bar, editing the latest
price, deleting (and undoing a delete) — invalidates
`priceChartPointsProvider` alongside the history and latest-price
providers, so the chart always reflects the current data. The entry sheet's
date picker supports past dates, so historical observations can be recorded
without the market trip.

## 3. Unit-aware price math

`PriceCalculator` (`lib/utils/price_calculator.dart`) provides pure, DB-free
helpers. Units are normalized with `UnitConverter` (`lib/utils/unit_conversion.dart`),
which groups units into weight (g/kg/mg/mcg/oz/lb), volume (ml/L/tbsp/tsp/cup/
fl oz), and count (pieces).

- `unitPrice` computes the price per base unit (piece, gram, milliliter) of a
  package. Returns null for missing/zero/negative/non-finite package size,
  a missing package unit, or a non-finite price. No density is ever invented
  between incompatible groups (e.g. grams vs pieces).
- `scaledIngredientCost` scales a package price to the cost of the ingredient
  quantity actually used, converting within the same measurement group. It
  returns `0.0` for zero quantity and null when the package is unusable, the
  price is not positive, or the units are incompatible. Both the scaled
  ingredient cost and the recipe total are rounded to cents via `Money`
  (`lib/utils/money.dart`) so recipe totals never carry fractional cents.

### 3.1 Package-size resolution for recipes

`calculateIngredientCost` (`lib/services/recipe_service.dart`) charges each
ingredient `price * (ingredient qty / package qty)` and resolves the package
size in this order (`_resolvePackageSize`):

1. The price row's own `package_quantity` / `package_unit`.
2. The product's packaging (`products.quantity` / `products.product_quantity`),
   resolving multi-pack strings like `"3 x 150 g"` to their TOTAL package
   size (450 g) via `parsePackageQuantity`
   (`lib/utils/quantity_parser.dart`) — the size the recorded price applies
   to. Bonus packs (`"2 x 300 g + 1 x 50 g"`) sum to 650 g.

`ingredientCosts` returns the same per-ingredient scaled cost keyed by
barcode, using one batched latest-price query
(`PriceDao.latestPricesByBarcodes`), for the recipe detail per-ingredient
cost rows.

The inventory row is deliberately **not** a package-size source: its stored
quantity is the current stock, not the size of the package the price applies
to, so using it would distort the scaled cost.

When the ingredient and package units are incompatible (e.g. a piece-counted
produce item against a gram package), a per-piece serving weight is resolved
via `ServingWeightResolver` (`lib/utils/serving_weight.dart`): the inventory
row's `serving_weight_g`, then `ProduceServingPresets`. The resolved weight
converts the ingredient into the package's measurement group before scaling.
When no package size or conversion resolves, the full package price is
charged (legacy behavior). Cook-history scoring uses the same path.

Example (issue #308): a dozen eggs priced at R$ 15.90 used as "2 pieces"
costs 15.90 x (2/12) = R$ 2.65; 250 ml of a 1 L carton priced at R$ 5.00
costs R$ 1.25; 500 g of a 1 kg bag priced at R$ 8.00 costs R$ 4.00.

### 3.2 Per-unit display

`PriceRepository.unitPriceLabel` (`lib/services/price_repository.dart:118`)
builds a localized label from the price row's own package columns only
-- it does not fall back to product or inventory rows (unlike recipe
scaling). Display scaling follows the base unit:

- pieces -> per piece
- grams -> per 100 g, or per kg when the package is at least one kilogram
- milliliters -> per 100 ml, or per L when the package is at least one liter

When no usable package size is present, the label is null and `UnitPriceLabel`
(`lib/widgets/unit_price_label.dart`) renders nothing.

### 3.3 Stats aggregation

`PriceDao` aggregates scale by the total held quantity of each barcode in the
inventory: total inventory value, average item price, monthly expenditure,
and store spending. When the latest price carries a positive package size,
the value is reduced to the per-item price first (`price / package size`),
matching recipe cost scaling. A dozen eggs priced for a 12-pack and held as
12 pieces therefore contribute one package price, not twelve; legacy prices
without a package size keep their unscaled behavior. Currency conversion is
applied by `PriceRepository` in the same pass.

## 4. Open Prices integration

### 4.1 Configuration

- Base URLs: production `https://prices.openfoodfacts.org/api/v1`,
  staging `https://prices.openfoodfacts.net/api/v1`.
- Bearer token: read from `AppConfig.openPricesToken` or the override stored
  in user settings. Token generation requires an Open Food Facts account
  (POST `/api/v1/auth`).
- Opt-in: the settings screen (SettingsScreen, "Share with Open Prices")
  shows a consent dialog explaining that a proof photo is required, then
  exposes the token field. With no token, the app runs in local-only mode and
  every API call short-circuits to an empty result.

### 4.2 Fetch

`OpenPricesApiClient.fetchPricesByBarcode(barcode)` calls
`GET /api/v1/prices?product_code=...&order=desc&page=..&size=..` and maps items
to `RemotePrice` (id, product_code, price, currency, product name, store,
date). Note: `price_per` and the product quantity fields are documented by
the API but are **not** parsed by `RemotePrice` today.

`validateToken()` probes a lightweight authenticated endpoint and reports
whether the configured token works.

### 4.3 Submit

`OpenPricesApiClient.submitPrice(...)` posts to `POST /api/v1/prices`. The
API requires an existing `proof_id` (a proof object created via
`POST /api/v1/proofs`), so the method is currently a placeholder: it requires
`proofId` but the app never produces one, and it does not yet send
`price_per` or `receipt_quantity`. The caller cannot reach this path because
`OpenPricesService.syncPendingPrices` still runs a local-only placeholder.

### 4.4 Sync

`OpenPricesService.syncPendingPrices` fetches rows with
`sync_status = 'pending'` and marks them `synced` directly in the database
without any HTTP request. Proof upload and price creation are blocked by the
missing receipt capture feature.

### 4.5 Conflict resolution — Planned

Remote prices fetched by barcode are not merged into the local table today,
so no local-vs-remote conflict can arise. The intended design, once proof
upload lands:

- Local prices always win for display (up-to-date purchase context);
- Remote prices for the same barcode + inventory are merged into the local
  history for trend data, tagged with their source;
- a shared price that already exists locally is de-duplicated by
  proof/owner, and pending local prices stay independent until synced.

## 5. Proof-photo requirement and storage strategy

Open Prices mandates a proof (receipt or shelf-label photo) for every price
write; prices without a photo stay local. The consent copy already states
this contract to the user.

Current storage:

- The `prices` table has no proof column. Proofs are not persisted or
  uploaded anywhere.

Planned path, in order:

1. Capture a receipt/shelf-label photo during price entry.
2. Re-encode (small WebP / bounded resolution) and store at a managed path.
3. Upload to Open Prices as a proof; store the returned `proof_id`.
4. Create the price with `proof_id`; mark `synced`.

## 6. Pitfalls and edge cases

- **Legacy prices (no package fields)**: served unscaled at full price; unit
  labels hidden. They are not explicitly flagged today.
- **Incompatible units**: grams vs pieces is converted using a per-piece
  serving weight for produce when available; otherwise the full package price
  is charged (no density is guessed).
- **Invalid package sizes**: zero, negative, or non-finite quantities (and
  non-finite or non-positive prices) produce null from `PriceCalculator`.
- **Multi-pack strings**: `parsePackageQuantity` resolves `"3 x 150 g"` to
  the TOTAL 450 g package (what a price observation covers), while
  `parseQuantity` keeps the per-unit 150 g for non-price contexts. Price
  entry and recipe scaling both use the total.
- **Full-price fallback**: when no package size or conversion resolves for
  an ingredient, the full package price is charged (legacy behavior) and a
  warning is logged.
- **Unit-label vs recipe asymmetry**: the per-unit label uses only the price
  row's package columns, while recipe cost falls back to product packaging.
  A price recorded without package data can show in recipe math scaled but
  without a unit label.
- **Rate limits**: Open Prices documents no limits; the app assumes ~15
  req/min and always sends a `User-Agent` header.
- **Licensing**: Open Prices data is OdBL-licensed; contributions must be
  attributed and shared alike.
- **Tokens**: prod and pre-prod use different tokens; an empty token silently
  disables all API work.
- **Inventory scoping**: prices carry `inventory_id`; updates preserve the
  original inventory, and all aggregations are scoped per inventory. Trip
  and move-to-inventory flows write the price row with the target pantry's
  id, never a default.
- **Price history survives cache maintenance**: `cleanupOldEntries` never
  deletes prices because a product left the pantry. Only the explicit price
  retention setting prunes prices, and only rows older than the configured
  window (aged by `COALESCE(date_purchased, date_added)`).
- **Deterministic latest-price ordering**: every latest-price lookup orders
  by `COALESCE(date_purchased, date_added) DESC, id DESC`, so same-day
  observations resolve to the most recently recorded row and rows without a
  purchase date sort by their creation date.
- **Trip package sizes**: package size/unit recorded during a market trip is
  carried on the shopping item (`price_package_quantity` /
  `price_package_unit`) and copied into the prices table when the trip
  finishes, so per-unit labels and recipe scaling keep working.
- **Retention**: `deleteStale` never deletes `pending` prices and treats a
  retention of zero or less as keep-forever.
- **Currency**: stats group latest prices by currency and convert to the base
  currency for display; writes always keep the original currency.