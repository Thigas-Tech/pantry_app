# AGENTS.md — Pantry App

An offline-first Flutter application for managing pantry inventory and expiry dates.

## Project overview

- **Stack:** Flutter (stable), Dart 3.12+, Riverpod 3.x, SQLite (sqflite)
- **Platforms:** Android (primary), iOS, Linux, macOS, Web, Windows
- **State management:** Riverpod (`flutter_riverpod`)
- **Database:** SQLite via `sqflite` with DAO pattern (see `lib/database/`)
- **API:** Open Food Facts v3 REST API via `dio`
- **Code generation:** freezed, json_serializable (via `build_runner`)
- **Linting:** `very_good_analysis`, `lint/strict`, `flutter_lints`
- **Testing:** `flutter_test` + `mocktail`
- **Localization:** ARB files in `lib/l10n/`, code-generated via `flutter gen-l10n`

## Commands

```bash
# Run all generators (always do this after changing models or l10n)
dart run build_runner build --delete-conflicting-outputs
flutter gen-l10n

# Analyze
flutter analyze

# Test (all)
flutter test --concurrency=8

# Test with coverage
flutter test --concurrency=8 --coverage

# Build
flutter build apk --debug          # debug APK
flutter build apk                   # release APK
flutter build appbundle --debug    # debug AAB
flutter build appbundle            # release AAB
```

## Rules for contributions

### Always
0. **Check TODO.md** — before starting new work, consult `TODO.md` for the current roadmap and pick an item at the appropriate effort/importance level.
1. **Doc comments** — every public class, constructor, field, and method must have a `///` doc comment. Run `flutter analyze` to verify (zero issues required).
2. **Tests** — add tests for ALL new code. Use `mocktail` for mocks. Place tests in the corresponding `test/` subdirectory. New screens/services need new test files.
3. **Update generated code** — after changing models (freezed) or ARB files (l10n), run `dart run build_runner build --delete-conflicting-outputs` AND `flutter gen-l10n`.
4. **Localize** — all user-visible strings go in `lib/l10n/app_en.arb`. Never hardcode English strings in widgets or services (except in doc comments).
5. **Run the full suite** — before committing: `flutter analyze && flutter test --concurrency=8`. Zero issues, all tests passing.
6. **Update documentation** — after making changes, update `CHANGELOG.md`, `README.md`, `ARCHITECTURE.md`, and/or `AGENTS.md` to reflect new features, structure changes, or updated commands. Always generate fresh API docs with `dart doc .`.
7. **Update CHANGELOG.md** — after every feature addition, bugfix, or significant change, add an entry under `[Unreleased]` grouped by category. Keep entries concise and user-facing. This is the canonical record of what ships in each release.
8. **Set Product.source** — every `Product()` constructor call MUST pass `source`. Use `'api'` for OFF‑fetched data and `'manual'` for user‑entered or CSV‑imported data. The default is `'api'`. Never omit this field — it protects manual products from being deleted by `clearCachedProducts()` during cache flushes.

### Code style
- 80-character line limit (enforced by lint)
- Single quotes for strings
- Explicit return types on all public methods
- Use `const` constructors where possible
- Prefer Riverpod `Provider`/`NotifierProvider` for state
- Use `unawaited()` for fire-and-forget futures (import `dart:async`)

### Architecture
```
lib/
  config.dart          # App-wide configuration (credentials, flags)
  main.dart            # Entry point, ProviderScope, DynamicColorBuilder
  database/
    database_helper.dart  # Singleton, schema/migrations, public API
    product_dao.dart      # Product table CRUD
    inventory_dao.dart    # Inventory items CRUD + join queries
    inventories_dao.dart  # Named pantries CRUD
  l10n/                  # ARB files + generated Dart localizations
  models/                # Freezed models (Product, InventoryItem, InventoryWithProduct)
  providers/             # Riverpod providers (state, DI)
  screens/               # UI pages
  services/              # Business logic (API, repository, CSV, notifications)
  utils/                 # Helpers (logger, snackbar)
  widgets/               # Reusable widgets
test/
  helpers/pump_app.dart  # Widget test harness
  database/              # Database tests
  models/                # Model tests
  providers/             # Provider tests
  screens/               # Screen/widget tests
  services/              # Service tests
  utils/                 # Utility tests
  widgets/               # Widget tests
```

