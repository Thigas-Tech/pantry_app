# Fix Failing Tests and Firestore Authentication

> **For agentic workers:** Each task is self-contained with exact file paths, code, and commands.

**Goal:** Fix the 23 failing `price_provider_test.dart` tests, enable anonymous Firebase Authentication so Firestore writes succeed, and silence the `setState() called during build` riverpod warning.

**Root cause summary:**

| Problem | Root cause |
|---|---|
| 23 tests fail with `Binding has not yet been initialized` | `ActiveInventoryNotifier.build()` calls `SharedPreferences.getInstance()` (crash in plain `test()` without binding) |
| Firestore writes return `PERMISSION_DENIED` | Anonymous auth not enabled in Firebase Console → `signInAnonymously()` fails with `CONFIGURATION_NOT_FOUND` → `request.auth == null` → rules deny writes |
| `setState() called during build` — UncontrolledProviderScope | Known riverpod issue: `TickerMode.didChangeDependencies` resumes provider subscriptions during build phase, triggering `scheduleRefresh` |

## Global Constraints

- `flutter analyze --fatal-infos --fatal-warnings` must pass with zero issues on every commit
- Never add `// ignore:` or `// ignore_for_file:` — fix the underlying issue
- All user-visible strings in `lib/l10n/app_en.arb` — never hardcode English
- Existing passing tests must not regress

---

### Task 1: Fix 23 failing price_provider_test.dart tests

**Files:**
- Modify: `test/providers/price_provider_test.dart:28-36`
- No other files touched

**Interfaces:**
- Consumes: `ActiveInventoryNotifier` (reads `SharedPreferences` in build)
- Consumes: `MockPriceRepository` (already mocked)
- Produces: All 23 tests pass

**Root cause:** `ActiveInventoryNotifier.build()` at `lib/providers/active_inventory_provider.dart:22` calls `unawaited(_validateAndLoad())`, which calls `SharedPreferences.getInstance()` at line 42. The `ProviderContainer` created in `setUp` triggers the notifier's `build()` which fails because `SharedPreferences.getInstance()` requires `WidgetsFlutterBinding` or mock values.

- [ ] **Step 1: Add shared_preferences import and mock initial values in setUp**

```dart
// In test/providers/price_provider_test.dart, add to imports:
import 'package:shared_preferences/shared_preferences.dart';

// In setUp(), before container creation:
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({'active_inventory_id': 1});
    mockRepo = MockPriceRepository();
    container = ProviderContainer(
      overrides: [
        priceRepositoryProvider.overrideWithValue(mockRepo),
        settingsProvider.overrideWith(_defaultSettings),
      ],
    );
  });
```

**Key detail:** `setUp` becomes async because `SharedPreferences.setMockInitialValues` is synchronous but `TestWidgetsFlutterBinding.ensureInitialized` must be awaited in some contexts. The fix uses `TestWidgetsFlutterBinding.ensureInitialized()` at the top of `setUp` and `SharedPreferences.setMockInitialValues({})` to provide fake prefs before the container is created.

- [ ] **Step 2: Run tests to verify all 23 pass**

```bash
flutter test --concurrency=2 test/providers/price_provider_test.dart
```

Expected: `All tests passed!` (no failures)

- [ ] **Step 3: Run full test suite to verify no regression**

```bash
flutter test --concurrency=2
```

Expected: The 23 failures are gone. Total should be 1028 pass (the previous 1005 + 23 now-passing price_provider tests = 1028), minus any auth tests that may have been added.

- [ ] **Step 4: Commit**

```bash
git add test/providers/price_provider_test.dart
git commit -m "fix: mock SharedPreferences in price_provider_test to fix 23 binding failures"
```

**Edge case / Pitfall:** `SharedPreferences.setMockInitialValues({})` must be called **before** `ProviderContainer` is created. If called after, the notifier has already tried to access `SharedPreferences` and crashed. The call is a no-op if called multiple times — it replaces all stored values.

