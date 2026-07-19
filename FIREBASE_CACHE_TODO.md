# Firebase Cache — Implementation TODO

## How to use this file

Each step is a checkbox. Check it off when the step is complete. Steps are ordered
so that tests can be run after each one without unrelated failures. Pitfall references
like `[P1]` refer to the numbered entries in `FIREBASE_CACHE_PLAN.md` Section 15
(Edge Cases & Pitfalls).

**Before starting:** Read `FIREBASE_CACHE_PLAN.md` entirely to understand the full
architecture and design decisions.

---

## Phase 0: Scaffolding

### [x] 0.1 Add dependencies to pubspec.yaml

```yaml
firebase_core: ^3.12.0
cloud_firestore: ^5.6.0
```

Then run:

```bash
flutter pub get
```

**Edge cases:**
- [P1] If Firebase packages fail to resolve, check SDK constraints in pubspec.yaml (requires Dart 3.2+)
- [P3] `FIREBASE_ENABLED` flag in `.env` keeps everything off by default, so missing `google-services.json` won't crash development builds

### [x] 0.2 Add `firebaseEnabled` to AppConfig

**File**: `lib/config.dart`

Add:
```dart
static bool get firebaseEnabled =>
    dotenv.env['FIREBASE_ENABLED']?.toLowerCase() == 'true';
```

**File**: `.env.example`

Add:
```
FIREBASE_ENABLED=false
```

### [x] 0.3 Add to analysis_options.yaml (if needed)

The `firebase_core` and `cloud_firestore` packages may trigger `unused_import` or
`depend_on_referenced_packages` lint rules in the provider file where we use
`dynamic firestore`. No changes expected, but run `flutter analyze` to confirm:

```bash
flutter analyze --fatal-infos --fatal-warnings
```

### [x] 0.4 Verify test infrastructure

```bash
flutter test --concurrency=2
```

All existing tests must pass before any new code is added.

---

## Phase 1: Models

### [x] 1.1 Create `ProduceCacheEntry` model

**File**: `lib/models/produce_cache_entry.dart`

**Reference**: FIREBASE_CACHE_PLAN.md Section 5.1

**Implementation checklist:**
- [x] Freezed class with all fields from Section 5.1
- [x] `fromJson` / `toJson` (json_serializable via `.g.dart`)
- [x] `extension ProduceCacheEntryConversions` with:
  - [x] `fromProduct()` static method — converts USDA `Product` to a cache entry with 180-day `nextRefreshAt`
  - [x] `toProduct()` instance method — converts back to local `Product` (barcode, produce type, null-safe nutrition)
  - [x] `withRefreshedData()` — preserves `createdAt` during refresh [P13]

**Key details:**
- `nutrition` field is `Map<String, double>` — keys are `energyKcal`, `proteinG`, `carbsG`, `fatG`, `fiberG`
- `pluCodes` defaults to `[]`, `localizedNames` defaults to `{}`, `schemaVersion` defaults to `1`
- `_produceRefreshIntervalMs = 180 * 24 * 60 * 60 * 1000`
- Only include fields that make sense in a shared cache (no local file paths)

**Run after completion:**
```bash
dart run build_runner build --delete-conflicting-outputs
flutter test --concurrency=2
```

### [x] 1.2 Create `ProductCacheEntry` model

**File**: `lib/models/product_cache_entry.dart`

**Reference**: FIREBASE_CACHE_PLAN.md Section 5.2

**Implementation checklist:**
- [x] Freezed class with all fields from Section 5.2
- [x] `fromJson` / `toJson`
- [x] `extension ProductCacheEntryConversions` with:
  - [x] `fromProduct()` — copies all OFF-sourced fields from Product; intentionally excludes local-only fields [P19]
  - [x] `toProduct()` — reconstructs Product; `lastSynced` set to now
  - [x] `withRefreshedData()` — preserves `createdAt` [P13]

**Fields excluded from cache** (local-only, not stored in Firestore):
- `nutritionImagePath`, `ingredientsImagePath`, `productImagePath`
- `source`, `submissionStatus`, `productType`, `pluCode`, `lastSynced`

**Run after completion:**
```bash
dart run build_runner build --delete-conflicting-outputs
flutter test --concurrency=2
```

### [x] 1.3 Write model tests

