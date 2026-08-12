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
/// - Expiring-soon days tile opens and saves a dialog value.
/// - "What's New" and "Send Feedback" tiles are present.
///
/// All tests use the pumpApp helper.  We override themeModeProvider and
/// settingsProvider with controlled fakes to isolate the screen from real
/// state.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pantry_app/providers/notification_service_provider.dart';
import 'package:pantry_app/providers/settings_provider.dart';
import 'package:pantry_app/providers/theme_provider.dart';
import 'package:pantry_app/screens/manage_inventories_screen.dart';
import 'package:pantry_app/screens/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/pump_app.dart';
import '../services/mock_notification_service.dart';

// ---------- Fakes -----------------------------------------------------------

/// A controllable fake for [ThemeModeNotifier].
class FakeThemeModeNotifier extends ThemeModeNotifier {
  @override
  ThemeModeOption build() => ThemeModeOption.system;
}

/// A controllable fake for the settings notifier.
/// Assumes [Settings] has the fields:
///   notificationsEnabled (bool, defaults to true)
///   retentionDays (int, defaults to 60)
class FakeSettingsNotifier extends SettingsNotifier {
  @override
  Settings build() => const Settings();
}

/// A fake with [Settings.notificationsEnabled] set to false.
class FakeSettingsNotifierNotifsOff extends SettingsNotifier {
  @override
  Settings build() => const Settings(notificationsEnabled: false);
}

/// A fake with imperial unit system.
class FakeSettingsNotifierImperial extends SettingsNotifier {
  @override
  Settings build() => const Settings(
    unitSystem: UnitSystem.imperial,
    preferredWeightUnit: WeightUnitPreference.pounds,
    preferredVolumeUnit: VolumeUnitPreference.cups,
  );
}

// ---------- Tests -----------------------------------------------------------

