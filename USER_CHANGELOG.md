# User Changelog

## [0.0.10]

- Recipe detail screen: view full ingredients, instructions, and cost of any
  recipe. Tap a recipe in the list to open it.
- "I made this": mark a recipe as cooked — ingredients are automatically
  deducted from your pantry (oldest first). Shortage warnings prevent
  cooking when you don't have enough stock. Undo supported.
- Recipe history: every time you cook a recipe, it's logged permanently.
- Eye icon: toggle price visibility on the recipe list and detail screens,
  just like the home and stats screens.
- Recipe form: adding the same ingredient twice now increases the quantity
  instead of showing two separate rows.
- Price visibility toggle now also hides costs in the recipe list cards and
  the average cost banner.
- Search product: a new button in the recipe form lets you search Open Food
  Facts and your local database by name or barcode to find ingredients.

## [0.0.9]

- Recipe registration: save recipes with ingredients and instructions,
  auto-populated from your pantry. View, edit, and delete recipes.
- Recipe cost: see how much each recipe costs, plus the average across all
  recipes. Costs use your currency setting.

## [0.0.8+4]

- Product data is now cached in the cloud, making repeat lookups faster even
  after clearing your local cache.
- Your selected pantry is now remembered across app restarts.
- Fixed a rare crash when navigating back from some screens.
- Fixed a rare startup crash that could occur when the product cache refreshes
  during the first frame.

## [0.0.8]

### Fixed
- USDA nutrition data for produce items now loads correctly (was returning 403 due to incorrect API key placement).
- Produce items no longer cause "refresh failed" warnings during pull-to-refresh.
- Portuguese translation for "apple" corrected from "Maca" to "Maçã".
- Statistics screen charts now display correctly with proper axis labels and store data.
- Keyboard no longer hides bottom sheet content when entering data.

### Added
- Produce items now show a green leaf icon in search results and the shopping list sheet instead of a barcode fallback.
- "What's New" sheet now shows changelog in Portuguese or Brazilian Portuguese when the app language is set accordingly.

### Changed
- Produce names are now properly localized in inventory cards and product detail screens.
- Changelog system simplified. In-app changelog now reads directly from a user-facing file with no parsing or cleaning needed.

## [0.0.7]

### Fixed
- Price calculator formatter no longer shows leading zeros.
- Bottom sheets no longer obscured by the system navigation bar.
- Keyboard no longer hides bottom sheet content.

## [0.0.6]

### Added
- Expiry notifications now show product names instead of barcodes.
- Shopping list suggests products from your pantry.
- New stats charts: monthly spending, spending by store, Nutri-Score by store.
- Barcode-less product support (PLU codes for produce).
- Weight and unit toggle for produce items.
- Quick-add produce carousel on the home screen.
- Price tracking on the shopping list with per-currency subtotals.
- Move purchased items to your pantry in one tap.
- Shopping list is now per-pantry.
- Product search when adding items to the shopping list.
- Persistent store autocomplete when entering prices.

### Fixed
- Shopping list items are scoped to the active inventory.
- No duplicate items when moving to your pantry.

## [0.0.5]

### Fixed
- Translation leak on the product detail page.
- Camera scanner no longer gets stuck in an error loop.
- Torch/flashlight toggle added to the scanner.
- User feedback when a barcode scan fails.

### Added
- Tap-to-focus and auto-zoom on the scanner.
- Scanner overlay pauses when app is backgrounded to save battery.

### Changed
- Notifications initialize earlier, preventing missed reminders.
- Better connectivity handling at startup.
- Mixed-currency prices are now converted properly.
- Manual product entries no longer overwrite cached API data.
- Feedback screenshots are now compressed and uploaded properly.
- Database performance improvements with new indexes.
- Shopping list loading no longer flashes empty state.
- Inventory card text is truncated instead of overflowing.

## [0.0.4]

### Added
- Shopping list as a new tab in the bottom navigation bar.
- Price tracking for products with currency conversion.
- AMOLED dark mode for power savings on compatible screens.
- Settings and theme persistence between app restarts.
- Inactivity reminder notification.
- Manual testing guide for QA.

### Changed
- Search screen upgraded to Material 3 search bar.
- Accent-insensitive search for better product discovery.
- Notification service rewritten for reliability.
- Doc comments now use square bracket references for better navigation.

### Fixed
- Feedback form now supports multiple screenshot attachments.
- Untranslated strings on stats and feedback screens are now localized.
- Inventory switcher redesigned with Nutri-Score badge.
- OFF API search retries on failure.

## [0.0.3]

### Added
- Stats screen with Nutri-Score charts, category and location breakdowns.
- ComingSoonView placeholder widgets for future features.
- Product thumbnails in search results.
- Settings "What's New" button to view changelog on demand.
- GitHub Wiki for API documentation.

### Fixed
- Product detail images now respect screen resolution.
- Chart labels visible in dark mode.
- Search now matches OFF website results more accurately.
- Expiry notification logs show correct product information.

## [0.0.2]

### Added
- Long-press to select inventory items for batch operations.
- Batch move items between pantries.
- Swipe between bottom navigation tabs.
- Swipe right on search results to add to pantry.
- Long-press context menu on search results.
- Swipe to delete inventory items and pantries.
- Pull-to-refresh on stats screen.

### Fixed
- Search now handles accented characters correctly.
- No more crashes from search screen after disposal.
- No more double background refresh on startup.

## [0.0.1]

### Added
- Autocomplete search with product thumbnails.
- Accent-insensitive search.
- Pinch-to-zoom on product photos.
- Settings screen grouped into sections.

### Nutri-Score
- Grey dash badge for non-applicable products.
- Tooltip explaining why Nutri-Score is not applicable.

### Batch delete
- Multi-select checkboxes on inventory cards.
- Delete confirmation with undo.

### Quick quantity adjustment
- Plus and minus buttons on inventory tiles.
- Tap quantity to type a value directly.

## [0.1.0] -- Initial release (MVP)

### Core
- Barcode scanning via device camera.
- Open Food Facts product lookup.
- Offline-first local caching.
- Expiry date tracking with notifications.
- Nutrition table and ingredients list.

### Product management
- Add products to inventory with quantity, unit, and location.
- Manual product entry when barcode is unknown.
- Product submission to Open Food Facts.

### UI
- Dark mode support.
- Settings screen with theme and notification preferences.

### Multi-inventory
- Named pantries (Home, Work, Camping).
- Per-pantry inventory views and stats.
