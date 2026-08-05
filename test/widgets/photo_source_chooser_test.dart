import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/widgets/photo_source_chooser.dart';
import '../helpers/pump_app.dart';

/// Holds the [showPhotoSourceChooser] result future so tests can await it
/// after choosing a source without triggering future flattening.
class ChooserHarness {
  /// Completes with the chosen [PhotoSource] (null on cancel).
  Future<PhotoSource?>? result;
}

/// Opens the source chooser and returns a [ChooserHarness].
Future<ChooserHarness> openChooser(WidgetTester tester) async {
  final harness = ChooserHarness();
  await pumpApp(
    tester,
    Builder(
      builder: (context) => ElevatedButton(
        onPressed: () {
          harness.result = showPhotoSourceChooser(context);
        },
        child: const Text('Open chooser'),
      ),
    ),
  );
  await tester.tap(find.text('Open chooser'));
  await tester.pumpAndSettle();
  return harness;
}

void main() {
  group('PhotoSourceChooser', () {
    testWidgets('shows title and both source options', (tester) async {
      await openChooser(tester);

      expect(find.text('Choose photo source'), findsOneWidget);
      expect(find.text('Take a new photo'), findsOneWidget);
      expect(find.text('Choose an existing photo'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('tapping camera returns PhotoSource.camera', (tester) async {
      final harness = await openChooser(tester);

      await tester.tap(find.text('Take a new photo'));
      await tester.pumpAndSettle();

      expect(await harness.result, PhotoSource.camera);
    });

    testWidgets('tapping gallery returns PhotoSource.gallery', (tester) async {
      final harness = await openChooser(tester);

      await tester.tap(find.text('Choose an existing photo'));
      await tester.pumpAndSettle();

      expect(await harness.result, PhotoSource.gallery);
    });

    testWidgets('tapping cancel returns null', (tester) async {
      final harness = await openChooser(tester);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(await harness.result, isNull);
    });

    testWidgets('source options are exposed as accessible buttons', (
      tester,
    ) async {
      await openChooser(tester);

      for (final label in ['Take a new photo', 'Choose an existing photo']) {
        final node = tester.getSemantics(find.bySemanticsLabel(label));
        expect(
          node.flagsCollection.isButton,
          isTrue,
          reason: '$label must be announced as a button',
        );
      }
    });
  });
}
