## 1. High-level overview

```
┌──────────────────────────────────────────────────────────────────────────────────┐
│  UI Layer                                                                        │
│  screens/          widgets/          utils/                                      │
│  HomeScreen        InventoryCard     logger                                      │
│  ScannerScreen     EmptyPantry       snackbar_helper                             │
│  ProductDetail     NutritionTable                                                │
│  AddToInventory    ScannerOverlay                                                │
│  Settings / Stats  PriceEntrySheet                                               │
│  ShoppingList      QuickAddProduce                                               │
│  ...                                                                             │
└───────────┬──────────────────────────────────────────────────────────────────────┘
            │ watches / reads Riverpod providers                                    
┌───────────▼──────────────────────────────────────────────────────────────────────┐
│  State / DI Layer                                                                │
│  providers/                                                                      │
│  activeInventoryProvider   inventoryWithProductProvider                          │
│  settingsProvider          themeModeProvider                                     │
│  productRepositoryProvider statsProvider                                         │
│  imageCacheProvider        notificationServiceProvider                           │
│  connectivityProvider      githubIssueServiceProvider                            │
│  apiServiceProvider        inventoryCountProvider                                │
│  priceRepositoryProvider   priceHistoryProvider                                  │
│  shoppingListProvider      storesProvider                                        │
│  currencyServiceProvider   inventoryProductsProvider                             │
│  cacheStalenessStoreProvider                                                     │
└───────────┬──────────────────────────────────────────────────────────────────────┘
            │ calls                                                                 
┌───────────▼──────────────────────────────────────────────────────────────────────┐
│  Business Logic Layer                                                            │
│  services/                                                                       │
│  ProductRepository    OffAdapter    NotificationService                          │
│  ImageCacheService    GithubIssueService                                         │
│  PriceRepository      CurrencyService  OpenPricesService                         │
│  StoreDao             ShoppingListDao  ShoppingListService                       │
│  CacheStalenessStore                                                             │
└─────────────┬───────────────────────────┬────────────────────────────────────────┘
              │                           │                                          
┌─────────▼─────────────────┐  ┌──▼───────────────┐                               
│ Local DB                  │  │ Remote API       │                               
│ database/                 │  │ services/        │                               
│ SQLite - 11 tables:       │  │ Open Food Facts  │                               
│ products                  │  │ v3 REST (SDK)    │                               
│ inventories               │  │ Open Prices API  │                               
│ inventory                 │  │ ExchangeRate-API │                               
│ product_submission_queue  │  └──────────────────┘                               
│ prices                    │                                                      
│ shopping_list             │                                                      
│ stores                    │                                                      
│ recipes                   │                                                      
│ recipe_ingredients        │                                                      
│ recipe_history            │                                                      
│ scan_history              │                                                      
│ DAO pattern               │                                                      
└───────────────────────────┘                                                      
                                           │
   ┌───────────────────────────────┐                                               
   │  [Planned] Services           │                                               
   │  AdMob (ads)                 │                                               
   │  Play Billing (IAP)          │                                               
   └───────────────────────────────┘                                               
```
