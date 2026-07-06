import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/widgets/coming_soon_view.dart';

import '../helpers/pump_app.dart';

void main() {
  group('ComingSoonView', () {
    testWidgets('shows title and default icon', (tester) async {
      await pumpApp(tester, const ComingSoonView(title: 'Coming soon'));

      expect(find.text('Coming soon'), findsOneWidget);
      expect(find.byIcon(Icons.construction), findsOneWidget);
    });

    testWidgets('shows subtitle when provided', (tester) async {
      await pumpApp(
        tester,
        const ComingSoonView(
          title: 'Feature X',
          subtitle: 'Available later.',
        ),
      );

      expect(find.text('Feature X'), findsOneWidget);
      expect(find.text('Available later.'), findsOneWidget);
    });

    testWidgets('shows only title when subtitle is null', (tester) async {
      await pumpApp(tester, const ComingSoonView(title: 'Stats'));

      expect(find.text('Stats'), findsOneWidget);
      // Only one Text widget descendant — the title alone, no subtitle.
      final texts = tester.widgetList<Text>(find.byType(Text));
      expect(texts.length, 1);
    });

    testWidgets('shows custom icon', (tester) async {
      await pumpApp(
        tester,
        const ComingSoonView(title: 'test', icon: Icons.star),
      );

      expect(find.byIcon(Icons.star), findsOneWidget);
      expect(find.byIcon(Icons.construction), findsNothing);
    });
  });
}
