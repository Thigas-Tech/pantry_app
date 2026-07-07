/// @file ComingSoonScreen smoke tests.
///
/// Verifies the screen renders its [AppBar] and [ComingSoonView] body
/// with the provided [String] title, [String] subtitle, and [IconData] icon.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/screens/coming_soon_screen.dart';
import 'package:pantry_app/widgets/coming_soon_view.dart';

void main() {
  /// Verifies [ComingSoonScreen] renders the title in the AppBar and the
  /// [ComingSoonView] body widget.
  testWidgets('renders title in AppBar and ComingSoonView body', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ComingSoonScreen(title: 'Price Tracking'),
      ),
    );

    expect(find.text('Price Tracking'), findsAtLeast(1));
    expect(find.byType(ComingSoonView), findsOneWidget);
  });

  /// Verifies an optional subtitle is forwarded to [ComingSoonView].
  testWidgets('passes subtitle to ComingSoonView', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ComingSoonScreen(
          title: 'Price Tracking',
          subtitle: 'Coming in a future update',
        ),
      ),
    );

    expect(find.text('Coming in a future update'), findsOneWidget);
  });
}
