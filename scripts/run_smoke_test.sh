#!/usr/bin/env bash
set -euo pipefail

AVD_NAME="smoke_test"
API_LEVEL=34
ARCH="x86_64"
DEVICE="pixel_5"
BOOT_TIMEOUT=120
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"

# 1. Check for Android SDK tools.
if ! command -v sdkmanager &>/dev/null || ! command -v avdmanager &>/dev/null; then
	echo "ERROR: Android SDK tools not found."
	echo "  Set ANDROID_HOME and add cmdline-tools/latest/bin to PATH:"
	echo "  export ANDROID_HOME=\$HOME/Android/sdk"
	echo "  export PATH=\$ANDROID_HOME/cmdline-tools/latest/bin:\$PATH"
	exit 1
fi

# 2. Create AVD if missing.
if ! avdmanager list avd -c | grep -q "$AVD_NAME"; then
	echo "Creating AVD $AVD_NAME (API $API_LEVEL)..."
	echo no | avdmanager create avd \
		-n "$AVD_NAME" \
		-k "system-images;android-$API_LEVEL;google_apis;$ARCH" \
		-d "$DEVICE" --force
fi

# 3. Start emulator if not already running.
EMULATOR_STARTED=false
if ! adb get-state 2>/dev/null | grep -q device; then
	echo "Starting emulator..."
	"$ANDROID_HOME/emulator/emulator" \
		-avd "$AVD_NAME" \
		-no-window \
		-gpu swiftshader_indirect \
		-no-snapshot \
		-noaudio \
		-no-boot-anim &
	EMULATOR_PID=$!
	EMULATOR_STARTED=true
else
	echo "Emulator already running."
fi

# 4. Wait for boot.
echo "Waiting for device to boot..."
timeout "$BOOT_TIMEOUT" bash -c '
  while [[ "$(adb shell getprop sys.boot_completed 2>/dev/null)" != "1" ]]; do
    sleep 3
  done
' || {
	echo "ERROR: Emulator did not boot within ${BOOT_TIMEOUT}s."
	exit 1
}
echo "Device booted."

# Disable animations for faster test execution.
adb shell settings put global window_animation_scale 0 &>/dev/null || true
adb shell settings put global transition_animation_scale 0 &>/dev/null || true
adb shell settings put global animator_duration_scale 0 &>/dev/null || true

# 5. Verify .env exists (read-only check).
if [ ! -f .env ]; then
	echo "ERROR: .env not found in project root."
	echo "  The app requires a .env file at startup. Copy .env.example if available."
	exit 1
fi

# 6. Run smoke tests.
echo "Running smoke tests..."
flutter test integration_test/

# 7. Report result.
RESULT=$?
if [ $RESULT -eq 0 ]; then
	echo "Smoke tests PASSED."
else
	echo "Smoke tests FAILED (exit code $RESULT)."
fi

if [ "$EMULATOR_STARTED" = true ]; then
	echo "Emulator left running (PID $EMULATOR_PID). Kill it when done:"
	echo "  kill $EMULATOR_PID"
fi

exit $RESULT