**Files**:
- `test/models/produce_cache_entry_test.dart` — 10 tests (Section 12.1)
- `test/models/product_cache_entry_test.dart` — 12 tests (Section 12.2)

**Test both files:**
```bash
flutter test test/models/produce_cache_entry_test.dart
flutter test test/models/product_cache_entry_test.dart
```

**Edge cases to cover:**
- Nutrition fields being null on the source Product -> empty map in cache entry [P8]
- Round-trip: Product -> entry -> Product produces correct barcode and product type
- Timestamps are within 100ms tolerance (not exact equality due to clock granularity)
- Null image URLs, null categoriesHierarchy, null ingredients on source Product

---

## Phase 2: Database Layer

### [x] 2.1 Create `FirebaseCacheMetaDao`

**File**: `lib/database/firebase_cache_meta_dao.dart`

**Reference**: FIREBASE_CACHE_PLAN.md Section 6

**Implementation checklist:**
- [ ] `const` constructor (follows existing DAO pattern)
- [ ] `createTable(Database db)` — CREATE TABLE IF NOT EXISTS + indexes
- [ ] `upsert(db, cacheKey, cacheType, {fdcId, lastRefreshedAt, nextRefreshAt})` — ConflictAlgorithm.replace
- [ ] `get(db, cacheKey)` -> `Map<String, dynamic>?`
- [ ] `getStaleEntries(db, {cacheType, required nowInMs})` — query `next_refresh_at < nowInMs`, ordered ASC
- [ ] `getAllKeys(db, {cacheType})` — list of cache_key strings
- [ ] `remove(db, cacheKey)`
- [ ] `updateRefreshTimestamps(db, cacheKey, {lastRefreshedAt, nextRefreshAt})` — UPDATE only time columns [P12]
- [ ] `count(db, {cacheType})` — SELECT COUNT(*)

**Naming convention**: SQLite columns use `snake_case` (matching existing tables):
- `cache_key`, `cache_type`, `fdc_id`, `last_refreshed_at`, `next_refresh_at`

**Run after completion:**
```bash
flutter test test/database/firebase_cache_meta_dao_test.dart
```

### [x] 2.2 Write DAO tests

**File**: `test/database/firebase_cache_meta_dao_test.dart` — 14 tests (Section 12.3)

**Setup pattern** (follow existing test conventions):
```dart
setUpAll(() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
});

late DatabaseHelper db;
setUp(() async {
  db = DatabaseHelper.withPath(inMemoryDatabasePath);
  await db.database;
});
```

**Key test scenarios:**
- Mixed barcoded + produce entries with correct type discrimination
- Stale query boundary: entry with `next_refresh_at == now - 1ms` vs `now + 1ms`
- `updateRefreshTimestamps` does NOT overwrite `cache_key`, `cache_type`, or `fdc_id`
- Count per type is accurate

```bash
flutter test test/database/firebase_cache_meta_dao_test.dart
```

### [x] 2.3 Add v24 migration to DatabaseHelper

**File**: `lib/database/database_helper.dart`

**Changes:**

1. Bump `version:` from `23` to `24` in `_initDatabase()`.
2. Add table creation in `_onCreate()` (after the last existing table creation).
3. Add migration block in `_onUpgrade()`:
   ```dart
   if (oldVersion < 24) {
     try {
       await const FirebaseCacheMetaDao().createTable(db);
       logInfo('Migration to version 24 (firebase_cache_meta) completed');
     } on Exception catch (e) {
       logWarning('Migration v24 failed: $e');
     }
   }
   ```
4. Add DAO property:
   ```dart
   final FirebaseCacheMetaDao firebaseCacheMetaDao = const FirebaseCacheMetaDao();
   ```

**Warning**: The `_onCreate` method already creates all tables. The new table should be added
there too (not just the migration), so that fresh installs get version 24 directly.

**Run after completion:**
```bash
flutter test --concurrency=2
```

### [x] 2.4 Write migration test

**Add to**: `test/database/database_helper_test.dart` (Section 13)

**Test:**
- Create v23 database with full schema + sample data
- Open with v24 DatabaseHelper
- Verify `firebase_cache_meta` table exists in `sqlite_master`
- Verify existing data intact (product, inventory, etc.)
- Close and reopen (idempotency check)
- Insert a row into `firebase_cache_meta`, verify it persists