**Edge case / Pitfall:** The mock values persist for the entire test file. Each test gets the same initial values. Since the default `_validateAndLoad()` looks for `'active_inventory_id'`, set it to `1` to match the default `state` and avoid a needless state change.

---

### Task 2: Enable Anonymous Authentication in Firebase Console

**Files:**
- Modify: `firebase.json` — add `auth` provider config
- No Dart/Flutter code changes

**Interfaces:**
- Consumes: Firebase project `pantry-app-c5c36` (already configured via `firebase.json`)
- Produces: `signInAnonymously()` succeeds in `main.dart:79`, Firestore writes pass with `request.auth != null`

**Root cause:** Anonymous auth provider not enabled in Firebase Console. `signInAnonymously()` at `lib/services/firebase_auth_service.dart:59` throws `[firebase_auth/unknown] CONFIGURATION_NOT_FOUND`. Without an authed user, Firestore rules at Task 3 deny writes.

- [ ] **Step 1: Set active Firebase project**

```bash
firebase use pantry-app-c5c36
```

- [ ] **Step 2: Initialize auth with anonymous provider in firebase.json**

Run interactive init for auth, or manually write the config:

Add to `firebase.json`:

```json
{
  "flutter": { ... existing flutter config ... },
  "auth": {
    "providers": {
      "anonymous": true,
      "emailPassword": false
    }
  }
}
```

> **Note:** The `firebase.json` currently has only the `"flutter"` key. We need to add the `"auth"` key alongside it.

- [ ] **Step 3: Deploy the auth config**

```bash
firebase deploy --only auth
```

Expected output: `Deploy complete!` with the auth configuration uploaded.

- [ ] **Step 4: Verify in Firebase Console**

Check https://console.firebase.google.com/project/pantry-app-c5c36/authentication/providers — Anonymous should show as **Enabled**.

- [ ] **Step 5: Run app and verify auth works**

```bash
flutter run --debug
```

Expected log line: `[INFO] Anonymous auth initialized` (currently shows `[WARN] Firebase init/auth failed (graceful degradation)`).

- [ ] **Step 6: Add a product and verify Firestore write succeeds**

From the app UI, add a product (barcoded or produce). Expected log:
- `[INFO] Firebase initialized successfully`
- `[INFO] Anonymous auth initialized`
- No `PERMISSION_DENIED` warnings — `setProduct` / `setProduce` logs the barcode without the warning

- [ ] **Step 7: Commit**

```bash
git add firebase.json
git commit -m "fix: enable anonymous Firebase Auth to resolve Firestore PERMISSION_DENIED"
```

**Edge case / Pitfall:** The `firebase deploy --only auth` command requires `firebase-tools` CLI. If not installed:
```bash
npm install -g firebase-tools
```

**Edge case / Pitfall:** If the auth config in `firebase.json` is not picked up, try `firebase init auth` interactively to generate the correct format.

**Edge case / Pitfall:** The anonymous provider may take up to 30 seconds to propagate after deployment. If it still fails immediately, wait and retry.

**Edge case / Pitfall:** If the user's `.env` has `FIREBASE_ENABLED=false`, revert it to `true`. After this fix, `FIREBASE_ENABLED=true` will work correctly (auth will succeed instead of failing).

---

### Task 3: Silence `setState() called during build` riverpod warning (non-critical)

**Files:**
- Modify: `lib/providers/active_inventory_provider.dart:52` — defer state changes via microtask
- No other files

**Interfaces:**
- Consumes: `ActiveInventoryNotifier` (same class, no API changes)
- Produces: No `setState() called during build` in logs when navigating back

**Root cause:** `ActiveInventoryNotifier._validateAndLoad()` calls `state = targetId` (line 52/59) which triggers invalidation on all dependent providers. When the invalidation cascades during `TickerMode.didChangeDependencies` (triggered by route pop), the riverpod scheduler tries to `setState` on `UncontrolledProviderScope` during the build phase.

- [ ] **Step 1: Wrap state assignments in microtask to defer invalidation**

In `lib/providers/active_inventory_provider.dart`:

