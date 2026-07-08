import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:pantry_app/main.dart' as app;

/// Smoke tests for the Pantry App.
///
/// Verifies the app starts, all 5 main tabs render, and key interactive
/// elements respond to taps. Run with `flutter test integration_test/`
/// on a connected Android device or emulator.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Smoke test', () {
    testWidgets('app launches and all tabs render', (tester) async {
      unawaited(app.main());
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      // NavigationBar with all 5 tabs.
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Search'), findsOneWidget);
      expect(find.text('Stats'), findsOneWidget);
      expect(find.text('List'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);

      // Home screen has a FloatingActionButton.
      expect(find.byType(FloatingActionButton), findsOneWidget);

      // Navigate to Search tab.
      await tester.tap(find.text('Search'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(TextField), findsWidgets);

      // Navigate to Stats tab.
      await tester.tap(find.text('Stats'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byIcon(Icons.bar_chart), findsAtLeast(1));
      expect(find.text('No items to analyze'), findsOneWidget);

      // Navigate to List tab.
      await tester.tap(find.text('List'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byIcon(Icons.shopping_cart_outlined), findsWidgets);

      // Navigate to Settings tab.
      await tester.tap(find.text('Settings'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text('Settings'),
        ),
        findsOneWidget,
      );

      // Settings page has theme content visible without scrolling.
      expect(find.text('Theme'), findsOneWidget);

      // Open theme dialog.
      await tester.tap(find.text('Theme'));
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.text('Choose theme'), findsOneWidget);

      // Select "dark" theme to dismiss dialog.
      await tester.tap(find.text('dark'));
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.text('Choose theme'), findsNothing);
    });
  });
}
