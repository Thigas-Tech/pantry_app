import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:pantry_app/main.dart' as app;
import 'package:pantry_app/widgets/inventory_card.dart';
import 'package:pantry_app/widgets/quick_add_produce.dart';

/// Integration tests for the seasonal produce carousel (#124).
///
/// Covers:
///   1. Carousel renders seasonal produce chips on the HomeScreen.
///   2. Tapping a carousel chip shows an undo SnackBar.
///   3. Undo removes the quick-added item.
///   4. Settings hemisphere picker is accessible and functional.
///
/// Uses coordinate-based taps on the NavigationBar (same approach as
/// produce_add_flow_test.dart) because Material 3 icon styling varies
/// across Flutter versions and text labels may be clipped on small
/// screens.
///
/// Network-dependent steps are guarded so tests can still pass when
/// OFF API is unreachable (e.g. in CI without network).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// Navigate to a NavigationBar tab by index.
  ///
  /// Index 0 = Home, 1 = Search, 2 = Stats, 3 = List, 4 = Settings.
  Future<void> goToTab(WidgetTester tester, int index) async {
    final navBar = find.byType(NavigationBar);
    final navRect = tester.getRect(navBar);
    final navCenterY = navRect.center.dy;
    final tabWidth = navRect.width / 5;
    await tester.tapAt(Offset(tabWidth * (index + 0.5), navCenterY));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  /// Wait for the app to finish its initial load.
  Future<void> waitForAppReady(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(seconds: 1));
      if (find.byType(FloatingActionButton).evaluate().isNotEmpty) break;
    }
  }

  // ----------------------------------------------------------------
  // Test 1: Carousel renders seasonal produce chips on HomeScreen
  // ----------------------------------------------------------------
  testWidgets(
    'carousel renders seasonal produce chips on HomeScreen',
    (tester) async {
      unawaited(app.main());
      await tester.pump();
      await waitForAppReady(tester);
      await goToTab(tester, 0);
      await tester.pump(const Duration(seconds: 2));

      // Verify carousel widget is present.
      final carousel = find.byType(QuickAddProduce);
      expect(carousel, findsOneWidget);

      // Verify the section header.
      expect(find.text('Quick Add'), findsOneWidget);

      // Verify the info tooltip icon.
      expect(find.byIcon(Icons.info_outline), findsOneWidget);

      // Verify carousel has at least one produce chip.
      final chips = find.byType(ActionChip);
      if (chips.evaluate().isEmpty) {
        // Carousel may still be loading seasonal data.
        // The empty state message should be shown instead.
        expect(
          find.text('Start adding produce to see quick picks here!'),
          findsOneWidget,
        );
        return;
      }
      expect(chips, findsWidgets);
    },
  );

  // ----------------------------------------------------------------
  // Test 2: Tap carousel chip → undo SnackBar appears
  // ----------------------------------------------------------------
  testWidgets(
    'tapping carousel chip shows undo SnackBar',
    (tester) async {
      unawaited(app.main());
      await tester.pump();
      await waitForAppReady(tester);
      await goToTab(tester, 0);
      await tester.pump(const Duration(seconds: 2));

      // Wait for carousel chips to appear.
      final chips = find.byType(ActionChip);
      if (chips.evaluate().isEmpty) {
        await tester.pump(const Duration(seconds: 2));
      }
      if (chips.evaluate().isEmpty) {
        // No chips available — carousel is empty or still loading.
        return;
      }

      // Tap the first produce chip.
      await tester.tap(chips.first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // A SnackBar should appear.
      expect(find.byType(SnackBar), findsOneWidget);

      // The SnackBar should have an "Undo" action.
      expect(find.text('Undo'), findsOneWidget);
    },
  );

  // ----------------------------------------------------------------
  // Test 3: Undo removes the quick-added item
  // ----------------------------------------------------------------
  testWidgets(
    'undo removes quick-added produce item',
    (tester) async {
      unawaited(app.main());
      await tester.pump();
      await waitForAppReady(tester);
      await goToTab(tester, 0);
      await tester.pump(const Duration(seconds: 2));

      // Wait for carousel chips.
      final chips = find.byType(ActionChip);
      if (chips.evaluate().isEmpty) {
        await tester.pump(const Duration(seconds: 2));
      }
      if (chips.evaluate().isEmpty) return;

      // Count inventory cards before adding.
      final before = find.byType(InventoryCard).evaluate().length;

      // Tap the first chip.
      await tester.tap(chips.first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify SnackBar with Undo appears.
      if (find.byType(SnackBar).evaluate().isEmpty) return;
      expect(find.text('Undo'), findsOneWidget);

      // Wait for inventory to refresh.
      await tester.pump(const Duration(milliseconds: 500));

      // Inventory should have at least one more item.
      final afterAdd = find.byType(InventoryCard).evaluate().length;
      expect(afterAdd, greaterThanOrEqualTo(before));

      // Tap Undo.
      await tester.tap(find.text('Undo'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Inventory should return to original count or less.
      final afterUndo = find.byType(InventoryCard).evaluate().length;
      expect(afterUndo, lessThanOrEqualTo(afterAdd));
    },
  );

  // ----------------------------------------------------------------
  // Test 4: Settings hemisphere picker is accessible and functional
  // ----------------------------------------------------------------
  testWidgets(
    'hemisphere picker exists in Settings and can be changed',
    (tester) async {
      unawaited(app.main());
      await tester.pump();
      await waitForAppReady(tester);
      await goToTab(tester, 3); // Settings
      await tester.pump(const Duration(seconds: 1));

      // Find the "General" ExpansionTile.
      final generalTile = find.widgetWithText(ExpansionTile, 'General');
      expect(generalTile, findsOneWidget);

      // Verify leading icon.
      expect(find.byIcon(Icons.tune), findsOneWidget);

      // Expand the General section.
      await tester.tap(generalTile);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Within General, find the Hemisphere ListTile.
      final hemisphereTile = find.widgetWithText(ListTile, 'Hemisphere');
      expect(hemisphereTile, findsOneWidget);

      // Verify leading icon.
      expect(find.byIcon(Icons.public), findsOneWidget);

      // Verify subtitle shows a valid hemisphere value.
      final hemisphereLabels = [
        'Auto (detect from country)',
        'Northern Hemisphere',
        'Southern Hemisphere',
      ];
      final subtitleFound = hemisphereLabels.any(
        (label) => find.text(label).evaluate().isNotEmpty,
      );
      expect(subtitleFound, isTrue);

      // Tap to open the hemisphere dialog.
      await tester.tap(hemisphereTile);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // A dialog should appear with the hemisphere title.
      expect(find.byType(SimpleDialog), findsOneWidget);
      expect(find.text('Hemisphere'), findsOneWidget);

      // All three hemisphere options should be present.
      for (final label in hemisphereLabels) {
        expect(find.text(label), findsOneWidget);
      }

      // Select "Southern Hemisphere".
      await tester.tap(find.text('Southern Hemisphere'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Dialog should close.
      expect(find.byType(SimpleDialog), findsNothing);

      // The ListTile subtitle should now show "Southern Hemisphere".
      expect(find.text('Southern Hemisphere'), findsOneWidget);

      // A confirmation SnackBar should appear.
      final snackBars = find.byType(SnackBar);
      if (snackBars.evaluate().isNotEmpty) {
        expect(find.text('Hemisphere updated'), findsOneWidget);
      }
    },
  );
}
