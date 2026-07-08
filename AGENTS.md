# AGENTS.md — Pantry App

## Pre-commit gate (NEVER SKIP)

Run BEFORE every local commit. Fix ALL issues:
  git fetch
  flutter analyze --fatal-infos --fatal-warnings
  flutter test --concurrency=2
  flutter build apk --debug
  dart doc .

## Pre-merge gate (run BEFORE creating a PR or converting draft to ready)

  1. Run smoke test: scripts/run_smoke_test.sh
  2. Push: git push -u origin <branch>
  3. Open a draft PR to trigger GitHub Actions.
  4. Verify ALL CI checks pass:
     - CI / Run static testing       (lint + formatting)
     - CI / Run unit testing
     - CI / Run widget testing
     - Build / Build debug apk       (from build.yml on PR)
  5. Convert draft PR -> Ready for Review.
  6. Merge via GitHub UI (Squash and merge).
  7. Delete remote branch; git checkout main && git pull

  Notes:
    - Feedback -> GitHub requires FEEDBACK_TOKEN in .env
    - Reference test product data in agents_docs/off_test_products.*

## Post-commit gate

Run AFTER every commit:
  flutter test --coverage --concurrency=2
  lcov --remove coverage/lcov.info \
    '*.g.dart' '*.freezed.dart' '*.gr.dart' '*.config.dart' \
    '*app_localizations*.dart' 'test/*' \
    -o coverage/lcov_cleaned.info --ignore-errors unused
  genhtml coverage/lcov_cleaned.info \
    -o coverage/html --ignore-errors source --num-spaces 2 --branch-coverage
  lcov --summary coverage/lcov_cleaned.info

Report at coverage/html/index.html
Fallback handling: see ~/.config/opencode/instructions/flutter_coverage_report.md

## Rules

0. Follow every rule. No exceptions.
1. Check TODO.md before starting new work.
2. /// doc comments on every public class, constructor, field, and method.
   These feed the public GitHub Wiki (see agents_docs/wiki.md). Write them
   as proper sentences — they are the user-facing API documentation.
3. Tests for ALL new code. Use mocktail. Place in test/ subdirectory.
4. After freezed or l10n changes: dart run build_runner build --delete-conflicting-outputs && flutter gen-l10n
5. Localize: all user-visible strings in lib/l10n/app_en.arb. Never hardcode English.
6. Update CHANGELOG.md for every feature, fix, or change. New dev-only ### section -> add to _devOnlySections in whats_new_sheet.dart.
7. Product() MUST pass source: 'api' or 'manual'. Never omit.
8. No emoji anywhere (code, docs, commits, ARB strings).
9. Audit every plan for pitfalls before writing code.
10. No backticks in doc comments. Ever. Use [square brackets] for cross-references. If comment_references fires, add the import — never switch to backticks. For constructor params (not referenceable), use the type: [http.Client]. Double-check every doc comment before committing.
11. Never ! on SQL aggregate results. Use ?? fallback instead.
12. Keep all markdown files ([README.md], [ARCHITECTURE.md], [CHANGELOG.md],
    [TODO.md], `agents_docs/*.md`) and `///` doc comments in sync with the
    codebase. After every feature, fix, or refactor, audit the affected docs
    in the same PR. When asked to find stale information, first consult
    `agents_docs/stale_info_checklist.md`.
13. Never overwrite .env. It is gitignored and contains credentials.
    - scripts/inject_env.sh uses `cat >.env` which truncates — never run it
      locally. It is only for CI (build, deploy workflows).
    - Never echo/redirect into .env from scripts or ad-hoc commands.
    - If .env is missing or empty, copy .env.example and fill in real values.
    - FEEDBACK_TOKEN is a GitHub PAT with repo scope. Create at
      https://github.com/settings/tokens (classic) or
      https://github.com/settings/tokens?type=beta (fine-grained).

## Pre-push gate (run BEFORE every push)

Run `scripts/install-hooks.sh` once after cloning the repo to install the
client-side hooks. The stale-info check will then fire automatically on
every `git push`. Use `git push --no-verify` to bypass.

### Automatic (git hook)

  - `scripts/check_stale_info.sh` runs on every `git push`, catching:
    - Wrong concurrency flag (`--concurrency=8` vs `--concurrency=2`)
    - Wrong retention-days in workflow files
    - Non-existent provider names in docs
    - Removed-dependency names (dio, connectivity_plus)
    - Removed-feature references (CSV import/export, quality_gate.sh)
  - Instant (< 1 s). Exit code 0 = pass, nonzero = fail.

### Manual steps

  1. Run smoke test: `scripts/run_smoke_test.sh`
      (integration_test/smoke_test.dart — app startup + 5 main tabs)
     Emulator-required. ~10 s on warm emulator, ~3 min first run.
  2. Audit stale docs: if `agents_docs/stale_info_checklist.md` hot spots
     are triggered by this branch, open the file and check the affected
     sections.

## Development workflow

- Branch from main: git checkout -b feat/description
- Implement -> pre-commit gate -> pre-push gate -> push
- Open draft PR -> wait for CI -> convert to ready -> merge
- Never commit directly to main.
- After merge: git checkout main && git pull

## Code style

80-char lines. Single quotes. const constructors. Riverpod providers.
unawaited() for fire-and-forget futures (import dart:async).

## Logging & feedback

- logInfo/logWarning/logError at every decision point (async ops start, cache hits/misses, guards, connectivity).
- SnackbarHelper for ALL user feedback. Never raw ScaffoldMessenger.showSnackBar().
- showUndo for EVERY destructive action (delete, move, clear).
- All SnackbarHelper strings MUST be localized via ARB.
- Never log secrets or PII.

## Reference docs

Read these when implementing specific features:
- Gestures & touch behaviors -> ~/.config/opencode/instructions/flutter_gestures.md
- Firebase / FlutterFire -> ~/.config/opencode/instructions/firebase_refs.md
- OFF API / SDK -> ~/.config/opencode/instructions/off_refs.md
- Performance optimization -> agents_docs/performance_guide.md
- Platform docs -> ~/.config/opencode/instructions/platform_refs.md
- Project architecture -> ARCHITECTURE.md
- API docs (generated) -> doc/api/ (run `dart doc .` first if missing)
- OFF test data -> agents_docs/off_test_products.*
- Wiki conventions -> agents_docs/wiki.md