### Credentials & security
- API credentials are stored in `.env` (loaded by `flutter_dotenv` — see `lib/config.dart`)
- **Never commit `.env`** — it is excluded via `.gitignore`
- `.env.example` is committed as a template with placeholder values
- For release, set `OFF_USER_ID` and `OFF_PASSWORD` in `.env`
- `CONTACT_EMAIL` is used in the User-Agent header

### Testing notes
- Use `pumpApp()` from `test/helpers/pump_app.dart` for widget tests — it provides Riverpod scope, l10n, and a stubbed image cache
- Database tests use `DatabaseHelper.withPath(':memory:')` with `sqflite_common_ffi`
- For screens with MobileScanner, use `settle: false` and manual `pump()` — perpetual animations prevent `pumpAndSettle`
- Mock `NotificationService`, `ProductRepository`, and `ImageCacheService` with mocktail

## API documentation (`dart doc`)

`dart doc` generates HTML API reference from Dart source code using `///`
doc comments.  It is part of the Dart SDK — no extra install needed.

### Writing docs

Use `///` (or `/** ... */`) documentation comments.  They support **Markdown**.
Follow the [Effective Dart: Documentation](https://dart.dev/effective-dart/documentation) guide.

### Generating

```bash
dart doc .                     # output → doc/api
dart doc --output=api_docs .   # custom output dir
dart doc --dry-run .            # check for issues without writing files
```

### Configuring

Create `dartdoc_options.yaml` in the project root to customize generation.
See [dart.dev/go/dartdoc-options-file](https://dart.dev/go/dartdoc-options-file).

### Viewing locally

The generated HTML uses JavaScript for search/sidebar and must be served
through an HTTP server:

```bash
dart pub global activate dhttpd
dart pub global run dhttpd --path doc/api
# Open http://localhost:8080
```

### Troubleshooting

- **Search / sidebar broken** — docs are not served via HTTP, or `index.json` is missing.
- **Missing API docs** — `dart doc` only generates for **public** libraries and members. Check your package's public exports.
- **Case‑sensitive URLs** — file names match source declarations exactly and end with `.html`.
- **Icons as text** — browser failed to load Material Symbols font. Proxy Google Fonts or use a local copy.

### Core library docs

The official Dart core library API reference at [api.dart.dev](https://api.dart.dev) is also built with `dart doc`.

## Mobile App Gestures & Behaviors

Mobile users have strong mental models around touch interactions. Below are standard gestures, their expected behaviors, Flutter implementation APIs, timing thresholds (from Flutter framework source), and platform-specific guidance.

### Flutter Timing Constants

These constants from `package:flutter/src/gestures/constants.dart` govern gesture recognition:

| Constant | Value | Gesture |
|---|---|---|
| `kPressTimeout` | **100 ms** | Tap ambiguity timeout |
| `kDoubleTapTimeout` | **300 ms** | Max interval between two taps |
| `kDoubleTapMinTime` | **40 ms** | Min interval between two taps |
| `kDoubleTapSlop` | **100 px** | Max distance between two tap positions |
| `kDoubleTapTouchSlop` | **18 px** | Max movement per tap in double-tap |
| `kTouchSlop` | **18 px** | Max movement for tap/drag disambiguation |
| `kLongPressTimeout` | **500 ms** | Long-press acceptance delay |
| `kPanSlop` | **36 px** (2× kTouchSlop) | Pan gesture initiation threshold |
| `kScaleSlop` | **18 px** | Scale gesture initiation threshold |
| `kMinFlingVelocity` | **50 px/s** | Minimum fling velocity |
| `kMaxFlingVelocity` | **8000 px/s** | Maximum fling velocity clamp |

---

### 1. Tap (Single Tap)

**Definition**: Briefly touching the screen with one finger and lifting.

**Expected Behavior**: Primary action — activate, select, or open an object.

**Flutter Implementation**:
- Use `InkWell` (Material ripple) or `GestureDetector.onTap` (raw)
- `kPressTimeout` = **100ms** — touch acknowledgment must fire within this window
- `kTouchSlop` = **18px** — max movement before the gesture is no longer a tap
- When using `InkWell`, `enableFeedback: true` (default) provides haptic/audio feedback
- Prefer `InkWell` over raw `GestureDetector` for tappable UI: it provides Material ripple, focus support, and auto-semantics
- Buttons compress slightly on touch — `InkWell` splash animation provides this affordance
- Minimum tappable area: **44pt** on iOS, **48dp** on Android (Material Design)

**Sources**:
- [Apple HIG – Interactivity Input](https://developer.apple.com/library/ios/documentation/userexperience/conceptual/MobileHIG/InteractivityInput.html)
- [Android Material Design – Touch Feedback](https://developer.android.google.cn/training/material/animations)
- Flutter: `GestureDetector`, `InkWell`, `kPressTimeout` in `gestures/constants.dart`

---

### 2. Double Tap

**Definition**: Two rapid taps in succession.

**Expected Behavior**:
- **Images/Photos**: Zoom in/out
- **Social apps**: "Like" or react to content

**Flutter Implementation**:
- Use `GestureDetector` with `onDoubleTap` callback
- `kDoubleTapTimeout` = **300ms** — max time between first tap up and second tap down
- `kDoubleTapMinTime` = **40ms** — minimum interval between the two taps
- `kDoubleTapSlop` = **100px** — max distance allowed between the two tap positions
- `kDoubleTapTouchSlop` = **18px** — max pointer movement during each tap
- **Important tradeoff**: When both `onTap` and `onDoubleTap` are set, `GestureDetector` waits `kDoubleTapTimeout` (300ms) before firing `onTap` to disambiguate. This introduces a perceptible delay on single-tap actions — avoid setting both when single-tap responsiveness is critical.
- `InkWell`/`InkResponse` also support `onDoubleTap`

**Accessibility**: Screen readers use a double-tap to activate. Adding `onDoubleTap` to an element that also has `onTap` can cause semantic conflicts — use `excludeFromSemantics: true` judiciously.

**Sources**:
- [Apple HIG – Gesture Expectations](https://github.com/pproenca/dot-skills/blob/master/skills/.experimental/ios-hig/references/inter-gesture-patterns.md)
- [Android GestureDetector API Reference](https://developer.android.google.cn/reference/android/view/GestureDetector.OnDoubleTapListener)
- [Apple Developer – Handling Tap Gestures](https://developer.apple.com/documentation/uikit/touches_presses_and_gestures/handling_tap_gestures)
- Flutter: `GestureDetector.onDoubleTap`, `kDoubleTapTimeout`, `kDoubleTapSlop` in `gestures/constants.dart`

---

### 3. Long Press (Press & Hold)

**Definition**: Touching and holding a finger on the screen for a minimum duration without significant movement.

**Expected Behavior**:
- **Context menu** — reveals relevant actions (right-click equivalent)
- **Edit/selection mode** — enters selection or editing state
- **Preview** — shows content preview before full action

**Flutter Implementation**:
- Use `GestureDetector.onLongPress` or `LongPressDraggable<T>`
- `kLongPressTimeout` = **500ms** — Flutter default (configurable via `duration` parameter on `LongPressGestureRecognizer`)
- For drag-after-long-press: `GestureDetector.onLongPressMoveUpdate` provides position deltas after long-press is accepted
- `LongPressDraggable` extends `Draggable` — fires `HapticFeedback.selectionClick()` on drag start (`hapticFeedbackOnStart: true`)
- Provide haptic feedback on long-press to signal gesture acceptance
- Movement constraint: finger must stay within `kTouchSlop` (18px) during the hold period

**Accessibility**: Long press is a common accessibility gesture (equivalent to right-click). Set `excludeFromSemantics: true` only if the action duplicates existing semantic information.

**Sources**:
- [Apple Developer – UILongPressGestureRecognizer](https://developer.apple.com/documentation/uikit/uilongpressgesturerecognizer)
- [Apple Developer – Handling Long-Press Gestures](https://developer.apple.com/documentation/uikit/touches_presses_and_gestures/handling_long-press_gestures)
- [Android ViewConfiguration – getLongPressTimeout()](https://developer.android.com/reference/android/view/ViewConfiguration#getLongPressTimeout())
- [Android AOSP – LONG_PRESS_TIMEOUT = 500](https://android.googlesource.com/platform/frameworks/base/+/master/core/java/android/view/ViewConfiguration.java)
- Flutter: `GestureDetector.onLongPress`, `LongPressDraggable`, `kLongPressTimeout` in `gestures/constants.dart`

---

### 4. Swipe Horizontal

#### 4a. Swipe Left (Trailing)

**Expected Behavior**: **Destructive or secondary actions** — delete item, archive message, reveal action tray with color-coded buttons (red for delete, orange for priority).

**Flutter Implementation**:
- Use `Dismissible` widget with `direction: DismissDirection.endToStart` (default)
- `_kMinFlingVelocity` = **700px/s** — minimum fling speed to trigger auto-dismiss
- `_kDismissThreshold` = **0.4** — 40% of widget width must be dragged before auto-dismiss
- `movementDuration` = **200ms** — slide-back animation if threshold not met
- `resizeDuration` = **300ms** — shrink animation after dismissal
- Use `confirmDismiss` callback for async confirmation dialogs
- `background` and `secondaryBackground` for stacked action visuals
- Customize thresholds per direction via `dismissThresholds` map
- Always also provide a visible delete/archive button — `Dismissible` does not expose semantics for the dismiss action

**Sources**:
- [Apple Developer – trailingSwipeActionsConfigurationForRowAt](https://developer.apple.com/documentation/uikit/uitableviewdelegate/tableView(_:trailingSwipeActionsConfigurationForRowAt:))
- [Apple Developer – swipeActions(edge:allowsFullSwipe:content:)](https://developer.apple.com/documentation/swiftui/view/swipeactions(edge:allowsfullswipe:content:))
- [GitHub – iOS Swipe Actions Pattern Reference](https://github.com/pproenca/dot-skills/blob/master/skills/.experimental/ios-hig/references/inter-swipe-actions.md)
- Flutter: `Dismissible` in `package:flutter/src/widgets/dismissible.dart`

#### 4b. Swipe Right (Leading)

**Expected Behavior**: **Positive actions** — mark as complete, archive, pin/favorite items.

**Flutter Implementation**:
- Use `Dismissible` with `direction: DismissDirection.startToEnd`
- Or `Dismissible` with `secondaryBackground` for two-way swipe actions (leading vs trailing)

**Sources**:
- [Apple Developer – leadingSwipeActionsConfigurationForRowAt](https://developer.apple.com/documentation/uikit/uitableviewdelegate/tableView(_:leadingSwipeActionsConfigurationForRowAt:))
- Flutter: `Dismissible.direction` in `package:flutter/src/widgets/dismissible.dart`

---

### 5. Swipe Vertical

#### 5a. Pull to Refresh (Pull Down)

**Definition**: Swiping downward from the top of a scrollable list or feed.

**Expected Behavior**: Refresh content — reload data, fetch new items.

**Flutter Implementation**:
- Use `RefreshIndicator` (Material) or `RefreshIndicator.adaptive` (Cupertino spinner on iOS)
- `displacement` = **40.0px** default — how far the indicator travels
- `triggerMode`: `RefreshIndicatorTriggerMode.onEdge` (default) — only triggers at scroll top; `anywhere` allows trigger from any position
- Transitions through: **pull → release → refreshing**
- `_kIndicatorSnapDuration` = **150ms** — animation to final displacement on release
- `_kIndicatorScaleDuration` = **200ms** — scale-down after refresh completes
- Rubber-band effect at scroll boundaries is provided by `ScrollPhysics` — use `AlwaysScrollableScrollPhysics` if content fits in viewport
- `RefreshIndicatorState.show()` for programmatic trigger
- Provide haptic feedback on refresh activation

**Sources**:
- [Apple Developer – RefreshAction Documentation](https://developer.apple.com/documentation/swiftui/refreshaction)
- [Android Developer – SwipeRefreshLayout API Reference](https://developer.android.com/reference/androidx/swiperefreshlayout/widget/SwipeRefreshLayout)
- [Android Developer – PullRefreshState](https://developer.android.google.cn/reference/kotlin/androidx/compose/material/pullrefresh/PullRefreshState)
- Flutter: `RefreshIndicator`, `RefreshIndicator.adaptive` in `package:flutter/src/material/refresh_indicator.dart`

#### 5b. Swipe Down to Dismiss

**Expected Behavior**: Dismiss sheets, modals, or cards.

**Flutter Implementation**: Use `Dismissible` with `direction: DismissDirection.vertical` or wrap in a `Draggable` with vertical axis constraint.

#### 5c. Swipe Up

**Expected Behavior**:
- Show more content
- System-level: go home (from bottom edge on gesture navigation)
- Open app switcher (swipe up and hold)

**Note**: System-level swipe-up is handled by the OS — do not override it.

---

### 6. Edge Swipe (Back Navigation)

**Definition**: Swiping inward from the left or right edge of the screen.

**Expected Behavior**: **Navigate back** to the previous screen.

**Flutter Implementation**:
- Use `PopScope` (replaces deprecated `WillPopScope` in Flutter 3.12+)
- `PopScope(canPop: bool, onPopInvokedWithResult: callback)` — `canPop: false` disables back navigation
- On Android: swipe from either edge triggers system-level predictive back gesture
- On iOS: `CupertinoPageRoute` provides native edge-swipe-back via `CupertinoRouteTransitionMixin`
- When `canPop: false` on iOS, the gesture is completely suppressed and `onPopInvokedWithResult` is NOT called
- When `canPop: false` on Android, `onPopInvokedWithResult` IS called with `didPop: false`
- **Never override this gesture** for custom actions — non-standard back gestures increase task completion time by 2-3×
- Use `NavigatorPopHandler` for simpler nested `Navigator` scenarios

**Sources**:
- [Android Developer – Ensure compatibility with gesture navigation](https://developer.android.com/guide/navigation/gesturenav)
- [Apple Developer – interactivePopGestureRecognizer](https://developer.apple.com/documentation/uikit/uinavigationcontroller/interactivepopgesturerecognizer)
- [MacRumors – iOS 26 Back Gesture](https://www.macrumors.com/2025/06/10/ios-26-tweaks-back-gesture/)
- Flutter: `PopScope` in `package:flutter/src/widgets/pop_scope.dart`, `CupertinoPageRoute` in `package:flutter/src/cupertino/route.dart`

---

### 7. Pinch to Zoom

**Definition**: Placing two fingers on the screen and dragging them apart (zoom in) or together (zoom out).

**Expected Behavior**: Zoom in/out on images, maps, and content.

**Flutter Implementation**:
- Use `InteractiveViewer` for built-in pan+zoom (preferred for image/map content)
  - `minScale` = **0.8**, `maxScale` = **2.5** (defaults)
  - `interactionEndFrictionCoefficient` = **0.0000135** (tuned to match Google Photos feel)
  - `panEnabled: true`, `scaleEnabled: true` (both enabled by default)
  - `boundaryMargin: EdgeInsets.zero` — prevents viewing beyond child bounds
  - `TransformationController` for programmatic zoom control
- For custom zoom behavior: use `GestureDetector` with `onScaleStart`, `onScaleUpdate`, `onScaleEnd` callbacks
  - `ScaleUpdateDetails.scale` — zoom factor delta
  - `ScaleUpdateDetails.pointerCount` — number of fingers touching
- **Important**: Scale callbacks supersede pan callbacks — use `onScale*` when both pan and zoom are needed (cannot mix `onPan*` and `onScale*` on the same `GestureDetector`)

**Accessibility**: `InteractiveViewer` does NOT provide accessibility zoom controls. Always provide +/- zoom buttons backed by `TransformationController`.

**Sources**:
- [Apple Developer – UIPinchGestureRecognizer](https://developer.apple.com/documentation/uikit/uipinchgesturerecognizer)
- [Apple Developer – Handling Pinch Gestures](https://developer.apple.com/documentation/uikit/touches_presses_and_gestures/handling_pinch_gestures)
- [Android Developer – ZoomGestureDetector](https://developer.android.com/reference/androidx/camera/viewfinder/core/ZoomGestureDetector)
- Flutter: `InteractiveViewer` in `package:flutter/src/widgets/interactive_viewer.dart`, `GestureDetector.onScale*` in `gesture_detector.dart`

---

### 8. Drag & Pan

**Definition**: Touching and moving a finger across the screen.

**Expected Behavior**:
- Move objects around the interface
- Scroll content
- Select multiple items (with two fingers)

**Flutter Implementation**:
- Use `GestureDetector` with `onPanStart`, `onPanUpdate`, `onPanEnd`, or `onPanDown`/`onPanCancel`
- `kPanSlop` = **36px** (2× kTouchSlop) — movement threshold before pan is recognized
- `DragUpdateDetails.delta` — relative movement since last update (use this for translation, not absolute position)
- `DragEndDetails.velocity` — fling velocity for momentum/inertia scrolling
- For drag-and-drop: use `Draggable<T>` and `DragTarget<T>`
  - `Draggable` has `feedback` widget (the dragged visual), `childWhenDragging`, `axis` constraint
  - `LongPressDraggable` for drag-after-long-press pattern
- `dragStartBehavior`: `DragStartBehavior.start` (default) — gesture at position where drag won the arena; `DragStartBehavior.down` — gesture at initial touch position
- Fling momentum is built into `ScrollView` via `ScrollPhysics` — implement custom momentum with `DragEndDetails.velocity`
- **Constraint**: `onPan*` and `onScale*` callbacks cannot coexist on the same `GestureDetector` — scale is a superset of pan

**Sources**:
- [Apple Developer – Handling Pan Gestures](https://developer.apple.com/documentation/uikit/touches_presses_and_gestures/handling_pan_gestures)
- [Apple Developer – UIPanGestureRecognizer](https://developer.apple.com/documentation/uikit/uipangesturerecognizer)
- Flutter: `GestureDetector.onPan*`, `Draggable`, `LongPressDraggable`, `DragTarget` in `package:flutter/src/widgets/drag_target.dart`

---

### 9. Two-Finger Drag (Multi-Select)

**Definition**: Placing two fingers on the screen and dragging them over items.

**Expected Behavior**: **Select multiple items at once** — works in lists by dragging down/up to highlight multiple items.

**Flutter Implementation**:
- **No dedicated widget exists** — implement via `GestureDetector.onScaleStart`/`onScaleUpdate`/`onScaleEnd`
- Check `ScaleStartDetails.pointerCount` / `ScaleUpdateDetails.pointerCount` — enter multi-select mode when `pointerCount >= 2`
- Or use `Listener` for raw pointer events: track `onPointerDown`/`onPointerUp` count manually
- When two-finger drag is recognized, switch list to selection mode with `SelectableText` or custom selection overlay
- This is a **custom implementation** — test thoroughly across platforms

**Accessibility**: Multi-touch gestures are inherently inaccessible to screen reader users. Always provide alternative selection mechanisms (checkboxes, long-press context menu with "Select All").

**Sources**:
- [Apple Developer – Selecting multiple items with a two-finger pan gesture](https://developer.apple.com/documentation/uikit/views_and_controls/collection_views/selecting_multiple_items_with_a_two-finger_pan_gesture)
- [MacRumors – Two-Finger Selection Trick](https://www.macrumors.com/2025/04/18/select-faster-on-iphone-with-this-two-finger-trick/)
- [How-To Geek – iPhone Two-Finger Drag](https://www.howtogeek.com/787361/nobody-told-me-about-these-iphone-gestures-now-i-use-them-every-day/)
- Flutter: `ScaleUpdateDetails.pointerCount` in `package:flutter/src/gestures/scale.dart`

---

### 10. Shake to Undo

**Definition**: Physically shaking the device.

**Expected Behavior**: **Undo** the last action (typing, deletion, etc.).

**Flutter Implementation**:
- **No Flutter framework built-in** — use `sensors_plus` package for accelerometer access
- Listen to `accelerometerEventStream()` — detect shakes by checking acceleration magnitude (`sqrt(x² + y² + z²)`)
- Typical threshold: magnitude > **25–30 m/s²**
- Debounce window: **500–1000ms** between shake events
- Add `sensors_plus` to `pubspec.yaml` and check platform permissions
- On iOS: system supports shake gesture via `UIResponder.userUndo` but Flutter does not auto-bridge it — custom implementation required
- On Android: no system shake gesture exists — entirely manual via sensors

**Accessibility**: Shake is inaccessible to users with motor impairments or devices without accelerometers. **Always** provide an alternative undo method (undo button, snackbar with "Undo" action, menu item).

**Sources**:
- [CNET – Shake to Undo on iPhone](https://www.cnet.com/tech/mobile/looking-for-ctrlz-on-your-iphone-3-ways-to-easily-undo-mistakes/)
- [SlashGear – Shake to Undo Feature](https://www.slashgear.com/1078170/this-underrated-iphone-feature-saves-time-deleting-what-you-typed/)
- [How-To Geek – How to Undo on iPhone](https://www.howtogeek.com/789901/how-to-undo-on-iphone/)
- Flutter: `sensors_plus` package on pub.dev (accelerometer stream)

---

### 11. Rotate (Two-Finger Rotation)

**Definition**: Placing two fingers on a view and rotating them.

**Expected Behavior**: Rotate an object or image.

**Flutter Implementation**:
- Use `GestureDetector.onScaleUpdate` — `ScaleUpdateDetails.rotation` provides rotation delta in **radians**
- Positive values = clockwise rotation
- Use the `focalPoint` from `ScaleStartDetails` as the center of rotation
- **Note**: `InteractiveViewer` ignores the rotation parameter by default (only uses scale and translation)
- For rotation + scale + pan together, use `onScaleUpdate` and manually compose a `Matrix4`:
  - `Matrix4.identity()` followed by `.translate()`, `.rotateZ()`, `.scale()`, `.translate()` (translate back)
- No separate rotation-only recognizer exists — scale recognizer handles both

**Accessibility**: Rotation gestures are not accessible to screen reader users. Always provide alternative controls (sliders, +/- buttons, angle input).

**Sources**:
- [Apple Developer – UIRotationGestureRecognizer](https://developer.apple.com/documentation/uikit/uirotationgesturerecognizer)
- [Apple Developer – Handling Rotation Gestures](https://developer.apple.com/documentation/uikit/touches_presses_and_gestures/handling_rotation_gestures)
- [Android Developer – transformable modifier (Jetpack Compose)](https://developer.android.com/reference/kotlin/androidx/compose/foundation/gestures/package-summary#transformable)
- Flutter: `ScaleUpdateDetails.rotation` in `package:flutter/src/gestures/scale.dart`, `InteractiveViewer`

---

### General Principles & Best Practices

#### Consistency
- Use standard gestures for their expected purposes. Don't override system gestures or create novel interactions where standards exist
- Avoid using a familiar gesture (tap, swipe) for an action unique to your app
- Non-standard gestures increase task completion time by 2-3×
- Use Flutter's built-in gesture widgets (`Dismissible`, `RefreshIndicator`, `InteractiveViewer`) rather than raw `GestureDetector` reimplementations

#### Feedback & Responsiveness
- Touch acknowledgment: **<100ms** (governed by `kPressTimeout`)
- Quick actions: **150-250ms** (e.g., `_kIndicatorSnapDuration` = 150ms)
- View transitions: **250-350ms**
- Complex animations: **350-500ms** (e.g., `_kIndictorScaleDuration` = 200ms)
- Visual changes should appear instantly when users interact — delayed feedback makes users doubt if their action registered
- Buttons compress on touch (`InkWell` splash); pull-to-refresh stretches content naturally
- Provide haptic feedback for long-press acceptance and refresh activation

#### Accessibility
- Always provide button alternatives for gesture-based actions:
  - `Dismissible` → provide a delete/archive button
  - `InteractiveViewer` → provide +/- zoom buttons
  - Shake to undo → provide undo button or SnackBar action
  - Swipe actions → provide long-press context menu as fallback
- Users with motor or dexterity impairments may struggle with double-tap, swipe, pinch, or press-and-hold
- `InkWell` is inherently more accessible than raw `GestureDetector` — it supports `focusNode`, `onFocusChange`, `onHover`, `autofocus`, `enableFeedback`
- Multi-touch gestures (pinch, rotate, two-finger select) cannot be performed by screen reader users — always provide single-pointer alternatives
- Use `Semantics` widget to annotate custom gesture interactions that lack built-in semantics
- Give people more than one way to interact with your app

#### Discoverability
- Add visual hints for available gestures (e.g., partially visible action behind a list item)
- Indicate when a gesture isn't available — if you don't clearly communicate why a gesture doesn't work, users might think the app has frozen
- Custom gestures should be discoverable, straightforward to perform, and distinct from other gestures

#### Platform-Specific
- **iOS**: Minimum tappable size **44pt**; standard gestures include tap, double-tap, long press, swipe, pinch, pan, and rotation; use `CupertinoPageRoute` for native back gesture; prefer `RefreshIndicator.adaptive` for Cupertino spinner
- **Android**: Minimum tappable size **48dp**; follow Material Design gesture documentation; `PopScope` handles predictive back gestures; use `RefreshIndicator` for Material-style refresh
- **Flutter**: Where possible, use `.adaptive` constructors (e.g., `RefreshIndicator.adaptive()`, `Switch.adaptive()`, `Slider.adaptive()`) to automatically select the correct platform widget
