# Onboarding Enhancements — Design Spec

## Objective

Extend the onboarding flow from 4 static showcase pages to 5 pages, adding
interactive configuration and fixing three UX issues:

1. FAB overlaps the bottom navigation bar during onboarding.
2. No way to navigate backward through the pages.
3. Page 3 ("Fresh Produce") CTA duplicates the FAB action sheet instead of
   guiding the user toward produce-specific functionality.

## Flow

```
Page 1: Scan Barcodes     → CTA: Open Scanner     → Navigator.push(ScannerScreen)
Page 2: Search Products    → CTA: Open Search       → Navigator.push(SearchScreen)
Page 3: Fresh Produce      → CTA: Search Produce    → Navigator.push(SearchScreen, filter: produce)
Page 4: Configure Pantry   → CTA: Set Up            → Persists settings, advances page
Page 5: Track Everything   → CTA: Get Started       → markComplete()
```

## Changes

### 1. FAB hidden during onboarding

**File**: `lib/screens/home_screen.dart` (line ~405)

Add `!onboardingComplete` to the existing FAB visibility condition:

```dart
floatingActionButton: (controller.selectionMode || !onboardingComplete)
    ? null
    : FloatingActionButton(...)
```

### 2. Back button

**File**: `lib/widgets/onboarding_flow.dart` — bottom bar

Add a `TextButton("Back")` on the left side of the bottom `Row`, visible only
when `_currentPage > 0`. Calls `_pageController.previousPage()`.

Bottom bar layout: `[Back (p2-5)] [spacer] [animated dots] [spacer] [Next / Get Started]`

New ARB key: `onboardingBack` ("Back").

### 3. Page 3 CTA — Search with filter

**Files**:
- `lib/screens/search_screen.dart` — filter support
- `lib/screens/home_screen.dart` — page 3 CTA wiring

#### `SearchFilter` enum

```dart
enum SearchFilter { all, produce, barcodedProducts, inPantry }
```

`inPantry` is declared but its implementation is deferred to a follow-up
GitHub issue (needs inventory cross-reference logic).

#### `SearchScreen` API

```dart
const SearchScreen({SearchFilter? initialFilter, super.key});
```

When `initialFilter` is provided:
- Show a `DropdownButton<SearchFilter>` below the search bar with options:
  All, Produce, Barcoded, In Pantry (disabled with "(coming soon)" suffix)
- The initialFilter option is pre-selected
- Client-side filter applied to results:
  - `all`: no filtering (current behavior)
  - `produce`: `product.productType == ProductType.produce`
  - `barcodedProducts`: `product.productType != ProductType.produce`
  - `inPantry`: no-op until follow-up
- Selecting `all` removes all filtering
- Dropdown is compact (single row, no extra vertical space)

New ARB keys:
- `searchFilterAll` ("All")
- `searchFilterProduce` ("Produce")
- `searchFilterBarcoded` ("Barcoded")
- `searchFilterInPantry` ("In Pantry")

### 4. New page: Configure Your Pantry

**File**: `lib/widgets/onboarding_flow.dart` — added as page 4 in the PageView

A scrollable `SingleChildScrollView` page with interactive settings controls
wrapped in a `Consumer` that reads/writes `settingsProvider` directly.

Layout (top to bottom):
1. Icon: `Icons.tune_outlined`
2. Title (ARB: `onboardingPage4Title`) — "Configure Your Pantry"
3. Description (ARB: `onboardingPage4Desc`) — brief explanation
4. **Settings rows**:
   - `SwitchListTile("Enable price tracking")` — uses existing
     `SettingsNotifier.setPriceTrackingEnabled`. Reads current state from
     `settingsProvider.select((s) => s.priceTrackingEnabled)`.
   - `ListTile("Currency")` — subtitle shows current code (e.g. USD).
     Tap opens a bottom sheet with ~10 common ISO 4217 currencies.
     Selection calls `SettingsNotifier.setBaseCurrency`.
   - `ListTile("Data retention")` — subtitle shows current days.
     Tap opens dialog with a slider (7-365 days).
     Confirmation calls `SettingsNotifier.setRetentionDays`.
   - `ListTile("Expiry warning threshold")` — subtitle shows current days.
     Tap opens dialog with a slider (1-30 days).
     Confirmation calls `SettingsNotifier.setExpiringSoonDays`.
