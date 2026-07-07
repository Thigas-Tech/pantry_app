# AGENTS.md — Pantry App

## Pre-commit gate (NEVER SKIP)

Run before EVERY commit. Fix ALL issues:
  flutter analyze --fatal-infos --fatal-warnings
  flutter test --concurrency=8
  flutter build apk --debug
  dart doc .

## Rules

0. Follow every rule. No exceptions.
1. Check TODO.md before starting new work.
2. /// doc comments on every public class, constructor, field, and method.
3. Tests for ALL new code. Use mocktail. Place in test/ subdirectory.
4. After freezed or l10n changes: dart run build_runner build --delete-conflicting-outputs && flutter gen-l10n
5. Localize: all user-visible strings in lib/l10n/app_en.arb. Never hardcode English.
6. Update CHANGELOG.md for every feature, fix, or change. New dev-only ### section -> add to _devOnlySections in whats_new_sheet.dart.
7. Product() MUST pass source: 'api' or 'manual'. Never omit.
8. No emoji anywhere (code, docs, commits, ARB strings).
9. Audit every plan for pitfalls before writing code.
10. No backticks in doc comments. Ever. Use [square brackets] for cross-references. If comment_references fires, add the import — never switch to backticks. For constructor params (not referenceable), use the type: [http.Client]. Double-check every doc comment before committing.
11. Never ! on SQL aggregate results. Use ?? fallback instead.
12. Sync before work: git fetch && git pull --rebase.

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
- Performance optimization -> ~/.config/opencode/instructions/performance_guide.md
- Platform docs -> ~/.config/opencode/instructions/platform_refs.md
- Project architecture -> ARCHITECTURE.md
