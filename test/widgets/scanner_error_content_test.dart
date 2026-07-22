import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:pantry_app/widgets/scanner_error_content.dart';
import '../helpers/pump_app.dart';

void main() {
  group('ScannerErrorContent', () {
    testWidgets(
      'permissionDenied shows Open Settings and manual entry buttons',
      (
        tester,
      ) async {
        var settingsCalled = false;
        var manualCalled = false;

        await pumpApp(
          tester,
          ScannerErrorContent(
            exception: const MobileScannerException(
              errorCode: MobileScannerErrorCode.permissionDenied,
            ),
            onRetry: () {},
            onSwitchToManual: () => manualCalled = true,
            onSwitchToPlu: () {},
            onOpenSettings: () => settingsCalled = true,
          ),
        );

        expect(
          find.text('Camera permission denied. Grant access in Settings.'),
          findsOneWidget,
        );
        expect(find.text('Open Settings'), findsOneWidget);
        expect(find.text('Enter barcode manually'), findsOneWidget);
        expect(find.byIcon(Icons.settings), findsOneWidget);
        expect(find.byIcon(Icons.edit), findsOneWidget);

        await tester.tap(find.text('Open Settings'));
        expect(settingsCalled, isTrue);

        await tester.tap(find.text('Enter barcode manually'));
        expect(manualCalled, isTrue);
      },
    );

    testWidgets('unsupported shows manual entry button only', (
      tester,
    ) async {
      var manualCalled = false;

      await pumpApp(
        tester,
        ScannerErrorContent(
          exception: const MobileScannerException(
            errorCode: MobileScannerErrorCode.unsupported,
          ),
          onRetry: () {},
          onSwitchToManual: () => manualCalled = true,
          onSwitchToPlu: () {},
          onOpenSettings: () {},
        ),
      );

      expect(
        find.text('Camera not available on this device.'),
        findsOneWidget,
      );
      expect(find.text('Enter barcode manually'), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsNothing);
      expect(find.byIcon(Icons.refresh), findsNothing);

      await tester.tap(find.text('Enter barcode manually'));
      expect(manualCalled, isTrue);
    });

    testWidgets('genericError shows Retry and manual entry buttons', (
      tester,
    ) async {
      var retryCalled = false;
      var manualCalled = false;

      await pumpApp(
        tester,
        ScannerErrorContent(
          exception: const MobileScannerException(
            errorCode: MobileScannerErrorCode.genericError,
          ),
          onRetry: () => retryCalled = true,
          onSwitchToManual: () => manualCalled = true,
          onSwitchToPlu: () {},
          onOpenSettings: () {},
        ),
      );

      expect(
        find.text(
          'An unexpected error occurred while starting the camera.',
        ),
        findsOneWidget,
      );
      expect(find.text('Retry'), findsOneWidget);
      expect(find.text('Enter barcode manually'), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsNothing);

      await tester.tap(find.text('Retry'));
      expect(retryCalled, isTrue);

      await tester.tap(find.text('Enter barcode manually'));
      expect(manualCalled, isTrue);
    });

    testWidgets('unknown error code falls back to generic error', (
      tester,
    ) async {
      await pumpApp(
        tester,
        ScannerErrorContent(
          exception: const MobileScannerException(
            errorCode: MobileScannerErrorCode.controllerDisposed,
          ),
          onRetry: () {},
          onSwitchToManual: () {},
          onSwitchToPlu: () {},
          onOpenSettings: () {},
        ),
      );

      expect(
        find.text(
          'An unexpected error occurred while starting the camera.',
        ),
        findsOneWidget,
      );
      expect(find.text('Retry'), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });
  });
}
