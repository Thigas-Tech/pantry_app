## 6. Models (`lib/models/`)

All models use **freezed** for immutable value types and **json_serializable**
for JSON deserialization from the Open Food Facts API, except where noted.

| Model | Source | Notes |
|---|---|---|
| `Product` | freezed | Cached OFF product data with nutrition (six core fields plus `additionalNutrients`), images, source tracking |
| `ProductNutrient` | freezed | Additional nutrient (OFF tag, value, canonical unit) |
| `InventoryItem` | freezed | An instance of a product in a pantry (qty, expiry, location) |
| `InventoryWithProduct` | plain Dart | Join result from `getInventoryWithProduct` query |
| `ShoppingItem` | freezed | Shopping list entry |
| `Store` | freezed | Saved store name for autocomplete |
