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
  group('NutriScoreBadge', () {
    testWidgets('renders badge for valid grade a', (tester) async {
      await _pumpBadge(tester, const NutriScoreBadge(grade: 'a'));
      expect(find.text('A'), findsOneWidget);
    });

    testWidgets('renders badge for valid grade e', (tester) async {
      await _pumpBadge(tester, const NutriScoreBadge(grade: 'e'));
      expect(find.text('E'), findsOneWidget);
    });

    testWidgets('renders nothing for null grade', (tester) async {
      await _pumpBadge(tester, const NutriScoreBadge(grade: null));
      expect(find.byType(Container), findsNothing);
    });

    testWidgets('renders nothing for invalid grade', (tester) async {
      await _pumpBadge(tester, const NutriScoreBadge(grade: 'x'));
      expect(find.byType(Container), findsNothing);
    });

    testWidgets('renders dashed badge for not-applicable', (tester) async {
      await _pumpBadge(tester, const NutriScoreBadge(grade: 'not-applicable'));
      expect(find.text('—'), findsOneWidget);
    });

    testWidgets('renders dashed badge for NOT-APPLICABLE casing', (
      tester,
    ) async {
      await _pumpBadge(tester, const NutriScoreBadge(grade: 'NOT-APPLICABLE'));
      expect(find.text('—'), findsOneWidget);
    });

    testWidgets('renders badge for uppercase grade', (tester) async {
      await _pumpBadge(tester, const NutriScoreBadge(grade: 'C'));
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
      expect(NutriScoreBadge.toNumeric('not-applicable'), null);
    });

    test('isNotApplicable returns correct values', () {
      expect(NutriScoreBadge.isNotApplicable('not-applicable'), true);
      expect(NutriScoreBadge.isNotApplicable('NOT-APPLICABLE'), true);
      expect(NutriScoreBadge.isNotApplicable('a'), false);
      expect(NutriScoreBadge.isNotApplicable(null), false);
      expect(NutriScoreBadge.isNotApplicable(''), false);
    });
  });

  group('NutriScoreBadge semantics', () {
    testWidgets('has semantics label for grade a', (tester) async {
      await _pumpBadge(tester, const NutriScoreBadge(grade: 'a'));
      final node = tester.getSemantics(find.byType(NutriScoreBadge));
      expect(node.label, contains('Nutri-Score A'));
    });

    testWidgets('has semantics label for grade e', (tester) async {
      await _pumpBadge(tester, const NutriScoreBadge(grade: 'e'));
      final node = tester.getSemantics(find.byType(NutriScoreBadge));
      expect(node.label, contains('Nutri-Score E'));
    });

    testWidgets('label is uppercase for lowercase grade input', (tester) async {
      await _pumpBadge(tester, const NutriScoreBadge(grade: 'c'));
      final node = tester.getSemantics(find.byType(NutriScoreBadge));
      expect(node.label, contains('Nutri-Score C'));
    });

    testWidgets('no semantics label for null grade', (tester) async {
      await _pumpBadge(tester, const NutriScoreBadge(grade: null));
      final node = tester.getSemantics(find.byType(NutriScoreBadge));
      expect(node.label, '');
    });

    testWidgets('no semantics label for invalid grade', (tester) async {
      await _pumpBadge(tester, const NutriScoreBadge(grade: 'x'));
      final node = tester.getSemantics(find.byType(NutriScoreBadge));
      expect(node.label, '');
    });

    testWidgets('has semantics label for not-applicable grade', (
      tester,
    ) async {
      await _pumpBadge(tester, const NutriScoreBadge(grade: 'not-applicable'));
      final node = tester.getSemantics(find.byType(NutriScoreBadge));
      expect(node.label, contains('not applicable'));
    });
  });
}
