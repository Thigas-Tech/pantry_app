#!/usr/bin/env bash
set -euo pipefail

echo "=== Quality Gate ==="

echo "--- dart format ---"
dart format --output=none --set-exit-if-changed .

echo "--- flutter analyze ---"
flutter analyze --fatal-infos --fatal-warnings

echo "--- flutter test ---"
flutter test --no-pub --concurrency=2 --coverage

echo "=== Quality Gate PASSED ==="
