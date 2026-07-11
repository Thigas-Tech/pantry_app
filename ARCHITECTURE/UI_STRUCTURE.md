## 5. Screen / widget structure

```
HomeScreen
├── AppBar (title, switcher, settings)
├── ErrorView (loading/error states)
├── EmptyPantry (empty state with scan prompt)
└── _InventoryList
    ├── SearchBar (Autocomplete with image thumbnails)
    ├── StockCountBadges (horizontal ListView.builder)
    ├── CategoryFilterChips (horizontal ListView.builder)
    ├── RefreshIndicator (pull-to-refresh)
    └── ListView.builder (RepaintBoundary on each card)
        ├── SectionHeader (expired / expiring soon / good)
        └── InventoryCard (tappable, image, NutriScoreBadge, expiry dot)

ProductDetailScreen
├── AppBar (name, OFF link)
├── Hero → CachedImage (FutureBuilder → cached WebP or network)
├── NutriScoreBadge + tooltip (A–E grade)
├── InfoRows (barcode, brand, category, serving size)
├── NutritionTable (energy, protein, carbs, fat, fiber, salt)
├── Ingredients (ExpansionTile)
├── InventoryTiles (location icon, qty, expiry, edit/delete)
└── "Add to Inventory" button

AddProductScreen (manual entry when offline or barcode not found)
├── Product name, brand, category, serving size
├── Nutrition table (6 fields, per 100g/ml)
├── Ingredients (multi-line)
└── Image capture (nutrition table, ingredients, product photos)

SearchScreen
├── SearchBar (300ms debounce timer)
├── ResultTile (product image or CircleAvatar fallback)
├── Swipe-to-add (Dismissible, start-to-end)
└── Long-press menu (add to inventory, copy barcode)

StatsScreen
├── Summary cards (total products, items, added this week/month)
├── NutriScoreBar (fl_chart BarChart by grade A–E)
├── CategoryChart (fl_chart BarChart by category)
├── LocationChart (fl_chart BarChart by storage location)
├── Photo completeness (local vs OFF photos)
├── ComingSoonView (price tracking — placeholder)
├── ComingSoonView (NFC-e receipts — placeholder)
└── RefreshIndicator (pull-to-refresh)

ScannerScreen
├── PopScope (confirmation dialog on back)
├── _MobileScannerView (camera + ScannerOverlayPainter)
└── _ManualEntryView (text field + submit button)

SettingsScreen
├── Theme dialog (RadioGroup: system/light/dark)
├── Notifications switch
├── Data retention dialog (days input)
├── Expiring-soon threshold dialog
├── Manage Inventories link
├── Flush cache (API products + image cache)
└── About (What's New changelog sheet)
```
