import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/widgets/quick_add_produce.dart';
import '../helpers/pump_app.dart';

void main() {
  group('QuickAddProduce', () {
    testWidgets('renders produce chips', (tester) async {
      await pumpApp(
        tester,
        Scaffold(
          body: QuickAddProduce(
            items: const ['Apple', 'Banana', 'Orange', 'Tomato'],
            onProduceSelected: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('Banana'), findsOneWidget);
      expect(find.text('Orange'), findsOneWidget);
      expect(find.byType(ActionChip), findsNWidgets(4));
    });

    testWidgets('tapping a chip calls onProduceSelected', (tester) async {
      var selected = '';
      await pumpApp(
        tester,
        Scaffold(
          body: QuickAddProduce(
            items: const ['Apple', 'Banana'],
            onProduceSelected: (name) => selected = name,
          ),
        ),
      );

      await tester.tap(find.text('Apple'));
      await tester.pumpAndSettle();
      expect(selected, 'Apple');
    });

    testWidgets('long produce names are truncated', (tester) async {
      await pumpApp(
        tester,
        Scaffold(
          body: QuickAddProduce(
            items: const ['Brussels Sprouts With Extra Long Name'],
            onProduceSelected: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final chip = tester.widget<ActionChip>(find.byType(ActionChip));
      final label = chip.label as Text;
      expect(label.overflow, TextOverflow.ellipsis);
      expect(label.maxLines, 1);
    });
  });
}