**Run:**
```bash
flutter test test/database/database_helper_test.dart
```

**Edge cases:**
- [P5] Migration from v23 where some v23 data already has `product_type = 'produce'` — verify no data loss
- Idempotency: re-running the migration (e.g., on a v24 database opened again) doesn't throw
- The `CREATE TABLE IF NOT EXISTS` + `CREATE INDEX IF NOT EXISTS` must not error on re-run

---

## Phase 3: Firestore Client

### [x] 3.1 Create `FirebaseCacheClient`

**File**: `lib/services/firebase_cache_client.dart`

**Reference**: FIREBASE_CACHE_PLAN.md Section 7

**Implementation checklist:**
- [ ] Constructor with `dynamic firestore` and `bool enabled` parameters
- [ ] `isAvailable` getter: `_firestore != null && _enabled`
- [ ] `getProduce(String name)` -> `Future<ProduceCacheEntry?>`
- [ ] `setProduce(ProduceCacheEntry entry)` -> `Future<bool>`
- [ ] `deleteProduce(String name)` -> `Future<void>`
- [ ] `getProduct(String barcode)` -> `Future<ProductCacheEntry?>`
- [ ] `setProduct(ProductCacheEntry entry)` -> `Future<bool>`
- [ ] `deleteProduct(String barcode)` -> `Future<void>`

**Graceful degradation contract** [P2]:
- When `isAvailable == false`: `get*` returns `null`, `set*` returns `false`, `delete*` is no-op
- When a Firestore exception occurs: `get*` returns `null`, `set*` returns `false`
- Every method logs a warning on failure
- Never rethrows

**Important**: Use `dynamic` for the `firestore` parameter type to avoid a hard import
of `FirebaseFirestore` when the feature flag is off. The actual runtime type will be
`FirebaseFirestore` when Firebase is configured.

**Run after completion:**
```bash
flutter test test/services/firebase_cache_client_test.dart
```

### [x] 3.2 Write Firestore client tests

**File**: `test/services/firebase_cache_client_test.dart` — 16 tests (Section 12.4)

**Mocking strategy:**

```dart
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}
class MockCollectionReference extends Mock implements CollectionReference {}
class MockDocumentReference extends Mock implements DocumentReference {}
class MockDocumentSnapshot extends Mock implements DocumentSnapshot {}
```

Register fallback values in `setUpAll`:
```dart
registerFallbackValue(ProduceCacheEntry(...));
registerFallbackValue(ProductCacheEntry(...));
```

**Key test scenarios:**
- Document exists with valid data -> returns deserialized entry
- Document does not exist (doc.exists == false) -> null
- Firestore throws `FirebaseException` -> null (logged)
- `isAvailable == false` -> all methods short-circuit
- Verify `collection().doc().get()` chain is called with correct collection name
- Verify `collection().doc().set()` chain is called with correct doc data

```bash
flutter test test/services/firebase_cache_client_test.dart
```

---

## Phase 4: Cache Service (Orchestrator)

### [x] 4.1 Create `FirebaseCacheService`

**File**: `lib/services/firebase_cache_service.dart`

**Reference**: FIREBASE_CACHE_PLAN.md Section 8

**Implementation checklist:**

**Constructor:**
- [x] Parameters: `DatabaseHelper db`, `FirebaseCacheClient firebaseClient`, `UsdaApiClient usdaClient`, `OffAdapter offAdapter`, `FirebaseCacheMetaDao? metaDao`
- [x] `isAvailable` getter delegate to `_firebaseClient.isAvailable`

**Lookup methods:**

`resolveBarcodedProduct(String barcode, {required String languageCode})`:
- [x] Check `isAvailable` before any Firebase operations [P4]
- [x] Try Firebase `_firebaseClient.getProduct(barcode)` — if hit: insert into SQLite, upsert meta, return Product
- [x] On Firebase miss/exception: call `_offAdapter.getByBarcode(barcode, languageCode: lang)`
- [x] On OFF success: fire-and-forget `cacheBarcodedProduct(product)`, return Product
- [x] On `ProductNotFoundException`: return null (caller handles)
- [x] On OFF network error: return null, log warning

