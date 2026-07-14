import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/models/produce_quick_add_item.dart';
import 'package:pantry_app/widgets/quick_add_produce.dart';

void main() {
  group('QuickAddProduce', () {
    const apple = ProduceQuickAddItem(
      name: 'apple',
      displayName: 'Apple',
      icon: Icons.apple,
      weightHintG: 182,
      source: ProduceItemSource.personalized,
    );
    const banana = ProduceQuickAddItem(
      name: 'banana',
      displayName: 'Banana',
      icon: Icons.local_dining,
      source: ProduceItemSource.seasonal,
    );
    const carrot = ProduceQuickAddItem(
      name: 'carrot',
      displayName: 'Carrot',
      icon: Icons.eco,
      weightHintG: 61,
      source: ProduceItemSource.fallback,
    );

    Widget buildWidget({
      List<ProduceQuickAddItem>? items,
      void Function(ProduceQuickAddItem)? onSelected,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: QuickAddProduce(
            items: items ?? const [apple, banana],
            onProduceSelected: onSelected ?? (_) {},
            sectionTitle: 'Quick Add',
            infoTooltip: 'Based on your purchases',
            emptyMessage: 'Start adding produce!',
          ),
        ),
      );
    }

    testWidgets('renders empty state when items empty', (tester) async {
      await tester.pumpWidget(buildWidget(items: const []));
      await tester.pumpAndSettle();

      expect(find.text('Start adding produce!'), findsOneWidget);
    });

    testWidgets('renders chips when items present', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('Banana'), findsOneWidget);
    });

    testWidgets('calls onProduceSelected with correct item', (tester) async {
      ProduceQuickAddItem? selected;
      await tester.pumpWidget(
        buildWidget(
          onSelected: (item) => selected = item,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Banana'));
      expect(selected?.name, 'banana');
    });

    testWidgets('shows weight hint when available', (tester) async {
      await tester.pumpWidget(
        buildWidget(
          items: const [apple, carrot],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('182g'), findsOneWidget);
      expect(find.textContaining('61g'), findsOneWidget);
    });

    testWidgets('no weight hint when null', (tester) async {
      await tester.pumpWidget(
        buildWidget(
          items: const [banana],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('g'), findsNothing);
    });

    testWidgets('section header visible', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.text('Quick Add'), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });
  });
}
