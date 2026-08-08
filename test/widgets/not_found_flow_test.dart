import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/widgets/not_found_flow.dart';
import '../helpers/pump_app.dart';

void main() {
  group('NotFoundFlow', () {
    Widget buildFlow({
      Key? key,
      void Function(String)? onBarcodeSubmitted,
      VoidCallback? onScanBarcode,
      void Function(String barcode)? onContributeToOff,
      void Function(String)? onSaveLocally,
    }) {
      return Scaffold(
        body: NotFoundFlow(
          key: key,
          onBarcodeSubmitted: onBarcodeSubmitted,
          onScanBarcode: onScanBarcode,
          onContributeToOff: onContributeToOff,
          onSaveLocally: onSaveLocally,
        ),
      );
    }

    testWidgets('renders initial stage with scan and enter buttons', (
      tester,
    ) async {
      await pumpApp(tester, buildFlow());

      expect(find.byType(NotFoundFlow), findsOneWidget);
      expect(
        find.text('No products found in Packaged Products.'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Try scanning or entering'),
        findsOneWidget,
      );
      expect(find.text('Scan Barcode'), findsOneWidget);
      expect(find.text('Enter Barcode'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('tapping Enter Barcode reveals barcode text field', (
      tester,
    ) async {
      await pumpApp(tester, buildFlow());

      await tester.tap(find.text('Enter Barcode'));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Type or paste a barcode number'), findsOneWidget);
    });

    testWidgets('submitting invalid barcode shows validation error', (
      tester,
    ) async {
      await pumpApp(tester, buildFlow());

      await tester.tap(find.text('Enter Barcode'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();

      expect(find.text('Enter a valid barcode number.'), findsOneWidget);
    });

    testWidgets('submitting valid barcode calls onBarcodeSubmitted', (
      tester,
    ) async {
      String? captured;
      await pumpApp(
        tester,
        buildFlow(onBarcodeSubmitted: (b) => captured = b),
      );

      await tester.tap(find.text('Enter Barcode'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '7622210449283');
      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();

      expect(captured, '7622210449283');
    });

    testWidgets('tapping Scan Barcode calls onScanBarcode', (
      tester,
    ) async {
      var called = false;
      await pumpApp(
        tester,
        buildFlow(onScanBarcode: () => called = true),
      );

      await tester.tap(find.text('Scan Barcode'));
      await tester.pumpAndSettle();

      expect(called, isTrue);
    });

    testWidgets('transitions to barcode not found stage when notified', (
      tester,
    ) async {
      final key = GlobalKey<NotFoundFlowState>();
      await pumpApp(tester, buildFlow(key: key));

      await tester.tap(find.text('Enter Barcode'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '7622210449283');

      key.currentState?.showBarcodeNotFound('7622210449283');
      await tester.pumpAndSettle();

      expect(
        find.text('This barcode is not registered with Open Food Facts.'),
        findsOneWidget,
      );
      expect(find.text('Contribute to Open Food Facts'), findsOneWidget);
      expect(find.text('Save Locally'), findsOneWidget);
    });

    testWidgets('stage 3: tapping Contribute to OFF calls onContributeToOff', (
      tester,
    ) async {
      String? captured;
      final key = GlobalKey<NotFoundFlowState>();
      await pumpApp(
        tester,
        buildFlow(
          key: key,
          onContributeToOff: (b) => captured = b,
        ),
      );

      key.currentState?.showBarcodeNotFound('7622210449283');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Contribute to Open Food Facts'));
      await tester.pumpAndSettle();

      expect(captured, '7622210449283');
    });

    testWidgets('stage 3: tapping Save Locally calls onSaveLocally', (
      tester,
    ) async {
      String? captured;
      final key = GlobalKey<NotFoundFlowState>();
      await pumpApp(
        tester,
        buildFlow(key: key, onSaveLocally: (b) => captured = b),
      );

      key.currentState?.showBarcodeNotFound('7622210449283');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save Locally'));
      await tester.pumpAndSettle();

      expect(captured, '7622210449283');
    });

    testWidgets('stage 3 shows the barcode that was searched', (
      tester,
    ) async {
      final key = GlobalKey<NotFoundFlowState>();
      await pumpApp(tester, buildFlow(key: key));

      key.currentState?.showBarcodeNotFound('7622210449283');
      await tester.pumpAndSettle();

      expect(find.textContaining('7622210449283'), findsWidgets);
    });

    testWidgets('resets to initial stage when back is tapped', (
      tester,
    ) async {
      await pumpApp(tester, buildFlow());

      await tester.tap(find.text('Enter Barcode'));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsNothing);
      expect(find.text('Scan Barcode'), findsOneWidget);
      expect(find.text('Enter Barcode'), findsOneWidget);
    });
  });
}
