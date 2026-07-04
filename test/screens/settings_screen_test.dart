/// @file SettingsScreen widget tests.
///
/// Tests for the application settings screen.  We verify:
/// - The current theme mode is displayed as a subtitle.
/// - Tapping the theme tile opens a dialog with radio buttons; selecting one
///   updates the theme and shows a snackbar.
/// - The notification switch toggles the setting and displays a snackbar.
/// - Tapping the data retention tile opens a dialog with a text field;
///   entering a valid number and saving updates the retention period.
/// - Tapping the manage inventories tile navigates to
///   [ManageInventoriesScreen].
///
/// All tests use the `pumpApp` helper.  We override `themeModeProvider` and
/// `settingsProvider` with controlled fakes to isolate the screen from real
/// state.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/providers/settings_provider.dart';
import 'package:pantry_app/providers/theme_provider.dart';
import 'package:pantry_app/screens/manage_inventories_screen.dart';
import 'package:pantry_app/screens/settings_screen.dart';
import '../helpers/pump_app.dart';

// ---------- Fakes -----------------------------------------------------------

/// A controllable fake for [ThemeModeNotifier].
class FakeThemeModeNotifier extends ThemeModeNotifier {
  @override
  ThemeModeOption build() => ThemeModeOption.system;
}

/// A controllable fake for the settings notifier.
/// Assumes [Settings] has the fields:
///   `notificationsEnabled` (bool, defaults to true)
///   `retentionDays` (int, defaults to 60)
class FakeSettingsNotifier extends SettingsNotifier {
  @override
  Settings build() => const Settings();
}

// ---------- Tests -----------------------------------------------------------

void main() {
  testWidgets('displays current theme mode as subtitle', (tester) async {
    await pumpApp(
      tester,
      const SettingsScreen(),
      overrides: [
        themeModeProvider.overrideWith(FakeThemeModeNotifier.new),
        settingsProvider.overrideWith(FakeSettingsNotifier.new),
      ],
    );

    // The subtitle is the theme mode name (in English).
    expect(find.text('system'), findsOneWidget);
  });

  testWidgets('tapping theme tile opens dialog and changes theme', (
    tester,
  ) async {
    await pumpApp(
      tester,
      const SettingsScreen(),
      overrides: [
        themeModeProvider.overrideWith(FakeThemeModeNotifier.new),
        settingsProvider.overrideWith(FakeSettingsNotifier.new),
      ],
    );

    // Tap the theme tile (title "Theme").
    await tester.tap(find.text('Theme'));
    await tester.pumpAndSettle();

    // A SimpleDialog appears.
    expect(find.byType(SimpleDialog), findsOneWidget);
    expect(find.text('Choose theme'), findsOneWidget);

    // Select "dark".
    await tester.tap(find.text('dark'));
    await tester.pumpAndSettle();

    // Dialog closed.
    expect(find.byType(SimpleDialog), findsNothing);

    // Snackbar shows the exact localised message (from log: "Theme: dark").
    expect(find.text('Theme: dark'), findsOneWidget);
  });

  testWidgets('notification switch toggles and shows snackbar', (
    tester,
  ) async {
    await pumpApp(
      tester,
      const SettingsScreen(),
      overrides: [
        themeModeProvider.overrideWith(FakeThemeModeNotifier.new),
        settingsProvider.overrideWith(FakeSettingsNotifier.new),
      ],
    );

    final switchFinder = find.byType(Switch);
    expect(switchFinder, findsOneWidget);
    var sw = tester.widget<Switch>(switchFinder);
    expect(sw.value, isTrue);

    // Tap to turn off.
    await tester.tap(switchFinder);
    await tester.pumpAndSettle();

    sw = tester.widget<Switch>(switchFinder);
    expect(sw.value, isFalse);
    // Snackbar message (from log: "Notifications disabled.").
    expect(find.text('Notifications disabled.'), findsOneWidget);
  });

  testWidgets('tapping data retention opens dialog and saves value', (
    tester,
  ) async {
    await pumpApp(
      tester,
      const SettingsScreen(),
      overrides: [
        themeModeProvider.overrideWith(FakeThemeModeNotifier.new),
        settingsProvider.overrideWith(FakeSettingsNotifier.new),
      ],
    );

    // Tap the data retention tile (identified by its leading icon).
    await tester.tap(
      find.ancestor(
        of: find.byIcon(Icons.timer),
        matching: find.byType(ListTile),
      ),
    );
    await tester.pumpAndSettle();

    // An AlertDialog appears.
    expect(find.byType(AlertDialog), findsOneWidget);

    // Enter a new value.
    await tester.enterText(find.byType(TextField), '90');
    await tester.pumpAndSettle();

    // Tap the Save button (the second TextButton in the dialog).
    await tester.tap(find.widgetWithText(TextButton, 'Save'));
    await tester.pumpAndSettle();

    // Dialog should close.
    expect(find.byType(AlertDialog), findsNothing);

    // Exact snackbar message from the log:
    expect(find.text('Retention period set to 90 days.'), findsOneWidget);
  });

  testWidgets(
    'tapping manage inventories navigates to ManageInventoriesScreen',
    (tester) async {
      await pumpApp(
        tester,
        const SettingsScreen(),
        overrides: [
          themeModeProvider.overrideWith(FakeThemeModeNotifier.new),
          settingsProvider.overrideWith(FakeSettingsNotifier.new),
        ],
      );

      // Tap the manage inventories tile (identified by its leading icon).
      await tester.tap(
        find.ancestor(
          of: find.byIcon(Icons.folder),
          matching: find.byType(ListTile),
        ),
      );
      // Give the navigation a moment to start – we don't use pumpAndSettle
      // because ManageInventoriesScreen may run forever‑pending async work.
      await tester.pump();
      await tester.pump();

      // The navigator should now show ManageInventoriesScreen.
      expect(find.byType(ManageInventoriesScreen), findsOneWidget);
    },
  );
  testWidgets('cancelling retention dialog does not change value', (
    tester,
  ) async {
    await pumpApp(
      tester,
      const SettingsScreen(),
      overrides: [
        themeModeProvider.overrideWith(FakeThemeModeNotifier.new),
        settingsProvider.overrideWith(FakeSettingsNotifier.new),
      ],
    );

    // Tap the data retention tile
    await tester.tap(
      find.ancestor(
        of: find.byIcon(Icons.timer),
        matching: find.byType(ListTile),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);

    // Tap Cancel
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    // Dialog closed, no snackbar
    expect(find.byType(AlertDialog), findsNothing);
    // No "Retention period set" message
    expect(find.textContaining('Retention period set'), findsNothing);
  });
}