`resolveProduceProduct(String produceName)`:
- [x] Validate input (empty/whitespace -> null)
- [x] Normalize to lowercase for cache key
- [x] Try Firebase `_firebaseClient.getProduce(lowerName)` — if hit: `toProduct()`, cache locally, upsert meta, return
- [x] On Firebase miss/exception: call `_usdaClient.searchFood(produceName)`
- [x] On USDA success: fire-and-forget `cacheProduceProduct(...)`, return Product
- [x] On USDA empty: return null (caller falls through to hardcoded data)

**Cache write methods:**

`cacheBarcodedProduct(Product product)` (fire-and-forget):
- [x] Check `isAvailable`, return early if false [P4]
- [x] `ProductCacheEntryConversions.fromProduct(product)` -> entry
- [x] `_firebaseClient.setProduct(entry)`
- [x] `_upsertMeta(product.barcode, 'barcoded', fdcId: null)`
- [x] Catch all exceptions, log warning, never rethrow [P2]

`cacheProduceProduct(Product product, String produceName, {int? fdcId})` (fire-and-forget):
- [x] Same pattern as barcoded version
- [x] Cache key = `'produce:$lowerName'`

**Refresh methods:**

`refreshStaleEntries({int maxBatchSize = 20})`:
- [x] Check `isAvailable`, return 0 if false [P4]
- [x] Get stale entries from `_metaDao.getStaleEntries(db, nowInMs: now)`
- [x] Return 0 if empty
- [x] Iterate with 500ms delay between entries [P10, P11]
- [x] Respect `maxBatchSize` [P12]
- [x] Each entry processed in try/catch [P9]
- [x] Return count of successes

`_refreshProduceEntry(Database db, String cacheKey)`:
- [x] Extract name from `produce:<name>` prefix
- [x] Call `_usdaClient.searchFood(name)`
- [x] If empty, return false (leave `nextRefreshAt` unchanged — retry next time)
- [x] Read existing Firestore entry to preserve `createdAt` [P13]
- [x] Create new entry with preserved `createdAt`
- [x] `_firebaseClient.setProduce(newEntry)`
- [x] `_metaDao.updateRefreshTimestamps(db, cacheKey, ...)`
- [x] `_db.insertProduct(localProduct)` — update local cache too

`_refreshBarcodedEntry(Database db, String cacheKey)`:
- [x] Call `_offAdapter.getByBarcode(cacheKey)`
- [x] Handle `ProductNotFoundException` — return false (entry not retried, as product may have been removed)
- [x] Read existing Firestore entry to preserve `createdAt` [P13]
- [x] Create new entry with preserved `createdAt`
- [x] Same pattern as produce refresh

**Helper methods:**

`_upsertMeta(cacheKey, cacheType, {fdcId})`:
- [x] Get database
- [x] Calculate `nextRefreshAt = now + 180 days`
- [x] `_metaDao.upsert(...)`
- [x] Catch, log, never rethrow

**Critical design decisions:**
- Fire-and-forget cache writes (no await in the lookup path) — the lookup returns as soon as the source API responds, caching happens in the background [P14]
- Refresh does NOT use fire-and-forget — it awaits each step because the entire point is to update the cache
- `nextRefreshAt` is NOT updated on refresh failure — the entry stays stale and will be retried [P16, P17]
- `createdAt` is ALWAYS preserved — only `lastRefreshedAt` and `nextRefreshAt` change [P13]

```bash
flutter analyze
flutter test test/services/firebase_cache_service_test.dart
```

### [x] 4.2 Write cache service tests

**File**: `test/services/firebase_cache_service_test.dart` — 22 tests (Section 12.5)

**Mock setup:**
```dart
class MockDatabaseHelper extends Mock implements DatabaseHelper {}
class MockFirebaseCacheClient extends Mock implements FirebaseCacheClient {}
class MockUsdaApiClient extends Mock implements UsdaApiClient {}
class MockOffAdapter extends Mock implements OffAdapter {}
class MockFirebaseCacheMetaDao extends Mock implements FirebaseCacheMetaDao {}
```

Register fallback values in `setUpAll`:
```dart
registerFallbackValue(ProduceCacheEntry(...));
registerFallbackValue(ProductCacheEntry(...));
registerFallbackValue(const Product(barcode: '', name: ''));
```

**Key test scenarios for lookup [P14, P15, P16]:**

