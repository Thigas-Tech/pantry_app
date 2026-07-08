#!/usr/bin/env bash
set -euo pipefail

# Dart VM Service health check wrapper.
#
# Starts the emulator (if not running), launches the app in debug mode,
# extracts the VM Service URI from the flutter run output, runs the
# health check tool, then detaches from the app.
#
# Usage: bash scripts/health_check.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
AVD_NAME="smoke_test"

cd "$PROJECT_DIR"

# 1. Ensure emulator is running.
if ! adb get-state 2>/dev/null | grep -q device; then
	echo "Starting emulator..."
	emulator -avd "$AVD_NAME" -no-snapshot -noaudio -no-boot-anim &
	echo "Waiting for boot..."
	for i in $(seq 1 40); do
		if adb get-state 2>/dev/null | grep -q device &&
			[ "$(adb shell getprop sys.boot_completed 2>/dev/null)" = "1" ]; then
			echo "Emulator ready."
			break
		fi
		sleep 3
	done
else
	echo "Emulator already running."
fi

# 2. Launch app and capture VM Service URI.
TMPFILE=$(mktemp)
echo "Launching app..."

(
	sleep 45
	echo "d"
) | timeout 60 flutter run --debug >"$TMPFILE" 2>&1 || true

VM_URI=$(grep -oP 'ws://[^\s]+' "$TMPFILE" | head -1 || true)

if [ -z "$VM_URI" ]; then
	# Try http:// format and convert
	HTTP_URI=$(grep -oP 'http://127\.0\.0\.1:\d+/\S+/=' "$TMPFILE" | head -1 || true)
	if [ -n "$HTTP_URI" ]; then
		VM_URI="ws://${HTTP_URI#http://}"
	fi
fi

if [ -z "$VM_URI" ]; then
	echo "ERROR: Could not extract VM Service URI from flutter run output."
	echo "Output was:"
	cat "$TMPFILE"
	rm "$TMPFILE"
	exit 1
fi

rm "$TMPFILE"

echo "VM Service URI: $VM_URI"
echo ""

# 3. Run health check.
dart run tools/vm_health_check.dart "$VM_URI"
