# Android Emulator Instructions

NOTE: Emulator smoke testing is no longer part of the pre-merge gate.
This document remains as a reference for manual debugging.

Instructions for `opencode` agents to create, start, and manage an Android
emulator from the command line.

## Environment

The Android SDK is already installed and configured:

```bash
export ANDROID_SDK_ROOT=$HOME/Android/sdk
export ANDROID_HOME=$HOME/Android/sdk
export PATH=$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/emulator:$ANDROID_HOME/platform-tools:$PATH
```

SDK command-line tools (`sdkmanager`, `avdmanager`) are available.

## Starting the emulator

```bash
emulator -avd my_avd -accel on
```

The AVD `my_avd` uses API 30 (Android 11), x86_64, with Google APIs.

### Headless mode (no GUI window)

```bash
emulator -avd my_avd -accel on -no-window
```

### Wait for boot

After starting the emulator, wait until the device appears:

```bash
adb wait-for-device
sleep 10  # extra time for system to settle
flutter devices  # should show the emulator
```

## Listing available AVDs

```bash
emulator -list-avds
```

## Creating a new AVD

```bash
sdkmanager --install "system-images;android-30;google_apis;x86_64"

avdmanager create avd -n my_avd \
  -k "system-images;android-30;google_apis;x86_64" \
  --device "pixel_5"
```

## Useful commands

| Command | Description |
|---------|-------------|
| `adb devices -l` | List connected devices |
| `adb install <path>.apk` | Install an APK |
| `adb uninstall <package>` | Remove an app |
| `adb shell am start -n <pkg>/.MainActivity` | Launch an app |
| `adb shell input tap <x> <y>` | Tap at coordinates |
| `adb shell input text "hello"` | Type text into focused field |
| `adb shell uiautomator dump /sdcard/ui.xml` | Dump UI hierarchy |

## Managing AVDs

| Command | Description |
|---------|-------------|
| `avdmanager list avd` | List all AVDs |
| `avdmanager delete avd -n <name>` | Delete an AVD |

## Testing workflow (always run before declaring a feature done)

### 1. Build and install

Always use a **debug build** for access to full logs:

```bash
flutter build apk --debug
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

Or run directly:

```bash
flutter run --debug -d emulator-5554
```

### 2. Test the SearchBar changes

1. Tap the **Search** tab (2nd nav item, x≈405 on 1080-wide screen).
2. Tap the search bar (y≈100).
3. Type a product name (e.g. `milk`) to verify the `SearchBar` widget responds.
4. Tap the clear icon (trailing `Icons.clear`) — verify the search resets.
5. Verify the `textInputAction` is `TextInputAction.search`.
6. Check logs for any errors related to `SearchBar` or `TextField`.

### 3. Test the feedback offline/online workflow

1. **Enable airplane mode** on the emulator:
   ```bash
   adb shell settings put global airplane_mode_on 1
   ```

2. **Navigate to Settings** (4th nav tab, x≈945 on 1080-wide screen).
3. Scroll down to the **About** section (the last `ExpansionTile`).
4. Tap **About** to expand it.
5. Tap **Send Feedback**.
6. Fill in title (min 5 chars) and description (min 10 chars).
7. Tap **Create Issue** — verify the offline queue message: `"You are offline. Your report will be submitted when you are back online."`
8. Check logs for `"Feedback _submit: isOnline=false screenshotCount=..."`.
9. Check logs for `"Feedback queued"` confirmation.

10. **Disable airplane mode**:
    ```bash
    adb shell settings put global airplane_mode_on 0
    ```

11. Wait 5-10 seconds for connectivity to restore.
12. Check logs for `"Feedback queue flush"` or `"No queued issues to flush"`.
13. Verify the GitHub issue was actually created at:
    `https://github.com/{GITHUB_OWNER}/{GITHUB_REPO}/issues`

### 4. Test the notification denial warning

1. Uninstall and reinstall the app:
   ```bash
   adb uninstall com.thigas_tech.pantry_app && adb install build/app/outputs/flutter-apk/app-debug.apk
   ```

2. Launch the app:
   ```bash
   adb shell am start -n com.thigas_tech.pantry_app/.MainActivity
   ```

3. When the system notification permission dialog appears, tap **Deny**.
4. Verify the warning snackbar appears: `"Notifications are disabled. Expiry and inactivity reminders will only show when you open the app. Enable them in Settings at any time."`
5. Check logs for `"Notification permission denied — flagged warning for PantryShell"`.

### 5. Test the inactivity reminder

1. Add a product to the pantry (scan a barcode or enter manually).
2. Verify log line: `"Cancelling inactivity reminder"` followed by inactivity scheduling logs.
3. Navigate to **Settings > Notifications** — verify the "Remind me to add products regularly" toggle is present and defaults to ON.
4. Tap the inactivity threshold tile — verify the dialog opens with default value 10.

### 6. Screen coordinate reference

For 1080×1920 emulator (Pixel 5):
| Element | Approximate tap (x, y) |
|---------|----------------------|
| Nav: Home | (135, 1880) |
| Nav: Search | (405, 1880) |
| Nav: Stats | (675, 1880) |
| Nav: Settings | (945, 1880) |
| SearchBar field | (540, 100) |
| Search results list | (540, 400)..(540, 1600) |
| Settings: ExpansionTile icons | (100, y_scrolled) |
| Settings: ListTile text | (400, y_scrolled) |
| Dialog: Create button | (540, 1200) |
| Feedback: Create Issue | (540, 1600) |

## References

- [avdmanager](https://developer.android.com/tools/avdmanager)
- [Emulator command line](https://developer.android.com/studio/run/emulator-commandline)
- [sdkmanager](https://developer.android.com/studio/command-line/sdkmanager)