1. Firebase hit for barcoded -> must NOT call OFF adapter
2. Firebase miss, OFF hit -> must call OFF, cache in Firebase + local
3. Both miss -> returns null
4. Firebase unavailable -> directly calls OFF (not Firebase)
5. Firebase get throws -> falls through to OFF
6. Firebase set throws after OFF success -> still returns Product (no data loss)

**Key test scenarios for refresh [P9, P12, P13, P17]:**

1. No stale entries -> 0, no API calls
2. One stale barcoded -> OFF called, Firestore updated, meta updated, returns 1
3. One stale produce -> USDA called, Firestore updated, meta updated, returns 1
4. Multiple mixed entries -> all processed sequentially with 500ms delays
5. API fails on one entry -> skipped, continues to next
6. `createdAt` preserved before/after refresh
7. `maxBatchSize` clips to 20

```bash
flutter test test/services/firebase_cache_service_test.dart
```

---

## Phase 5: ProductRepository Integration

### [x] 5.1 Add `firebaseCache` parameter

**File**: `lib/services/product_repository.dart`

**Changes:**

1. Add optional parameter to constructor:
   ```dart
   final FirebaseCacheService? _firebaseCache;

   ProductRepository(
     this._db,
     this._api, {
     this._fallbackApi,
     this._usdaClient,
     this._prefs,
     this._firebaseCache,  // NEW
   });
   ```

2. No changes to existing constructor callers needed — it's optional and defaults to `null`.

### [x] 5.2 Modify `getProduct`

**File**: `lib/services/product_repository.dart` (around line 90)

Insert step 1.5 between local cache check and OFF API call:

```dart
// 1. Local cache (existing)
final cached = await _db.getProduct(barcode);
if (cached != null) {
  logInfo('Cache hit for $barcode');
  return cached;
}

// NEW: 1.5 Firebase cache
if (_firebaseCache != null && _firebaseCache.isAvailable) {
  try {
    final fbProduct = await _firebaseCache.resolveBarcodedProduct(
      barcode,
      languageCode: lang,
    );
    if (fbProduct != null) {
      logInfo('Firebase cache hit for $barcode');
      return fbProduct;
    }
  } on Exception catch (e) {
    logWarning('Firebase cache lookup failed for $barcode: $e');
  }
}
```

**Edge cases:**
- [P4] `_firebaseCache` can be null (feature flag off) — skip Firebase entirely
- [P2] If Firebase throws, it's caught, logged, and we fall through to OFF API
- The existing `_db.insertProduct(remote)` in the OFF API path is complemented by the fire-and-forget in `resolveBarcodedProduct`

### [x] 5.3 Modify `_resolveProduceProduct`

**File**: `lib/services/product_repository.dart` (around line 262)

Insert Firebase check before USDA API call:

```dart
// NEW: 1. Firebase cache first
if (_firebaseCache != null) {
  try {
    final cached = await _firebaseCache.resolveProduceProduct(produceName);
    if (cached != null) {
      logInfo('Firebase produce cache hit for "$produceName"');
      return cached.copyWith(
        barcode: barcode,
        productType: ProductType.produce,
        source: 'manual',
        category: ProduceCategoryMapper.forName(produceName),
        lastSynced: DateTime.now().millisecondsSinceEpoch,
      );
    }
  } on Exception catch (e) {
    logWarning('Firebase produce cache lookup failed: $e');
  }
}
```

**Edge cases:**
- [P4] Firebase unavailable -> skip to USDA
- Firebase returns Product with null nutrition -> still returned (caller expects this — existing USDA path can also return null nutrition)
- `resolveProduceProduct` normalizes to lowercase internally, so "Apple" and "apple" both hit the same cache key

### [x] 5.4 Write integration tests

**Add to**: `test/services/product_repository_test.dart` — 10 tests total
(Firebase section in `product_repository_test.dart`)

**New mock:**
```dart
class MockFirebaseCacheService extends Mock implements FirebaseCacheService {}
```

**Test scenarios:**

1. **Firebase checked after local miss**: When `_db.getProduct` returns null and FirebaseCacheService is available, `resolveBarcodedProduct` must be called
2. **Firebase NOT called on local hit**: When local cache returns a product, Firebase must NOT be called
3. **OFF API skipped when Firebase returns null**: When Firebase is available and `resolveBarcodedProduct` returns null, direct OFF call is skipped (service already tried OFF internally) — falls through to fallback chain
4. **OFF API called when Firebase throws**: When Firebase throws an exception, direct OFF call is still attempted as fallback
5. **Produce Firebase checked before USDA**: `resolveProduceProduct` on FirebaseCacheService called first
6. **Produce USDA called when `firebaseCache` is null**: No firebase cache configured -> directly calls USDA
7. **addProduceToInventory uses Firebase when local cache misses**: Firebase is checked when local product not found

