import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:pantry_app/providers/scanner_providers.dart';
import 'package:pantry_app/widgets/scanner_camera_view.dart';

import '../helpers/pump_app.dart';

void main() {
  group('ScannerCameraView pop regression', () {
    testWidgets(
      'popping a scanner route does not call setState during build',
      (tester) async {
        final controller = MobileScannerController(
          autoStart: false,
          autoZoom: true,
        );

        await pumpApp(
          tester,
          Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ScannerCameraView(
                        onSwitchToManual: _noop,
                        onSwitchToPlu: _noop,
                      ),
                    ),
                  ),
                  child: const Text('open scanner'),
                ),
              ),
            ),
          ),
          overrides: [
            mobileScannerControllerProvider.overrideWithValue(controller),
          ],
          settle: false,
        );

        await tester.tap(find.text('open scanner'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        expect(find.byType(ScannerCameraView), findsOneWidget);

        // Pop the route exactly like the confirm-exit path does on device.
        Navigator.of(tester.element(find.byType(ScannerCameraView))).pop();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        expect(tester.takeException(), isNull);
      },
    );
  });
}

void _noop() {}
