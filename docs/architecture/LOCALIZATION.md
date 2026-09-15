## 7. Localization (`lib/l10n/`)

- Source: `app_en.arb` (English).
- Generated code in `lib/l10n/app_localizations*.dart`.
- **All user-visible strings** must be in `app_en.arb` — never hardcoded.
- After changing ARB files, run `flutter gen-l10n`.