```bash
flutter test test/services/product_repository_test.dart
```

### [x] 5.5 Full regression test

```bash
flutter test --concurrency=2
```

All existing tests must still pass. The changes are purely additive (new optional parameter,
additional code path before existing code paths) so no existing test should break.

---

## Phase 6: Providers

### [x] 6.1 Create `firebaseCacheProvider`

**File**: `lib/providers/firebase_cache_provider.dart`

**Reference**: FIREBASE_CACHE_PLAN.md Section 10

```dart
final firebaseCacheProvider = Provider<FirebaseCacheService>((ref) {
  final db = ref.read(databaseProvider);
  final api = ref.read(apiServiceProvider);

  dynamic firestore;
  if (AppConfig.firebaseEnabled) {
    try {
      firestore = FirebaseFirestore.instance;
    } on Exception catch (e) {
      logWarning('Firestore unavailable, caching disabled: $e');
    }
  }

  final client = FirebaseCacheClient(
    firestore: firestore,
    enabled: firestore != null,
  );

  return FirebaseCacheService(
    db: db,
    firebaseClient: client,
    usdaClient: UsdaApiClient(),
    offAdapter: api,
  );
});
```

**Edge cases:**
- [P1] If `FirebaseFirestore.instance` throws (no `google-services.json` or wrong project), the try/catch catches it and the client is created with `isAvailable: false`
- [P3] When `firebaseEnabled == false`, `firestore` stays `null`, client is disabled

**Note**: The `firestore` field is typed as `dynamic` to avoid a Dart import error when
Firebase is not configured. The lint rule `unnecessary_cast` or `unused_import` should
be suppressed with a comment if needed, but `dynamic` generally avoids the issue.

### [x] 6.2 Wire into `productRepositoryProvider`

**File**: `lib/providers/product_repository_provider.dart`

```dart
final productRepositoryProvider = Provider<ProductRepository>((ref) {
  final db = ref.read(databaseProvider);
  final api = ref.read(apiServiceProvider);
  final firebaseCache = ref.read(firebaseCacheProvider);  // NEW
  return ProductRepository(
    db,
    api,
    usdaClient: UsdaApiClient(),
    firebaseCache: firebaseCache,  // NEW
  );
});
```

```bash
flutter analyze
flutter test --concurrency=2
```

---

## Phase 7: App Initialization

### [x] 7.1 Add Firebase init to `main.dart`

**File**: `lib/main.dart`

Insert after `await dotenv.load()` and before `off.OpenFoodAPIConfiguration.userAgent`:

```dart
if (AppConfig.firebaseEnabled) {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    logInfo('Firebase initialized successfully');
  } on Exception catch (e) {
    logWarning('Firebase init failed (graceful degradation): $e');
  }
}
```

**Edge cases:**
- [P1] `Firebase.initializeApp()` throws on missing `google-services.json` -> caught, logged, app continues
- [P4] `DefaultFirebaseOptions.currentPlatform` requires `firebase_options.dart` generated by `flutterfire configure`. If the file doesn't exist, the import itself will error — so this should only be compiled when `FIREBASE_ENABLED=true` or we use conditional imports.
  - **Solution**: Wrap in `if (AppConfig.firebaseEnabled)` which is a runtime check. But the import will still fail at compile time if the file doesn't exist.
  - **Alternative**: Guard with `kReleaseMode` + try/catch around the entire block, or create a small wrapper that handles the missing file.
  - **Recommended approach**: The `flutterfire configure` step creates `firebase_options.dart` automatically. If it hasn't been run yet, the import fails at compile time. To keep the build passing with the flag off, conditionally import:

```dart
// In a separate helper file lib/services/firebase_init.dart:
import 'package:flutter/foundation.dart';
import 'package:pantry_app/config.dart';
import 'package:pantry_app/utils/logger.dart';

Future<void> initializeFirebase() async {
  if (!AppConfig.firebaseEnabled) return;
  try {
    // eslint-disable-next-line depend_on_referenced_packages
    await Firebase.initializeApp();
    logInfo('Firebase initialized');
  } on Exception catch (e) {
    logWarning('Firebase init failed: $e');
  }
}
```

