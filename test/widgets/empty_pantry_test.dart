/// @file EmptyPantry widget tests.
///
/// Tests the empty‑state widget that appears when the pantry has no items.
/// The widget renders a kitchen icon, a title, a subtitle, and a scan button.
/// We verify that the correct localised strings appear and that the button
/// triggers the onScan callback.
///
/// This test uses the shared pumpApp helper from test/helpers/pump_app.dart
/// to wrap the widget in a minimal MaterialApp with English locale and
/// localisation delegates.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/widgets/empty_pantry.dart';
import '../helpers/pump_app.dart';

void main() {
  group('EmptyPantry', () {
    /// Verifies that the widget displays the expected title, subtitle, and
    /// button label, and that tapping the button invokes the [onScan] callback.
    testWidgets('shows title, subtitle, and scan button', (tester) async {
      var tapped = false;

      // Render the widget inside a full test environment.
      await pumpApp(
        tester,
        EmptyPantry(onScan: () => tapped = true),
      );

      // Check localised strings (locale is pinned to English in pumpApp).
      expect(find.text('Your pantry is empty'), findsOneWidget);
      expect(
        find.text('Tap the button below to scan your first product'),
        findsOneWidget,
      );
      expect(find.text('Scan a barcode'), findsOneWidget);

      // Simulate a tap on the only ElevatedButton.
      await tester.tap(find.byType(ElevatedButton));
      expect(tapped, isTrue);
    });
  });
}
