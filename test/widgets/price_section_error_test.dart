import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/widgets/price_section_error.dart';

import '../helpers/pump_app.dart';

void main() {
  testWidgets('renders the title, error message, and retry action', (
    tester,
  ) async {
    await pumpApp(
      tester,
      const Scaffold(body: PriceSectionError(onRetry: _noop)),
    );

    expect(find.text('Prices'), findsOneWidget);
    expect(
      find.text('Something went wrong. Please try again.'),
      findsOneWidget,
    );
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('invokes the retry callback on tap', (tester) async {
    var retried = false;
    await pumpApp(
      tester,
      Scaffold(
        body: PriceSectionError(onRetry: () => retried = true),
      ),
    );

    await tester.tap(find.text('Retry'));
    await tester.pump();

    expect(retried, isTrue);
  });
}

void _noop() {}