Or simpler: just wrap in try/catch and don't import `DefaultFirebaseOptions`:

```dart
if (AppConfig.firebaseEnabled) {
  try {
    await Firebase.initializeApp();
    logInfo('Firebase initialized');
  } on Exception catch (e) {
    logWarning('Firebase init failed: $e');
  }
}
```

`Firebase.initializeApp()` without options will use the `google-services.json` / `GoogleService-Info.plist` embedded in the app bundle. This is the simplest approach and avoids the generated `firebase_options.dart` dependency.

### [x] 7.2 Add background refresh scheduling

**File**: `lib/main.dart`

Add to `_runPostInitTasks()`:

```dart
unawaited(
  Future<void>.delayed(
    const Duration(seconds: 8),
    _refreshFirebaseCache,
  ),
);
```

Add method:

```dart
Future<void> _refreshFirebaseCache() async {
  try {
    final cacheService = appContainer.read(firebaseCacheProvider);
    if (cacheService.isAvailable) {
      final refreshed = await cacheService.refreshStaleEntries();
      if (refreshed > 0) {
        logInfo('Firebase cache: $refreshed entries refreshed');
      }
    }
  } on Exception catch (e) {
    logWarning('Firebase cache refresh failed: $e');
  }
}
```

**Edge cases:**
- [P9] If the user closes the app during refresh, unprocessed entries stay stale and will be retried next startup
- [P12] Large stale entry counts are handled by `maxBatchSize: 20` — no need to worry about long-running operations blocking startup
- The 8-second delay avoids competing with `_scheduleCacheRefresh`, `_runDatabaseCleanup`, `_flushFeedbackQueue`, `_schedulePostInitNotifications`, and `_flushProductSubmissionQueue` for network bandwidth

### [x] 7.3 Verify compile

```bash
flutter analyze --fatal-infos --fatal-warnings
```

Must pass with zero warnings.

---

## Phase 8: Firebase Project Setup (Manual)

These steps are done by a developer with Firebase Console access, in parallel with
the code changes. They do not block merging (feature flag is off).

### [ ] 8.1 Create Firebase project

1. Go to https://console.firebase.google.com
2. Create a new project (or use an existing one)
3. Enable Firestore (Native mode)
4. Choose a region (us-central1 recommended for lowest latency)

### [ ] 8.2 Deploy Firestore security rules

Copy rules from FIREBASE_CACHE_PLAN.md Section 14 and deploy:

```bash
firebase deploy --only firestore:rules
```

Or paste directly in the Firebase Console > Firestore > Rules tab.

### [ ] 8.3 Run `flutterfire configure`

```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=<your-project-id>
```

This generates:
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist` (if iOS is configured)
- `lib/firebase_options.dart`

### [ ] 8.4 Add Android SHA fingerprints (optional, for Google Sign-In future)

If Google Sign-In is planned, add the debug keystore SHA-1 to Firebase Console >
Project Settings > General > Your apps > Android app > Add fingerprint:

```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

### [ ] 8.5 Enable Firebase in .env

```env
FIREBASE_ENABLED=true
```

### [ ] 8.6 Verify end-to-end

Run on emulator or device:

1. `flutter run`
2. Check logs for `Firebase initialized successfully`
3. Scan a barcode (e.g., a product with known OFF data)
4. Go to Firebase Console > Firestore > `product_cache` — a document should exist with the barcode as key
5. Add a produce item (e.g., "Apple") from the quick-add screen
6. Check Firebase Console > Firestore > `produce_cache` — a document named `apple` should exist
7. Kill the app, reopen, wait 10 seconds — check logs for `Firebase cache: N entries refreshed`

---

## Phase 9: Pre-Commit Gate

### [ ] 9.1 Run full analysis and tests

```bash
flutter analyze --fatal-infos --fatal-warnings
flutter test --concurrency=2
```

### [ ] 9.2 Run build smoke test

```bash
flutter build apk --debug
```

### [ ] 9.3 Check for stale documentation

```bash
bash scripts/check_stale_info.sh
```

### [ ] 9.4 Update ARCHITECTURE docs

After the feature is complete and working:

