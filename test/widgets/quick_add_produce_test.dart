/// Tests for [QuickAddProduce].
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/widgets/quick_add_produce.dart';

void main() {
  group('QuickAddProduce', () {
    testWidgets('shows all items as chips when none are loading', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuickAddProduce(
              items: const ['Apple', 'Banana'],
              onProduceSelected: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('Banana'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('shows spinner alongside text on loading chip', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuickAddProduce(
              items: const ['Apple', 'Banana'],
              loadingItems: const {'Apple'},
              onProduceSelected: (_) {},
            ),
          ),
        ),
      );

      // Spinner should be present (wrapped via ProgressIndicatorHelper)
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      // Text should still be visible alongside spinner
      expect(find.text('Apple'), findsOneWidget);
      // Non-loading chip shows text
      expect(find.text('Banana'), findsOneWidget);
    });

    testWidgets('non-loading chips remain interactive', (tester) async {
      var tapped = '';
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuickAddProduce(
              items: const ['Apple', 'Banana'],
              loadingItems: const {'Apple'},
              onProduceSelected: (name) => tapped = name,
            ),
          ),
        ),
      );

      // Tap the non-loading chip
      await tester.tap(find.text('Banana'));
      expect(tapped, 'Banana');
    });

    testWidgets('loading chip is disabled', (tester) async {
      var tapped = '';
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuickAddProduce(
              items: const ['Apple', 'Banana'],
              loadingItems: const {'Apple'},
              onProduceSelected: (name) => tapped = name,
            ),
          ),
        ),
      );

      // Tap the loading chip — should not fire callback
      await tester.tap(find.text('Apple'));
      expect(tapped, '');

      // Verify onPressed is null via ActionChip widget
      final chips = tester.widgetList<ActionChip>(find.byType(ActionChip));
      final chipList = chips.toList();
      expect(chipList.length, 2);
      // First chip (Apple) is loading => onPressed is null
      // Order in ListView may vary, check by loading state
      final loadingChip = chipList
          .where(
            (c) => c.onPressed == null,
          )
          .single;
      expect(loadingChip, isNotNull);
    });

    testWidgets('returns SizedBox.shrink when items is empty', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuickAddProduce(
              items: const [],
              onProduceSelected: (_) {},
            ),
          ),
        ),
      );

      expect(find.byType(QuickAddProduce), findsOneWidget);
      expect(find.byType(ActionChip), findsNothing);
    });

    testWidgets('spinner appears and disappears when loading set toggles', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuickAddProduce(
              items: const ['Apple', 'Banana'],
              loadingItems: const {'Apple'},
              onProduceSelected: (_) {},
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Update: Apple is no longer loading
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuickAddProduce(
              items: const ['Apple', 'Banana'],
              onProduceSelected: (_) {},
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Apple'), findsOneWidget);
    });

    testWidgets('uses ProgressIndicatorHelper for loading spinner', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuickAddProduce(
              items: const ['Apple'],
              loadingItems: const {'Apple'},
              onProduceSelected: (_) {},
            ),
          ),
        ),
      );

      // The helper wraps CircularProgressIndicator in a SizedBox
      final sizedBoxes = tester.widgetList<SizedBox>(find.byType(SizedBox));
      // Find the spinner SizedBox (14x14, not the 48-height outer)
      final spinnerBox = sizedBoxes.firstWhere(
        (s) => s.width == 14 && s.height == 14,
      );
      expect(spinnerBox, isNotNull);

      // The CircularProgressIndicator should have strokeWidth 2
      final indicator = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      expect(indicator.strokeWidth, 2);
    });
  });
}
