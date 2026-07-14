# Bottom Sheet Safe Area (System Navigation Bar)

## Problem

Bottom sheets opened with `showModalBottomSheet(useSafeArea: true)` position the
sheet itself within the safe area, but **content inside the sheet** is not
automatically padded for the system navigation bar (gesture hint bar or
3-button nav). On devices with a nav bar at the bottom, buttons and content
can be partially obscured.

## Fix Pattern

Every bottom sheet with scrollable content must add
`MediaQuery.of(context).padding.bottom` to its innermost content `Padding`
widget.

### Before

```dart
return Padding(
  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
  child: Form(
    key: _formKey,
    child: SingleChildScrollView(...),
  ),
);
```

### After

```dart
final bottomPad = MediaQuery.of(context).padding.bottom;
return Padding(
  padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomPad),
  child: Form(
    key: _formKey,
    child: SingleChildScrollView(...),
  ),
);
```

## Why Not SafeArea

`SafeArea` inside the sheet would double-pad because
`showModalBottomSheet(useSafeArea: true)` already wraps the sheet in a
`SafeArea`. Adding another inside would push content up by twice the nav
bar height.

## Why Not viewInsets

`viewInsets.bottom` (keyboard height) is handled by
`isScrollControlled: true` + `SingleChildScrollView`. Do not add
`viewInsets.bottom` to the padding — it would create extra blank space
below the content when the keyboard is open.

## Do Not Use const

Once `MediaQuery` is involved, the `const` keyword on `Padding` must be
removed because the padding value is now computed at runtime.

## Affected Files

| File | Status |
|------|--------|
| `lib/widgets/price_entry_sheet.dart` | Fixed — `EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomPad)` |
| `lib/widgets/quantity_and_pantry_sheet.dart` | Fixed — same pattern |
| `lib/widgets/add_to_shopping_list_sheet.dart` | Fixed — custom form and main form button |
| `lib/widgets/whats_new_sheet.dart` | Already handled — `maxHeight` calc subtracts `bottomPadding` |

## Template for New Bottom Sheets

```dart
@override
Widget build(BuildContext context) {
  final bottomPad = MediaQuery.of(context).padding.bottom;
  return Padding(
    padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomPad),
    child: Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [...],
        ),
      ),
    ),
  );
}
```

## Testing

Widget tests cannot easily verify nav-bar padding because
`showModalBottomSheet` inserts into the `Overlay`, which uses the
`MaterialApp`'s `MediaQuery`, not the test's local override. Validate by:

1. **Code review** — verify the pattern above is followed
2. **Manual testing** — run on a device with gesture navigation
   (Samsung S711B or similar). Open each sheet and verify the bottom
   button/content is fully visible above the nav bar.
3. **Unit tests** — formatter logic is unit-testable; safe area is not.

## Stale Info Trigger

If a new bottom sheet is added without this pattern, the stale-info check
should flag it. Search for `showModalBottomSheet` in `lib/widgets/` and
verify each one has `padding.bottom` in its content.
