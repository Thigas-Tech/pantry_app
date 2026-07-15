import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/l10n/app_localizations.dart';
import 'package:pantry_app/widgets/whats_new_sheet.dart';

import '../helpers/pump_app.dart';

/// A helper that wraps [child] in the same localisation shell as [pumpApp]
/// so that ARB strings resolve.
Future<void> pumpSheet(
  WidgetTester tester,
  Widget child, {
  bool settle = true,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => showWhatsNewSheet(
            context,
            rawChangelog: rawChangelog,
          ),
          child: const Text('Show'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Show'));
  if (settle) await tester.pumpAndSettle();
}

const rawChangelog =
    '# User Changelog\n'
    '\n'
    '## [Unreleased]\n'
    '### Added\n'
    '- Nothing yet.\n'
    '\n'
    '## [0.1.0]\n'
    '### Added\n'
    '- First feature.\n'
    '- Second feature.\n'
    '\n'
    '## [0.2.0]\n'
    '### Added\n'
    '- Second version feature.\n'
    '\n'
    '### Fixed\n'
    '- Bug fix one.\n'
    '\n'
    '### Added\n'
    '- **Bold** feature name.\n';

void main() {
  group('WhatsNewSheet', () {
    testWidgets('renders title', (tester) async {
      await pumpSheet(tester, const SizedBox.shrink());
      expect(find.text("What's new"), findsOneWidget);
    });

    testWidgets('renders version header for single entry', (tester) async {
      await pumpSheet(tester, const SizedBox.shrink());
      expect(find.textContaining('0.1.0'), findsOneWidget);
    });

    testWidgets('renders bullet points from changelog', (tester) async {
      await pumpSheet(tester, const SizedBox.shrink());
      expect(find.text('First feature.'), findsOneWidget);
      expect(find.text('Second feature.'), findsOneWidget);
    });

    testWidgets('renders multiple version entries', (tester) async {
      await pumpSheet(tester, const SizedBox.shrink());
      expect(find.textContaining('0.1.0'), findsOneWidget);
      expect(find.textContaining('0.2.0'), findsOneWidget);
    });

    testWidgets('renders bold text in markdown', (tester) async {
      await pumpSheet(tester, const SizedBox.shrink());
      expect(find.text('Bold feature name.'), findsOneWidget);
    });

    testWidgets('renders multiple sections under one version', (tester) async {
      await pumpSheet(tester, const SizedBox.shrink());
      expect(find.text('First feature.'), findsOneWidget);
      expect(find.text('Bug fix one.'), findsOneWidget);
    });

    testWidgets('renders Unreleased as localised string', (tester) async {
      await pumpSheet(tester, const SizedBox.shrink());
      expect(find.textContaining('Unreleased'), findsOneWidget);
    });
  });
}
