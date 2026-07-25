# Flutter Performance & Footprint Optimization

## Build-time optimizations

- **Tree shaking**: Flutter automatically removes unused Dart code and
  assets from release builds. Verify with `flutter build apk --analyze-size`
  to inspect the APK size breakdown per package.
- **AAB with deferred components**: Split large features (scanner, OFF API)
  into on-demand modules. Users only download features they actually use,
  reducing install size and bandwidth.
- **Impeller**: Enabled by default on Android (API 29+). Use `--enable-impeller`
  to force it on older devices. Provides consistent frame pacing and lower
  GPU overhead compared to Skia.
- **Asset tree shaking**: Only assets declared in `pubspec.yaml` are bundled.
  Verify the assets list is minimal. Run `flutter build apk` and inspect
  `build/app/intermediates/assets/release/` for unexpected files.

## Runtime optimizations

- **`RepaintBoundary`**: Wrap widget subtrees that change independently of
  the rest of the UI. Use on scrollable lists, animated badges, and charts.
  Never wrap entire screens — only targeted subtrees that repaint frequently
  while their parent remains static.
- **`ListView.builder` / `ListView.separated`**: Always use lazy constructors
  for lists with more than ~10 items. The default `ListView(children: [])`
  builds ALL children at once — each frame without `RepaintBoundary` rebuilds
  the entire list.
- **Confine `setState`**: Extract stateful parts into small isolated widgets.
  `setState` at the top of the tree rebuilds the entire screen. Follow the
  "ScrollToTopButton" pattern: the parent passes a `ScrollController` to
  a child that manages its own `setState` only when its visibility changes.
- **`Isolate` / `compute()`**: Offload JSON parsing (OFF API responses) and
  image encoding to background isolates. sqflite already runs on a background
  isolate internally — keep DB calls on the main thread.
- **`const` constructors**: Use `const` wherever possible. Const widgets are
  created once at compile time and never rebuilt, reducing memory and GC
  pressure.
- **Image caching + resolution**: `ImageCacheService` downloads product images
  in WebP format and caches them locally. Network images should be requested
  at display resolution (width x `devicePixelRatio`) — never download full-size
  images only to scale them down.
- **Offline-first**: `ProductRepository` returns cached data immediately,
  reducing API calls. Background refresh only fires when connectivity is
  available AND cache is overdue.

## Expensive raster operations

Avoid widgets that trigger `saveLayer` on the raster thread — they create
offscreen buffers that stress the GPU:

- `ShaderMask` — group multiple masked children under a single parent mask.
- `Opacity` with alpha < 1.0 — use `AnimatedOpacity` or render opacity
  directly in the paint method.
- `ClipPath` — prefer `ClipRRect` or `ClipRect` when possible.
- `ColorFiltered` — apply effects at the source instead of runtime.
- Multiple `ClipRRect` instances — batch under one clip boundary.

## Measuring performance

- **DevTools Performance page**: Open via `Ctrl+Shift+P` > `Flutter: Open
  Performance`. Enable **Track Widget Builds** to see which widgets rebuild
  per frame. Enable **Check for oversized images** to find resolution issues.
- **DevTools CPU Profiler**: `Ctrl+Shift+P` > `Flutter: Open CPU Profiler`.
  Record a session and examine the Flame Chart for long UI-thread operations
  (orange bars = blocked UI thread).
- **Flashlight**: `dart run flashlight measure --duration 30` — measures
  battery drain, CPU, GPU, and memory usage during automated test scenarios.
  Generates detailed reports for before/after comparison. Ideal for CI
  regression detection. Reference: [github.com/bamlab/flashlight](https://github.com/bamlab/flashlight).
- **Perfetto**: `flutter drive --profile --trace-startup` — generates a
  Perfetto trace file. Open in `ui.perfetto.dev` or use the `perfetto` CLI
  to analyze frame timing, jank, and CPU scheduling patterns.

## Per-plan performance audit checklist

Before shipping any feature that adds dependencies, screens, or queries, verify:

- [ ] **Dependencies:** estimate APK size increase, verify tree shaking
  trims unused code via `flutter build apk --analyze-size`
- [ ] **Screens:** count widgets created per frame, add `RepaintBoundary`
  on every independent chart, animated badge, or image-heavy section
- [ ] **DB queries:** verify read-only for concurrent safety, estimate
  runtime on 100/1 000/10 000 rows, confirm no missing indexes
- [ ] **Providers:** choose `autoDispose` vs `keepAlive` based on access
  pattern (background tabs, modals, always-visible widgets)
- [ ] **Models:** estimate memory per instance, batch size in collections
- [ ] **Rebuild scope:** verify `setState` calls rebuild the smallest
  subtree; check that `const` constructors are used where possible

## Testing on real devices

- Debug mode and simulators are misleading — debug mode adds overhead,
  and simulators run on powerful host machines (10x+ faster than real
  devices). Always test performance on a **physical low-end device**.
- The most sold Android phone (Samsung A10s, 2 GB RAM) runs Dart code
  ~10x slower than the most sold iPhone (iPhone 13). Profile on both
  ends of the hardware spectrum.
- Performance measurements are non-deterministic. Run multiple iterations
  and average results. Keep conditions as stable as possible.

## Eco-mode pattern

When implementing features that consume significant device resources:
- Provide an eco-mode toggle (similar to `ThemeModeNotifier`) that reduces
  animation complexity, throttles network requests, and disables non-essential
  haptic feedback.
- Detect device capability (`MediaQuery.platformBrightness`, battery level via
  `battery_plus`) and adjust behavior automatically.
- AMOLED devices benefit most from dark mode — nudge users during onboarding.

## Performance rules of thumb

| Rule | Implementation |
|------|----------------|
| Build as few widgets as possible | Use `ListView.builder`, lazy loading, caching |
| Confine `setState` to smallest widget | Extract stateful logic down the widget tree |
| Keep images small while looking good | Request at display resolution (size x pixel ratio) |
| Minimize expensive rendering ops | Avoid multiple `ShaderMask`, `ClipPath` — group them |
| Do not block the UI thread | Offload heavy computations to isolates (`compute`) |
| Measure on real low-end devices | Profile mode, physical device, multiple iterations |

## Impeller EGL warnings

- **Impeller EGL warnings**: `[ERROR:flutter/impeller/toolkit/egl/egl.cc(56)] EGL Error: Success (12288) in display.cc:161`. These are harmless Impeller init noise, often occurring on specific Android emulator drivers or older devices. They do not indicate a functional issue and can be safely ignored.

