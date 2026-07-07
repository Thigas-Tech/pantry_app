# Android Emulator Instructions

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

## References

- [avdmanager](https://developer.android.com/tools/avdmanager)
- [Emulator command line](https://developer.android.com/studio/run/emulator-commandline)
- [sdkmanager](https://developer.android.com/studio/command-line/sdkmanager)
