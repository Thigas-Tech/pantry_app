## 1. High-level overview

```
┌──────────────────────────────────────────────────────────────────────────────────┐
│  UI Layer                                                                        │
│  screens/          widgets/          utils/                                      │
│  HomeScreen        InventoryCard     logger                                      │
│  ScannerScreen     EmptyPantry       snackbar_helper                             │
│  ProductDetail     NutritionTable                                                │
│  AddToInventory    ScannerOverlay                                                │
│  Settings                                                                       │
│  ShoppingList                                                                    │
│  ...                                                                             │
└───────────┬──────────────────────────────────────────────────────────────────────┘
            │ watches / reads Riverpod providers                                    
┌───────────▼──────────────────────────────────────────────────────────────────────┐
│  State / DI Layer                                                                │
│  providers/                                                                      │
│  activeInventoryProvider   inventoryWithProductProvider                          │
│  settingsProvider          themeModeProvider                                     │
│  productRepositoryProvider                                                      │
│  imageCacheProvider        notificationServiceProvider                           │
│  connectivityProvider      githubIssueServiceProvider                            │
│  apiServiceProvider        inventoryCountProvider                                │
│  shoppingListProvider                                                           │
│  cacheStalenessStoreProvider  inventoryProductsProvider                         │
└───────────┬──────────────────────────────────────────────────────────────────────┘
            │ calls                                                                 
┌───────────▼──────────────────────────────────────────────────────────────────────┐
│  Business Logic Layer                                                            │
│  services/                                                                       │
│  ProductRepository    OffAdapter    NotificationService                          │
│  ImageCacheService    GithubIssueService                                         │
│  ShoppingListDao     ShoppingListService                                        │
└─────────────┬───────────────────────────┬────────────────────────────────────────┘
              │                           │                                          
┌─────────▼─────────────────┐  ┌──▼───────────────┐                               
│ Local DB                  │  │ Remote API       │                               
│ database/                 │  │ services/        │                               
│ SQLite - 9 tables:        │  │ Open Food Facts  │                               
│ products                  │  │ v3 REST (SDK)    │                               
│ inventories               │  │                    │                               
│ inventory                 │  │                  │                               
│ product_submission_queue  │  └──────────────────┘                               

│ shopping_list             │                                                      

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
