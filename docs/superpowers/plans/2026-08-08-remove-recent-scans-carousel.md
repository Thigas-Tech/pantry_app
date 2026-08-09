# Remove Recent Scans Carousel Implementation Plan

**Goal:** Remove the "Recent scans" carousel from the home screen (issue #299)
because it pollutes the UI. Users still reach products through search, the
pantry, and the scanner.

**Architecture:** The carousel is purely presentational. The scan-history
backend stays intact: the scanner still records every successful scan into
the `scan_history` table via `ScanHistory.record`. Only the home-screen
wiring, the `RecentScansSection` widget, the `quickAdd` path, and the
orphaned l10n keys are deleted.

**Tech Stack:** Flutter/Dart, Riverpod, mocktail, ARB l10n.

## Global Constraints

- Keep 80-char lines, single quotes, const constructors
- /// doc comments on every public member
- Tests for ALL new/changed code (use mocktail)
- No emoji in code, docs, commits, or ARB strings
- Do not delete the scan-history backend (`scanHistoryProvider`, DAO, model)
- Remove l10n keys from all three ARB files in one change, then run
  `flutter gen-l10n`
- Run `dart analyze lib/ test/`, `flutter test --concurrency=2`,
  `flutter build apk --debug`, and `dart doc .` before committing

---

### Task 1: Regression test (RED)

Replace the `Recent scans section` group in `test/screens/home_screen_test.dart`
with a single non-vacuous test that seeds non-empty scan history and asserts
the section text, an entry name, and the quick-add icon are all absent.
Run the test before touching production code to confirm it fails.

### Task 2: Remove the section from the home screen (GREEN)

In `lib/screens/home_screen.dart`:
- Delete `_buildRecentScans`, `_quickAdd`, `_openProduct`, and the wiring line
  that gated the section on selection mode and onboarding.
- Remove the now-unused imports (`scan_history_entry`, `scan_history_provider`,
  `product_repository_provider`, `exceptions`, `logger`,
  `recent_scans_section`).
- Run the updated home screen test to confirm it passes.

### Task 3: Delete the widget and its test

`git rm lib/widgets/recent_scans_section.dart test/widgets/recent_scans_section_test.dart`

### Task 4: Remove the quickAdd path

- In `lib/providers/scan_history_provider.dart`, delete `quickAdd` and the
  imports it was the only consumer of (`inventory_item`, `product`,
  `active_inventory_provider`, `pantry_provider`, `product_repository_provider`,
  `logger`). Keep `record` and `clear`.
- In `test/providers/scan_history_provider_test.dart`, delete the `quickAdd`
  group plus the now-dead `mockRepo`, `_TestActiveInventoryNotifier`,
  `activeInventoryProvider` override, `productRepositoryProvider` override,
  and unused imports (including `mocktail`, `pump_app`).
- Run the provider and scanner-history tests.

### Task 5: l10n cleanup

Remove `recentScans`, `quickAdd`, `quickAddAdded`, `quickAddFailed` from
`lib/l10n/app_en.arb`, `app_pt.arb`, and `app_pt_BR.arb`. Run
`flutter gen-l10n` and `flutter test test/l10n/arb_integrity_test.dart`.

### Task 6: Docs sync

- `README.md`: drop the "Recent scans strip / one-tap quick-add" claim from
  the barcode-history bullet.
- `ARCHITECTURE/UI_STRUCTURE.md`: remove the `RecentScansSection` tree line.
- `CHANGELOG.md`: add a `### Removed` entry under Unreleased.
- `USER_CHANGELOG.md` + `USER_CHANGELOG_pt.md` + `USER_CHANGELOG_pt_BR.md`:
  add a user-facing entry describing the cleaner home screen.

### Task 7: Pre-commit gate

`git fetch`, `dart analyze lib/ test/` (No issues found!),
`flutter test --concurrency=2`, `flutter build apk --debug`,
`dart doc .`, confirm the feature freeze is not active.

---

## Pitfalls and edge cases

- A naive "section not rendered" test passes even before the fix if history
  is empty; the regression test seeds non-empty history to be meaningful.
- `dart analyze` fails on unused imports, so every deletion must be audited
  for orphaned imports (in source and test files).
- `scanHistoryProvider` still has a live consumer (the scanner records scans),
  so the provider, DAO, table, and model are NOT removed.
- l10n keys must be removed from all three locales at once or
  `arb_integrity_test.dart` fails and gen-l10n silently falls back to English.
- The home screen golden test never stubbed `getRecentScanHistory`, so no
  golden re-baseline is required.
