## 5. Screen / widget structure

```
HomeScreen
├── AppBar (title, switcher, settings)
├── QuickAddProduce (horizontal carousel of 8 common produce items)
├── ErrorView (loading/error states)
├── EmptyPantry (empty state with scan prompt)
└── _InventoryList
    ├── SearchBar (Autocomplete with image thumbnails, leaf icon for produce)
    ├── StockCountBadges (horizontal ListView.builder)
    ├── CategoryFilterChips (horizontal ListView.builder)
    ├── RefreshIndicator (pull-to-refresh)
    └── ListView.builder (RepaintBoundary on each card)
        ├── SectionHeader (expired / expiring soon / good)
        └── InventoryCard (tappable, image, NutriScoreBadge, expiry dot)

ProductDetailScreen
├── AppBar (name, OFF link)
├── Hero -> CachedImage (FutureBuilder -> cached WebP or network)
├── NutriScoreBadge + tooltip (A-E grade)
├── InfoRows (barcode, brand, category, serving size)
├── NutritionTable (energy, protein, carbs, fat, fiber, salt)
├── Ingredients (ExpansionTile)
├── InventoryTiles (location icon, qty, expiry, edit/delete)
├── PriceHistorySection (latest price, store, date; tap for history)
└── "Add to Inventory" button

AddProductScreen (manual entry when offline or barcode not found)
├── Product name, brand, category, serving size
├── Nutrition table (6 fields, per 100g/ml)
├── Ingredients (multi-line)
└── Image capture (nutrition table, ingredients, product photos)

SearchScreen
├── SearchPanel (composition root, owns SearchPanelController via Riverpod)
│   ├── SearchQueryBar (search input, 300ms debounce timer, clear button)
│   ├── SearchSourceSelector (dropdown: Packaged / Fresh Produce / My Pantry)
│   ├── FilterChip (inPantry filter, shown when results exist)
│   └── SearchResultsList (result tiles + swipe-to-add rows)
├── SearchPanelController (async search state, debounce, request guard)
├── ResultTile (product image or CircleAvatar fallback, leaf icon for produce)
├── Swipe-to-add (Dismissible, start-to-end)
└── Long-press menu (add to inventory, copy barcode)

StatsScreen
├── Summary cards (total products, items, added this week/month)
├── NutriScoreBar (fl_chart BarChart by grade A-E)
├── CategoryChart (fl_chart BarChart by category)
├── LocationChart (fl_chart BarChart by storage location)
├── Photo completeness (local vs OFF photos)
├── PriceStatistics (total value, average price, priced item count)
├── ComingSoonView (NFC-e receipts -- placeholder)
└── RefreshIndicator (pull-to-refresh)

ScannerScreen
├── PopScope (confirmation dialog on back)
├── _MobileScannerView (camera + ScannerOverlayPainter)
├── PLU code entry (numeric keypad for produce items)
└── _ManualEntryView (text field + submit button)

SettingsScreen
├── Theme dialog (RadioGroup: system/light/dark)
├── Notifications switch
├── Data retention dialog (days input)
├── Expiring-soon threshold dialog
├── Manage Inventories link
├── Flush cache (API products + image cache)
├── About (What's New changelog sheet)
└── Sign out (Firebase Auth)

ShoppingListScreen
├── AppBar (add-to-pantry button, clear-purchased, refresh)
├── PendingSection (items not yet purchased)
│   ├── ShoppingItemTile (name, qty, price, store; swipe actions)
│   └── SectionHeader with per-currency running totals
├── PurchasedSection (items marked purchased)
└── FAB -> AddToShoppingListSheet (search cached products or manual entry)

PriceEntrySheet (bottom sheet, reused from multiple screens)
├── Amount field (POS-style calculator with locale-aware decimal)
├── Store field (Autocomplete from saved stores, "+ Add new store" button)
├── Date picker
├── Discounted toggle
├── Notes field
└── Submit button
```