void main() {
  /// Verifies the theme mode is displayed as a subtitle under the
  /// "Appearance" tile.
  testWidgets('displays current theme mode as subtitle', (tester) async {
    await pumpApp(
      tester,
      const SettingsScreen(),
      overrides: [
        themeModeProvider.overrideWith(FakeThemeModeNotifier.new),
        settingsProvider.overrideWith(FakeSettingsNotifier.new),
      ],
    );

    expect(find.text('System'), findsOneWidget);
  });

  /// Verifies tapping the theme tile opens a dialog with radio buttons,
  /// and selecting one updates the theme and shows a snackbar.
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
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();

    // Dialog closed.
    expect(find.byType(SimpleDialog), findsNothing);

    // Snackbar shows the exact localised message (from log: "Theme: Dark").
    expect(find.text('Theme: Dark'), findsOneWidget);
  });

  /// Verifies the notification switch toggles between enabled/disabled
  /// and displays the appropriate snackbar.
  testWidgets('notification switch toggles and shows snackbar', (
    tester,
  ) async {
    final mockNotif = MockNotificationService();
    when(mockNotif.requestPermission).thenAnswer((_) async => true);
    when(mockNotif.cancelAllReminders).thenAnswer((_) async {});
    when(mockNotif.canScheduleExactNotifications).thenAnswer((_) async => true);

    await pumpApp(
      tester,
      const SettingsScreen(),
      overrides: [
        themeModeProvider.overrideWith(FakeThemeModeNotifier.new),
        settingsProvider.overrideWith(FakeSettingsNotifier.new),
        notificationServiceProvider.overrideWithValue(mockNotif),
      ],
    );

    final switchFinder = find.byType(Switch);
    expect(switchFinder, findsNWidgets(3));
    // The first switch is AMOLED toggle (defaults off). The second switch
    // (at index 1) is the notifications switch.
    var sw = tester.widget<Switch>(switchFinder.at(1));
    expect(sw.value, isTrue);

    // Tap to turn off.
    await tester.tap(switchFinder.at(1));
    await tester.pumpAndSettle();

    sw = tester.widget<Switch>(switchFinder.at(1));
    expect(sw.value, isFalse);
    // Snackbar message (from log: "Notifications disabled.").
    expect(find.text('Notifications disabled.'), findsOneWidget);
  });

  /// Verifies the data retention tile opens a dialog, accepts a new
  /// value, saves it, and shows a confirmation snackbar.
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

    // Scroll down to reveal the Data Management section.
    await tester.drag(find.byType(ListView), const Offset(0, -1000));
    await tester.pumpAndSettle();

    // Expand the "Data Management" section.
    await tester.tap(find.byIcon(Icons.timer));
    await tester.pumpAndSettle();

    // Tap the data retention tile.
    await tester.tap(find.text('Data retention'));
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

  /// Verifies tapping the manage inventories tile navigates to
  /// [ManageInventoriesScreen].
  testWidgets(
    'tapping manage inventories navigates to ManageInventoriesScreen',
    (tester) async {
      final mockNotif = MockNotificationService();
      when(mockNotif.requestPermission).thenAnswer((_) async => true);
      when(mockNotif.cancelAllReminders).thenAnswer((_) async {});
      when(
        mockNotif.canScheduleExactNotifications,
      ).thenAnswer((_) async => true);
      await pumpApp(
        tester,
        const SettingsScreen(),
        overrides: [
          themeModeProvider.overrideWith(FakeThemeModeNotifier.new),
          settingsProvider.overrideWith(FakeSettingsNotifier.new),
          notificationServiceProvider.overrideWithValue(mockNotif),
        ],
      );

      // Scroll down to reveal the Data Management section.
      await tester.drag(find.byType(ListView), const Offset(0, -1000));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Data Management'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Manage Inventories'));

      await tester.pump();
      await tester.pump();

      expect(find.byType(ManageInventoriesScreen), findsOneWidget);
    },
  );

  /// Verifies that cancelling the retention dialog does not change the
  /// current value and shows no snackbar.
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

    // Scroll down to reveal the Data Management section.
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();

    // Expand the "Data Management" section.
    await tester.tap(find.byIcon(Icons.timer));
    await tester.pumpAndSettle();

    // Tap the data retention tile.
    await tester.tap(find.text('Data retention'));
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

  /// Verifies the "What's New" tile is present.
  testWidgets('shows what is new tile', (tester) async {
    await pumpApp(
      tester,
      const SettingsScreen(),
      overrides: [
        themeModeProvider.overrideWith(FakeThemeModeNotifier.new),
        settingsProvider.overrideWith(FakeSettingsNotifier.new),
      ],
    );

    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.info_outline));
    await tester.pumpAndSettle();

    expect(find.text("What's new"), findsOneWidget);
  });

  /// Verifies that a changelog load failure shows the changelog-specific
  /// error snackbar, not the cache-flush message.
  testWidgets('whats new load failure shows changelog error snackbar', (
    tester,
  ) async {
    // Simulate missing changelog assets: the asset channel resolves with
    // null data, which makes rootBundle.loadString throw a FlutterError.
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          ..setMockMessageHandler('flutter/assets', (message) async {
            return null;
          });
    addTearDown(() {
      messenger.setMockMessageHandler('flutter/assets', null);
    });

    await pumpApp(
      tester,
      const SettingsScreen(),
      overrides: [
        themeModeProvider.overrideWith(FakeThemeModeNotifier.new),
        settingsProvider.overrideWith(FakeSettingsNotifier.new),
      ],
    );

    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.info_outline));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text("What's new"));
    await tester.pumpAndSettle();

    await tester.tap(find.text("What's new"));
    await tester.pumpAndSettle();

    expect(find.text('Could not load the changelog.'), findsOneWidget);
    expect(find.text('Failed to flush cache. Please try again.'), findsNothing);
  });

  /// Verifies toggling notifications ON shows rationale dialog first time.
  testWidgets('notif toggle shows rationale dialog on first attempt', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    final mockNotif = MockNotificationService();
    when(mockNotif.requestPermission).thenAnswer((_) async => true);
    when(mockNotif.cancelAllReminders).thenAnswer((_) async {});
    when(mockNotif.canScheduleExactNotifications).thenAnswer((_) async => true);

    await pumpApp(
      tester,
      const SettingsScreen(),
      overrides: [
        themeModeProvider.overrideWith(FakeThemeModeNotifier.new),
        settingsProvider.overrideWith(FakeSettingsNotifierNotifsOff.new),
        notificationServiceProvider.overrideWithValue(mockNotif),
      ],
    );

    final switchFinder = find.byType(Switch);
    // The second switch (at index 1) is the notifications switch.
    // It starts OFF thanks to FakeSettingsNotifierNotifsOff.
    await tester.tap(switchFinder.at(1));
    await tester.pumpAndSettle();

    // Rationale dialog should be shown.
    expect(find.text('Notifications help you keep track'), findsOneWidget);
    // requestPermission should NOT yet be called.
    verifyNever(mockNotif.requestPermission);
  });

  /// Verifies that "Allow" in rationale dialog calls requestPermission.
  testWidgets('rationale Allow calls requestPermission and shows snackbar', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    final mockNotif = MockNotificationService();
    when(mockNotif.requestPermission).thenAnswer((_) async => true);
    when(mockNotif.cancelAllReminders).thenAnswer((_) async {});
    when(mockNotif.canScheduleExactNotifications).thenAnswer((_) async => true);

    await pumpApp(
      tester,
      const SettingsScreen(),
      overrides: [
        themeModeProvider.overrideWith(FakeThemeModeNotifier.new),
        settingsProvider.overrideWith(FakeSettingsNotifierNotifsOff.new),
        notificationServiceProvider.overrideWithValue(mockNotif),
      ],
    );

    final switchFinder = find.byType(Switch);
    await tester.tap(switchFinder.at(1));
    await tester.pumpAndSettle();

    // Tap "Allow"
    await tester.tap(find.text('Allow'));
    await tester.pumpAndSettle();

    verify(mockNotif.requestPermission).called(1);
    // Snackbar appears.
    expect(find.text('Notifications enabled.'), findsOneWidget);
  });

  /// Verifies that "Not now" in rationale dialog skips requestPermission.
  testWidgets('rationale Not now skips requestPermission', (tester) async {
    SharedPreferences.setMockInitialValues({});

    final mockNotif = MockNotificationService();
    when(mockNotif.requestPermission).thenAnswer((_) async => true);
    when(mockNotif.cancelAllReminders).thenAnswer((_) async {});
    when(mockNotif.canScheduleExactNotifications).thenAnswer((_) async => true);

    await pumpApp(
      tester,
      const SettingsScreen(),
      overrides: [
        themeModeProvider.overrideWith(FakeThemeModeNotifier.new),
        settingsProvider.overrideWith(FakeSettingsNotifierNotifsOff.new),
        notificationServiceProvider.overrideWithValue(mockNotif),
      ],
    );

    final switchFinder = find.byType(Switch);
    await tester.tap(switchFinder.at(1));
    await tester.pumpAndSettle();

    // Tap "Not now"
    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();

    verifyNever(mockNotif.requestPermission);
  });

  /// Verifies toggling notifications ON again skips rationale and calls
  /// requestPermission directly.
  testWidgets(
    'second toggle skips rationale calls requestPermission directly',
    (tester) async {
      SharedPreferences.setMockInitialValues({});

      final mockNotif = MockNotificationService();
      when(mockNotif.requestPermission).thenAnswer((_) async => true);
      when(mockNotif.cancelAllReminders).thenAnswer((_) async {});
      when(
        mockNotif.canScheduleExactNotifications,
      ).thenAnswer((_) async => true);

      await pumpApp(
        tester,
        const SettingsScreen(),
        overrides: [
          themeModeProvider.overrideWith(FakeThemeModeNotifier.new),
          settingsProvider.overrideWith(FakeSettingsNotifierNotifsOff.new),
          notificationServiceProvider.overrideWithValue(mockNotif),
        ],
      );

      // Pre-set the flag so rationale is skipped.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notification_rationale_shown', true);

      final switchFinder = find.byType(Switch);
      await tester.tap(switchFinder.at(1));
      await tester.pumpAndSettle();

      // No rationale dialog.
      expect(
        find.text('Notifications help you keep track'),
        findsNothing,
      );
      // requestPermission called directly.
      verify(mockNotif.requestPermission).called(1);
    },
  );

  /// Verifies the "Send Feedback" tile is present.
  testWidgets('shows send feedback tile', (tester) async {
    await pumpApp(
      tester,
      const SettingsScreen(),
      overrides: [
        themeModeProvider.overrideWith(FakeThemeModeNotifier.new),
        settingsProvider.overrideWith(FakeSettingsNotifier.new),
      ],
    );

    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.info_outline));
    await tester.pumpAndSettle();

    expect(find.text('Send Feedback'), findsOneWidget);
  });

  // ---- Unit system -------------------------------------------------------

  testWidgets('shows unit system radio group with Metric selected by default', (
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

    // Open the units section
    await tester.tap(find.text('Units'));
    await tester.pumpAndSettle();

    expect(find.text('Metric'), findsOneWidget);
    expect(find.text('Imperial'), findsOneWidget);
  });

  testWidgets(
    'tapping Imperial updates unit system via notifier',
    (tester) async {
      await pumpApp(
        tester,
        const SettingsScreen(),
        overrides: [
          themeModeProvider.overrideWith(FakeThemeModeNotifier.new),
          settingsProvider.overrideWith(FakeSettingsNotifier.new),
        ],
      );

      await tester.tap(find.text('Units'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Imperial'));
      await tester.pumpAndSettle();

      // Imperial radio should now be selected (groupValue == imperial)
      final radioGroup = tester.widget<RadioGroup<UnitSystem>>(
        find.byType(RadioGroup<UnitSystem>),
      );
      expect(radioGroup.groupValue, UnitSystem.imperial);
    },
  );

  testWidgets(
    'shows imperial preferences when system is imperial',
    (tester) async {
      await pumpApp(
        tester,
        const SettingsScreen(),
        overrides: [
          themeModeProvider.overrideWith(FakeThemeModeNotifier.new),
          settingsProvider.overrideWith(FakeSettingsNotifierImperial.new),
        ],
      );

      await tester.tap(find.text('Units'));
      await tester.pumpAndSettle();

      expect(find.text('Weight preference'), findsOneWidget);
      expect(find.text('Volume preference'), findsOneWidget);
    },
  );

  testWidgets('hides imperial preferences when system is metric', (
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

    await tester.tap(find.text('Units'));
    await tester.pumpAndSettle();

    expect(find.text('Weight preference'), findsNothing);
    expect(find.text('Volume preference'), findsNothing);
  });
}
