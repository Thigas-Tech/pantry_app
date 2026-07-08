# Stale Info Checklist

When asked to audit for stale or outdated documentation, check these
hot spots in order. Each entry lists the trigger that makes it stale.

---

## 1. `README.md`

| Location | Staleness trigger |
|---|---|
| Features list (lines 11-27) | Feature added or removed |
| Tech stack table (lines 138-152) | Dependency added, removed, or replaced |
| Project structure tree (lines 94-111) | File created or deleted under `lib/` |
| Build commands (lines 78-90) | Flags changed or new build variants added |

## 2. `ARCHITECTURE.md`

| Location | Staleness trigger |
|---|---|
| Architecture diagram (lines 10-54) | Any layer added, removed, or renamed |
| DB schema version (line 60) | Schema bumped in `_onUpgrade` |
| Migration table (lines 99-111) | New migration added |
| Service sections 3.x | Service added, removed, or rewritten |
| Provider table (lines 242-268) | Provider added, removed, or renamed |
| Screen/widget structure (lines 273-333) | Screen widget tree changes |
| CI/CD pipeline table (lines 504-519) | Workflow added, renamed, or trigger changed |
| Design decisions (lines 394-418) | New pattern adopted or old one abandoned |
| Monetization / cloud / ads sections | Any of those features implemented or deferred |

## 3. `TODO.md`

| Location | Staleness trigger |
|---|---|
| Any `[ ]` checkbox | Feature implemented (mark `[x]`) |
| Any `[x]` checkbox | Implementation details change |
| Play Console block (top) | Document verification complete |
| "Deploy workflow" items | Workflow file created or enabled |
| DB version references | Schema version bumped |

## 4. `CHANGELOG.md`

| Location | Staleness trigger |
|---|---|
| `[Unreleased]` entries | Earlier changelog entries contradict them |
| Test counts | Tests added or removed |
| Dependency names | Dependency replaced (e.g. `dio` -> `http`) |
| Feature descriptions | Feature behaviour changes after rewrite |

## 5. `pubspec.yaml`

| Location | Staleness trigger |
|---|---|
| `description` field | App focus changes |
| Dependency list | Package added or removed |
| Version number | Release tagged |

## 6. Doc comments (`///` in `.dart` files)

| Location | Staleness trigger |
|---|---|
| Backtick-cross-reference mismatch | New public class/method added — rule 10 requires `[square brackets]` not backticks for type refs |
| `toMap()` / `fromMap()` on DAOs | Column added or removed |
| Provider doc comments | Provider type changed (e.g. `Provider` -> `FutureProvider`) |
| Screen doc comments | Widget tree or navigation flow changed |

## 7. `agents_docs/*.md`

| File | Staleness trigger |
|---|---|
| `playstore.md` | CI/CD deploy workflow changed |
| `play_console_later.md` | Play Console verification complete |
| `emulator_instructions.md` | Smoke test script or AVD config changed |
| `manual_testing_guide.md` | Smoke test, emulator script, or AVD config changed |
| `FEATURE_FREEZE.md` | Feature freeze checkbox added or removed |
| `wiki.md` | Wiki CI workflow changed |

---

## Common dead-information patterns

These patterns reappear frequently. Search for them when auditing:

- **Removed feature mentioned as current**: CSV import/export, Dio, `quality_gate.sh`, `exportData()`
- **Non-existent provider listed**: `adServiceProvider`, `donationServiceProvider`, `firebaseServiceProvider`, `cloudBackupServiceProvider`, `backupStatusProvider`, `isProProvider`, `isAdFreeProvider`
- **Implemented feature marked `[ ]`**: Check `TODO.md` against actual source files
- **Contradictory `[Unreleased]` entries**: Earlier changelog sections may describe the true current state
- **Wrong dependency name**: `connectivity_plus` vs `internet_connection_checker`, `dio` vs `http`
- **Wrong concurrency flag**: `--concurrency=8` vs `--concurrency=2`
- **Wrong artifact retention**: 7 days vs 90 days
- **Deploy workflow described as active**: Tag trigger may be commented out