5. CTA button: "Set Up" — calls `_nextPage()` (advances to page 5).

Reuses existing ARB keys for labels:
`priceTrackingEnabled`, `currency`, `baseCurrency`, `dataRetention`,
`expiringSoonDays`, `retentionDaysValue`, `expiringSoonDaysValue`.

New ARB keys:
- `onboardingPage4Title` ("Configure Your Pantry")
- `onboardingPage4Desc` ("Set up price tracking, currency, and data
  preferences to get the most out of Pantry.")
- `onboardingPage4Cta` ("Set Up")

### 5. ARB key summary (new)

| Key | English | Portuguese | Brazilian Portuguese |
|-----|---------|------------|---------------------|
| `onboardingBack` | Back | Voltar | Voltar |
| `onboardingPage4Title` | Configure Your Pantry | Configurar Despensa | Configurar Despensa |
| `onboardingPage4Desc` | Set up price tracking... | Configure monitoramento... | Configure monitoramento... |
| `onboardingPage4Cta` | Set Up | Configurar | Configurar |
| `searchFilterAll` | All | Todos | Todos |
| `searchFilterProduce` | Produce | Frescos | Frescos |
| `searchFilterBarcoded` | Barcoded | Com Codigo | Com Codigo |
| `searchFilterInPantry` | In Pantry | Na Despensa | Na Despensa |

## Implementation Plan (TDD — test first for each change)

### Increment 1 — ARB keys
- Add 8 new keys to `app_en.arb`, `app_pt.arb`, `app_pt_BR.arb`
- Run `flutter gen-l10n`

### Increment 2 — SearchScreen filter
- Tests: write `SearchScreen` filter tests (dropdown renders, selection
  filters results, `all` shows all, `produce` filters, `barcoded` filters)
- Code: add `SearchFilter` enum, `initialFilter` param, dropdown UI,
  client-side filter logic

### Increment 3 — OnboardingFlow 5 pages + Back button
- Tests: write new onboarding flow tests (5 pages, Back button navigates
  to previous page, Back absent on page 1, page 4 has Set Up, page 5 has
  Get Started)
- Code: expand to 5 pages, add Back button, insert settings page

### Increment 4 — Configure Your Pantry page
- Tests: write settings interaction tests (price tracking toggle,
  currency selector, data retention dialog, expiry warning dialog)
- Code: add interactive settings page inside OnboardingFlow's PageView

### Increment 5 — HomeScreen wiring
- Tests: update home_screen_test (FAB hidden during onboarding,
  page 3 navigates to SearchScreen with filter)
- Code: conditionally hide FAB, wire page 3 CTA to navigate to
  SearchScreen with `initialFilter: SearchFilter.produce`

### Increment 6 — Follow-up issue
- Create GitHub issue for generalized SearchFilter API and "In Pantry"
  filter implementation

### Increment 7 — Final verification
- `dart analyze`
- `flutter test --concurrency=2`
- `dart format --set-exit-if-changed .`

## Open Items / Edge Cases

1. **Onboarding interrupted mid-flow**: If the user navigates to a feature
   (ScannerScreen, SearchScreen) from pages 1-3 and then returns, the
   OnboardingFlow remains on the same page (since OnboardingFlow is a child
   of HomeScreen's body, the PageController state persists). No special
   handling needed.

2. **Settings changes are immediate**: Each toggle/picker on page 4
   persists to SharedPreferences immediately via SettingsNotifier. If the
   user taps Skip or navigates away before reaching page 5, their config
   changes are already saved. This is intentional — no data loss.

3. **Currency detection**: On first launch before page 4, the currency
   defaults to locale-detected value (existing behavior). The bottom sheet
   on page 4 pre-selects this value.

4. **SearchFilter.inPantry**: Deferred to follow-up. The dropdown shows
   the option but is disabled with "(coming soon)" suffix.

5. **FAB visibility**: The FAB is hidden for the entire duration of
   onboarding. Since pages 1-3 have their own CTAs that navigate to
   features, the user does not need the FAB during onboarding.
