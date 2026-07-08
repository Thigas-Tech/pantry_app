# Manual Testing Guide (Emulator + ADB)

For testing the Pantry App interactively on an emulator with `adb` commands.
Use this after the automated smoke test (`scripts/run_smoke_test.sh`) to verify
edge cases, per-feature behavior, and data integrity.

Refer to `emulator_instructions.md` for automated smoke test basics and
troubleshooting.

---

## 1. Prerequisites

```bash
export ANDROID_SDK_ROOT=$HOME/Android/sdk
export ANDROID_HOME=$ANDROID_SDK_ROOT
export PATH=$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/emulator:$ANDROID_HOME/platform-tools:$PATH
```

**.env note:** The app reads `.env` from assets at build time. Changing `.env` on
disk has no effect on an already-installed APK. Always rebuild after changing
`.env`:

```bash
flutter build apk --debug
```

If `.env` is missing or empty, copy `.env.example` and fill in real values
(especially `FEEDBACK_TOKEN` — a GitHub PAT with repo scope).

---

## 2. Emulator lifecycle

### Create the AVD (once)

```bash
sdkmanager --install "system-images;android-34;google_apis;x86_64"
echo "no" | avdmanager create avd \
  -n "smoke_test" \
  -k "system-images;android-34;google_apis;x86_64" \
  -d "pixel_5" \
  --force
```

### Start with visible window

```bash
emulator -avd smoke_test -gpu host -no-snapshot -noaudio -no-boot-anim &
```

**Fallback if emulator crashes on startup** (missing GPU drivers on Linux):

```bash
emulator -avd smoke_test -gpu swiftshader_indirect -no-snapshot -noaudio -no-boot-anim &
```

### Wait for boot

```bash
timeout 120 bash -c 'while [[ "$(adb shell getprop sys.boot_completed 2>/dev/null)" != "1" ]]; do sleep 3; done'
```

### Disable animations (faster testing)

```bash
adb shell settings put global window_animation_scale 0
adb shell settings put global transition_animation_scale 0
adb shell settings put global animator_duration_scale 0
```

### Kill emulator

```bash
kill "$(pgrep -f 'emulator.*smoke_test')"
```

**Shortcut:** `scripts/run_smoke_test.sh` automates all of the above and runs
the smoke test. Use it first, then continue with manual testing below.

### Check free disk space

```bash
adb shell df /data
```

If the `/data` partition is >90% full, the emulator may fail silently. Wipe
userdata:

```bash
adb emu kill
emulator -avd smoke_test -wipe-data -gpu host &
```

---

## 3. Smoke test

```bash
flutter test integration_test/
```

Covers: app launch, 5-tab `NavigationBar` (Home, Search, Stats, List,
Settings), Home FAB, Search `TextField`, Stats chart icon + empty state,
List (shopping cart icon), Settings theme dialog.

All assertions pass or you get a clear failure message. No manual
interpretation needed.

---

## 4. Per-feature manual testing scenarios

Run these after the smoke test. Check each expected behavior and note any
deviation.

### 4a. Home tab

| # | Action | Expected |
|---|--------|----------|
| 1 | Fresh install — open Home | "Your pantry is empty" with scan button |
| 2 | Tap FAB | Scanner opens; on emulator expect camera error fallback to manual entry |
| 3 | In manual entry, type `3017620422003` (Nutella) and submit | Navigates to `ProductDetailScreen` showing "Nutella" |
| 4 | On product detail, tap "Add to Inventory" | Form opens; fill quantity, tap save; return to ProductDetail showing added item |
| 5 | Navigate back to Home | Nutella appears in "Good" section with expiry label |
| 6 | Long-press Nutella card | Enters selection mode; checkbox appears on each card |
| 7 | Select checkbox, tap delete icon, confirm | Item deleted; undo snackbar appears |
| 8 | Pull down to refresh | Cached data stays visible (no full-screen spinner flash) |
| 9 | Repeat steps 2-5 for barcode `737628064502` | Verify product detail shows correctly; no crash |

### 4b. Search tab

| # | Action | Expected |
|---|--------|----------|
| 1 | Tap Search tab | Search bar is present, no results initially |
| 2 | Type `milk` | Results appear (local + OFF API); cloud icon on API results |
| 3 | Tap a result | Navigates to `ProductDetailScreen` |
| 4 | Type gibberish like `zxcvbnmqwerty` | "No results" message after grace period |
| 5 | Long-press a result | Bottom sheet with "Add to inventory", "Copy barcode", "Add to shopping list" |
| 6 | Tap "Add to shopping list" | Item added; snackbar confirmation |

### 4c. Stats tab

