import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:pantry_app/providers/scanner_providers.dart';
import 'package:pantry_app/widgets/scanner_camera_view.dart';
import 'package:pantry_app/widgets/scanner_overlay_painter.dart';
import '../helpers/pump_app.dart';

/// Finds [CustomPaint] widgets whose [CustomPaint.painter] is a
/// [ScannerOverlayPainter].
final Finder _overlayPainterFinder = find.byWidgetPredicate(
  (w) => w is CustomPaint && w.painter is ScannerOverlayPainter,
);

void main() {
  group('ScannerCameraView', () {
    MobileScannerController createFakeController() {
      return MobileScannerController(autoStart: false, autoZoom: true);
    }

    Future<void> pumpCameraView(
      WidgetTester tester, {
      required ScannerCameraState state,
      MobileScannerController? controller,
    }) async {
      final effectiveController = controller ?? createFakeController();
      await pumpApp(
        tester,
        ScannerCameraView(
          onSwitchToManual: () {},
          onSwitchToPlu: () {},
        ),
        overrides: [
          mobileScannerControllerProvider.overrideWithValue(
            effectiveController,
          ),
          scannerCameraProvider.overrideWithValue(state),
        ],
        settle: false,
      );
      await tester.pump();
    }

    testWidgets('shows no overlay when camera is not streaming', (
      tester,
    ) async {
      await pumpCameraView(tester, state: const ScannerCameraState());

      expect(find.text('Scan Barcode'), findsOneWidget);
      expect(_overlayPainterFinder, findsNothing);
    });

    testWidgets('shows overlay when camera is streaming', (tester) async {
      await pumpCameraView(
        tester,
        state: const ScannerCameraState(isStreaming: true),
      );

      expect(_overlayPainterFinder, findsOneWidget);
    });

    testWidgets('shows error content when camera has error', (tester) async {
      await pumpCameraView(
        tester,
        state: const ScannerCameraState(
          cameraError: MobileScannerException(
            errorCode: MobileScannerErrorCode.genericError,
          ),
        ),
      );

      expect(
        find.text(
          'An unexpected error occurred while starting the camera.',
        ),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.flash_off), findsNothing);
    });

    testWidgets('shows permission denied error content', (tester) async {
      await pumpCameraView(
        tester,
        state: const ScannerCameraState(
          cameraError: MobileScannerException(
            errorCode: MobileScannerErrorCode.permissionDenied,
          ),
        ),
      );

      expect(
        find.text('Camera permission denied. Grant access in Settings.'),
        findsOneWidget,
      );
      expect(find.text('Open Settings'), findsOneWidget);
    });

    testWidgets('shows torch and mode switch buttons in streaming state', (
      tester,
    ) async {
      await pumpCameraView(
        tester,
        state: const ScannerCameraState(isStreaming: true),
      );

      expect(find.byIcon(Icons.flash_off), findsOneWidget);
      expect(find.byIcon(Icons.dialpad), findsOneWidget);
      expect(find.byIcon(Icons.edit), findsOneWidget);
    });

    testWidgets('embedded mode omits Scaffold, AppBar, and action buttons', (
      tester,
    ) async {
      await pumpApp(
        tester,
        ScannerCameraView(
          onSwitchToManual: () {},
          onSwitchToPlu: () {},
          embedded: true,
        ),
        overrides: [
          mobileScannerControllerProvider.overrideWithValue(
            createFakeController(),
          ),
          scannerCameraProvider.overrideWithValue(
            const ScannerCameraState(isStreaming: true),
          ),
        ],
        settle: false,
      );
      await tester.pump();

      expect(find.byType(Scaffold), findsNothing);
      expect(find.byType(AppBar), findsNothing);
      expect(find.text('Scan Barcode'), findsNothing);
      expect(find.byIcon(Icons.flash_off), findsNothing);
      expect(find.byIcon(Icons.dialpad), findsNothing);
      expect(find.byIcon(Icons.edit), findsNothing);
      expect(_overlayPainterFinder, findsOneWidget);
    });
  });
}
