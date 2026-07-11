## 6. Models (`lib/models/`)

All models use **freezed** for immutable value types and **json_serializable**
for JSON deserialization from the Open Food Facts API.

| Model                 | Source     | Notes                           |
|-----------------------|------------|---------------------------------|
| `Product`             | freezed    | Cached OFF product data         |
| `InventoryItem`       | freezed    | An instance of a product in a pantry |
| `InventoryWithProduct`| plain Dart | Join from `getInventoryWithProduct` |