| # | Action | Expected |
|---|--------|----------|
| 1 | With items added (from 4a), switch to Stats | Charts render (expiry donut, Nutri-Score bar, category pie) |
| 2 | Switch away from Stats and back | No loading spinner flash; previous data shown immediately |
| 3 | With no items (fresh install) | "No items to analyze" message with chart icon |

### 4d. List (Shopping List) tab

| # | Action | Expected |
|---|--------|----------|
| 1 | Fresh list | Empty state: shopping cart icon + "Your shopping list is empty" |
| 2 | Tap FAB | Quick-add dialog with name and quantity fields |
| 3 | Enter "Milk", quantity 2, tap Add | Item appears in pending section |
| 4 | Enter another item "Bread", qty 1 | Both items in pending section |
| 5 | Tap checkbox on "Milk" | Item moves to purchased section with strikethrough |
| 6 | Tap "Add again" on purchased "Milk" | Item moves back to pending (unpurchased) |
| 7 | Swipe "Bread" left | Delete action fires; undo snackbar appears |
| 8 | Tap undo on snackbar | Item restored to pending |
| 9 | Tap clear-purchased button in AppBar | Confirmation dialog; confirm; purchased cleared |
| 10 | For non-empty list, tap share button | Share intent with text list |
| 11 | Navigate to ProductDetail, tap cart icon | Item added to shopping list; snackbar confirms |
| 12 | Return to List tab | Item appears in pending section |
| 13 | Check all pending items as purchased | Clear-purchased becomes available with correct count |

### 4e. Settings tab

| # | Action | Expected |
|---|--------|----------|
| 1 | Tap Theme | Dialog with system/light/dark options |
| 2 | Select dark | Theme changes; dialog closes |
| 3 | Select light | Theme reverts |
| 4 | Toggle AMOLED dark mode (with dark theme) | Background becomes pure black |
| 5 | Toggle Price Tracking on | Price section appears on Home and ProductDetail |
| 6 | Tap currency picker | Dialog with 33 currencies; select a different one |
| 7 | Tap "What's New" | Changelog bottom sheet with version sections |
| 8 | Tap "Flush cache" | Confirmation dialog; confirm; shows success snackbar |
| 9 | After cache flush, return to Home | Products re-fetch from API (or show barcodes if offline) |
| 10 | Toggle notifications off, then back on | No crash; notification permission requested on re-enable |

### 4f. Offline behavior

| # | Action | Expected |
|---|--------|----------|
| 1 | Enable airplane mode: `adb shell cmd connectivity airplane-mode enable` | — |
| 2 | Switch to Search tab, type a query | Shows local-only results (or "no results"); no crash |
| 3 | Switch to Home, pull to refresh | Skips OFF API calls; shows snackbar if offline detected |
| 4 | Tap FAB, scan a barcode | Manual entry screen opens (API lookup skipped) |
| 5 | Submit feedback (Settings -> Send feedback) | Issue queued offline with visual indicator |
| 6 | Disable airplane mode: `adb shell cmd connectivity airplane-mode disable` | Feedback auto-flushes on reconnect |
| 7 | Wait ~5 seconds, check Home tab | Products refresh automatically |

### 4g. Product detail and price tracking

| # | Action | Expected |
|---|--------|----------|
| 1 | Open a product detail screen | Nutri-Score badge, nutrition table, ingredients (expandable) |
| 2 | Tap "Add Price" | Price entry sheet opens |
| 3 | Enter amount, store, date; submit | Price appears in price section |
| 4 | Tap the price card | Navigates to Price History screen |
| 5 | Swipe-delete a price entry | Undo snackbar appears |
| 6 | Toggle Prices Hidden in Settings | Prices show as bullets on Home and ProductDetail |
| 7 | Toggle Prices Hidden off | Prices show normally again |

### 4h. Shopping list barcode FK integrity

| # | Action | Expected |
|---|--------|----------|
| 1 | Add a product to shopping list via product detail (cart icon) | Item has barcode link |
| 2 | Flush cache in Settings | Cache cleared; product deleted from local DB |
| 3 | Return to List tab | Shopping list item still exists; barcode is now null (text-only) |
| 4 | Re-fetch product (scan the barcode again from Home) | Product re-cached; barcode link NOT automatically restored (item remains text-only) |

---

## 5. ADB edge case commands

### Force-stop and restart

```bash
# Force-stop
adb shell am force-stop com.thigastech.pantry_app
# Re-launch
adb shell am start -n com.thigastech.pantry_app/.MainActivity
# Verify data survives force-stop (items, settings, theme)
```

### Airplane mode

```bash
adb shell cmd connectivity airplane-mode enable
adb shell cmd connectivity airplane-mode disable
```

