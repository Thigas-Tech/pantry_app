import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/l10n/app_localizations.dart';
import 'package:pantry_app/utils/changelog_loader.dart';
import 'package:pantry_app/widgets/whats_new_sheet.dart';

import '../helpers/pump_app.dart';

/// A helper that wraps [child] in the same localisation shell as [pumpApp]
/// so that ARB strings resolve.
Future<void> pumpSheet(
  WidgetTester tester,
  Widget child, {
  bool settle = true,
  Locale locale = const Locale('en'),
  String rawChangelog = rawChangelogEn,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
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

const rawChangelogEn =
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

const rawChangelogPt =
    '# Registro de alteracoes do usuario\n'
    '\n'
    '## [Unreleased]\n'
    '### Adicionado\n'
    '- Nada ainda.\n'
    '\n'
    '## [0.1.0]\n'
    '### Adicionado\n'
    '- Primeiro recurso.\n'
    '- Segundo recurso.\n';

void main() {
  group('changelogAssetPath', () {
    test('returns English path for en locale', () {
      expect(changelogAssetPath(const Locale('en')), 'USER_CHANGELOG.md');
    });

    test('returns Portuguese path for pt locale', () {
      expect(
        changelogAssetPath(const Locale('pt')),
        'USER_CHANGELOG_pt.md',
      );
    });

    test('returns pt_BR path for pt_BR locale', () {
      expect(
        changelogAssetPath(const Locale('pt', 'BR')),
        'USER_CHANGELOG_pt_BR.md',
      );
    });

    test('builds path for unsupported locale', () {
      expect(
        changelogAssetPath(const Locale('fr')),
        'USER_CHANGELOG_fr.md',
      );
    });
  });

  group('loadLocalizedChangelog', () {
    test('returns English content for en locale', () async {
      final content = await loadLocalizedChangelog(const Locale('en'));
      expect(content, contains('# User Changelog'));
    });

    test('falls back to English for unsupported locale', () async {
      // When the asset file for an unsupported locale does not exist,
      // the function falls back to the English file.
      final content = await loadLocalizedChangelog(const Locale('fr'));
      expect(content, contains('# User Changelog'));
    });
  });

  group('WhatsNewSheet', () {
    testWidgets('renders title in English', (tester) async {
      await pumpSheet(tester, const SizedBox.shrink());
      expect(find.text("What's new"), findsOneWidget);
    });

    testWidgets('renders title in Portuguese', (tester) async {
      await pumpSheet(
        tester,
        const SizedBox.shrink(),
        locale: const Locale('pt'),
        rawChangelog: rawChangelogPt,
      );
      expect(find.text('Novidades'), findsOneWidget);
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

    testWidgets('renders Unreleased as localised string in English', (
      tester,
    ) async {
      await pumpSheet(tester, const SizedBox.shrink());
      expect(find.textContaining('Unreleased'), findsOneWidget);
    });

    testWidgets('renders Unreleased as localised string in Portuguese', (
      tester,
    ) async {
      await pumpSheet(
        tester,
        const SizedBox.shrink(),
        locale: const Locale('pt'),
        rawChangelog: rawChangelogPt,
      );
      expect(find.textContaining('Nao lancado'), findsOneWidget);
    });

    testWidgets('renders Portuguese content when locale is pt', (tester) async {
      await pumpSheet(
        tester,
        const SizedBox.shrink(),
        locale: const Locale('pt'),
        rawChangelog: rawChangelogPt,
      );
      expect(find.text('Primeiro recurso.'), findsOneWidget);
      expect(find.text('Segundo recurso.'), findsOneWidget);
    });
  });
}
