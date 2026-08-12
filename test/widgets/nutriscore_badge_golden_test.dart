import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/l10n/app_localizations.dart';
import 'package:pantry_app/widgets/nutriscore_badge.dart';

/// Pumps the badge inside a MaterialApp with full localization support.
Future<void> _pumpBadge(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: child),
      ),
    ),
  );
}

void main() {
  group('NutriScoreBadge golden', () {
    for (final grade in ['a', 'b', 'c', 'd', 'e']) {
      testWidgets('grade $grade renders correct colour', (tester) async {
        await _pumpBadge(tester, NutriScoreBadge(grade: grade));
        await expectLater(
          find.byType(NutriScoreBadge),
          matchesGoldenFile('goldens/nutriscore_$grade.png'),
        );
      });
    }

    testWidgets('null grade renders empty', (tester) async {
      await _pumpBadge(tester, const NutriScoreBadge(grade: null));
      await expectLater(
        find.byType(NutriScoreBadge),
        matchesGoldenFile('goldens/nutriscore_null.png'),
      );
    });

    testWidgets('not-applicable grade renders dashed grey badge', (
      tester,
    ) async {
      await _pumpBadge(tester, const NutriScoreBadge(grade: 'not-applicable'));
      await expectLater(
        find.byType(NutriScoreBadge),
        matchesGoldenFile('goldens/nutriscore_not_applicable.png'),
      );
    });
  });
}