1. Add `FirebaseCacheService` to `ARCHITECTURE/SERVICES.md` (between 3.6 and 3.7)
2. Add `firebase_cache_meta` table to `ARCHITECTURE/DATABASE.md`
3. Add Firebase cache flow to `ARCHITECTURE/OVERVIEW.md` diagram
4. Add `firebaseCacheProvider` to `ARCHITECTURE/PROVIDERS.md`

---

## Phase 10: Post-Commit

### [ ] 10.1 Update CHANGELOG.md

Add entry describing the Firebase cache feature.

### [ ] 10.2 Update USER_CHANGELOG.md and translations

Add user-facing entry: "Faster product lookups through cloud cache"

Translate to `USER_CHANGELOG_pt.md` and `USER_CHANGELOG_pt_BR.md`.

### [ ] 10.3 Update TODO.md

Mark the Firebase setup item as completed in TODO.md.

---

## Summary of all test commands

Run these in order as each phase completes:

```bash
# Phase 0
flutter pub get
flutter analyze --fatal-infos --fatal-warnings
flutter test --concurrency=2

# Phase 1
dart run build_runner build --delete-conflicting-outputs
flutter test test/models/produce_cache_entry_test.dart
flutter test test/models/product_cache_entry_test.dart

# Phase 2
flutter test test/database/firebase_cache_meta_dao_test.dart
flutter test test/database/database_helper_test.dart

# Phase 3
flutter test test/services/firebase_cache_client_test.dart

# Phase 4
flutter test test/services/firebase_cache_service_test.dart

# Phase 5
flutter test test/services/product_repository_test.dart
flutter test --concurrency=2

# Phase 6
flutter analyze --fatal-infos --fatal-warnings
flutter test --concurrency=2

# Phase 7
flutter analyze --fatal-infos --fatal-warnings
flutter test --concurrency=2

# Phase 8 (manual QA)
flutter build apk --debug

# Phase 9 (pre-commit)
flutter analyze --fatal-infos --fatal-warnings
flutter test --concurrency=2
bash scripts/check_stale_info.sh
```

---

## Quick reference: Edge cases by phase

| Phase | Relevant Pitfalls |
|-------|-------------------|
| 0 — Scaffolding (done) | P1, P3 |
| 1 — Models (done) | P8, P13, P19 |
| 2 — Database (done) | P5, P12 |
| 3 — Firestore Client (done) | P2, P4 |
| 4 — Cache Service (done) | P2, P4, P9, P10, P11, P12, P13, P14, P15, P16, P17 |
| 5 — Repository Integration (done) | P2, P4 |
| 6 — Providers (done) | P1, P3, P4 |
| 7 — App Init (done) | P1, P4, P9, P12 |
| 8 — Firebase Setup | P1, P4 |

## Quick reference: Pitfall descriptions

| ID | Pitfall | Mitigation |
|----|---------|------------|
| P1 | No `google-services.json` | Try/catch in `main.dart`, `isAvailable` stays false |
| P2 | Firestore read/write throws | Every method catches `FirebaseException`, returns null/false |
| P3 | `FIREBASE_ENABLED=true` but no .env entry | `??` operator defaults to false |
| P4 | Firebase unavailable at runtime | `isAvailable` check before every operation |
| P5 | Migration from v23 with produce data | Verify data intact in migration test |
| P8 | Source Product has null nutrition | Empty nutrition map, null fields on toProduct |
| P9 | App killed during refresh | Unprocessed entries retry next startup |
| P10 | USDA rate limit (360 req/min) | 500ms delay = 2 req/sec = 120 req/min |
| P11 | OFF rate limit | Same 500ms delay, 429 triggers skip+retry |
| P12 | Hundreds of stale entries | Max 20 per run, rest retry next startup |
| P13 | `createdAt` overwritten on refresh | Explicitly read and preserve old value |
| P14 | Lookup vs refresh race on same doc | Firebase `set()` is atomic, last-writer-wins |
| P15 | Two instances refresh same doc simultaneously | Data is identical (same source API), timestamps differ by ms |
| P16 | Refresh: API fails (no results) | nextRefreshAt unchanged, retried next time |
| P17 | Refresh: API fails (network error) | nextRefreshAt unchanged, retried next time |
| P19 | Local-only Product fields not in Firestore | Intentionally excluded from cache entry model |
