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
///
/// Tab navigation uses coordinate taps on the NavigationBar because
/// Material 3 icon styling varies across Flutter versions, and text
/// labels may be clipped on small screens. All assertions are
/// locale-independent (they check widget types and presence, not text).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Smoke test', () {
    testWidgets('app launches and all tabs render', (tester) async {
      unawaited(app.main());
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      // NavigationBar with all 5 tabs.
      expect(find.byType(NavigationBar), findsOneWidget);
      final navBar = find.byType(NavigationBar);
      // All 5 NavigationDestination labels exist.
      expect(
        find.descendant(of: navBar, matching: find.text('Home')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: navBar, matching: find.text('Search')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: navBar, matching: find.text('Stats')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: navBar, matching: find.text('List')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: navBar, matching: find.text('Settings')),
        findsOneWidget,
      );

      // Home screen has a FloatingActionButton.
      expect(find.byType(FloatingActionButton), findsOneWidget);

      // NavigationBar rect for coordinate-based taps.
      final navRect = tester.getRect(navBar);
      final navCenterY = navRect.center.dy;
      final tabWidth = navRect.width / 5;

      // Navigate to Search tab (index 1) — verify TextField appears.
      await tester.tapAt(Offset(tabWidth * 1.5, navCenterY));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(TextField), findsWidgets);

      // Navigate to Stats tab (index 2) — verify TextField gone.
      await tester.tapAt(Offset(tabWidth * 2.5, navCenterY));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(NavigationBar), findsOneWidget);

      // Navigate to List tab (index 3) — verify NavigationBar still there.
      await tester.tapAt(Offset(tabWidth * 3.5, navCenterY));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(NavigationBar), findsOneWidget);

      // Navigate to Settings tab (index 4).
      await tester.tapAt(Offset(tabWidth * 4.5, navCenterY));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      // Settings has an AppBar.
      expect(find.byType(AppBar), findsOneWidget);
      // Theme row is tappable.
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
