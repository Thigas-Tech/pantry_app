# AGENTS.md — Pantry App

## Pre-commit gate (NEVER SKIP)

Run BEFORE every local commit. Fix ALL issues:
  git fetch
  dart analyze lib/ test/   # MUST report "No issues found!" — zero warnings AND infos
  flutter test --concurrency=2
  flutter build apk --debug
  dart doc .
  # If FEATURE_FREEZE.md is checked, verify only fixes + polish are included.
  grep -q '[x] feature_freeze' FEATURE_FREEZE.md && \
    echo "FEATURE FREEZE ACTIVE — only bug fixes and polish allowed" || true

## Pre-merge gate (run BEFORE creating a PR or converting draft to ready)

  1. Push: git push -u origin <branch>
  3. Open a draft PR to trigger GitHub Actions.
  4. Verify ALL CI checks pass:
     - CI / Run static testing       (lint + formatting)
     - CI / Run unit testing
     - CI / Run widget testing
     - Build / Build debug apk       (from build.yml on PR)
  5. Convert draft PR -> Ready for Review.
   6. Merge via GitHub UI (Squash and merge).
      BEFORE clicking merge, paste `Fixes #<issue>` lines into the
      **commit message** (not just PR body). Use one line per issue
      with a separate `Fixes` keyword (e.g. `Fixes #1\nFixes #2`).
      Comma-separated lists like `Fixes #1, #2` do NOT auto-close.
      GitHub only auto-closes from squash merge commit messages,
      not PR bodies.
   7. Delete remote branch; git checkout main && git pull

  Notes:
    - Feedback -> GitHub requires FEEDBACK_TOKEN in .env
    - Reference test product data in docs/superpowers/agents/off_test_products.*

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

0. Before starting any feature work, check [FEATURE_FREEZE.md]. If
   feature_freeze is checked, only bug fixes, polish, a11y/perf
   improvements, and documentation are allowed. New features MUST be
   deferred until the freeze is lifted.
1. Follow every rule. No exceptions.
2. Check [TODO.md] before starting new work.
3. /// doc comments on every public class, constructor, field, and method.
   These feed the public GitHub Wiki (see docs/superpowers/agents/wiki.md). Write them
   as proper sentences — they are the user-facing API documentation.
4. Tests for ALL new code. Use mocktail. Place in test/ subdirectory.
5. After freezed or l10n changes: dart run build_runner build --delete-conflicting-outputs && flutter gen-l10n
6. Localize: all user-visible strings in lib/l10n/app_en.arb. Never hardcode English.
7. Update CHANGELOG.md (developer-facing) and USER_CHANGELOG.md (user-facing) for every feature, fix, or change. The USER_CHANGELOG.md must contain only user-facing information with no implementation details. When USER_CHANGELOG.md is modified, also update USER_CHANGELOG_pt.md and USER_CHANGELOG_pt_BR.md with the same entries translated.
8. Product() MUST pass source: 'api' or 'manual'. Never omit.
9. No emoji anywhere (code, docs, commits, ARB strings).
10. Audit every plan for pitfalls before writing code.
11. No backticks in doc comments. Ever. Use [square brackets] for cross-references. If comment_references fires, add the import — never switch to backticks. For constructor params (not referenceable), use the type: [http.Client]. Double-check every doc comment before committing.
12. Never ! on SQL aggregate results. Use ?? fallback instead.
13. Keep all markdown files ([README.md], [ARCHITECTURE/INDEX.md], [CHANGELOG.md],
    [TODO.md], `docs/superpowers/agents/*.md`) and `///` doc comments in sync with the
    codebase. After every feature, fix, or refactor, audit the affected docs
    in the same PR. When asked to find stale information, first consult
    `docs/superpowers/agents/stale_info_checklist.md`.
14. Never overwrite .env. It is gitignored and contains credentials.
    - Never echo/redirect into .env from scripts or ad-hoc commands.
    - If .env is missing or empty, copy .env.example and fill in real values.
    - FEEDBACK_TOKEN is a GitHub PAT with repo scope. Create at
      https://github.com/settings/tokens (classic) or
      https://github.com/settings/tokens?type=beta (fine-grained).

## Development workflow

- Branch from main: git checkout -b feat/description
- Implement -> pre-commit gate -> push
- Open draft PR -> wait for CI -> convert to ready -> merge
- Device builds inject the .env credentials at build time (the .env is never
  bundled as an asset): `flutter run --dart-define-from-file=.env` or
  `flutter build apk --debug --dart-define-from-file=.env`. The plain
  `flutter build apk --debug` in the pre-commit gate intentionally builds
  WITHOUT credentials — USDA produce search and OFF submission degrade
  gracefully when their credential is absent. The Play Store release
  workflow recreates .env from GitHub secrets for the same flag.
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
- OFF API / SDK -> ~/.config/opencode/instructions/off_refs.md
- Platform docs -> ~/.config/opencode/instructions/platform_refs.md
- Project architecture -> ARCHITECTURE/INDEX.md
- API docs (generated) -> doc/api/ (run `dart doc .` first if missing)
- Project-specific guides and testing procedures -> docs/superpowers/agents/ directory
  (read the relevant file for each task)
