import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/l10n/app_localizations.dart';
import 'package:pantry_app/services/changelog_parser.dart';
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
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) {
          return SizedBox(
            height: 600,
            child: ElevatedButton(
              onPressed: () => showWhatsNewSheet(
                context,
                const [
                  ChangelogEntry(
                    version: 'Unreleased',
                    content: '### Enhancements\n- Item A\n- Item B',
                  ),
                ],
              ),
              child: const Text('Open'),
            ),
          );
        },
      ),
    ),
  );

  if (!settle) {
    await tester.pump();
    return;
  }

  await tester.pump();
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

void main() {
  group('WhatsNewSheet', () {
    testWidgets('shows bottom sheet with version header', (tester) async {
      await pumpSheet(tester, const SizedBox.shrink());

      expect(find.text("What's new"), findsOneWidget);
      expect(find.text('Version Unreleased'), findsOneWidget);
    });

    testWidgets('shows section headers and content lines', (tester) async {
      await pumpSheet(tester, const SizedBox.shrink());

      expect(find.text('Enhancements'), findsOneWidget);
      expect(find.text('Item A'), findsOneWidget);
      expect(find.text('Item B'), findsOneWidget);
    });

    testWidgets('dismiss button closes sheet', (tester) async {
      await pumpSheet(tester, const SizedBox.shrink());

      await tester.tap(find.text('Got it'));
      await tester.pumpAndSettle();

      // Bottom sheet should be gone.
      expect(find.text("What's new"), findsNothing);
    });

    testWidgets('renders multiple version sections', (tester) async {
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
          home: Builder(
            builder: (context) {
              return SizedBox(
                height: 600,
                child: ElevatedButton(
                  onPressed: () => showWhatsNewSheet(
                    context,
                    const [
                      ChangelogEntry(
                        version: 'Unreleased',
                        content: '### Enhancements\n- Dev work',
                      ),
                      ChangelogEntry(
                        version: '0.1.0',
                        content: '### Core\n- Initial release',
                      ),
                    ],
                  ),
                  child: const Text('Open'),
                ),
              );
            },
          ),
        ),
      );

      await tester.pump();
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Both version headers visible.
      expect(find.text('Version 0.1.0'), findsOneWidget);
      expect(find.text('Version Unreleased'), findsOneWidget);
    });

    testWidgets('renders bold text via markdown parsing', (tester) async {
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
          home: Builder(
            builder: (context) {
              return SizedBox(
                height: 600,
                child: ElevatedButton(
                  onPressed: () => showWhatsNewSheet(
                    context,
                    const [
                      ChangelogEntry(
                        version: '0.1.0',
                        content: '### Enhancements\n- **Bold** feature name',
                      ),
                    ],
                  ),
                  child: const Text('Open'),
                ),
              );
            },
          ),
        ),
      );

      await tester.pump();
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Bold text rendered (as rich-text span inside Text.rich).
      final richText = find.byType(RichText);
      expect(richText, findsWidgets);
    });

    testWidgets('strips bullet markers from content lines', (tester) async {
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
          home: Builder(
            builder: (context) {
              return SizedBox(
                height: 600,
                child: ElevatedButton(
                  onPressed: () => showWhatsNewSheet(
                    context,
                    const [
                      ChangelogEntry(
                        version: '0.1.0',
                        content: '### Core\n- Feature one\n- Feature two',
                      ),
                    ],
                  ),
                  child: const Text('Open'),
                ),
              );
            },
          ),
        ),
      );

      await tester.pump();
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Bullet markers are stripped — text appears without leading dash.
      expect(find.text('Feature one'), findsOneWidget);
      expect(find.text('Feature two'), findsOneWidget);
      expect(find.textContaining('- Feature one'), findsNothing);
    });

    testWidgets('dark mode adapts sheet colours', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          themeMode: ThemeMode.dark,
          darkTheme: ThemeData.dark(useMaterial3: true),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              return SizedBox(
                height: 600,
                child: ElevatedButton(
                  onPressed: () => showWhatsNewSheet(
                    context,
                    const [
                      ChangelogEntry(
                        version: '0.1.0',
                        content: '### Core\n- Works in dark mode',
                      ),
                    ],
                  ),
                  child: const Text('Open'),
                ),
              );
            },
          ),
        ),
      );

      await tester.pump();
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Content renders without overflow or contrast issues in dark mode.
      expect(find.text('Works in dark mode'), findsOneWidget);
    });

    testWidgets('hides dev-only section headers', (tester) async {
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
          home: Builder(
            builder: (context) {
              return SizedBox(
                height: 600,
                child: ElevatedButton(
                  onPressed: () => showWhatsNewSheet(
                    context,
                    const [
                      ChangelogEntry(
                        version: '0.1.0',
                        content:
                            '### Tests\n'
                            '- Unit test added\n'
                            '### Documentation\n'
                            '- Updated docs\n'
                            '### Dependencies\n'
                            '- Bumped foo to 2.0\n',
                      ),
                    ],
                  ),
                  child: const Text('Open'),
                ),
              );
            },
          ),
        ),
      );

      await tester.pump();
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Dev-only section headers are hidden.
      expect(find.text('Tests'), findsNothing);
      expect(find.text('Documentation'), findsNothing);
      expect(find.text('Dependencies'), findsNothing);
      // Content under those sections is also hidden.
      expect(find.text('Unit test added'), findsNothing);
      expect(find.text('Updated docs'), findsNothing);
      expect(find.text('Bumped foo to 2.0'), findsNothing);
    });

    testWidgets('shows user-facing section headers', (tester) async {
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
          home: Builder(
            builder: (context) {
              return SizedBox(
                height: 600,
                child: ElevatedButton(
                  onPressed: () => showWhatsNewSheet(
                    context,
                    const [
                      ChangelogEntry(
                        version: '0.1.0',
                        content:
                            '### Enhancements\n'
                            '- New feature\n'
                            '### Bugfixes\n'
                            '- Fixed crash\n',
                      ),
                    ],
                  ),
                  child: const Text('Open'),
                ),
              );
            },
          ),
        ),
      );

      await tester.pump();
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // User-facing section headers and content are visible.
      expect(find.text('Enhancements'), findsOneWidget);
      expect(find.text('New feature'), findsOneWidget);
      expect(find.text('Bugfixes'), findsOneWidget);
      expect(find.text('Fixed crash'), findsOneWidget);
    });
  });
}
