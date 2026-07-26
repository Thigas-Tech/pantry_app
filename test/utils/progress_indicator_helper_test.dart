/// Tests for [ProgressIndicatorHelper].
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/utils/progress_indicator_helper.dart';

void main() {
  group('ProgressIndicatorHelper', () {
    group('circular', () {
      testWidgets('indeterminate circular by default', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ProgressIndicatorHelper.build(),
            ),
          ),
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        final indicator = tester.widget<CircularProgressIndicator>(
          find.byType(CircularProgressIndicator),
        );
        expect(indicator.value, isNull);
      });

      testWidgets('determinate circular with value', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ProgressIndicatorHelper.build(value: 0.3),
            ),
          ),
        );

        final indicator = tester.widget<CircularProgressIndicator>(
          find.byType(CircularProgressIndicator),
        );
        expect(indicator.value, 0.3);
      });

      testWidgets('size wraps in SizedBox with correct dimensions', (
        tester,
      ) async {
        const customSize = 24.0;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ProgressIndicatorHelper.build(size: customSize),
            ),
          ),
        );

        final sizedBox = tester.widget<SizedBox>(
          find.byType(SizedBox),
        );
        expect(sizedBox.width, customSize);
        expect(sizedBox.height, customSize);
      });

      testWidgets('strokeWidth forwarded to CircularProgressIndicator', (
        tester,
      ) async {
        const customStroke = 2.0;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ProgressIndicatorHelper.build(strokeWidth: customStroke),
            ),
          ),
        );

        final indicator = tester.widget<CircularProgressIndicator>(
          find.byType(CircularProgressIndicator),
        );
        expect(indicator.strokeWidth, customStroke);
      });

      testWidgets('defaults to 36.0 size and 4.0 strokeWidth', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ProgressIndicatorHelper.build(),
            ),
          ),
        );

        final sizedBox = tester.widget<SizedBox>(
          find.byType(SizedBox),
        );
        expect(sizedBox.width, 36.0);
        expect(sizedBox.height, 36.0);

        final indicator = tester.widget<CircularProgressIndicator>(
          find.byType(CircularProgressIndicator),
        );
        expect(indicator.strokeWidth, 4.0);
      });

      testWidgets('color forwarded to CircularProgressIndicator.color', (
        tester,
      ) async {
        const customColor = Colors.green;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ProgressIndicatorHelper.build(color: customColor),
            ),
          ),
        );

        final indicator = tester.widget<CircularProgressIndicator>(
          find.byType(CircularProgressIndicator),
        );
        expect(indicator.color, customColor);
      });

      testWidgets('backgroundColor forwarded to CircularProgressIndicator', (
        tester,
      ) async {
        const customBg = Colors.grey;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ProgressIndicatorHelper.build(backgroundColor: customBg),
            ),
          ),
        );

        final indicator = tester.widget<CircularProgressIndicator>(
          find.byType(CircularProgressIndicator),
        );
        expect(indicator.backgroundColor, customBg);
      });
    });

    group('linear', () {
      testWidgets('indeterminate linear', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ProgressIndicatorHelper.build(
                type: ProgressIndicatorType.linear,
              ),
            ),
          ),
        );

        expect(find.byType(LinearProgressIndicator), findsOneWidget);
        final indicator = tester.widget<LinearProgressIndicator>(
          find.byType(LinearProgressIndicator),
        );
        expect(indicator.value, isNull);
      });

      testWidgets('determinate linear with value', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ProgressIndicatorHelper.build(
                type: ProgressIndicatorType.linear,
                value: 0.7,
              ),
            ),
          ),
        );

        final indicator = tester.widget<LinearProgressIndicator>(
          find.byType(LinearProgressIndicator),
        );
        expect(indicator.value, 0.7);
      });

      testWidgets('minHeight forwarded to LinearProgressIndicator', (
        tester,
      ) async {
        const customHeight = 8.0;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ProgressIndicatorHelper.build(
                type: ProgressIndicatorType.linear,
                minHeight: customHeight,
              ),
            ),
          ),
        );

        final indicator = tester.widget<LinearProgressIndicator>(
          find.byType(LinearProgressIndicator),
        );
        expect(indicator.minHeight, customHeight);
      });

      testWidgets('default minHeight is 4.0', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ProgressIndicatorHelper.build(
                type: ProgressIndicatorType.linear,
              ),
            ),
          ),
        );

        final indicator = tester.widget<LinearProgressIndicator>(
          find.byType(LinearProgressIndicator),
        );
        expect(indicator.minHeight, 4.0);
      });

      testWidgets('color forwarded to LinearProgressIndicator.color', (
        tester,
      ) async {
        const customColor = Colors.orange;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ProgressIndicatorHelper.build(
                type: ProgressIndicatorType.linear,
                color: customColor,
              ),
            ),
          ),
        );

        final indicator = tester.widget<LinearProgressIndicator>(
          find.byType(LinearProgressIndicator),
        );
        expect(indicator.color, customColor);
      });

      testWidgets('backgroundColor forwarded to LinearProgressIndicator', (
        tester,
      ) async {
        const customBg = Colors.black12;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ProgressIndicatorHelper.build(
                type: ProgressIndicatorType.linear,
                backgroundColor: customBg,
              ),
            ),
          ),
        );

        final indicator = tester.widget<LinearProgressIndicator>(
          find.byType(LinearProgressIndicator),
        );
        expect(indicator.backgroundColor, customBg);
      });
    });
  });
}
