import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/screens/scanner_screen.dart';
import 'package:pantry_app/widgets/scanner_camera_view.dart';
import '../helpers/pump_app.dart';

void main() {
  group('ScannerScreen', () {
    testWidgets(
      'initial state shows ScannerCameraView with edit and torch buttons',
      (
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
        expect(find.byIcon(Icons.dialpad), findsOneWidget);
        expect(find.byType(ScannerCameraView), findsOneWidget);
      },
    );

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

    testWidgets('manual entry: empty submit shows warning', (tester) async {
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

    testWidgets(
      'manual entry: camera button switches back to camera view',
      (
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
      },
    );

    testWidgets(
      'manual entry: PLU button from camera switches to PLU view',
      (
        tester,
      ) async {
        await pumpApp(
          tester,
          const ScannerScreen(),
          settle: false,
        );
        await tester.pump();
        await tester.tap(find.byIcon(Icons.dialpad));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.text('Enter PLU Code'), findsOneWidget);
      },
    );

    testWidgets('back navigation shows confirmation dialog', (
      tester,
    ) async {
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

      await tester.tap(find.text('Open Scanner'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(ScannerScreen), findsOneWidget);

      final nav = tester.state<NavigatorState>(find.byType(Navigator));
      unawaited(nav.maybePop());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Stop scanning?'), findsOneWidget);
      expect(find.text('The current scan will be discarded.'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Stay'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Leave'), findsOneWidget);

      await tester.tap(find.widgetWithText(TextButton, 'Stay'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(ScannerScreen), findsOneWidget);

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
