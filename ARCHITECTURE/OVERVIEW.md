## 1. High‑level overview

```
┌─────────────────────────────────────────────────────────────┐
│                         UI Layer                             │
│  screens/          widgets/          utils/                  │
│  HomeScreen        InventoryCard     logger                  │
│  ScannerScreen     EmptyPantry       snackbar_helper         │
│  ProductDetail     NutritionTable                            │
│  AddToInventory    ScannerOverlay                            │
│  Settings / Stats  ...                                       │
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
└─────────┬────────────────────────────────────────────────────┘
          │  calls
┌─────────▼────────────────────────────────────────────────────┐
│                    Business Logic Layer                        │
│  services/                                                    │
│  ProductRepository    OffAdapter    NotificationService       │
│  ImageCacheService    GithubIssueService  AdService           │
│  DonationService      CloudBackupService FirebaseService      │
└─────────┬──────────────┬──────────────────┬─────────────────┘
          │              │                  │
┌─────────▼────┐  ┌─────▼──────────────┐   │
│  Local DB    │  │  Remote API        │   │
│  database/   │  │  services/         │   │
│  SQLite      │  │  Open Food Facts   │   │
│  DAO pattern │  │  v3 REST (SDK) │   │
└──────────────┘  └────────────────────┘   │
                                            │
                               ┌───────────────────────────────┐
                               │  [Planned] Firebase Services   │
                               │  Auth (Google Sign-In)        │
                               │  Storage (cloud backup)       │
                               │  AdMob (ads)                  │
                               │  Play Billing (IAP)           │
                               └───────────────────────────────┘
```
