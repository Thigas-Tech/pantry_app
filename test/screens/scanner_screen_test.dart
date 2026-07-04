/// @file ScannerScreen widget tests.
///
/// Tests for the barcode input screen.  The screen offers two modes:
/// - Camera scanner (MobileScanner)
/// - Manual entry (text field)
///
/// Because MobileScanner is a native plugin, the onDetect callback is not
/// triggered in a pure Dart test environment.  We therefore focus on:
///   - Initial camera view with the correct app bar title and toggle button.
///   - Switching to manual entry and back to camera.
///   - Manual barcode entry and submission.
///
/// The scanner has a perpetual animation; we avoid `pumpAndSettle` and use
/// `pump()` with explicit durations.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/screens/scanner_screen.dart';
import '../helpers/pump_app.dart';

void main() {
  group('ScannerScreen', () {
    testWidgets('initial state shows camera view and manual entry button', (
      tester,
    ) async {
      await pumpApp(
        tester,
        const ScannerScreen(),
        settle: false, // don't wait for perpetual animation
      );
      await tester.pump(); // one frame

      expect(find.text('Scan Barcode'), findsOneWidget);
      expect(find.byIcon(Icons.edit), findsOneWidget);
      // The overlay custom painter is present (may appear multiple times due to
      // scaffold background, etc.)
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('tapping edit button switches to manual entry view', (
      tester,
    ) async {
      await pumpApp(
        tester,
        const ScannerScreen(),
        settle: false,
      );
      await tester.pump();
      await tester.tap(find.byIcon(Icons.edit));
      await tester.pump(); // rebuild

      // Now we are in manual entry mode; still no settle needed
      await tester.pump(
        const Duration(milliseconds: 500),
      ); // let build complete

      expect(find.text('Enter Barcode'), findsOneWidget);
      expect(find.byIcon(Icons.camera_alt), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Submit'), findsOneWidget);
    });

    testWidgets('manual entry: empty submit does not pop', (tester) async {
      await pumpApp(
        tester,
        const ScannerScreen(),
        settle: false,
      );
      await tester.pump();
      await tester.tap(find.byIcon(Icons.edit));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.widgetWithText(ElevatedButton, 'Submit'));
      await tester.pump();
      // Still on the scanner screen
      expect(find.byType(ScannerScreen), findsOneWidget);
    });

    testWidgets('manual entry: submit with barcode pops the route', (
      tester,
    ) async {
      await pumpApp(
        tester,
        const ScannerScreen(),
        settle: false,
      );
      await tester.pump();
      await tester.tap(find.byIcon(Icons.edit));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await tester.enterText(find.byType(TextField), '123456789');
      await tester.pump();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Submit'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // The route should be popped;
      // The scanner screen gone from navigation stack
      expect(find.byType(ScannerScreen), findsNothing);
    });

    testWidgets('manual entry: camera button switches back to camera view', (
      tester,
    ) async {
      await pumpApp(
        tester,
        const ScannerScreen(),
        settle: false,
      );
      await tester.pump();
      await tester.tap(find.byIcon(Icons.edit));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Enter Barcode'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.camera_alt));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Now the camera view should be shown again
      expect(find.text('Scan Barcode'), findsOneWidget);
      expect(find.byIcon(Icons.edit), findsOneWidget);
    });
  });
}
