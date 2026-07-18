## 1. High-level overview

```
┌─────────────────────────────────────────────────────────────┐
│                         UI Layer                             │
│  screens/          widgets/          utils/                  │
│  HomeScreen        InventoryCard     logger                  │
│  ScannerScreen     EmptyPantry       snackbar_helper         │
│  ProductDetail     NutritionTable                            │
│  AddToInventory    ScannerOverlay                            │
│  Settings / Stats  PriceEntrySheet                           │
│  ShoppingList      QuickAddProduce                           │
│                    ...                                       │
└─────────┬────────────────────────────────────────────────────┘
          │  watches / reads Riverpod providers
┌─────────▼────────────────────────────────────────────────────┐
│                     State / DI Layer                          │
│  providers/                                                   │
│  activeInventoryProvider   inventoryWithProductProvider       │
│  settingsProvider          themeModeProvider                  │
│  productRepositoryProvider statsProvider                      │
│  imageCacheProvider        notificationServiceProvider        │
│  connectivityProvider      githubIssueServiceProvider         │
│  apiServiceProvider        inventoryCountProvider             │
│  priceRepositoryProvider   priceHistoryProvider               │
│  shoppingListProvider      storesProvider                     │
│  currencyServiceProvider   photoServiceProvider              │
│  firebaseCacheProvider     authServiceProvider               │
│  authStateProvider         inventoryProductsProvider          │
└─────────┬────────────────────────────────────────────────────┘
          │  calls
┌─────────▼────────────────────────────────────────────────────┐
│                    Business Logic Layer                        │
│  services/                                                    │
│  ProductRepository    OffAdapter    NotificationService       │
│  ImageCacheService    GithubIssueService                      │
│  PriceRepository      CurrencyService  OpenPricesService      │
│  StoreDao             ShoppingListDao  PhotoService           │
│  FirebaseCacheService  FirebaseCacheClient                    │
│  FirebaseFirestoreClientAdapter  AuthService                  │
│  FirebaseAuthService                                          │
└─────────┬──────────────┬──────────────────┬─────────────────┘
          │              │                  │
┌─────────▼────┐  ┌─────▼──────────────┐   │
│  Local DB    │  │  Remote API        │   │
│  database/   │  │  services/         │   │
│  SQLite      │  │  Open Food Facts   │   │
│  9 tables:   │  │  v3 REST (SDK)     │   │
│  products    │  │                     │   │
│  inventories │  │  Open Prices API    │   │
│  inventory   │  │  ExchangeRate-API   │   │
│  feedback_q  │  └─────────┬───────────┘   │
│  prices      │            │                │
│  shopping_l. │  ┌─────────▼───────────┐   │
│  stores      │  │  Cloud Cache        │   │
│  firebase_   │  │  Cloud Firestore    │   │
│   cache_meta │  │  product_cache/     │   │
│  DAO pattern │  │  produce_cache/     │   │
└──────────────┘  └─────────────────────┘   │
                    │
       ┌───────────────────────────────┐
       │  [Planned] Firebase Services   │
       │  Auth (Google Sign-In)        │
       │  Storage (cloud backup)       │
       │  AdMob (ads)                  │
       │  Play Billing (IAP)           │
       └───────────────────────────────┘
```
