# Changelog

## [Unreleased]

### Nutri-Score
- Grey dash badge for non-applicable products (food additives, sweeteners, etc.)
- Tooltip on product detail screen explains why with the OFF category name
- `nutriscore_not_applicable_category` stored in DB, exported in CSV

### Batch delete
- Multi-select checkboxes on inventory cards
- Delete confirmation with undo snackbar
- FAB hidden in selection mode, replaced by app bar delete button

### Quick quantity adjustment
- `+`/`-` buttons on inventory tiles in product detail screen
- Tap the quantity to type a number directly
- Decrementing to 0 triggers delete with undo
- Notifications re-scheduled after every change

### Cache flush on app update
- Version detection via `package_info_plus` and `shared_preferences`
- Clears image cache and product DB on first launch after upgrade
- Manual "Flush cache" button in settings screen

### Accessibility
- `Semantics` labels on NutriScoreBadge: "Nutri-Score A" through "Nutri-Score E", "Nutri-Score, not applicable"
- All badge golden tests also verify semantics labels

### Testing and coverage
- Golden tests: NutriScoreBadge (A–E, null, not-applicable), StatsScreen, SettingsScreen
- StatsScreen: 32.8% → 83.6%
- AddProductScreen: 58.8% → 85.3%
- AddToInventoryScreen: 72.4% → 94.0%
- Connectivity provider stream emission tests
- InventoryCard tap navigation + image cache fallback tests
- HomeScreen: stats navigation, create-pantry dialog, batch delete tests
- 259 tests total, 0 analyze issues

### Code health
- Extracted `parseExpiryDate`, `isExpired`, `isExpiringSoon` into `lib/utils/date_helpers.dart`
- Removed dead `product_api_service.dart`
- Deduplicated custom-input and days-dialog builders in `AddToInventoryScreen`
- Singleton `DatabaseHelper` delegates to `const` DAOs

### Localization
- All user-visible strings externalised via ARB (`flutter gen-l10n`)
- English base with Portuguese planned for future release

### Connectivity
- `connectivity_plus` wrapping Riverpod provider
- Offline-first: cached products shown immediately, background refresh when online

### CSV export/import
- Full round-trip: product data, nutrition, Nutri-Score, inventory metadata
- Handles CRLF, UTF-8 BOM, quoted fields, content:// URIs
- Fixture tests with real Open Food Facts product data

### Multi-inventory
- Named pantries (Home, Work, Camping, …)
- Per-pantry inventory views and stats

### Performance
- Image caching in local filesystem (`ImageCacheService`)
- Hero animations on product images when navigating between screens

---

## [0.1.0] — Initial release (MVP)

### Core
- Barcode scanning via `mobile_scanner`
- Open Food Facts v3 API product lookup
- Offline-first local caching (SQLite via `sqflite`)
- Expiry date tracking with local notifications
- Nutrition table (energy, protein, carbs, fat, fiber, salt per 100 g/ml)
- Ingredients list with collapsible expansion tile

### Product management
- Add products to inventory with quantity, unit, location, expiry date
- Manual product entry form with camera capture when barcode is unknown
- Product submission to Open Food Facts for new barcodes

### UI
- Dark mode support respecting device theme
- Settings screen: theme toggle, notification preferences, CSV export/import
- Snackbar notifications for errors and confirmations
- Haptic feedback on scan

### Database
- Three-table schema: `products`, `inventory`, `inventories`
- DAO pattern for all CRUD operations
- Automatic cleanup of stale entries (configurable retention)

### CSV
- Export current pantry to CSV (all columns)
- Import CSV files to rebuild inventory
- RFC-4180 compliant parser
