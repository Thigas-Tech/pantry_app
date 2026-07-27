/// Tests for the [EmptyPantry] widget in compact mode.
///
/// The widget renders a compact empty-state prompt with a single scan button.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/widgets/empty_pantry.dart';
import '../helpers/pump_app.dart';

void main() {
  group('EmptyPantry', () {
    testWidgets('shows title, subtitle, and scan button', (tester) async {
      var tapped = false;

      await pumpApp(
        tester,
        EmptyPantry(onScan: () => tapped = true),
      );

      expect(find.text('Your pantry is empty'), findsOneWidget);
      expect(
        find.text('Tap the button below to scan your first product'),
        findsOneWidget,
      );
      expect(find.text('Scan a barcode'), findsOneWidget);

      await tester.tap(find.byType(ElevatedButton));
      expect(tapped, isTrue);
    });
  });
}
