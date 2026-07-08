# Feature Freeze

- [x] feature_freeze

When checked, **no new features** may be added to the codebase.
Only bug fixes, pre-launch polish, and security patches are allowed.
The freeze MUST be lifted (uncheck the box in a follow-up PR) before
new feature work can be merged.

## Allowed during freeze

- Bug fixes with tests
- Accessibility improvements
- Performance optimizations
- Security patches
- Documentation updates
- CI/CD pipeline fixes
- l10n / ARB additions for existing features
- Database migrations required by fixes

## Blocked during freeze

- New screens or tabs
- New user-facing features or providers
- New packages or dependencies not related to fixes
- User-facing UI/UX changes (except a11y/perf fixes)
