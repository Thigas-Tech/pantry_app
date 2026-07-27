/// Tests for the [OnboardingFlow] widget.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/widgets/onboarding_flow.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/pump_app.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('OnboardingFlow', () {
    testWidgets(
      'renders first page title, Next, and Skip; Back absent; Get Started'
      ' absent',
      (
        tester,
      ) async {
        await pumpApp(
          tester,
          OnboardingFlow(
            onScanBarcode: () {},
            onSearchProduct: () {},
            onAddProduce: () {},
            onGetStarted: () {},
          ),
        );

        expect(find.text('Scan Barcodes'), findsOneWidget);
        expect(
          find.text(
            'Quickly add products to your pantry by scanning their barcodes'
            ' with your camera.',
          ),
          findsOneWidget,
        );
        expect(find.text('Skip'), findsOneWidget);
        expect(find.text('Next'), findsOneWidget);
        expect(find.text('Back'), findsNothing);
        expect(find.text('Get Started'), findsNothing);
        expect(find.text('Set Up'), findsNothing);
      },
    );

    testWidgets(
      'Next button advances through all pages, Set Up and Get Started appear'
      ' on correct pages',
      (
        tester,
      ) async {
        await pumpApp(
          tester,
          OnboardingFlow(
            onScanBarcode: () {},
            onSearchProduct: () {},
            onAddProduce: () {},
            onGetStarted: () {},
          ),
        );

        expect(find.text('Search Products'), findsNothing);

        // Page 1 -> 2
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
        expect(find.text('Search Products'), findsOneWidget);

        // Page 2 -> 3
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
        expect(find.text('Fresh Produce'), findsOneWidget);

        // Page 3 -> 4 (Configure)
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
        expect(find.text('Configure Your Pantry'), findsOneWidget);
        expect(find.text('Set Up'), findsAtLeast(1));
        expect(find.text('Next'), findsNothing);

        // Page 4 -> 5 (Track Everything)
        await tester.tap(find.text('Set Up').last);
        await tester.pumpAndSettle();
        expect(find.text('Track Everything'), findsOneWidget);
        expect(find.text('Get Started'), findsAtLeast(1));
        expect(find.text('Next'), findsNothing);
      },
    );

    testWidgets('Back button visible from page 2, navigates to previous page', (
      tester,
    ) async {
      await pumpApp(
        tester,
        OnboardingFlow(
          onScanBarcode: () {},
          onSearchProduct: () {},
          onAddProduce: () {},
          onGetStarted: () {},
        ),
      );

      expect(find.text('Back'), findsNothing);

      // Go to page 2
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('Back'), findsOneWidget);
      expect(find.text('Search Products'), findsOneWidget);

      // Back to page 1
      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();
      expect(find.text('Scan Barcodes'), findsOneWidget);
      expect(find.text('Back'), findsNothing);
    });

    testWidgets('Skip button fires onGetStarted', (tester) async {
      var getStartedFired = false;

      await pumpApp(
        tester,
        OnboardingFlow(
          onScanBarcode: () {},
          onSearchProduct: () {},
          onAddProduce: () {},
          onGetStarted: () => getStartedFired = true,
        ),
      );

      await tester.tap(find.text('Skip'));
      expect(getStartedFired, isTrue);
    });

    testWidgets('Get Started button fires onGetStarted', (tester) async {
      var getStartedFired = false;

      await pumpApp(
        tester,
        OnboardingFlow(
          onScanBarcode: () {},
          onSearchProduct: () {},
          onAddProduce: () {},
          onGetStarted: () => getStartedFired = true,
        ),
      );

      // Go to last page (page 5)
      for (var i = 0; i < 4; i++) {
        if (i < 3) {
          await tester.tap(find.text('Next'));
        } else {
          await tester.tap(find.text('Set Up').last);
        }
        await tester.pumpAndSettle();
      }

      await tester.tap(find.text('Get Started').last);
      expect(getStartedFired, isTrue);
    });

    testWidgets('swipe left advances to page 2', (tester) async {
      await pumpApp(
        tester,
        OnboardingFlow(
          onScanBarcode: () {},
          onSearchProduct: () {},
          onAddProduce: () {},
          onGetStarted: () {},
        ),
      );

      await tester.drag(find.byType(PageView), const Offset(-500, 0));
      await tester.pumpAndSettle();

      expect(find.text('Search Products'), findsOneWidget);
    });

    testWidgets('Page 1 CTA fires onScanBarcode', (tester) async {
      var scanFired = false;

      await pumpApp(
        tester,
        OnboardingFlow(
          onScanBarcode: () => scanFired = true,
          onSearchProduct: () {},
          onAddProduce: () {},
          onGetStarted: () {},
        ),
      );

      await tester.tap(find.text('Open Scanner'));
      expect(scanFired, isTrue);
    });

    testWidgets('Page 3 CTA fires onAddProduce', (tester) async {
      var addProduceFired = false;

      await pumpApp(
        tester,
        OnboardingFlow(
          onScanBarcode: () {},
          onSearchProduct: () {},
          onAddProduce: () => addProduceFired = true,
          onGetStarted: () {},
        ),
      );

      // Go to page 3
      for (var i = 0; i < 2; i++) {
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
      }

      await tester.tap(find.text('Add Produce'));
      expect(addProduceFired, isTrue);
    });

    testWidgets('Configure page shows price tracking toggle', (tester) async {
      await pumpApp(
        tester,
        OnboardingFlow(
          onScanBarcode: () {},
          onSearchProduct: () {},
          onAddProduce: () {},
          onGetStarted: () {},
        ),
      );

      // Go to page 4
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
      }

      expect(find.text('Enable price tracking'), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);
    });

    testWidgets(
      'Configure page shows currency, data retention, and expiry warning',
      (
        tester,
      ) async {
        await pumpApp(
          tester,
          OnboardingFlow(
            onScanBarcode: () {},
            onSearchProduct: () {},
            onAddProduce: () {},
            onGetStarted: () {},
          ),
        );

        // Go to page 4
        for (var i = 0; i < 3; i++) {
          await tester.tap(find.text('Next'));
          await tester.pumpAndSettle();
        }

        expect(find.text('Data retention'), findsOneWidget);
        expect(find.text('Expiring soon threshold'), findsOneWidget);
        expect(find.text('USD'), findsOneWidget);
      },
    );
  });
}
