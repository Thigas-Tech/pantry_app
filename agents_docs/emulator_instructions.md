# Emulator & Smoke Test Guide

## Quick start

    scripts/run_smoke_test.sh

This command creates AVD `smoke_test` (API 34, Pixel 5, x86\_64) if
missing, starts the emulator, waits for boot, and runs the smoke test
suite from `integration_test/smoke_test.dart`.

## Keeping the emulator alive

After the script finishes, the emulator stays running. For the next run:

    scripts/run_smoke_test.sh

The script detects the running device and skips boot, running only the
tests (~10s).

To kill the emulator manually:

    kill "$(pgrep -f 'emulator.*smoke_test')"

## Troubleshooting

| Error | Fix |
|---|---|
| `sdkmanager: command not found` | Set `ANDROID_HOME` and add `$ANDROID_HOME/cmdline-tools/latest/bin` to `PATH` |
| `failed to create AVD` | Run `sdkmanager "system-images;android-34;google_apis;x86_64"` manually first |
| `adb: no devices/emulators found` | Wait for boot; check `adb devices` |
| `.env not found` | The app needs `.env` to start. Copy `.env.example` to `.env` if missing |
| `flutter test ... no devices` | Ensure only one emulator is running |
| `KVM not available` | Check BIOS settings; on WSL2 use `--gpu swiftshader_indirect` |
| `avdmanager create avd` fails | Verify the system image is downloaded: `sdkmanager --list \| grep "system-images;android-34"` |

## Manual debugging

    adb logcat | grep flutter

## Reference

- `integration_test/smoke_test.dart` — smoke test implementation
- `scripts/run_smoke_test.sh` — local runner script
- Report issues at https://github.com/Thigas-Tech/pantry_app/issues
