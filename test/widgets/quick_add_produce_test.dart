/// Tests for [QuickAddProduce].
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/widgets/quick_add_produce.dart';

void main() {
  testWidgets('shows all items as chips when none are loading', (tester) async {
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

  testWidgets('shows loading spinner on a chip when it is in loadingItems', (
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

    // Loading chip shows spinner instead of text
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Apple'), findsNothing);
    // Non-loading chip still shows text
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

    // Loading chip's onPressed should be null (disabled)
    final chips = tester.widgetList<ActionChip>(find.byType(ActionChip));
    expect(chips.length, 2);
    final loadingChip = chips.first;
    final nonLoadingChip = chips.last;
    expect(loadingChip.onPressed, isNull);
    expect(nonLoadingChip.onPressed, isNotNull);
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
}
