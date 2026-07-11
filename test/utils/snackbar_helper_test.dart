import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/l10n/app_localizations.dart';
import 'package:pantry_app/utils/snackbar_helper.dart';

/// A helper that pumps a minimal app with a [Scaffold] and a callback
/// that triggers a snackbar via [SnackbarHelper].
Future<void> pumpTestApp(
  WidgetTester tester,
  Future<void> Function(BuildContext context) trigger,
) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => trigger(context),
              child: const Text('Trigger'),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('SnackbarHelper', () {
    testWidgets('showInfo shows a styled snackbar', (tester) async {
      await pumpTestApp(tester, (context) async {
        SnackbarHelper.showInfo(context, 'Info message');
      });

      // Tap the button.
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump(); // animate snackbar in

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Info message'), findsOneWidget);
    });

    testWidgets('showWarning shows a styled snackbar', (tester) async {
      await pumpTestApp(tester, (context) async {
        SnackbarHelper.showWarning(context, 'Warning message');
      });

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Warning message'), findsOneWidget);
    });

    testWidgets('showError shows a styled snackbar', (tester) async {
      await pumpTestApp(tester, (context) async {
        SnackbarHelper.showError(context, 'Error message');
      });

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Error message'), findsOneWidget);
    });
  });
}
