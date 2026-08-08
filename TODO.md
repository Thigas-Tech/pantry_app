# TODO.md — Pantry App Roadmap

Items ordered: CI/CD first, then low-to-high effort. Features requiring paid
infrastructure or external server hosting are listed last.

---

## CI/CD & DevOps (top priority)

- [x] **GitHub Actions — CI pipeline** — on every PR to `main`:
  - `dart analyze` (lint check)
  - `dart format --set-exit-if-changed .` (formatting check)
  - `flutter test --concurrency=2 --coverage` (tests + coverage report)
  - Upload coverage artifact, comment coverage on PR.
- [x] **GitHub Actions — Build artifacts** — on every push to `main`:
  - `flutter build apk --debug` + `flutter build appbundle --debug`
  - Inject `.env` from GitHub secrets if available.
  - Upload APK and AAB as workflow artifacts (7-day retention).
- [x] **GitHub Actions — Release drafter** — on push to `main`:
  - Auto-creates draft release with changelog from PR labels.
- [x] **GitHub Actions — PR labeler** — auto-labels PRs by title prefix.
- [x] **GitHub Actions — Patrol E2E on schedule** — weekly run of the Patrol
  test suite on a real Android emulator (GitHub‑hosted runner).
- [x] **GitHub Actions — Flashlight performance regression** — run
  [Flashlight](https://github.com/bamlab/flashlight) on an emulator in CI.
  Store baseline scores (FPS, CPU, GPU, memory) as CI artifacts.
  Compare PR scores against main branch. Block merging if scores
  degrade >10%.
- [x] **GitHub Actions — Perfetto trace analysis** — collect Perfetto traces
  during key user flows (home screen scroll, product detail navigation,
  scanner start). Parse with `perfetto` CLI for frame timing violations,
  jank metrics, and CPU scheduling patterns. Fail CI if metrics degrade below
  baseline. Reference: [Flutter performance profiling](https://docs.flutter.dev/perf/ui-performance).
- [ ] **Track Flutter 3.44.0 AAB stripping regression** — upstream fix
  expected in a patch release. Remove `ndk { debugSymbolLevel }` workaround
  when fixed.
  Follow [flutter/flutter#186810](https://github.com/flutter/flutter/issues/186810).
- [x] **GitHub Actions — Play Store deployment** — on release published:
  - Decode keystore from `ANDROID_KEYSTORE_BASE64` secret
  - Decode `key.properties` from `KEY_PROPERTIES_BASE64` secret
  - `flutter build appbundle` + `flutter build apk` (release, signed)
  - Upload both to Google Play Console via `r0adkll/upload-google-play`
  - Triggered by `build.yml` publish job (creates GitHub Release) or
    manual release creation.
  - Requires: Play Store service account JSON, signing keystore, and
    AdMob/Firebase configs stored as GitHub secrets.
- [x] **Deploy-to-Play-Store workflow file** — exists at
  `.github/workflows/deploy-to-playstore.yml`. Triggers on
  `release: [published]`.
- [x] **Signing setup** — `android/key.properties` template exists,
  `build.gradle.kts` reads from `key.properties` with fallback to debug
  signing. Keystore and properties decoded from GitHub secrets in CI.

### Monetization (shipped with Play Store launch)

- [ ] **AdMob integration** — add `google_mobile_ads` package, create
  `AdService` (init, load banners/native ads, dispose), `AdBanner`
  widget and `SearchNativeAd` widget. Banner on Home, Product Detail,
  Settings, Stats. Native ad in Search results (every 5th).
- [ ] **GDPR/LGPD consent flow** — UMP SDK consent on first launch,
  "Ad Preferences" toggle in Settings, privacy policy link.
- [ ] **Donation IAP** — add `in_app_purchase` package, create
  `DonationService` wrapping Play Billing. Three consumable tiers
  ($2.99, $4.99, $9.99). "Support Development" section in Settings.
- [ ] **Pro subscription** — monthly ($0.99) and yearly ($9.99)
  auto-renewing subscription. Removes all ads when active. Tied to
  cloud backup feature.
- [x] **Firebase core setup** — Firebase project created, `google-services.json`
  downloaded, `firebase_core` + `cloud_firestore` + `firebase_auth`
  added as dependencies. Product cache and anonymous auth are live.
- [ ] **Google Sign-In** — enable Google Sign-In in Firebase Console,
  add `google_sign_in` package, wire into `AuthService`.
- [ ] **Cloud backup service** — `FirebaseService` (Auth + Storage init),
  `CloudBackupService` (export DB → upload to `users/{uid}/backup.db`,
  restore by download + replace + provider invalidation).
  `CloudBackupScreen` with sign-in prompt, backup/restore buttons,
  last-backup metadata display. Gated behind Pro subscription.

---

## Low Effort

- [x] **Batch delete** — multi-select items via checkboxes, delete all
  selected. Reuses existing `deleteInventoryItem` + undo snackbar.
- [x] **Expiry date guard** — date picker already uses
  `firstDate: DateTime.now()`. Verified correct.
- [x] **Quick quantity adjustment** — `+/−` buttons on each inventory tile in
  `ProductDetailScreen`. Tap quantity to type a number directly. Decrementing
  to 0 deletes the item with confirmation + undo. Re-schedules notifications
  on restore.
- [x] **Coverage: `stats_screen.dart`** (83.6%) — test export + import button
  flows.
- [x] **Coverage: `home_screen.dart`** (72.2%) — test create-pantry dialog,
  batch delete.
- [x] **Coverage: `add_product_screen.dart`** (85.3%) — test form validation +
  save-and-pop.
- [x] **Coverage: `add_to_inventory_screen.dart`** (94.0%) — test custom
  unit/location dialogs.
- [x] **Coverage: `inventory_card.dart`** (87.7%) — test tap navigation, image
  cache miss.
- [x] **Coverage: `connectivity_provider.dart`** (33.3%) — stream emission
  test.
- [x] **Extract expiry-date parsing** — duplicated in `home_screen.dart`,
  `product_detail_screen.dart`, `inventory_card.dart`. Extracted to
  `utils/date_helpers.dart`: `parseExpiryDate()`, `isExpired()`,
  `isExpiringSoon()`.
- [x] **Deduplicate custom picker dialogs** — extracted
  `_showCustomInput(title, onPicked)` shared by both.
- [x] **Deduplicate settings dialogs** — extracted
  `_showDaysDialog(title, initialValue)` shared by both.
- [x] **Screenshots section** — removed placeholder table; added single‑line
  placeholder.
- [x] **Remove unused `product_api_service.dart`** — removed;
  `ProductRepository` now uses `OffAdapter` directly. `close()` method
  removed from `OffAdapter`.
- [x] **Golden tests for `NutriScoreBadge`** — verify A–E colours render
  correctly via `matchesGoldenFile`.
- [x] **Accessibility audit** — added Semantics label to NutriScoreBadge; 5
  semantics tests verify labels for grades a–e, null, and invalid.
- [x] **Flutter widget catalog review** — audited Material 3 widgets. New
  candidates added below.
- [x] **Performance optimization reference doc** — added section 11 to
  `ARCHITECTURE/PERFORMANCE.md` documenting: dark mode energy savings, image caching
  rationale, offline-first, `RepaintBoundary` strategy, thread strategy,
  AAB/deferred components, eco-mode pattern, and performance measurement.

### Performance audits

- [x] **Repaint boundaries audit** — wrap animated or independently-scrolling
  widget subtrees with `RepaintBoundary`. Audit `HomeScreen._InventoryList`
  (scroll), `SearchScreen` results list, `StatsScreen` charts. Reference:
  [Flutter Performance Best Practices](https://docs.flutter.dev/perf/best-practices).
- [x] **`ListView.builder` audit** — audit all uses of `ListView()` across
  screens. The default `ListView(children: [])` builds ALL children at once
  (O(n) build cost), causing jank on large lists. Convert to
  `ListView.builder` or `ListView.separated` where item count exceeds ~10 or
  is dynamic. Priority: `home_screen.dart` inventory list,
  `product_detail_screen.dart` inventory tiles, `stats_screen.dart` stat
  rows. `search_screen.dart` already uses `ListView.separated`.
- [x] **Confine setState audit** — extract stateful logic into small isolated
  widgets so `setState` does not rebuild the entire parent screen. Audit 32
  `setState` calls; highest impact: `PantryShell._onPageChanged` (rebuilds
  entire PageView on every swipe), `HomeScreen._searchQuery`,
  `HomeScreen._selectedItems`, `StatsScreen._refreshKey`. Pattern: extract
  `ScrollToTopButton`-style widgets that call their own `setState` only when
  visibility actually changes.
- [x] **Image resolution audit** — check network images are requested at
  display resolution, not full size. OFF CDN images are loaded at full
  resolution (~200 KB) and scaled to 40x40 dp on cards or full-width on
  detail screens, wasting memory and decode time. Check if OFF API supports
  resize parameters.
- [x] **Impeller usage check** — verify Impeller is enabled for release
  builds (`--enable-impeller`). Impeller is default on Android API 29+;
  verify it is not disabled in `AndroidManifest.xml`.
- [x] **Tree shaking audit** — run `flutter build apk --analyze-size` and
  inspect the app size breakdown. Verify unused packages, assets, and fonts
  are stripped. Remove any dead dependency imports.
- [x] **Asset optimization audit** — convert remaining PNG assets to WebP
  with lossless encoding. Check if bundled fonts can be subsetted to only
  used glyphs. Verify `pubspec.yaml` font declarations are minimal.
- [x] **Expensive raster ops audit** — check for widgets that trigger
  `saveLayer` on the raster thread: `ShaderMask`, `Opacity` (alpha < 1.0),
  `ClipPath`, `ColorFiltered`, multiple `ClipRRect` instances. Only 1
  `ClipRRect` found (`add_product_screen.dart`) — low priority but verify.
  Reference: [Flutter Performance Best Practices](https://docs.flutter.dev/perf/best-practices#minimize-use-of-opacity-and-clipping).

### UI polish

- [x] **Dark mode nudge for AMOLED** — show a one-time prompt to AMOLED
  users suggesting dark mode (up to 60% less power with black pixels).
  Detect via `MediaQuery.platformBrightness` at launch.
- [x] **SegmentedButton** — replaced `FilterChip` row on home screen with
  M3 `SegmentedButton` inside horizontal `SingleChildScrollView`.
- [ ] **OFF language & localization strategy** — product names, categories,
  and ingredients from Open Food Facts are currently hardcoded to English
  regardless of the user's app locale. Define a strategy to fetch and
  display OFF data in the user's preferred language.

  **Scope**:
  - Make OFF query language dynamic via `offLanguageFromLocale()` utility.
  - Add `languageCode` field to `Product` model.
  - Update `stats_provider.dart` to filter by locale's prefix, with `en:`
    fallback.
  - Handle DB migration: new `language_code` column (v11 → v12), legacy
    rows default to `'en'`.
  - Lazy re-fetch: "Show in [lang]" `ActionChip` on product detail when
    `product.languageCode` != current locale.
  - Manual products (`source: 'manual'`) never overwritten.

  **Pitfalls & edge cases**:
  - `OpenFoodFactsLanguage.PORTUGUESE` has `offTag: 'pt'` — no Brazilian
    Portuguese variant exists. `pt_BR` users get European Portuguese data.
  - OFF silently falls back to English when data unavailable in requested
    language. Store *requested* `languageCode`, not returned.
  - Overwrite vs per-language storage: (A) overwrite is simpler, (B)
    per-language table is more robust. Prefer (A) for now.
  - Ingredients and numeric nutrients handled correctly across languages.
  - Offline guard: show snackbar if user taps "Show in [lang]" while offline.
  - Keep `OpenFoodAPIConfiguration.globalLanguages` as `[ENGLISH]` — only
    change per-query language for safety.
- [x] **Autocomplete** — add autocomplete suggestions to the home screen
  search bar based on cached product names.
- [x] **InteractiveViewer** — enable pinch-to-zoom on product
  nutrition/ingredient photos.
- [x] **ExpansionTile in settings** — group related settings (notifications,
  data retention) under `ExpansionTile`.
- [x] **DropdownMenu** — replaced via alternative approach: modal bottom
  sheet in `InventorySwitcherCard`.
- [x] **Redesign inventory switcher with border card** — replaced plain
  `PopupMenuButton` icon with [InventorySwitcherCard] widget showing pantry
  name, average NutriScore badge, and dropdown arrow. Opens modal bottom
  sheet on tap with inventory list, create, and manage options.
  `PopupMenuButton` icon with a tappable card showing the pantry name,
  average NutriScore badge, and a tap/swipe-down indicator. Style the
  container with a border matching the search bar (`InputBorder` / outline
  style) so it looks consistent.

  **Implementation**:
  1. Create `InventorySwitcherCard` widget in `lib/widgets/`.
  2. Card shows active inventory name (resolved from `inventoryListProvider`),
     an average `NutriScoreBadge` (read from `averageNutriscoreProvider`),
     and a `Icons.swap_horiz` or `Icons.arrow_drop_down` icon.
  3. On tap, show the existing `PopupMenuButton` content or a modal
     bottom sheet with the inventory list.
  4. Replace the inline `PopupMenuButton` in `HomeScreen.build()` with the
     new widget.
  5. Add tests: verify the card displays the correct name, badge, and
     opens the menu on tap.

  **Pitfalls & edge cases**:
  - **Average NutriScore badge may be null**: If no products exist in the
    active inventory, `averageNutriscoreProvider` returns `null`. Hide badge
    in that case and widen the card to just name + icon.
  - **Long inventory names**: Truncate with ellipsis (`TextOverflow.ellipsis`)
    and set a `maxLines: 1` constraint. Use a `Flexible` row layout so the
    NutriScore badge doesn't get clipped.
  - **Tap area too small**: Follow Material Design minimum 48dp touch target.
    Wrap the card in a `GestureDetector` with adequate padding.
  - **Color contrast**: Border colour must be visible in both light and dark
    modes. Use `colorScheme.outline` to match the search bar's default style.
  - **Provider dependency**: `averageNutriscoreProvider` and
    `inventoryListProvider` are async providers. Show a loading skeleton
    while they resolve, or fall back to just the name if still loading.
  - **Active inventory ID 1 default**: On first launch, `activeInventoryProvider`
    returns `1` but inventory 1 may not exist. Handle gracefully — show
    "No pantry" fallback label instead of a broken card.
  - **Inventory name changes**: If user renames the active inventory, the
    card must reflect the new name. Use `ref.watch(inventoryListProvider)`
    to react to DB changes.
  - **No inventories at all**: When the user has deleted all inventories,
    hide the switcher entirely and show a "Create pantry" button instead.
- [x] **Price tracking** — implemented via `prices` table and `PriceRepository`
  with per-product price history, total inventory value, and store autocomplete.
  See `lib/database/price_dao.dart`, `lib/services/price_repository.dart`,
  `lib/services/open_prices_service.dart`, `lib/widgets/price_entry_sheet.dart`.
- [ ] **NFC-e receipt scanning** — parse Brazilian electronic tax receipts
  (NFC-e QR codes) to auto-populate product lists with quantities and
  prices. Requires camera integration, SEFAZ API for QR decoding, and
  product-name matching against the local pantry. Stubbed with
  `ComingSoonView` on Stats screen.
- [ ] **Photo contribution to Open Food Facts** — identify products in the
  user's pantry that lack nutrition/ingredient/product photos on OFF and
  prompt the user to contribute via the OFF product submission API.
  Composite stat already tracked in `PhotoStats.offPhotos`.

### Documentation

- [x] `ARCHITECTURE/INDEX.md` — add security section.
- [x] `ARCHITECTURE/INDEX.md` — add offline-first pattern diagram.
- [x] `AGENTS.md` — add "always check TODO.md before starting new work".
- [x] **Small-screen golden tests (partial)** — `HomeScreen`, `SettingsScreen`,
  and `StatsScreen` have golden tests. `ProductDetailScreen` still pending.
- [ ] **NFC‑e reference doc** — create `lib/docs/nfce_reference.md` with
  complete technical reference (QR code URL formats, state variations,
  v2 vs v3, parsing approach, open‑source tools).

---

## Medium Effort

### Code health

- [x] **Fix SearchScreen accent-insensitive + case-insensitive search** — the
  `SearchScreen` (_SearchScreenState._search) does NOT apply
  `removeDiacritics()` to the query or results before matching. The home
  screen inline search (`_InventoryListState._filtered`) DOES use
  `removeDiacritics`, creating inconsistency. Add normalization to
  `SearchScreen`, then add comprehensive tests for both search paths with
  diacritics, prefixes, suffixes, and empty queries.

  **Implementation**:
  1. In `SearchScreen._search()` (line 73), normalize the query via
     `removeDiacritics(query.trim().toLowerCase())` before passing to both
     `db.searchProducts()` and `api.searchProducts()`.
  2. In `ProductDao.search()` (line 133), ensure the local DB search also
     normalises both query and product name/barcode before comparing.
     Currently it does — verify the test coverage.
  3. Add tests in `test/screens/search_screen_test.dart`:
     - Search "cafe" finds a locally cached "Cafe au lait" (case)
     - Search "cafe" finds "Cafe au lait" (accent-insensitive: é → e)
     - Search with accents finds local items
     - Search with accent finds API items when combined with mock
     - Empty query returns idle state
     - Very short query (1 char) does not trigger API call
  4. Add tests in `test/services/product_repository_test.dart`:
     - `searchProducts` with diacritic query matches correctly
  5. Add tests in `test/database/product_dao_test.dart`:
     - `search` with accent-insensitive query returns correct rows

  **Pitfalls & edge cases**:
  - **Double-normalisation of API query**: The OFF SDK may already normalise
    queries internally. Applying `removeDiacritics` to the query before
    sending to the API could degrade results (e.g. "cafe" won't find French
    "cafe" on OFF if the SDK expects accented input). Apply
    `removeDiacritics` ONLY for local DB search; for API search, send both
    the original and the normalised query as separate requests or try the
    original first and fall back.
  - **Performance on DB search**: `ProductDao.search()` already loads all
    products and filters in Dart. Adding `removeDiacritics` on every keystroke
    adds CPU cost. For 500+ products, consider caching the normalised name
    column or using LIKE with COLLATE NOCASE at SQL level.
  - **Search "tomato" inconsistency in logs**: The emulator logs show that
    "tom" and "tomat" fail with OFF server error, but "toma" and "tomato"
    succeed. This is an OFF server-side issue — not caused by client code.
    Document that 503/offline OFF responses are expected and handled.
  - **Stale request guard interaction**: If the user types "cafe" and the
    debounce fires two searches (original + normalised), the stale request
    guard (`_requestId`) must correctly track both. Fire only ONE search
    per debounce tick.
  - **SQLite COLLATE NOCASE only handles ASCII**: For proper Unicode
    accent-insensitive SQL search, use `COLLATE UNICODE` or load ICU
    extension. Current Dart-level filtering works but doesn't scale. Decide
    whether to add a separate `normalized_name` column.

- [x] **Fix Riverpod `setState() called during build` exception** — all
  unwrapped `ref.invalidate()` calls wrapped in `addPostFrameCallback`.
  Sites fixed: stats_screen.dart (2), manage_inventories_screen.dart (4),
  home_screen.dart (1). Removed empty `setState(() {})` from
  `product_detail_screen.dart._retrySubmission()`.

- [x] **SearchBar/SearchAnchor upgrade** — replace manual `TextField` in
  SearchScreen and HomeScreen with M3 `SearchBar`/`SearchAnchor` for native
  autocomplete and animation.
- [ ] **Fix issues discovered during emulator run** — address the following
  warnings and errors from an Android emulator debug session:

  1. **Kotlin Gradle Plugin (KGP) warning**: Plugins `dynamic_color`,
     `mobile_scanner` apply KGP directly. Future Flutter versions will
     fail if plugins use KGP instead of Built-in Kotlin. Check each
     plugin's changelog for a version that supports Built-in Kotlin.
     If no such version exists, report the issue to the plugin authors.
  - [x] 2. **Timezone resolution for raw UTC offsets**: Resolved via
     `flutter_timezone.getLocalTimezone()` on mobile platforms. Linux
     desktop may still return raw offsets — falls back to UTC.
  3. **Dynamic color not detected**: This is a third‑party package debug
     message (`dynamic_color` v1.8.1, `debugPrint` inside `initPlatformState`).
     Cannot suppress without forking the package. No action needed.
  4. **Impeller EGL warnings**: `[ERROR:flutter/impeller/toolkit/egl/
     egl.cc(56)] EGL Error: Success (12288) in display.cc:161`. These are
     harmless Impeller init noise. Research whether they indicate a
     misconfiguration or can be safely ignored. Document in
      `ARCHITECTURE/PERFORMANCE.md` section 11.7.
  5. **OFF API "Page temporarily unavailable" errors**: Added retry loop
     in `OffAdapter.searchProducts()` (3 attempts, 1s/2s backoff). Added
     1s grace timer in `SearchScreen._search()` before showing "No results"
     when API fails and local results are empty.
  6. **Contribute Photos button**: Wired to ComingSoonScreen navigation.
  - [x] 7. **Notification settings toggle doesn't re-request permission**:
     The toggle now calls `requestPermission()` when toggled on and shows
     an "Open Settings" dialog if permission was previously denied.
  8. **No expiry date skip logs**: Fixed log message to show barcode
     instead of null id (`item.id` → `item.barcode`).
  9. **Skipped 35 frames on startup**: `[INFO] Skipped 35 frames! The
     application may be doing too much work on its main thread.` This is
     expected on debug builds during first launch (DB init + product
     refresh). Verify on a release build; if persists, investigate
     `_runDatabaseCleanup` and `main.dart` init ordering.
  10. **`Composing region changed by the framework` after search**: Text
      input log spam after searching with Japanese/Chinese IME. This is a
      Flutter framework issue on Android — no action needed.
- [ ] **Thread strategy audit** — identify heavy work that blocks the UI
  thread: OFF API JSON parsing, image
  encoding. Offload to `Isolate` / `compute()` where beneficial. sqflite
  already runs on a background isolate internally.
- [ ] **NavigationRail** — adaptive sidebar layout for tablets/desktop
  alongside `NavigationBar`.
- [ ] **Repaint boundary enforcement** — add a lint rule or architecture doc
  requiring `RepaintBoundary` on widget subtrees that scroll independently,
  animate repeatedly, or sit inside `ListView`/`GridView` with many items.
  Never wrap entire screens.

### Feature development

- [x] **Changelog at startup** — detect app update via existing
  `_handleAppUpdate()` scaffolding (`package_info_plus` +
  `SharedPreferences` `app_version` key). On first launch after update, show
  a `WhatsNewDialog` or bottom sheet with new entries from `CHANGELOG.md`.

  **Implementation**:
  1. Create `lib/widgets/whats_new_dialog.dart` — reads CHANGELOG.md, parses
     entries by version, filters to unseen versions.
  2. Modify `main.dart` to set `changelog_last_seen` SharedPreferences key
     separate from `app_version`.
  3. In `PantryShell` init, check flag and show dialog once.
  4. New ARB strings: `whatsNew`, `dismiss`.
  5. Tests: verify dialog appears on version change, doesn't on same
     version, doesn't on first install.

  **Pitfalls & edge cases**:
  - **Missing file**: `rootBundle.loadString('CHANGELOG.md')` throws
    `FlutterError`. Bundle a fallback JSON file instead of parsing
    markdown, or check `File.exists()` first.
  - **`flutter_markdown` discontinued**: Official package last updated at
    0.7.x; community forks exist (`flutter_markdown_plus`). Consider a
    simple line‑based parser for version extraction instead of a full
    markdown renderer.
  - **Markdown parser crashes**: Known assertion failures with malformed
    inline elements. Always wrap in `FlutterError` boundary.
  - **Memory on large CHANGELOG**: Full markdown builds a complete AST in
    memory. Keep displayed content short (last 2–3 versions max).
  - **First install**: Don't show changelog on first install (no
    `app_version` in prefs). Only show on detected version change.
  - **Accumulated versions**: User may skip multiple releases. Show all
    entries from `last_seen` to `current`, not just the latest.
  - **Inline HTML**: `flutter_markdown` does not support inline HTML
    (`<br/>`, `<div>`). Strip or escape before rendering.
   - **No `CHANGELOG.md` in release bundle**: Ensure `pubspec.yaml` includes
     `assets: [CHANGELOG.md]` or switch to a bundled JSON release‑notes file.

- [x] **Fix expiry notifications not triggering** — notifications are not
  firing for scheduled expiry reminders. Debug and fix the entire scheduling
  pipeline. Re-use the existing `NotificationService` but fix the root cause
  of missed or silent notifications.

  **Investigation steps**:
  1. Verify `FlutterLocalNotificationsPlugin.zonedSchedule()` is being called
     with correct `TZDateTime` values (check `tz.local` vs `tz.UTC` mismatch).
  2. Verify `AndroidScheduleMode.inexactAllowWhileIdle` works on Android 12+.
     Test with `exactAllowWhileIdle` as fallback.
  3. Verify notification channel ID `'expiry_channel'` is created before
     scheduling (it must exist in `initialize()` — confirm line 57-62).
  4. Check `requestPermission()` result on Android 13+ — if user denied,
     notifications are silently dropped. Show permission rationale dialog.
  5. Add integration test: schedule a notification 1 minute in the future,
     advance the device clock, verify notification appears.
  6. Check that `cancelReminders()` is not called accidentally before the
     notification fires (check `_openAddEditScreen` flow — it cancels old
     reminders for the same item on edit, not on add).
  7. Verify the `payload` field is set in `NotificationDetails` — without
     payload, the notification tap action is null.
  8. Log every `zonedSchedule` call with its ID, time, and channel so
     debugging is possible from device logs.

  **Pitfalls & edge cases**:
  - **Android 15+ notification cooldown**: May delay or suppress
    notifications from the same app within a short window. Use
    importance `High` and category `Alarm`.
  - **`inexactAllowWhileIdle` vs `exactAllowWhileIdle`**: On Android 12+,
    exact alarms require `SCHEDULE_EXACT_ALARM` permission. If not granted,
    `zonedSchedule` fails silently. Check permission before scheduling and
    fall back to inexact.
  - **Timezone mismatch**: The `timezone` package may return `tz.UTC` when
    the device timezone is a raw UTC offset (e.g. `-03`). The log already
    shows `[WARN] Raw UTC offset "-03" detected`. This causes notifications
    scheduled at 9 AM UTC to fire at 6 AM local. Fix the timezone resolution
    in `NotificationService._resolveFromOffset`.
  - **Notification not showing in debug mode**: Android may suppress
    notifications from debug builds. Test on a release build or via
    `adb shell dumpsys notification`.
  - **Multiple notifications for same item**: If `scheduleExpiryReminders`
    is called multiple times for the same item (e.g. add, then edit
    location), old notifications with the same ID are replaced. This is
    correct — no duplicate.
  - **Crash when `expiryDate` is malformed**: `DateTime.tryParse` silently
    returns `null` for invalid dates. The method already checks for
    `null` expiry. Add a logWarning when parsing fails.
  - **Device reboot**: `inexactAllowWhileIdle` and `exactAllowWhileIdle`
    alarms survive reboot. But on Android 12+, `ALARM_SERVICE` may not
    persist across reboot for scheduled notifications. Test by rebooting
    device and verifying notification fires.
  - **App killed by user**: Android may cancel all pending alarms when the
    app is force-stopped. On next launch, `main.dart` should reschedule
    all pending notifications. Currently no reschedule-on-boot exists.
  - **`flutter_local_notifications` version compatibility**: The current
    version is `^22.0.1`. Check changelog for any known `zonedSchedule`
    bugs in this version. Reference:
    https://pub.dev/packages/flutter_local_notifications/changelog — the
    official package changelog.
  - **Notification IDs must be unique per item**: Currently uses
    `item.id?.hashCode ?? item.barcode.hashCode`. If two items have the
    same barcode (different locations), their notifications may collide.
    Use `item.id!` directly (already non-null for saved items) and
    `(item.id! * 2)` / `(item.id! * 2 + 1)` for the two reminders.

- [x] **Re-engagement notifications (inactivity reminder)** — tracks last add date, sends daily reminder at 9 AM if inactive beyond threshold (configurable).

  **Implementation**:
  1. Create `ReengagementService` that tracks last-open timestamp in
     `SharedPreferences`.
  2. On app launch, check if last open was > N days ago. If so, schedule
     a one-time notification for the next morning.
  3. Use `flutter_local_notifications.zonedSchedule()` with a new channel
     `'reengagement_channel'` (separate from expiry channel for user
     control — allow muting re-engagement independently).
  4. Add toggle in Settings: "Remind me to check my pantry" with interval
     picker (3, 7, 14, 30 days).
  5. Cancel pending re-engagement notification when user opens the app.
  6. New ARB strings: `reengagementTitle`, `reengagementBody`,
     `reengagementEnabled`, `reengagementInterval`.

  **Pitfalls & edge cases**:
  - **User opens app at 11:59 PM and notification fires at 12:01 AM**:
    If the user opens the app late at night, the "tomorrow morning"
    notification could fire within minutes. Cancel any pending
    re-engagement notification on app open, then schedule the next one
    only after N days of inactivity.
  - **Time-of-day scheduling**: Schedule for 9:00 AM local time using
    `TZDateTime` with `tz.local`. Use `tz.TZDateTime(tz.local, year, month,
    day, 9, 0)`.
  - **User disables all notifications**: Check `settings.notificationsEnabled`
    before scheduling. If disabled, skip entirely.
  - **First launch**: Do not send re-engagement notification on first
    launch. Seed `lastOpened` timestamp on first open.
  - **App uninstall/reinstall**: `SharedPreferences` is cleared on
    uninstall. Treat as first launch — no notification.
  - **Multiple re-engagement notifications**: Only schedule one at a time.
    Cancel existing before scheduling new.
  - **Battery/Doze mode**: Use `AndroidScheduleMode.inexactAllowWhileIdle`
    to ensure delivery in Doze. The 9:00 AM window is approximate —
    acceptable for a reminder.
  - **Weekend vs weekday**: Some users may prefer weekday-only reminders.
    Defer to a future enhancement.
  - **User changes interval in Settings**: Cancel existing re-engagement
    notification and reschedule with new interval.

- [x] **Recipe registration** — create named recipes with ingredient lists
  (linked to products in inventory), instructions, and cost calculation
  using the user's base currency setting. Database migration v25/v26.
  (`lib/models/recipe.dart`, `lib/screens/recipe_form_screen.dart`,
  `lib/screens/recipe_list_screen.dart`)
- [x] **Recipe detail screen** — read-only view with ingredient list,
  instructions, cost (maskable via eye icon), and "I made this" button.
  (`lib/screens/recipe_detail_screen.dart`)
- [x] **"I made this" (cook) flow** — marks recipe as cooked, deducts
  ingredients from inventory (FEFO), logs immutable history entry.
  Shortage warnings and undo support.
  (`lib/providers/recipe_provider.dart`)
- [x] **Recipe history** — immutable cook-event logging via `recipe_history`
  table and DAO. (`lib/database/recipe_history_dao.dart`)
- [x] **Search-powered ingredient picker** — bottom sheet that searches
  local DB and OFF API by name/barcode. Adds result as ingredient.
  (`lib/widgets/search_ingredient_sheet.dart`)
- [x] **Duplicate ingredient merging** — same barcode added twice increments
  quantity instead of duplicate row.
- [ ] **Recipe recommendation notifications from pantry** — generate
  personalised recipe suggestions based on the user's current inventory:
  "Hey, how about making a chicken sandwich today? You have all the
  ingredients!" Fetch recipes from a public recipe API (e.g. Spoonacular,
  Edamam, or TheMealDB) matching available ingredients. Send as a
  notification (not a push — scheduled locally).

  **Implementation (Phase 1 — notification-only, no recipe UI)**:
  1. Create `RecipeService` that queries a recipe API with available
     ingredients from the user's inventory.
  2. Batch query: send top 3-5 ingredient names as comma-separated list.
  3. Parse response, pick one recipe at random, format notification with
     recipe name and a short preview.
  4. Schedule weekly on Sunday evening (or configurable day/time).
  5. New ARB strings: `recipeSuggestionTitle`, `recipeSuggestionBody` (with
     \`{recipeName}\` and \`{itemCount}\` placeholders),
     `recipeSuggestionEnabled`, `recipeDay`, `recipeTime`.
  6. Toggle in Settings: "Weekly recipe suggestions" with day-of-week
     picker and time picker.
  7. Tap notification → open a recipe detail screen (coming soon).

  **Pitfalls & edge cases**:
  - **Empty pantry**: If the user has 0 items, skip recipe suggestion
    entirely. Log reason.
  - **Few items (1-2)**: Recipe API may not find matches with so few
    ingredients. Fall back to "quick meals" endpoint or suggest based on
    recently added items instead.
  - **Dietary restrictions**: Not implemented in Phase 1 — notifications
    may suggest recipes with ingredients the user doesn't eat. Add a
    disclaimer: "This suggestion is based on your inventory. Always check
    ingredients for dietary suitability."
  - **Recipe API cost**: Spoonacular offers 150 free queries/day. Edamam
    offers 5000/month free tier. TheMealDB is free (no API key). Choose
    TheMealDB for Phase 1 to avoid cost; provide `RecipeApiService`
    abstraction so the backend can be swapped later.
  - **Rate limiting**: TheMealDB has no documented rate limit but limit
    to 1 query per suggestion to be respectful. Cache results.
  - **Offline**: Skip suggestion when offline. Log warning.
  - **Notification not actionable (Phase 1)**: Tapping the notification
    does nothing in Phase 1 (no recipe detail screen yet). Mark as
    `noAction` in notification payload, or navigate to a ComingSoonView.
  - **Language**: Recipe names from the API are in English. If the app
    locale is pt-BR, the notification will mix languages. Defer
    translation to a future phase.
  - **Duplicate suggestions**: Avoid suggesting the same recipe twice in a
    row. Keep a `lastSuggestedRecipe` key in SharedPreferences.
  - **Perishable ingredients first**: Prioritise recipes that use items
    expiring soon. Query the recipe API with the user's soon-to-expire
    items first, then fall back to all items.
  - **User removes all relevant ingredients before notification fires**:
    The notification was scheduled with a snapshot of the inventory.
    Accept this limitation — the recipe may still be useful.

- [ ] **Fix manual product registration & OFF submission flow** — users
  report being unable to submit products to Open Food Facts, and having
  issues with product photos (cannot retake, cannot replace, cannot delete
  a bad photo). Revamp the photo management in `AddProductScreen` and the
  submission UX.

  **Implementation**:
  1. [x] **Gallery support** — `AddProductScreen` now shows a bottom sheet
     source chooser with "Take a new photo" and "Choose an existing photo".
     Done in issue #263.
  2. [x] **Photo preview + replace** — photos open in a full-screen preview
     with Close, Retake, and Replace actions. Done in issue #263.
  3. [x] **Photo deletion** — each image tile has a delete button that
     removes the photo and offers undo. Done in issue #263.
   4. [x] **Submission progress UI** — after tapping "Save", the form shows a
      linear progress indicator and step status ("Submitting metadata...",
      "Uploading photo 2 of 3...") via a `SubmitNotifier` that outlives the
      screen, then auto-pops with a success snackbar. Done in issue #268.
   5. [x] **Submission retry from failure state** — the product detail
      screen shows a persistent status chip (submitted, pending, partially
      completed, failed, not submitted) with a live progress panel while a
      submission is in flight and a "Retry now" button that drives the
      shared submission notifier, re-reading the product from the database
      first. Photos can be changed on the detail screen before retrying.
      Done in issue #269.
   6. [x] **Photo management from detail screen** — `ProductDetailScreen`
      now shows the 3 local photos of a manually-entered product with
      preview, replace, retake, and delete (with undo); changes are
      persisted and orphaned files are removed when the screen is disposed.
      Done in issue #269.
   7. [x] **Camera permission denied handling** — denied camera permission
      shows a dialog with an "Open Settings" button. Done in issue #263.
      Issue #266 refined the flow: the Open Settings dialog now appears only
      when the camera permission is permanently denied; a one-time denial
      shows a recoverable warning. Gallery denials surface a localized dialog
      with Cancel and Open Settings, and a gallery permission is requested
      only when the platform requires one.
   8. [x] Study the official Open Food Facts app (smooth-app) for UX patterns:
      - Photo capture flow with retake
      - Progress indicators during submission
      - Error states and retry
      - Image quality guidelines before upload
      Reference: https://github.com/openfoodfacts/smooth-app
   9. [x] **Testable photo persistence & cleanup** — photo persistence now
      lives in `ProductImageService` (`lib/services/product_image_service.dart`)
      with the immutable `ProductPhotoSlots` snapshot, so the copy/cleanup
      logic is unit-tested without camera hardware. Picked files are copied
      to deterministic managed paths under `product_images`, deletion is
      deferred so undo can restore a live file, and uncommitted files are
      removed from `AddProductScreen.dispose()`. Done in issue #262.

  **Pitfalls & edge cases**:
  - **Image file size**: Camera photos can be 3-10 MB. Submission recompresses
    each photo to under 1 MB (`ProductImageCompressor`,
    `lib/services/product_image_compressor.dart`) using the existing `image`
    package in a background isolate, so no new dependency is needed. Done in
    issue #270.
  - **Storage permissions**: Saving images to app-local directory
    (`getApplicationDocumentsDirectory()`) does NOT require storage
    permission. Loading from gallery does NOT require one either: the image
    picker uses the system Photo Picker (Android 13+), ACTION_GET_CONTENT
    (older Android), and PHPicker (iOS), all of which grant access without a
    permission. `ProductPhotoPicker` only requests a gallery permission when
    the platform requires one (off by default) and surfaces a localized
    dialog when the picker reports denial. Do not add `READ_MEDIA_IMAGES`
    unless the picker is swapped for one that needs it. Handled in issue
    #266.
  - **Photo deletion deletes local file**: Deleting a photo from the form
    clears the slot; the managed file under
    `product_images/<barcode>_<suffix>.jpg` is deleted only when it is not
    committed to a saved product. `ProductImageService.cleanupUncommitted`
    runs from `AddProductScreen.dispose()`, preserving `committedPaths`.
    Done in issue #262.
  - **Submission in progress when user navigates away**: Current
    `unawaited(_cacheAndSubmit(...))` makes the submission fire-and-forget.
    If the user pops the screen, submission still runs but errors are
    logged only. Replace with a `SubmitNotifier` that outlives the screen
    and shows status via snackbar or a persistent notification.
    Done in issue #268: `ProductSubmissionNotifier` keeps the submission
    running after the screen is disposed and exposes typed progress.
  - **OFF API submission quota**: The OFF API may rate-limit submissions.
    Check `OffAdapter.submitProduct()` response for 429 status. Wait and
    retry with exponential backoff.
    Done in issue #268: the adapter retries 429 responses with backoff and
    the service reports a `rateLimited` category with retry available.
  - **Image upload ordering**: Currently sequential (front, ingredients,
    nutrition). If the 2nd or 3rd upload fails, the product is marked
    `failed` even though metadata and some images succeeded. Consider
    partial success: mark as `submitted` if metadata + at least 1 image
    succeeds; report partial failure in the UI.
    Done in issue #268: partial successes persist the
    `productSubmissionPartiallyCompleted` status and the UI offers retry.
  - **Network timeout during upload**: Image uploads can take 10-30s on
    slow connections. Set a per-image timeout of 60s. Show per-image
    progress if the SDK supports it.
  - **Product already exists on OFF**: The `submitProduct()` call may fail
    if the barcode already exists in the OFF database. Add a check before
    submission: query OFF for the barcode first. If it exists, show "This
    product is already in Open Food Facts" instead of submitting.
  - **Submission of product without photos**: Allow submitting metadata
    only. The OFF API accepts products with no image fields.
    Done in issue #268: metadata-only products submit and complete without
    upload calls (covered by tests).
   - **Photo EXIF data stripping**: Strip EXIF location data from uploaded
     photos for privacy. Use `flutter_image_compress` or a manual EXIF
     removal step before upload.

- [ ] **Text extraction from product photos (OCR)** — let users take a
  photo of a product's nutrition facts table, ingredients list, or barcode,
  and automatically extract text using on-device OCR. Pre-fill the
  registration form fields from extracted text, making manual entry much
  faster.

  **Implementation (Phase 1 — barcode + nutrition OCR)**:
  1. Add `google_mlkit_text_recognition` or `mlkit` Flutter plugin for
     on-device text recognition (no network required).
  2. On `AddProductScreen`, add "Scan nutrition facts" button next to the
     nutrition photo field. Use OCR to extract: energy, protein, carbs,
     fat, fiber, salt values from the recognised text.
  3. Parse numerical values using regex patterns like
     `(\d+[,.]?\d*)\s*(kcal|kJ|g|mg)` and a mapping of known nutrient
     names in multiple languages (e.g. `"Energia"`, `"Energi"`,
     `"Energy"`, `"Proteínas"`, `"Protein"`, etc.).
  4. Pre-fill the corresponding form fields. Show a confirmation dialog
     before filling: "Extracted values: Energy 250kcal, Protein 8g. Apply?"
  5. Also extract the barcode from a photo of the barcode using
     `MobileScanner` or the existing `image_picker` + ML Kit barcode
     scanning.
  6. New ARB strings: `scanNutrition`, `extractFromPhoto`,
     `extractedValues`, `applyExtracted`, `ocrFailed`, `ocrRetry`.

  **Pitfalls & edge cases**:
  - **OCR accuracy varies**: Nutrition facts table layout differs by
    country and brand. The OCR may misread "0" as "O", "1" as "l", or
    miss decimal separators ("," vs "."). Show extracted values for user
    confirmation — never silently fill.
  - **Multi-language nutrient names**: A product sold in Brazil has
    Portuguese labels, in France French labels. Build a language-agnostic
    parser using known nutrient synonyms across 10+ languages (EN, PT,
    FR, ES, DE, IT, NL, PL, SV, DA). Start with EN + PT (app's target
    languages).
  - **`google_mlkit_text_recognition` Android/iOS only**: No web or Linux
    desktop support. Gate OCR feature behind platform check and show a
    ComingSoonView on unsupported platforms.
  - **APK size increase**: ML Kit adds ~5-8 MB to the APK (OCR model).
    Consider downloading the model at runtime via
    `ModelManager.download()` for on-demand use.
  - **Permission**: Camera permission is already requested for photo
    capture. OCR from gallery does not need extra permission.
  - **Barcode scanning via image**: ML Kit can detect barcodes in images
    without using `MobileScanner` (which requires the live camera).
    Add a "Scan barcode from photo" button in the add product form.
  - **Dark / blurry photos**: OCR accuracy drops significantly on poorly
    lit or blurry images. Show a warning: "Photo is too dark/blurry for
    accurate text recognition. Retake?" using image brightness detection.
  - **Nutrition table in non-standard format**: Some products use
    horizontal layout (row per nutrient) vs vertical (column). The parser
    should handle both orientations. Start with horizontal (most common)
    and detect orientation from recognised text bounding boxes.
  - **Ingredient list OCR**: Extracting ingredients is harder than
    nutrition (free-form text, may be in multiple languages). Defer to
    Phase 2.
  - **Offline-first**: ML Kit runs entirely on-device. No network needed
    for text recognition. Perfect for offline-first architecture.
  - **CPU/GPU usage**: OCR runs on the CPU and may take 1-3 seconds.
    Show a loading indicator. Use `compute()` isolate to avoid blocking
    the UI thread.
  - **Testing**: Mock `InputImage` from file path in unit tests. Use
    fixture nutrition table images for golden-level integration tests.

- [x] **In-app issue/error reporting integrated with GitHub Issues** — `FeedbackScreen`, `GithubIssueService`, offline queue in `feedback_queue` table.

  **Implementation (Phase 1 — feedback form)**:
  1. Create `FeedbackScreen` with fields: issue type (bug / feature
     request / general feedback), title, description, optional screenshot
     attachment, optional device info (app version, OS version, device
     model).
  2. Create `GithubIssueService` that posts to the GitHub Issues API:
     `POST /repos/{owner}/{repo}/issues`.
  3. Store a GitHub personal access token (classic with `public_repo` scope)
     in a secure config or env var. The token must have minimal scope —
     not the user's personal token, a dedicated bot account token.
  4. Show confirmation: "Thanks! Your report has been submitted." with
     the issue URL (so the user can track progress).
  5. Add a "Report an issue" button in Settings (About section).
  6. New ARB strings: `reportIssue`, `issueType`, `bugReport`,
     `featureRequest`, `generalFeedback`, `issueTitle`, `issueDescription`,
     `attachScreenshot`, `includeDeviceInfo`, `issueSubmitted`,
     `issueSubmissionFailed`, `issueUrl`.

  **Pitfalls & edge cases**:
  - **GitHub API token security**: The token must NOT be embedded in the
    client app binary — anyone can decompile the APK and extract it. Use
    a backend proxy or GitHub App installation token flow. For Phase 1,
    accept this limitation (token with `public_repo` scope only, for a
    bot account with no other privileges). Phase 2: add a lightweight
    Cloudflare Worker / Firebase Function that proxies the request with
    the token stored server-side.
  - **Token expiry**: GitHub PATs can expire. If the token expires, all
    submissions fail silently. Log the failure and show a generic "Could
    not submit. Please try again later." message.
  - **Rate limiting**: GitHub API allows 5000 requests/hour for
    authenticated requests. For a single-user app, this is ample. But if
    every app install submits, a bug could trigger thousands of issues.
    Add client-side rate limiting: max 1 issue per 60 seconds, max 5 per
    day per device.
  - **Spam / duplicate issues**: Add a simple title+description hash to
    SharedPreferences to prevent identical submissions within 24 hours.
    GitHub doesn't have a built-in dedup.
  - **No internet**: Queue the issue locally and submit when connectivity
    returns. Show "Your report will be submitted when you're back online."
  - **Screenshot attachment**: GitHub Issues API accepts base64-encoded
    images via `POST /repos/{owner}/{repo}/issues/{issue_number}/comments`
    with `application/octet-stream`. Or upload to a CDN and include the
    URL in the issue body. Phase 1: include screenshot as base64 in the
    issue body (max 10 MB per issue).
  - **Privacy**: Device info (Android version, model) is not PII but may
    reveal device fingerprint. Add a checkbox "Include device info" that
    is ON by default but can be unchecked.
  - **Repository owner/repo config**: Store `GITHUB_OWNER` and
    `GITHUB_REPO` in `.env` alongside other configs. Example values:
    `GITHUB_OWNER=ThiagoAssis`, `GITHUB_REPO=pantry_app`.
  - **Loading state**: Issue creation via API takes 1-3 seconds. Show a
    full-screen loading overlay with "Submitting your report..."
  - **Wrong repo**: If `GITHUB_REPO` is misconfigured, the API returns
    404. Show "Could not submit — repository not found. Please report
    manually at https://github.com/{owner}/{repo}/issues."
  - **OAuth vs PAT**: GitHub Apps with OAuth offer better security but
    require a web server for the OAuth flow. Defer to Phase 2.
  - **Legal**: Include a note: "By submitting, you agree that this
    information will be publicly visible on GitHub."

- [ ] **Product name translations** — pass `lc=<app_locale>` to OFF API v3.
  `product_name` and `ingredients_text` return in the user's locale. Brands
  are **never translated** (proper nouns/trademarks). Add
  `brand_name_overrides` alias map for edge cases.

  **Implementation**:
  1. Add `lc` and `tags_lc` query parameters to
     `OffAdapter.getByBarcode()` and `searchProducts()`.
  2. Extract locale from `Localizations.localeOf(context).languageCode` (or
     `PlatformDispatcher.instance.locale.languageCode` for non‑widget code).
  3. Add `lang` field to `Product` model (persisted in DB).
  4. Add `brand_name_overrides` JSON map to `Product` model + seed data in
     `ProductDao`.
  5. Add display helper `resolveBrandName()` in `Product` extension.
   6. DB migration: add `products.lang` column (bundled with other schema changes; added at v15).
  7. Tests: mock API responses with `lc=fr`, verify French name returned;
     verify brand names preserved.

  **Pitfalls & edge cases**:
  - **Silent fallback**: If no translation exists for the requested `lc`,
    OFF silently returns the product's default language. Always display the
    returned value — it may be in a different language.
  - **`Platform.localeName` is unreliable**: Returns `null` on iOS first
    launch; never updates on Android at runtime. Use
    `Localizations.localeOf(context).languageCode` instead.
  - **Locale string mismatch**: Dart `Locale.languageCode` returns ISO
    639-1 (`"en"`). This is correct for OFF. But `locale.toString()` gives
    `"en_US"` which OFF doesn't understand. Always use `.languageCode`.
  - **`und` locale**: `PlatformDispatcher.locale` returns
    `Locale.fromSubtags(languageCode: "und")` when the device locale list is
    empty. Validate: `if (code.isEmpty || code == 'und') code = 'en'`.
  - **`lc` without `tags_lc`**: Product name may come in the right language
    but category/label taxonomy names remain in default language. Always
    pass both: `{'lc': lang, 'tags_lc': lang}`.
  - **Empty product name**: Fall back to product's `_id` (barcode).
  - **Search API legacy endpoint**: `cgi/search.pl` may not support `lc`
    identically to v3. Test before deploying. Accept mixed-language search
    results if needed.
  - **Brand alias map maintenance**: Add mechanism to update without app
    updates (remote config, or seed file in assets). Start with known cases
    (Hungry Jack's → Burger King in Australia, Quick → Burger King in
    Belgium).
  - **CORS on Flutter Web**: Open bug #1089 — OFF API lacks CORS headers.
    Blocked on web irrespective of `lc`. Not actionable here.
  - **iOS unsupported locale**: `PlatformDispatcher.locale` on iOS returns
    the OS language even when not in `supportedLocales`. Handle silently.

- [ ] **Ingredients translations + allergen localization** — same `lc`
  parameter renders `ingredients_text` in the user's locale. Show allergen
  highlighting via `ingredients_text_with_allergens_XX` when available. Add
  "show original" toggle.

  **Implementation**:
  1. Extend `OffAdapter` conversion to extract
     `ingredients_text_with_allergens_XX` and `ingredients_text_languages`
     (requires `fields=ingredients_text_languages` in API call).
  2. Add `ingredientsTextLanguages` field to `Product` model
     (`Map<String, String>?`).
  3. DB migration: add `products.ingredients_text_languages` JSON column
     (version 15, bundled).
  4. On `ProductDetailScreen`, display ingredients in app's locale. Add
     toggle button "show original".
  5. When `ingredients_text_with_allergens_XX` is available, render
     allergens in bold/coloured.
  6. New ARB strings: `showOriginal`, `showTranslated`,
     `ingredientsInLanguage`.
  7. Tests: model, DAO, widget tests for language toggle and allergen
     highlighting.

  **Pitfalls & edge cases**:
  - **Allergen mistranslation is a safety hazard**: Display disclaimer —
    "Ingredients list is user‑contributed. Always check the product
    packaging for allergens."
  - **`ingredients_text_with_allergens_XX` is not always available**: Many
    products only have `ingredients_text`. When unavailable, fall back with
    no highlighting. Do not attempt to parse allergens yourself.
  - **Ingredients formatting varies by language**: The "show original"
    toggle must switch the entire text block, not per‑segment comparison.
  - **`ingredients_text_languages` field may be large**: 10+ language
    translations on some products. Store as JSON map in SQLite for now
    (<5 KB typical); consider separate `product_translations` table if
    >100 KB becomes common.
  - **"Show original" needs the product's `lang`**: If `lang` is `null` or
    empty, fall back to first non‑empty language in
    `ingredients_text_languages`, then English, then raw text.
  - **Only request translations on detail screen**: `fields` adds payload
    size. Do not request during search/list views.
  - **Allergen formatting varies**: Use lightweight parser for basic
    bold/color markup; avoid heavyweight `flutter_html` if possible.

- [x] **Shopping list** — tab or separate screen; mark items as "to buy"
  with a toggle. Items appear in a dedicated list until purchased (then
  move to inventory).
- [x] **Barcode history** — show the last N scanned barcodes with quick-add
  button. Persist to SQLite.
- [ ] **Empty-pantry onboarding** — when inventory is empty, show a guided
  "scan your first item" flow instead of just the empty state widget.
- [x] **Offline-first product submission queue** — queue `submitProduct`
  calls when offline; flush when `connectivityProvider` emits `true`.
- [ ] **WHO-based food quality recommendations** — research complete:
  ADI-based additive safety warnings, non‑sugar sweetener health guidance,
  free‑sugar threshold alerts (5 g per 100 g), sodium level awareness labels
  (low/medium/high per WHO thresholds), balanced diet prompts, and Five
  Keys to Safer Food tips.
- [ ] **Cosmetics & toiletries support** — extend OFF API integration to
  query Open Beauty Facts (`openbeautyfacts.org`), add `productType` to the
  `Product` model (`'food'` / `'beauty'` / `'petfood'`), add
  cosmetic‑specific fields (periodAfterOpening, beauty category), hide
  nutrition/Nutri‑Score for non‑food items, and add filter chips on the
  home screen.
- [ ] **Custom eco-mode** — implement `EcoModeNotifier` (similar to
  `ThemeModeNotifier`) with a toggle in Settings. When enabled: reduce
  animation complexity, throttle network refresh interval, disable
  non-essential haptic feedback. Detect battery level via `battery_plus`
  and suggest eco-mode when low. New ARB strings: `ecoMode`,
  `ecoModeDescription`, `ecoModeBatteryTip`.
- [ ] **Flashlight local development setup** — install and configure
  [Flashlight](https://github.com/bamlab/flashlight) CLI for local
  performance testing. Run baseline tests and store results in
  `test/performance/`. Document compare workflow
  (`flashlight report bad.json good.json`). Reference: Flutter Heroes
  2025 talk (Alexandre Moureaux, BAM).
- [ ] **Deferred components (Android dynamic features)** — split the app
  into on-demand APK modules: (1) scanner, (2) OFF API + search, (3)
  import/export. Users only download modules they use. Requires
  `dynamicFeature` in `build.gradle` and `split` attributes in
   `AndroidManifest.xml`. Reference: [Flutter Deferred Components](https://docs.flutter.dev/perf/deferred-components).

### Database migrations

- [x] **DB migrations through v30** -- schema is at version 30 with all
  planned migrations including firebase_cache_meta (v24), recipe tables (v25,
  v26), and subsequent schema evolution. Further version bumps for new
  features still needed.

---

## High Effort — Free

- [ ] **Multi‑language support** — ARB infrastructure exists; add
  translations (pt, fr, es, de). Contribute via community PRs.
- [ ] **Widget test → golden coverage** — product detail, settings, stats
  screens.
- [x] **Remake notification feature from scratch** — rewritten:
  `itemId * 2`/`*2+1` ID scheme, 9:00 AM scheduling, timezone fix via
  `flutter_timezone`, `rescheduleAllItems()` on boot, proper channel
  creation, permission re-request. See CHANGELOG for details.
- [ ] **Rebuild import/export** — export cached (API-fetched) products,
  export a specific inventory, and import via platform file picker with
  format detection and error recovery.
- [ ] **Recipe suggestions** — call a recipe API with items expiring this
  week; suggest meals that use them. Coordinate with "Recipe notification
  recommendations from pantry" (Medium Effort). If both are implemented,
  the notification feature triggers on a schedule, while the full Recipe
  suggestions tab provides a richer UI with filtering, saving, and meal
  planning. Coordinate with Samsung Food meal planning integration below
  — if all three are implemented, Samsung Food can serve as the meal
  planning UI layer and recipe source, while the generic recipe API
  provides wider coverage in regions where Samsung Food is unavailable.
- [ ] **Patrol E2E tests** — real‑device integration tests via
  [Patrol](https://patrol.leancode.co). Uses `patrol_cli` and `patrol`
  dev-dependency. Replace the generic `integration_test/` with
  `patrol_test/` directory.

  **Test scenarios**:
  1. **Setup** — install `patrol_cli`, add `patrol` to `dev_dependencies`,
     configure `pubspec.yaml`, create `patrol_test/`.
  2. **Scan → add to inventory** — tap FAB, simulate barcode scan, verify
     product detail appears, add item, verify home screen shows it.
  3. **Offline scan → manual entry** — simulate offline, scan barcode,
     verify manual entry screen opens, fill form, save, verify cached.
  4. **Quantity adjustment flow** — open product detail, tap + 3x, verify
     quantity, tap - to 0, confirm delete, verify item gone.
  5. **Notification flow** — add item with expiry tomorrow, background
     the app, advance time, verify notification appears.
  6. **Inventory switch** — tap dropdown, select different pantry, verify
     items change.

- [ ] **Low-end device testing program** — test the app on a physical
  low‑end Android device (Samsung A10s or equivalent, 2 GB RAM) after
  every major feature. Dev machines (M2 Pro, 32 GB RAM) are 10x+ faster
  than real user devices. Document baseline metrics: home screen scroll
  fps, product detail open time, search result render time, barcode scan
  init time. Reference: [Flutter Performance Best Practices](https://docs.flutter.dev/perf).
- [ ] **Remove functional debt** — audit for features that have been
  superseded, unused code paths (dead code after refactors), outdated API
  endpoints. Older app versions with unused features cost server-side (API
  calls from orphaned clients) and client-side (larger APK, more rebuilds).
- [ ] **EcoCode Flutter rules contribution** — create Flutter-specific
  EcoCode rules based on the [ecoCode project](https://github.com/cnumr/ecoCode).
  Publish as a standalone ruleset. Rules would cover: `ListView()` vs
  `ListView.builder`, `setState` scope, `ShaderMask` grouping, `compute()`
  for heavy parsing, and image resolution checking.

---

## Health Platform Integrations

- [ ] **Health Connect (Android) — nutrition read/write** — integrate
  Android Health Connect Jetpack (`v1.1.0+`) via
  `androidx.health.connect:connect-client`. Read/write `NutritionRecord`
  (calories, macros). Universal Android coverage (API 28+).

  **Implementation (Phase 1 — foundation)**:
  1. Add `health-connect-client` Flutter plugin or write platform channel
     in `android/app/src/main/kotlin/`. Audit pub.dev packages first.
  2. Create `lib/services/health_connect_service.dart` — wraps
     `HealthConnectClient` init, permission requests, CRUD operations.
  3. Define `HealthNutritionData` model (calories_kcal, protein_g, carbs_g,
     fat_g, fiber_g, timestamp, meal_type).
  4. Add `NutritionRecord` write — triggered when user logs a meal or adds
     an item to inventory with known nutrition data.
  5. Add `NutritionRecord` read — fetch today's totals from Health Connect
     for a nutrition dashboard.
  6. Request permissions on first write attempt (lazy permission model).
  7. New ARB strings: `healthConnectPermission`, `nutritionSynced`,
     `nutritionSyncFailed`, `todayCalories`.

  **Implementation (Phase 2 — meal logging)**:
  1. Add "Log Meal" button on `ProductDetailScreen`.
  2. Add "Today's Nutrition" summary card on `StatsScreen` or `HomeScreen`.
  3. Background sync: flush pending nutrition records when connectivity
     permits.

  **Pitfalls & edge cases**:
  - **Flutter plugin maturity**: The `health_connect` package on pub.dev
    may have incomplete `NutritionRecord` support. Audit source before
    committing. Be prepared to write a custom platform channel in Kotlin.
  - **Health Connect must be installed separately**: Not built into
    Android. `HealthConnectClient.getSdkStatus()` returns
    `SdkStatus.AVAILABLE` only when "Health Connect by Google" is installed
    from Play Store. If unavailable, show setup prompt with Play Store deep
    link. Do not crash.
  - **System permission sheet UX**: Health Connect uses a system-level
    permission sheet, NOT standard Android runtime permissions. User grants
    per-data-type access. This sheet cannot be styled. If user denies a
    type, writes to that type fail silently — always check
    `getGrantedPermissions()` before writing.
  - **No aggregation — raw records**: Writing breakfast and lunch produces
    two separate records. Implement idempotency: generate a deterministic
    `uid` from `product_barcode + timestamp + meal_type` and check for
    existing records before inserting.
  - **Uninstall = permanent data loss**: ALL stored data across all apps is
    deleted if user uninstalls Health Connect. Detect uninstall between
    launches and warn. Keep your own sync log in SQLite.
  - **Android backup excludes Health Connect**: After device restore,
    Health Connect starts empty. Detect "first launch after restore" and
    offer to re-sync.
  - **API 28 minimum**: Health Connect requires Android 9+. On API 27 and
    below, hide all Health Connect UI. SDK methods throw
    `UnsupportedOperationException` if called.
  - **Permission revocation at any time**: Before every write, re-check
    `getGrantedPermissions()`. Show snackbar with "Fix" button to open
    permission settings.
  - **Background sync restrictions**: Android 14+ limits background work.
    Use `WorkManager` with `PeriodicWorkRequest` (minimum 15‑minute
    interval). Test on Android 14+.
  - **Testing without physical device**: CI emulators (GitHub Actions)
    generally don't have Health Connect. Mock `HealthConnectClient` with
    `mocktail` in unit tests.
  - **NutritionRecord data model mismatch**: Health Connect uses `Energy`
    (kcal), `Mass` (g) for macros, and `MealType` enum. Map cleanly to
    `HealthNutritionData`. Use `MEAL_UNKNOWN` as fallback.

- [ ] **Samsung Health Data SDK — nutrition sync** — integrate Samsung's
  active Health Data SDK (NOT the deprecated SDK). Write
  `HealthConstants.Food` (calories) and `HealthConstants.Nutrition`
  (macros) to Samsung Health. Works on all Android phones with Samsung
  Health app 6.30.2+.

  **Implementation**:
  1. Create Android platform channel or use community Flutter plugin for
     Samsung Health Data SDK.
  2. Implement `HealthDataStore` connection lifecycle.
  3. Request permissions via `HealthPermissionManager` per data type.
  4. Build `InsertRequest` with `HealthDataResolver` to write food intake.
  5. Align with Health Connect abstraction: write to both platforms via the
     same `HealthNutritionData` model.
  6. New ARB strings: `samsungHealthPermission`, `samsungHealthConnected`.

  **Pitfalls & edge cases**:
  - **Deprecated SDK cut-off**: Old "Samsung Health SDK for Android" was
    deprecated as of 31 July 2025. Verify integration uses **Samsung Health
    Data SDK** (new). Migration guide: [developer.samsung.com](https://developer.samsung.com/health/data/migration-guide/overview.html).
  - **Samsung Health app must be installed AND at v6.30.2+**: If missing or
    outdated, `HealthDataStore.connectService()` fails. Show Play Store
    deep link.
  - **SI units only — no imperial**: `CALORIE` is in kcal (not cal),
    `WEIGHT` in kg (not lb). Convert before writing if app allows imperial
    display.
  - **Partner registration for write access**: Some data types require a
    [Partner Request](https://developer.samsung.com/SHealth/business-partner/m48wvqi1mt9w2w4c).
    Food/Nutrition may be restricted. Register early — approval can take
    weeks.
  - **Connection lifecycle is fragile**: Register a strong
    `HealthDataStore.ConnectionListener` that reconnects automatically.
    Test by force-stopping Samsung Health from Settings.
  - **Non-Samsung devices work too**: SDK works on any Android phone
    (Marshmallow+) with Samsung Health installed. Do not gate behind
    `Build.MANUFACTURER == "samsung"`.
  - **Disconnection on app background**: SDK auto-disconnects. Reconnect
    in `onResume()` or `onForeground()`.
  - **Threading**: All SDK callbacks run on a binder thread. Post results
    to main thread before updating UI. Failure causes
    `CalledFromWrongThreadException`.
  - **Data deduplication across platforms**: If Samsung Health syncs to
    Health Connect, writing to both creates duplicates. Check "Sync with
    Health Connect" setting before writing.
  - **Official docs links**:
    - [Health Data Store Guide](https://developer.samsung.com/health/android/data/guide/health-data-store.html)
    - [API Reference 1.5.1](https://developer.samsung.com/health/android/data/api-reference/overview-summary.html)
    - [Programming Guide](https://developer.samsung.com/health/android/data/guide/intro.html)
    - [FoodNote Sample](https://developer.samsung.com/health/data/sample/foodnote.html)

- [ ] **Samsung Food (formerly Whisk) — meal planning UX** — integrate
  Samsung Food's meal planning pattern (recipe saving, drag-and-drop weekly
  planner, auto-generated grocery lists). Uses Samsung Health Data SDK
  underneath for nutrition sync.

  **Implementation**:
  1. Research Samsung Food public API / integration points.
  2. Implement meal suggestion from expiring items (coordinate with Recipe
     suggestions item above).
  3. Add weekly meal plan UI: drag-and-drop items into day slots,
     auto-generate grocery list from planned meals.
  4. Write planned meals' nutrition data to Samsung Health via the SDK.
  5. New ARB strings: `mealPlan`, `weeklyPlanner`, `groceryList`,
     `addToPlan`.

  **Pitfalls & edge cases**:
  - **API access may require partnership**: Samsung Food's integration API
    may require business partnership. Research access requirements before
    scoping.
  - **Regional availability**: Not available in all countries. Check
    [samsungfood.com](https://samsungfood.com/). If unavailable, hide meal
    planning UI with "Not available in your region" message.
  - **Recipe suggestions overlap**: Decide whether to use Samsung Food as
    the recipe source or keep a generic recipe API for wider coverage.
  - **Data portability lock-in**: If user builds their weekly meal plan in
    Samsung Food, they cannot export. Consider export-to-SQLite option.
  - **Meal plan → grocery list → inventory conflict**: Samsung Food
    auto-generates grocery lists. Implement "mark as purchased" flow that
    cross-references with existing inventory items.
  - **Official docs links**:
    - [Samsung Food](https://samsungfood.com/)
    - [FoodNote Sample](https://developer.samsung.com/health/data/sample/foodnote.html)

- [ ] **Apple HealthKit (future iOS version)** — integrate HealthKit via
  `HKHealthStore` for reading/writing `HKQuantitySample` with
  `HKQuantityTypeIdentifier.dietaryEnergyConsumed` and related nutrition
  types. Minimum iOS 8.0+.

  **Implementation**:
  1. Add HealthKit capability in Xcode when building iOS.
  2. Use `health` Flutter package or platform channel for `HKHealthStore`.
  3. Request per-type permissions.
  4. Write nutrition records using same `HealthNutritionData` model.
  5. New ARB strings: `appleHealthPermission`, `healthKitSynced`.

  **Pitfalls & edge cases**:
  - **iOS-only**: Gate all HealthKit code behind
    `defaultTargetPlatform == TargetPlatform.iOS`.
  - **Entitlement provisioning**: Requires Apple Developer account (paid).
    Missing entitlement → `HKHealthStore.isHealthDataAvailable()` returns
    `false`.
  - **Per-type permission granularity — no bulk requests**: Request
    read/write for EACH data type individually. Maintain list and verify
    each is granted before writing.
  - **No cross-device sync without iCloud**: Detect iCloud Health sync
    status and surface in UI.
  - **Private medical data — no server transmission**: Apple guidelines
    prohibit transmitting to third-party servers without explicit consent.
  - **Simulator limitations**: Works on simulator but with restrictions.
    End-to-end testing requires physical device.
  - **Background delivery**: iOS may delay delivery for power management.
    Use foreground queries for dashboard.
  - **User can delete records from Health app**: Implement periodic
    reconciliation between SQLite log and HealthKit records.
  - **HealthKit data deletion on app uninstall**: All records written by
    your app are deleted per Apple's privacy model. Warn user.
  - **Official docs links**:
    - [HealthKit Framework](https://developer.apple.com/documentation/healthkit)

### Health platform abstraction layer

- [ ] **Health platform abstraction layer** — create a unified Dart
  interface `HealthService` with methods `writeNutrition()`,
  `readNutrition()`, `requestPermissions()`, `isAvailable()`. Implement for
  each platform: `HealthConnectService`, `SamsungHealthService`,
  `AppleHealthService`. Makes adding OEM platforms (Huawei Health Kit,
  Xiaomi Health Cloud, etc.) a matter of writing a new implementation
  class.

  **Reference architecture**:
  ```
  Your Pantry App
        │
        ▼
  HealthService (abstract interface)
        │
        ├── HealthConnectService (Android — universal)
        ├── SamsungHealthService (Android — Samsung Health app)
        └── AppleHealthService (iOS — future)
              │
              ▼
        Health platform's native SDK
  ```

  **Pitfalls & edge cases**:
  - **Platform channel complexity multiplies**: Each health SDK requires
    its own platform channel code. Use separate `MethodChannel` per service.
    Do NOT share a single channel for all health operations.
  - **Testing across platforms is hard**: Unit tests can mock the
    `HealthService` interface. Integration tests require real devices with
    Health Connect / Samsung Health / HealthKit installed. Keep in a
    separate `health_integration_test/` directory run manually.
  - **Cross-platform data deduplication**: If both Health Connect and
    Samsung Health are active AND Samsung Health syncs to Health Connect,
    writing to both creates duplicates. Detect cross-sync before writing.
  - **User consent fatigue**: Up to 3 permission sheets on first use.
    Stagger requests: Health Connect on first nutrition write, Samsung
    Health when user opens Samsung Health settings, HealthKit on first
    iOS nutrition dashboard visit.
  - **Privacy regulations (LGPD/GDPR)**: Health data is sensitive personal
    data. Get explicit consent, provide deletion mechanism, include in
    privacy policy.
  - **App store scrutiny**: Additional review requirements on Google Play
    and Apple App Store. Prepare documents before release.
  - **Error aggregation**: Create typed error classes per platform with
    clear user-facing messages. Never show raw SDK errors in UI.
  - **Feature flagging**: Each health platform integration should be behind
    a feature flag that can be disabled remotely or via debug menu.

### Quick-reference table

```
| Platform | Write | Nutrition | Meal Plan | Docs |
|----------|-------|-----------|-----------|------|
| Health Connect (Android) | Yes | Yes NutritionRecord | No | [developer.android.com](https://developer.android.com/health-and-fitness/health-connect) |
| Samsung Health Data SDK | Yes | Yes Food/Nutrition | Yes via Samsung Food | [developer.samsung.com](https://developer.samsung.com/health) |
| Samsung Food | N/A (via SDK) | Yes | Yes meal planner | [samsungfood.com](https://samsungfood.com/) |
| Apple HealthKit | Yes (future) | Yes dietary energy | No | [developer.apple.com](https://developer.apple.com/documentation/healthkit) |
| Huawei Health Kit | Yes | Yes limited | No | [developer.huawei.com](https://developer.huawei.com/consumer/en/hms/huawei-healthkit) |
| Xiaomi Health Cloud | Yes | limited | No | [dev.mi.com](http://developer.mi.com) |
| OPPO Health | Yes | limited | No | [open.oppomobile.com](https://open.oppomobile.com/) |
| vivo Health Kit | Yes | limited | No | [developers.vivo.com](https://developers.vivo.com/) |
| Honor Health Kit | Yes | limited | No | [developer.honor.com](https://developer.honor.com/) |
```

---

## Server-Dependent / Paid Services (last)

Items that require paid hosting, external server infrastructure, or cloud
storage costs.

- [x] **Product prices + inventory total value** — new `prices` SQLite
  table, `PriceDao`, `Price` freezed model. Dual-source: local user‑entered
  prices and Open Prices API (`prices.openfoodfacts.org`). Price badge on
  `InventoryCard` (unit price), `InventoryTile` (price + store), total
  value in `StatsScreen`. Price editing via bottom sheet. Open Prices
  submissions upload proof photo.

  **Implementation (Phase 1 — local‑first)**:
  1. Create `Price` model (`lib/models/price.dart`).
  2. Create `prices` table schema: `id INTEGER PK`, `barcode TEXT FK
     products`, `price REAL`, `store TEXT`, `date INTEGER`, `currency
     TEXT`, `proof_image_path TEXT`, `source TEXT` (`'local'` /
     `'open_prices'`).
  3. Create `PriceDao` with CRUD.
  4. Add unit‑price badge to `InventoryCard`.
  5. Add price + store display on `ProductDetailScreen._InventoryTile`.
  6. Add total inventory value to `StatsScreen`.
  7. Price editing bottom sheet (long‑press on inventory tile).
  8. DB migration version 12 (bundled with other schema changes; stores at v19).

  **Implementation (Phase 2 — Open Prices API)**:
  1. Create `lib/services/open_prices_api.dart` — HTTP client.
  2. Fetch prices by barcode: `GET /api/v1/prices?barcode={barcode}`.
  3. Submit prices: `POST /api/v1/prices` with proof photo and Bearer
     token.
  4. Create `PriceService` combining local DB + API (local wins).
  5. Queue offline price submissions; flush when connectivity returns.
  6. Tests: model, DAO, service, widget tests.

  **Pitfalls & edge cases**:
  - **Open Prices has NO documented rate limits**: Assume ~15 req/min.
    Always set `User-Agent` header: `AppName/Version (contact@email)`.
  - **Photo proof is MANDATORY**: Every submission requires a photo of the
    price tag/receipt. Adds camera permission, storage, and network
    overhead.
  - **Environment‑specific tokens**: Auth tokens differ between
    `prices.openfoodfacts.org` (prod) and `prices.openfoodfacts.net`
    (pre‑prod). Use `--dart-define` flavors.
  - **License obligations**: Open Prices data is OdBL-licensed. Must
    attribute Open Food Facts. User contributions must be contributed back
    under OdBL. Cannot mix with proprietary price databases.
  - **Data quality**: "No guarantees for accuracy." Display disclaimer.
  - **Currency handling**: Default to `BRL` for Brazilian users, `USD`
    otherwise. No currency conversion — display in original.
  - **Multiple prices for same product**: Show most recent local price;
    fall back to most recent from Open Prices.
  - **Decimal precision**: Store as `double` but format with locale‑aware
    `NumberFormat.currency()`.
  - **Offline submission queue**: Proof photos can be large (MBs). Queue
    with `connectivityProvider`. Handle retry.
  - **Privacy**: Open Prices opt‑in with explicit consent dialog.
    Local‑only prices work offline and never leave the device.
  - **Proof photo storage**: Store in app‑local directory; delete after
    successful upload.
  - **HTTP 503 from infra**: Implement exponential backoff with jitter (1s,
    2s, 4s, max 60s). Distinguish from service downtime via
    `status.openfoodfacts.org`.
  - **User‑entered vs API conflict resolution**: Local wins. Show both in
    detail view: "Your price: $4.99 | Store average: $5.20."

- [ ] **NFC‑e importing from QR code** — detect NFC‑e QR URLs on the
  scanner screen (pattern `fazenda.*/nfce/qrcode`). Fetch SEFAZ page via
  HTTP GET. Parse product items from DANFE HTML using `package:html`. Map
  items to `Product` + `InventoryItem`. Show review screen with checkboxes
  and quantity edits before importing. Phase 2: dedicated backend service
  (nfce-scraper Docker).

  **Implementation (Phase 1 — in‑app scraping)**:
  1. Add `html` package to `pubspec.yaml`.
  2. Create `lib/services/nfce_service.dart` — validate NFC‑e URL, HTTP
     GET SEFAZ page, parse DANFE HTML table rows.
  3. Create `NfceItem` model (description, quantity, unit, unit_price,
     total).
  4. Detect NFC‑e QR code on `ScannerScreen` or add "Import NFC‑e" button
     on home screen.
  5. Show review screen: list of parsed items with checkboxes +
     quantity/price edits.
  6. On confirm: `upsertProduct` + `addInventoryItem` for each checked
     item.
  7. New ARB strings: `importNfce`, `nfceItemCount`, `nfceImportSuccess`,
     `nfceImportFailed`, `nfceParseError`.
  8. Create `lib/docs/nfce_reference.md`.

  **Implementation (Phase 2 — backend service, costs hosting)**:
  - Deploy `nfce-scraper` (Python FastAPI) as Docker service.
  - Flutter sends QR URL → backend returns JSON.
  - Backend handles multi‑state HTML variations.

  **Pitfalls & edge cases**:
  - **25+ Brazilian states, each with unique HTML structure**: Build
    state‑detection layer and route to state‑specific parsers. Start with
    the most common states.
  - **SEFAZ can change HTML structure at any time**: Scraping is
    inherently fragile. Implement `version` field in parser; log raw HTML
    on failure.
  - **`package:html` O(n²) tokenizer on large invoices**: Confirmed open
    issue (`dart-lang/html#18`). Use `parseFragment()` instead of
    `parse()`. Consider chunk‑based processing.
  - **QR code v2 vs v3 format**: v3 mandatory from Sep 2025. Parse URL
    parameters to determine version.
  - **Offline contingency QR codes** (`tpEmis=9`): Extra fields, different
    content/layout. Handle gracefully.
  - **No barcode on NFC‑e items**: Map to `Product` with
    `source: 'manual'` and generated ID. Cache by description hash.
  - **Duplicate detection**: Show warning in review screen. Let user
    choose: skip, add as new, or increment quantity.
  - **Network errors fetching SEFAZ page**: Show loading with 10s timeout.
    Retry once, then show error with "Try again" button.
  - **Encoding**: Brazilian Portuguese uses ISO‑8859-1 / Latin-1 in some
    SEFAZ pages. Detect charset from HTML `<meta>` tag or Content-Type
    header. Convert to UTF‑8 before parsing.
  - **Privacy**: NFC‑e URLs may encode consumer's CPF. Warn user before
    fetching. Never cache raw HTML.
  - **Large invoices (50+ items)**: Use `ListView.builder` on review
    screen. Show progress indicator during parsing.
  - **HTML5 "error recovery"**: `package:html` silently "fixes" malformed
    HTML (auto‑closes tags, injects `<tbody>`). Test against real SEFAZ
    pages with fixture files.
  - **State‑specific error pages**: Detect error keywords in response.
    Show descriptive error in user's language.
  - **Rate limiting by SEFAZ**: Add 1‑second delay between fetch and
    retry.

- [ ] **Cloud backup** — upload DB to Firebase Storage / S3. Restore on a
  new device. **Costs**: Firebase Storage ($0.026/GB stored, $0.12/GB
  transferred) or S3 ($0.023/GB). Ongoing hosting expense.
- [ ] **Backend for Frontend (BFF) evaluation** — evaluate offloading OFF
  API response transformation (JSON → freezed model mapping) to a
  lightweight backend service. Tradeoff: reduces client CPU but adds
  **server cost**, deploy complexity, and latency. Only worthwhile when
  combined with other BFF benefits (API key hiding, response caching,
  multi-source aggregation). Defer final decision to post‑MVP.

### Documentation tied to paid features

- [ ] **Price tracking doc** — add section to `ARCHITECTURE/INDEX.md`
  documenting local + Open Prices API data flow, conflict resolution, and
  proof‑photo requirement.

---

## Effort × Impact Matrix

```
                     Low effort ─────────── High effort
                     ─────────────────────────────────────
High impact      │ Batch delete            │ Shopping list
                 │ Quick quantity adjust   │ Offline submission queue
                 │ Expiry date guard       │ Changelog at startup
                 │ Expiry parsing extract  │ Product name translations
                 │ GitHub CI pipeline      │ Ingredients translations
                 │ Repaint boundaries      │ Health Connect nutrition sync
                 │ ListView.builder audit  │ Samsung Health Data SDK
                 │ Confine setState audit  │ Samsung Food meal planning
                 │ Image resolution audit  │ Health abstraction layer
                 │ Impeller check          │ Custom eco-mode
                 │ Tree shaking audit      │ Deferred components
                 │ Dark mode nudge         │ Patrol E2E tests
                 │ Thread strategy audit   │ Low-end device testing
                 │ Flashlight local setup  │ Remake notifications
                 │─────────────────────────│──────────────────────────
                 │ Golden tests            │ Multi-language support
                 │ Accessibility audit     │ Recipe suggestions
                 │ SearchBar upgrade       │ Widget golden coverage
                 │ Screenshots             │ Remake import/export
                 │ Empty-pantry onboarding │ Barcode history
                 │ Asset optimization      │ Cloud backup (paid)
                 │ Expensive raster ops    │ Product prices (paid)
                 │ EcoCode contribution    │ NFC-e importing (paid)
                 │ Small-screen golden     │ WHO food recommendations
 Low impact      │ Performance docs        │ Cosmetics/toiletries
                 │ NavigationRail          │ Apple HealthKit (future)
                 │                         │ Remove functional debt
                 │                         │ BFF evaluation (paid)
                 │                         │ OEM platforms (Xiaomi, etc.)
                 │                         │ Flashlight CI baseline
                 │                         │ Perfetto CI trace analysis
                 │                         │ Play Store CI deploy
```

---

## Summary of pitfalls documentation

Every feature item with an implementation plan includes a **Pitfalls & edge
cases** section covering:

| Category | Common examples |
|---|---|
| **API limitations** | Rate limits, silent fallbacks, undocumented behaviour, CORS |
| **Platform quirks** | iOS locale differences, Android background isolates, Windows locale bugs |
| **Data quality** | Missing translations, no accuracy guarantees, stale prices, different HTML structures |
| **Security/privacy** | NFC-e URLs with CPF, proof photos as PII, offline submission queuing |
| **Performance** | HTML parser O(n²), large markdown ASTs, DB size for multilingual fields |
| **UX edge cases** | First install vs update, accumulated version skips, partial imports, mixed-language results |
| **Dependency risk** | Discontinued packages (`flutter_markdown`), fragile scraping (SEFAZ), license obligations (OdBL) |
| **Safety** | Allergen mistranslation, dietary restriction implications, no authoritative translation claims |