Current:
```dart
      final exists = inventories.any((i) => i['id'] == targetId);
      if (exists) {
        if (targetId != state) {
          state = targetId;
        }
        return;
      }
```

Replace with:
```dart
      final exists = inventories.any((i) => i['id'] == targetId);
      if (exists) {
        if (targetId != state) {
          scheduleMicrotask(() => state = targetId);
        }
        return;
      }
```

Also wrap the same line further down:
```dart
      unawaited(prefs.setInt('active_inventory_id', resolvedId));
      state = resolvedId;
```

Replace with:
```dart
      unawaited(prefs.setInt('active_inventory_id', resolvedId));
      scheduleMicrotask(() => state = resolvedId);
```

- [ ] **Step 2: Run analyze to verify no issues**

```bash
flutter analyze --fatal-infos --fatal-warnings
```

Expected: `No issues found!`

- [ ] **Step 3: Run full test suite**

```bash
flutter test --concurrency=2
```

Expected: All tests pass.

- [ ] **Step 4: Run app and verify no `setState` errors on back navigation**

```bash
flutter run --debug
```

Navigate to a detail screen, press back. Verify no `setState() called during build` in the logs.

- [ ] **Step 5: Commit**

```bash
git add lib/providers/active_inventory_provider.dart
git commit -m "fix: defer state assignments in ActiveInventoryNotifier to prevent setState during build"
```

**Edge case / Pitfall:** `scheduleMicrotask` requires `import 'dart:async';` — this is already imported at the top of the file (line 1).

**Edge case / Pitfall:** `scheduleMicrotask` fires after the current microtask queue drains. This means dependent providers won't see the new state until the next microtask. For `activeInventoryProvider`, this delay is acceptable because the value is only used in read operations (inventory listing, price lookups) that already have their own loading states.

**Edge case / Pitfall:** This fix may not fully eliminate the warning if other providers in the dependency chain also call `invalidateSelf` during `TickerMode`. If it persists, check which specific provider is being invalidated by placing a breakpoint at `ProviderElement.invalidateSelf`. However, since the warning is non-fatal (Flutter explicitly allows it), this is a best-effort fix.

**Edge case / Pitfall:** If `scheduleMicrotask` doesn't suppress the warning, an alternative is `Future.microtask(() => state = targetId)` which schedules on the event queue instead (deeper deferral).

---

### Task 4: Verify Firestore data is actually persisted

**No code changes — verification task.**

After Tasks 1-3 are done, verify end-to-end that data reaches Firestore.

- [ ] **Step 1: Run app and add a produce item**

```bash
flutter run --debug
```

Add "Apple" (or any produce). Verify logs show:
```
[INFO] Searching USDA for "Apple"
[INFO] USDA: N results for "Apple"
[INFO] Firestore setProduce succeeded (or no PERMISSION_DENIED)
```

- [ ] **Step 2: Check Firebase Console Firestore data viewer**

Open https://console.firebase.google.com/project/pantry-app-c5c36/firestore/data

Verify:
- `produce_cache/{name}` document exists (e.g. `produce_cache/apple`)
- `product_cache/{barcode}` document exists (if barcoded product was added)
- Each document has the required fields: `fdcId`, `name`, `nutrition`, `createdAt`, `lastRefreshedAt`, `nextRefreshAt` (for produce) or `barcode`, `name`, `createdAt`, `lastRefreshedAt`, `nextRefreshAt` (for barcoded)

- [ ] **Step 3: Add a barcoded product and verify**

Scan a barcode or search by barcode. Verify the product is cached to both local SQLite and Firestore.

- [ ] **Step 4: Verify cache reads work**

Remove the product from local SQLite (or modify the data). Restart the app. The next lookup should show `Firebase cache hit` and the product should be returned from Firestore without calling the source API.

- [ ] **Step 5: Run full verification suite**

```bash
flutter analyze --fatal-infos --fatal-warnings
flutter test --concurrency=2
```

Both should pass with zero issues.

---
