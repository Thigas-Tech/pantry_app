import 'dart:async';

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
        settle: false,
      );
      await tester.pump();

      expect(find.text('Scan Barcode'), findsOneWidget);
      expect(find.byIcon(Icons.edit), findsOneWidget);
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
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

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

      expect(find.text('Scan Barcode'), findsOneWidget);
      expect(find.byIcon(Icons.edit), findsOneWidget);
    });

    testWidgets('back navigation shows confirmation dialog', (
      tester,
    ) async {
      // Pump a parent route, then push ScannerScreen via the Navigator.
      await pumpApp(
        tester,
        Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () {
                  unawaited(
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const ScannerScreen(),
                      ),
                    ),
                  );
                },
                child: const Text('Open Scanner'),
              ),
            ),
          ),
        ),
        settle: false,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Navigate to scanner
      await tester.tap(find.text('Open Scanner'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Scanner should be visible
      expect(find.byType(ScannerScreen), findsOneWidget);

      // Trigger a back-pop attempt
      final nav = tester.state<NavigatorState>(find.byType(Navigator));
      unawaited(nav.maybePop());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Confirmation dialog should appear
      expect(find.text('Stop scanning?'), findsOneWidget);
      expect(find.text('The current scan will be discarded.'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Stay'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Leave'), findsOneWidget);

      // Tapping Stay should keep the scanner visible
      await tester.tap(find.widgetWithText(TextButton, 'Stay'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(ScannerScreen), findsOneWidget);

      // Tapping Leave should pop the scanner
      // Trigger back-pop attempt (pop result is ignored)
      unawaited(nav.maybePop());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.widgetWithText(TextButton, 'Leave'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(ScannerScreen), findsNothing);
    });
  });
}
