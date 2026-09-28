## 5. Screen / widget structure

```
HomeScreen
├── AppBar (title, switcher, settings)
├── SearchBar (inline search panel)
├── ErrorView (loading/error states)
├── EmptyPantry (empty state with scan prompt)
└── _InventoryList
    ├── SearchBar (inline search panel)
    ├── RefreshIndicator (pull-to-refresh)
    └── ListView.builder (lazy, flattened InventoryGrouping entries, RepaintBoundary on each card)
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
├── ProductSubmissionStatus (manual products only; status chip + retry)
│   └── Live progress panel while a submission for this barcode is in flight
├── ProductPhotoManagement (manual products only)
│   └── ProductPhotoTile x3 (preview / replace / delete / crop with undo snackbar)
└── "Add to Inventory" button

AddProductScreen (manual entry when offline or barcode not found)
├── Product name, brand, category, serving size
├── Nutrition table (6 fields, per 100g/ml)
├── Ingredients (multi-line)
└── ProductPhotoTile x3 (nutrition table, ingredients, product photos)
    ├── Empty slot -> PhotoSourceChooser (camera / gallery bottom sheet)
    ├── Filled slot -> ProductPhotoPreview (full screen)
    │   └── Close / Retake (camera) / Replace (source chooser) / Delete (undo snackbar) / Crop
    │       └── PhotoCropScreen (crop grid + rotate; Apply -> ProductPhotoCropper)
    └── Camera permission denied -> showCameraPermissionDialog ("Open Settings")

SearchScreen
├── SearchPanel (composition root, owns SearchPanelController via Riverpod)
│   ├── SearchQueryBar (search input, 300ms debounce timer, clear button)
│   ├── SearchSourceSelector (dropdown: Packaged / My Pantry)
│   ├── FilterChip (inPantry filter, shown when results exist)
│   └── SearchResultsList (result tiles + swipe-to-add rows)
├── SearchPanelController (async search state, debounce, request guard)
├── ResultTile (product image or CircleAvatar fallback)
├── Swipe-to-add (Dismissible, start-to-end)
└── Long-press menu (add to inventory, copy barcode)

StatsScreen (coming soon)
└── ComingSoonScreen (icon, localized title and description)

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
├── About (What's New changelog sheet)

ShoppingListScreen
├── AppBar (move-to-pantry button, clear-purchased, share)
├── PendingSection (items not yet purchased)
│   ├── ShoppingItemTile (name, qty stepper; swipe actions,
│   │   edit sheet via pencil/long-press, drag handle)
│   └── SectionHeader with item counts
├── PurchasedSection (items marked purchased)
├── FAB -> AddToShoppingListSheet (search cached products or manual entry)
└── ShoppingItemEditSheet (rename item, change quantity/unit)

PantryShell
└── NavigationBar with Badge on the List destination showing the pending
    shopping item count

```
