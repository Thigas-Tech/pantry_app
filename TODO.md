# TODO.md — Pantry App Roadmap

Items are organised by effort (low → high) and importance (critical → nice-to-have).

---

## Quick Wins (low effort, high impact)

- [ ] **Batch delete** — multi-select items via checkboxes, delete all selected. Reuses existing `deleteInventoryItem` + undo snackbar.
- [ ] **Expiry date guard** — date picker min-date = today; validate before saving.
- [ ] **Quick quantity adjustment** — `+/−` buttons on each inventory tile in `ProductDetailScreen`. Tap quantity to type a number directly (e.g. used 3 of 12 eggs at breakfast). Decrementing to 0 deletes the item with confirmation + undo. Re-schedules notifications on restore.
- [ ] **Coverage: `stats_screen.dart`** (32.8%) — test export + import button flows.
- [ ] **Coverage: `home_screen.dart`** (65.1%) — test create-pantry dialog, pull-to-refresh.
- [ ] **Coverage: `add_product_screen.dart`** (58.8%) — test form validation + save-and-pop.
- [ ] **Coverage: `add_to_inventory_screen.dart`** (65.8%) — test custom unit/location dialogs.
- [ ] **Coverage: `inventory_card.dart`** (65.5%) — test tap navigation, image cache miss.
- [ ] **Coverage: `connectivity_provider.dart`** (33.3%) — stream emission test.

## Code Health (low/medium effort)

- [ ] **Extract expiry-date parsing** — duplicated in `home_screen.dart`, `product_detail_screen.dart`, `inventory_card.dart`. Extract to a shared utility `DateTime? parseExpiry(String?)`.
- [ ] **Deduplicate custom picker dialogs** — `_pickCustomUnit` and `_pickCustomLocation` in `add_to_inventory_screen.dart` are structurally identical; parameterise.
- [ ] **Deduplicate settings dialogs** — `_showRetentionDialog` and `_showExpiringSoonDialog` share structure; extract a builder.
- [ ] **Screenshots section** — add actual PNGs to `README.md` or remove the placeholder table.
- [ ] **Remove unused `product_api_service.dart`** or add a stub test for `close()`.
- [ ] **Golden tests for `NutriScoreBadge`** — verify A–E colours render correctly via `matchesGoldenFile`.
- [ ] **Accessibility audit** — add Semantics traversal tests for inventory cards, badges, dialogs.

## Features (medium effort)

- [ ] **Shopping list** — tab or separate screen; mark items as "to buy" with a toggle. Items appear in a dedicated list until purchased (then move to inventory).
- [ ] **Barcode history** — show the last N scanned barcodes with quick-add button. Persist to SQLite.
- [ ] **Category filter** — dropdown/filter chip on home screen to filter items by product category.
- [ ] **Stock count badge** — show "N items" and "added this week" on the home screen app bar or stats page.
- [ ] **Empty-pantry onboarding** — when inventory is empty, show a guided "scan your first item" flow instead of just the empty state widget.
- [ ] **Offline-first product submission queue** — queue `submitProduct` calls when offline; flush when `connectivityProvider` emits `true`.
- [ ] **Cloud backup** — upload DB to Firebase Storage / S3. Restore on a new device.
- [ ] **Serving‑size & Nutri‑Score in manual entry** — `add_product_screen.dart` already has the fields; verify they are wired and tested.

## Larger Projects (high effort)

- [ ] **Multi‑language support** — ARB infrastructure exists; add translations (pt, fr, es, de). Contribute via community PRs.
- [ ] **Recipe suggestions** — call a recipe API with items expiring this week; suggest meals that use them.
- [ ] **Widget test → golden coverage** — product detail, settings, stats screens.
- [ ] **Patrol E2E tests** — real‑device integration tests via [Patrol](https://patrol.leancode.co). Uses `patrol_cli` and `patrol` dev-dependency. Replace the generic `integration_test/` with `patrol_test/` directory.

### Patrol E2E test scenarios

- [ ] **Setup** — install `patrol_cli`, add `patrol` to `dev_dependencies`, configure `pubspec.yaml` (`pacakge_name`, `bundle_id`), create `patrol_test/`, gitignore `test_bundle.dart`.
- [ ] **Scan → add to inventory** — tap FAB, simulate barcode scan, verify product detail appears, add item, verify home screen shows it.
- [ ] **Offline scan → manual entry** — simulate offline, scan barcode, verify manual entry screen opens, fill form, save, verify product cached.
- [ ] **Quantity adjustment flow** — open product detail, tap + 3×, verify quantity, tap − to 0, confirm delete, verify item gone.
- [ ] **Notification flow** — add item with expiry tomorrow, background the app, advance time, verify notification appears.
- [ ] **Inventory switch** — tap dropdown, select different pantry, verify items change.
- [ ] **CSV export → import round‑trip** — export inventory, import the same CSV, verify item count.

## CI/CD & DevOps

- [ ] **GitHub Actions — CI pipeline** — on every PR and push to `main`:
  - `flutter analyze` (lint check)
  - `dart format --set-exit-if-changed .` (formatting check, not force‑format)
  - `flutter test --concurrency=8 --coverage` (tests + coverage report)
  - Upload coverage artifact, fail if tests fail.
- [ ] **GitHub Actions — Play Store deployment** — on new tag (`v*`):
  - `flutter build appbundle` + `flutter build apk` (release)
  - Upload both to Google Play Console via `r0adkll/upload-google-play`
  - Requires Play Store service account JSON stored as a GitHub secret.
- [ ] **GitHub Actions — Patrol E2E on schedule** — weekly run of the Patrol test suite on a real Android emulator (GitHub‑hosted runner).

## Documentation (quick wins)

- [ ] `ARCHITECTURE.md` — add security section (dotenv env-var handling, no-committed-secrets rule).
- [ ] `ARCHITECTURE.md` — add offline-first pattern diagram or ASCII flow.
- [ ] `AGENTS.md` — add "always check TODO.md before starting new work" instruction.

---

## Effort × Importance Matrix

```
                     Low effort ─────────── High effort
                     ─────────────────────────────────────
High importance  │ Batch delete            │ Shopping list
                 │ Quick quantity adjust   │ Offline submission queue
                 │ Expiry date guard       │ Cloud backup
                 │ Expiry parsing extract  │ GitHub CI pipeline
                 │─────────────────────────│──────────────────────────
                 │ Golden tests            │ Multi-language
                 │ Accessibility audit     │ Recipe suggestions
                 │ Stock count badge       │ Patrol E2E tests
                 │ Screenshots             │ Play Store CI deploy
Low importance   │ Empty-pantry onboarding │ Barcode history
                 │ Category filter         │
```
