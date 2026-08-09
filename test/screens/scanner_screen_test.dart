import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/providers/product_repository_provider.dart';
import 'package:pantry_app/providers/scanner_providers.dart';
import 'package:pantry_app/screens/add_product_screen.dart';
import 'package:pantry_app/screens/scanner_screen.dart';
import 'package:pantry_app/widgets/scanner_camera_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/pump_app.dart';

/// Fake [ScannerCamera] that skips platform controller creation.
class _FakeScannerCamera extends ScannerCamera {
  @override
  ScannerCameraState build() => const ScannerCameraState();

  @override
  Future<void> stopCamera() async {
    state = state.copyWith(isStreaming: false);
  }

  @override
  Future<void> resolveBarcode(
    String barcode, {
    Duration timeout = const Duration(seconds: 15),
  }) async {
    // No-op for widget tests — avoids real resolution.
  }
}

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

    testWidgets(
      'manual entry accepts 6-digit input (UPC-E length)',
      (tester) async {
        await pumpApp(
          tester,
          const ScannerScreen(),
          overrides: [
            scannerCameraProvider.overrideWith(_FakeScannerCamera.new),
          ],
          settle: false,
        );
        await tester.pump();
        await tester.tap(find.byIcon(Icons.edit));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        await tester.enterText(find.byType(TextField), '123456');
        await tester.tap(find.widgetWithText(ElevatedButton, 'Submit'));
        await tester.pump();

        // Should NOT show invalid-barcode warning
        expect(
          find.text('Enter a valid barcode number.'),
          findsNothing,
        );
      },
    );

    testWidgets(
      'manual entry rejects 3-digit input',
      (tester) async {
        await pumpApp(
          tester,
          const ScannerScreen(),
          overrides: [
            scannerCameraProvider.overrideWith(_FakeScannerCamera.new),
          ],
          settle: false,
        );
        await tester.pump();
        await tester.tap(find.byIcon(Icons.edit));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        await tester.enterText(find.byType(TextField), '123');
        await tester.tap(find.widgetWithText(ElevatedButton, 'Submit'));
        await tester.pump();

        expect(
          find.text('Enter a valid barcode number.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'switching from camera to manual stops the camera',
      (tester) async {
        await pumpApp(
          tester,
          const ScannerScreen(),
          overrides: [
            scannerCameraProvider.overrideWith(_FakeScannerCamera.new),
          ],
          settle: false,
        );
        await tester.pump();

        final container = ProviderScope.containerOf(
          tester.element(find.byType(ScannerScreen)),
          listen: false,
        );

        // Start streaming
        final notifier = container.read(scannerCameraProvider.notifier);
        final camState = container.read(scannerCameraProvider);
        notifier.state = camState.copyWith(isStreaming: true);
        await tester.pump();
        expect(container.read(scannerCameraProvider).isStreaming, true);

        // Switch to manual entry
        await tester.tap(find.byIcon(Icons.edit));
        await tester.pump();

        expect(container.read(scannerCameraProvider).isStreaming, false);
      },
    );

    testWidgets(
      'switching from camera to PLU stops the camera',
      (tester) async {
        await pumpApp(
          tester,
          const ScannerScreen(),
          overrides: [
            scannerCameraProvider.overrideWith(_FakeScannerCamera.new),
          ],
          settle: false,
        );
        await tester.pump();

        final container = ProviderScope.containerOf(
          tester.element(find.byType(ScannerScreen)),
          listen: false,
        );

        final notifier = container.read(scannerCameraProvider.notifier);
        final camState = container.read(scannerCameraProvider);
        notifier.state = camState.copyWith(isStreaming: true);
        await tester.pump();
        expect(container.read(scannerCameraProvider).isStreaming, true);

        // Switch to PLU entry
        await tester.tap(find.byIcon(Icons.dialpad));
        await tester.pump();

        expect(container.read(scannerCameraProvider).isStreaming, false);
      },
    );

    testWidgets(
      'switching from manual back to camera retries the scanner',
      (tester) async {
        await pumpApp(
          tester,
          const ScannerScreen(),
          overrides: [
            scannerCameraProvider.overrideWith(_FakeScannerCamera.new),
          ],
          settle: false,
        );
        await tester.pump();

        final container = ProviderScope.containerOf(
          tester.element(find.byType(ScannerScreen)),
          listen: false,
        );
        final initialKey = container.read(scannerCameraProvider).scannerKey;

        // Switch to manual then back to camera
        await tester.tap(find.byIcon(Icons.edit));
        await tester.pump();

        await tester.tap(find.byIcon(Icons.camera_alt));
        await tester.pump();

        // retryScanner increments scannerKey
        expect(
          container.read(scannerCameraProvider).scannerKey,
          greaterThan(initialKey),
        );
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

    testWidgets(
      'product not found opens the contribute form and clears on return',
      (
        tester,
      ) async {
        SharedPreferences.setMockInitialValues({});
        final mockRepo = createMockProductRepository();

        await pumpApp(
          tester,
          const ScannerScreen(),
          overrides: [
            productRepositoryProvider.overrideWithValue(mockRepo),
            scannerCameraProvider.overrideWith(_FakeScannerCamera.new),
          ],
          settle: false,
        );
        await tester.pump();

        final container = ProviderScope.containerOf(
          tester.element(find.byType(ScannerScreen)),
          listen: false,
        );
        final notifier = container.read(scannerCameraProvider.notifier);

        // Emit the not-found failure exactly as resolveBarcode does.
        notifier.state = notifier.state.copyWith(
          scanResolution: const ScanFailed(
            'PRODUCT_NOT_FOUND',
            barcode: '9999999999999',
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        // The scanner redirects to the contribute form in submit mode.
        final screen = tester.widget<AddProductScreen>(
          find.byType(AddProductScreen),
        );
        expect(screen.barcode, '9999999999999');
        expect(screen.submitToOff, isTrue);

        // Returning from the form clears the resolution so the next barcode
        // detection is not blocked by the null guard.
        final nav = tester.state<NavigatorState>(find.byType(Navigator));
        unawaited(nav.maybePop());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(container.read(scannerCameraProvider).scanResolution, isNull);
      },
    );

    testWidgets(
      'product not found without a barcode does not navigate',
      (
        tester,
      ) async {
        SharedPreferences.setMockInitialValues({});
        final mockRepo = createMockProductRepository();

        await pumpApp(
          tester,
          const ScannerScreen(),
          overrides: [
            productRepositoryProvider.overrideWithValue(mockRepo),
            scannerCameraProvider.overrideWith(_FakeScannerCamera.new),
          ],
          settle: false,
        );
        await tester.pump();

        final container = ProviderScope.containerOf(
          tester.element(find.byType(ScannerScreen)),
          listen: false,
        );
        final notifier = container.read(scannerCameraProvider.notifier);

        notifier.state = notifier.state.copyWith(
          scanResolution: const ScanFailed('PRODUCT_NOT_FOUND'),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.byType(AddProductScreen), findsNothing);
        expect(container.read(scannerCameraProvider).scanResolution, isNull);
      },
    );
  });
}
