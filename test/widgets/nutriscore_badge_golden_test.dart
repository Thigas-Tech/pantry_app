import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/widgets/nutriscore_badge.dart';

void main() {
  group('NutriScoreBadge golden', () {
    for (final grade in ['a', 'b', 'c', 'd', 'e']) {
      testWidgets('grade $grade renders correct colour', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              backgroundColor: Colors.white,
              body: Center(
                child: NutriScoreBadge(grade: grade),
              ),
            ),
          ),
        );
        await expectLater(
          find.byType(NutriScoreBadge),
          matchesGoldenFile('goldens/nutriscore_$grade.png'),
        );
      });
    }

    testWidgets('null grade renders empty', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: NutriScoreBadge(grade: null),
            ),
          ),
        ),
      );
      await expectLater(
        find.byType(NutriScoreBadge),
        matchesGoldenFile('goldens/nutriscore_null.png'),
      );
    });
  });
}
