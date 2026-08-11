## 6. Models (`lib/models/`)

All models use **freezed** for immutable value types and **json_serializable**
for JSON deserialization from the Open Food Facts API, except where noted.

| Model | Source | Notes |
|---|---|---|
| `Product` | freezed | Cached OFF product data with nutrition (six core fields plus `additionalNutrients`), images, source tracking |
| `ProductNutrient` | freezed | Additional nutrient (OFF tag, value, canonical unit) |
| `InventoryItem` | freezed | An instance of a product in a pantry (qty, expiry, location) |
| `InventoryWithProduct` | plain Dart | Join result from `getInventoryWithProduct` query |
| `Price` | freezed | Purchase price observation (amount, currency, store, sync status, package size/unit) |
| `UnitPrice` | plain Dart | Per-base-unit price (piece / gram / milliliter) from `PriceCalculator.unitPrice` |
| `ShoppingItem` | freezed | Shopping list entry with price fields and photo support |
| `PantryStats` | freezed | Aggregated statistics for the stats screen |
| `Store` | freezed | Saved store name for autocomplete |
| `ProductType` | enum | Barcoded, produce, or custom |
| `AuthUser` | plain Dart | Authenticated user (uid, isAnonymous, email, displayName) |
| `ProductCacheEntry` | freezed | Firestore document for `product_cache/{barcode}` |
| `ProduceCacheEntry` | freezed | Firestore document for `produce_cache/{name}` |
| `FeedbackQueueEntry` | freezed | Offline queue item for GitHub issue reports |
| `ProductSubmissionQueueEntry` | freezed | Offline queue item for OFF product submissions |
