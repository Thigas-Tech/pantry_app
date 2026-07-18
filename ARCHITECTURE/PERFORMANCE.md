## 11. Carbon footprint design decisions

### 11.1 Dark mode (OLED/AMOLED energy savings)

The app supports `ThemeMode.system` (default), `ThemeMode.light`, and
`ThemeMode.dark` via `ThemeModeNotifier`. On AMOLED displays, dark mode
consumes up to 60% less power because black pixels are physically turned
off. A future enhancement will detect AMOLED devices at launch and nudge
the user toward dark mode with a one-time prompt.

### 11.2 Image caching (WebP)

`ImageCacheService` downloads product images in WebP format from the Open
Food Facts CDN and stores them in the app's local documents directory. WebP
is ~30% smaller than JPEG at equivalent quality, reducing network transfer
and storage footprint. Cached images are served instantly — no network calls
on subsequent views.

All `Image.network` calls set `cacheWidth` and `cacheHeight` at display
resolution (display dp x `devicePixelRatio`) to prevent full-resolution
decode. Inventory card and search thumbnails are 40x40 dp; product detail
photos are 200 dp tall x screen-width wide.

### 11.3 Offline-first architecture

`ProductRepository` implements offline-first: always return cached data
first, fetch from API only on cache miss. This dramatically reduces API
calls — a product viewed twice generates one network call, not two. The
background cache refresh is throttled (5+ days overdue, connectivity
required), and only API-sourced products are refreshed — user-entered
products are never re-fetched.

### 11.4 Firestore cloud cache

`FirebaseCacheService` adds a remote caching layer on top of the local
SQLite cache. Product data is replicated to Cloud Firestore with a 180-day
rolling refresh window. Benefits:

- Survives local cache flushes — products are still available from Firestore
  after the user clears their local cache.
- Reduces OFF API calls — repeated lookups for popular barcodes hit the
  Firestore cache instead of the upstream API.
- Write-throttled — the 180-day TTL and per-entry refresh tracking ensure
  the Firestore free-tier daily write limits are respected.
- Graceful degradation — all Firestore operations are wrapped in try/catch
  with `isAvailable: false` fallback. No errors propagate to the UI when
  Firebase is unavailable.

### 11.5 RepaintBoundary placement

`RepaintBoundary` should be applied to widget subtrees that:
- Scroll independently (e.g., items inside `ListView.builder`)
- Animate repeatedly (e.g., badge transitions, progress indicators)
- Are embedded in a scrolling parent but have static content

Each `InventoryCard` in the main inventory `ListView.builder` is
wrapped in `RepaintBoundary` with `ValueKey(item.id)`. This prevents parent
scroll events from triggering card repaints and enables efficient widget
recycling. Cards that load network images or toggle selection do not
force their siblings to repaint.

### 11.6 Thread strategy

sqflite already executes SQL on a background isolate internally. The
following operations are candidates for `Isolate` / `compute()` offloading:
- Open Food Facts API response parsing (`json.decode` of large payloads)
- Image encoding (camera capture -> WebP conversion in `ImageCacheService`)

`compute()` from `package:flutter/foundation.dart` is preferred over raw
`Isolate` for fire-and-forget tasks. Use `SendPort` messaging for
long-running workers.

### 11.7 AAB and deferred components (Android)

The app builds as an Android App Bundle (AAB) for Play Store distribution.
A future optimization will split into dynamic feature modules so users only
download the features they actually use:
- `scanner` — MobileScanner camera integration
- `search` — Open Food Facts SDK

This reduces the initial install size and download bandwidth, especially
for users on metered connections.

### 11.8 Eco-mode pattern

A planned `EcoModeNotifier` (mirrors `ThemeModeNotifier`) will let users
opt into reduced energy consumption. When enabled:
- Animations are simplified or disabled
- Network refresh intervals are doubled
- Non-essential haptic feedback is disabled

Designed to complement Android Battery Saver and iOS Low Power Mode.

### 11.9 CI/CD pipeline

The project uses GitHub Actions for continuous integration and delivery.
Workflows live in `.github/workflows/`:

| Workflow | Trigger | Purpose |
|---|---|---|---|---|
| `ci.yml` | Pull request to `main` | Format check, `flutter analyze`, unit + widget tests, coverage report with PR comment |
| `build.yml` | Push to `main` | Re-runs all checks, injects `.env` from secrets, builds debug APK + AAB + release APK + AAB, uploads artifacts (90-day retention), and creates a GitHub release via `gh release create` (publish job) |
| `patrol-e2e.yml` | Weekly (Sun 03:00 UTC) | Patrol integration test suite on Android emulator |
| `flashlight.yml` | Weekly (Sun 04:00 UTC) | Flashlight battery/CPU/GPU profiling on emulator |
| `perfetto.yml` | Weekly (Sun 05:00 UTC) | Perfetto startup trace collection and frame-timing analysis |
| `deploy-to-playstore.yml` | Release published | Signed release AAB + APK, upload to Play Console internal track via `r0adkll/upload-google-play`. Triggered by `build.yml` publish job or manual release creation. |

> **Note:** The `publish` job in `build.yml` creates a GitHub release using
> `gh release create` with artifacts attached.

All workflows use SHA-pinned actions for supply-chain security. Dependabot
updates GitHub Action versions monthly. Runner: `ubuntu-latest` for QA and
build, `macos-latest` for emulator-based workloads (E2E, Flashlight, Perfetto).

Helper script in `scripts/`:
- `inject_env.sh` — creates `.env` from GitHub secrets for build-time config injection

### 11.10 Performance measurement

The CI pipeline integrates automated performance profiling:
- **Flashlight** — weekly automated battery, CPU, GPU profiling on emulator.
  Reports stored as artifacts; baseline comparison planned for PR gating.
- **Perfetto** — weekly startup and frame timing traces. Open in `ui.perfetto.dev`
  or parse with `perfetto` CLI for jank metrics.
- **Dart DevTools** — manual profiling during development: Performance page
  (widget rebuilds, oversized images) and CPU Profiler (Flame Chart for
  UI-thread blocking).

Reference: Flutter Heroes 2025 performance talk by Alexandre Moureaux (BAM)
— [github.com/bamlab/flashlight](https://github.com/bamlab/flashlight).
