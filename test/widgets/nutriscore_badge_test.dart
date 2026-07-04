import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/widgets/nutriscore_badge.dart';

void main() {
  group('NutriScoreBadge', () {
    testWidgets('renders badge for valid grade a', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: NutriScoreBadge(grade: 'a')),
      );
      expect(find.text('A'), findsOneWidget);
    });

    testWidgets('renders badge for valid grade e', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: NutriScoreBadge(grade: 'e')),
      );
      expect(find.text('E'), findsOneWidget);
    });

    testWidgets('renders nothing for null grade', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: NutriScoreBadge(grade: null)),
      );
      expect(find.byType(Container), findsNothing);
    });

    testWidgets('renders nothing for invalid grade', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: NutriScoreBadge(grade: 'x')),
      );
      expect(find.byType(Container), findsNothing);
    });

    testWidgets('renders badge for uppercase grade', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: NutriScoreBadge(grade: 'C')),
      );
      expect(find.text('C'), findsOneWidget);
    });

    test('toNumeric returns correct values', () {
      expect(NutriScoreBadge.toNumeric('a'), 5);
      expect(NutriScoreBadge.toNumeric('b'), 4);
      expect(NutriScoreBadge.toNumeric('c'), 3);
      expect(NutriScoreBadge.toNumeric('d'), 2);
      expect(NutriScoreBadge.toNumeric('e'), 1);
      expect(NutriScoreBadge.toNumeric(null), null);
      expect(NutriScoreBadge.toNumeric('x'), null);
    });
  });
}
