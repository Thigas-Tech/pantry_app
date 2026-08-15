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

## 2. `ARCHITECTURE/INDEX.md`

| Location | Staleness trigger |
|---|---|
| `ARCHITECTURE/OVERVIEW.md` — architecture diagram | Any layer added, removed, or renamed |
| `ARCHITECTURE/DATABASE.md` — schema version & migration table | Schema bumped in `_onUpgrade` or new migration added |
| `ARCHITECTURE/SERVICES.md` — each service subsection | Service added, removed, or rewritten |
| `ARCHITECTURE/PROVIDERS.md` — provider table | Provider added, removed, or renamed |
| `ARCHITECTURE/UI_STRUCTURE.md` — screen/widget tree | Screen widget tree changes |
| `ARCHITECTURE/PERFORMANCE.md` — CI/CD pipeline table (section 11.8) | Workflow added, renamed, or trigger changed |
| `ARCHITECTURE/INDEX.md` — design decisions | New pattern adopted or old one abandoned |
| `ARCHITECTURE/PRICE_TRACKING.md` — local data model / sync / proof sections | Schema version bumped, Open Prices sync stops being a local placeholder, proof upload implemented, price entry gains package-size fields |
| `docs/superpowers/agents/monetization.md` | Any monetization features implemented or deferred |

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

## 7. `docs/superpowers/agents/*.md` and `docs/superpowers/plans/*.md`

| File | Staleness trigger |
|---|---|
| `playstore.md` | CI/CD deploy workflow changed |
| `play_console_later.md` | Play Console verification complete |
| `FEATURE_FREEZE.md` | Feature freeze checkbox added or removed |
| `wiki.md` | Wiki CI workflow changed |

---

## Common dead-information patterns

These patterns reappear frequently. Search for them when auditing:

- **Removed feature mentioned as current**: CSV import/export, Dio, `exportData()`
- **Price tracking described as fully synced**: Open Prices sync currently marks prices `synced` locally without HTTP, there is no `proof_image_path` column, and `submitPrice` does not send `price_per` yet (see `ARCHITECTURE/PRICE_TRACKING.md`)
- **Non-existent provider listed**: `adServiceProvider`, `donationServiceProvider`, `firebaseServiceProvider`, `cloudBackupServiceProvider`, `backupStatusProvider`, `isProProvider`, `isAdFreeProvider`, `firebaseCacheProvider`, `authServiceProvider`, `authStateProvider` (all Firebase and auth providers were removed with Firebase)
- **Implemented feature marked `[ ]`**: Check `TODO.md` against actual source files
- **Contradictory `[Unreleased]` entries**: Earlier changelog sections may describe the true current state
- **Wrong dependency name**: `connectivity_plus` vs `internet_connection_checker`, `dio` vs `http`
- **Wrong concurrency flag**: `--concurrency=8` vs `--concurrency=2`
- **Wrong artifact retention**: 7 days vs 90 days
- **Deploy workflow described as active**: Tag trigger may be commented out
- **ARCHITECTURE.md referenced as flat file**: Was restructured to `ARCHITECTURE/INDEX.md` directory. Search for bare `ARCHITECTURE.md` references across all `.md` files
- **Bottom sheet without system nav bar padding**: Search for `showModalBottomSheet` in `lib/widgets/` and verify each one has `MediaQuery.of(context).padding.bottom` or equivalent. See `docs/superpowers/agents/bottom_sheet_safe_area.md` for the pattern.