### Database inspection (debug builds only)

`run-as` fails on release builds with "package not debuggable". Build with
`--debug` for these commands.

```bash
# List database files
adb shell run-as com.thigastech.pantry_app ls databases/

# Pull database for local inspection
adb shell run-as com.thigastech.pantry_app cat databases/pantry.db > /tmp/pantry_debug.db
sqlite3 /tmp/pantry_debug.db ".tables"
sqlite3 /tmp/pantry_debug.db ".schema"
sqlite3 /tmp/pantry_debug.db "SELECT COUNT(*) FROM products"
sqlite3 /tmp/pantry_debug.db "SELECT COUNT(*) FROM inventory"
sqlite3 /tmp/pantry_debug.db "SELECT COUNT(*) FROM shopping_list"

# Verify FK enforcement
sqlite3 /tmp/pantry_debug.db "PRAGMA foreign_keys"
```

### Notification state

```bash
adb shell dumpsys notification --noredact | grep -A5 pantry
```

### Screenshot and recording

```bash
# Screenshot
adb exec-out screencap -p > screenshot.png

# Screen recording (Ctrl+C to stop)
adb shell screenrecord /sdcard/test_recording.mp4
# Pull recording
adb pull /sdcard/test_recording.mp4 .
```

### Clear all app data (fresh start)

```bash
adb shell pm clear com.thigastech.pantry_app
```

Wipes database, SharedPreferences, image cache. Equivalent to fresh install.

### Multiple devices

```bash
# List all devices
adb devices -l

# Target a specific device
adb -s emulator-5554 shell ...

# Or set default
export ANDROID_SERIAL=emulator-5554
```

---

## 6. logcat monitoring

Run in a separate terminal during all manual testing:

```bash
adb logcat | grep -E 'flutter|ERROR|Exception|WARN|FATAL|Null check|LateInitialization|FOREIGN KEY'
```

**Expected:** No `[ERR]` lines from the Pantry App logger. `[WARN]`
lines should only be for expected conditions (e.g., "Failed to load
settings from SharedPreferences" on a fresh install if SharedPreferences
is empty — this is a `MissingPluginException` in tests but should not
appear on a real emulator).

**Red flags that indicate a bug:**
- `LateInitializationError`
- `Null check operator used on a null value`
- `FOREIGN KEY constraint failed` (after our FK fix)
- `SqfliteFfiException`
- `setState() called after dispose()`
- Any unhandled exception in the `flutter` tag

---

## 7. Post-test checklist

After all manual tests pass:

1. Check logcat for errors: `adb logcat -d | grep -E 'flutter.*ERR'` — should be empty
2. Verify database integrity: pull DB and check all tables have expected data
3. Confirm no crash dialogs appeared during testing (watch emulator screen)
4. Run `flutter analyze --fatal-infos --fatal-warnings` — clean
5. Run `flutter test --concurrency=2` — all pass
6. Run `flutter build apk --debug` — builds cleanly
7. Run `dart doc .` — 0 warnings, 0 errors

---

## 8. Troubleshooting

| Error | Fix |
|---|---|
| `emulator: GPU not found` | Use `-gpu swiftshader_indirect` instead of `-gpu host` |
| `adb: device unauthorized` | Check emulator screen for RSA fingerprint dialog; authorize it |
| `run-as: package not debuggable` | Build with `--debug`, not `--release` |
| `more than one device/emulator` | Use `adb -s emulator-5554 ...` or set `ANDROID_SERIAL` |
| `INSTALL_FAILED_UPDATE_INCOMPATIBLE` | Run `adb uninstall com.thigastech.pantry_app` first |
| OFF API returns errors during search test | Wait 30 seconds between runs; check internet on emulator |
| Emulator hangs during boot | Kill it, add `-no-snapshot -wipe-data`, try again |
| `.env` changes not reflected | Rebuild APK: `flutter build apk --debug` |
| Disk full on emulator | `adb emu kill && emulator -avd smoke_test -wipe-data` |
| sdkmanager not found | Set `ANDROID_HOME` and add `cmdline-tools/latest/bin` to `PATH` |
| KVM not available | Use `-gpu swiftshader_indirect`; check BIOS VT-x/AMD-V settings |

---

## Reference

- `emulator_instructions.md` — automated smoke test runner
- `integration_test/smoke_test.dart` — smoke test implementation
- `scripts/run_smoke_test.sh` — local emulator runner script
- [avdmanager](https://developer.android.com/tools/avdmanager)
- [emulator CLI](https://developer.android.com/studio/run/emulator-commandline)
- [sdkmanager](https://developer.android.com/studio/command-line/sdkmanager)
