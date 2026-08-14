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
│  currencyServiceProvider   firebaseCacheProvider                                 │
│  authStateProvider         inventoryProductsProvider                             │
└───────────┬──────────────────────────────────────────────────────────────────────┘
            │ calls                                                                 
┌───────────▼──────────────────────────────────────────────────────────────────────┐
│  Business Logic Layer                                                            │
│  services/                                                                       │
│  ProductRepository    OffAdapter    NotificationService                          │
│  ImageCacheService    GithubIssueService                                         │
│  PriceRepository      CurrencyService  OpenPricesService                         │
│  StoreDao             ShoppingListDao  ShoppingListService                       │
│  FirebaseCacheService  FirebaseCacheClient                                       │
│  FirebaseFirestoreClientAdapter  AuthService                                     │
│  FirebaseAuthService                                                             │
└─────────────┬───────────────────────────┬──────────────────────┬─────────────────┘
              │                           │                      │                  
┌─────────▼─────────────────┐  ┌──▼───────────────┐   ┌───────▼─────────┐
│ Local DB                  │  │ Remote API       │   │ Cloud Cache     │
│ database/                 │  │ services/        │   │ Cloud Firestore │
│ SQLite - 13 tables:       │  │ Open Food Facts  │   │ product_cache/  │
│ products                  │  │ v3 REST (SDK)    │   │ produce_cache/  │
│ inventories               │  │ Open Prices API  │   └─────────────────┘
│ inventory                 │  │ ExchangeRate-API │                      
│ feedback_queue            │  └──────────────────┘                      
│ product_submission_queue  │                                            
│ prices                    │                                            
│ shopping_list             │                                            
│ stores                    │                                            
│ firebase_cache_meta       │                                            
│ recipes                   │                                            
│ recipe_ingredients        │                                            
│ recipe_history            │                                            
│ scan_history              │                                            
│ DAO pattern               │                                            
└───────────────────────────┘                                            
                                          │
   ┌───────────────────────────────┐                                                
   │  [Planned] Firebase Services   │                                               
   │  Auth (Google Sign-In)        │                                                
   │  Storage (cloud backup)       │                                                
   │  AdMob (ads)                  │                                                
   │  Play Billing (IAP)           │                                                
   └───────────────────────────────┘                                                
```
