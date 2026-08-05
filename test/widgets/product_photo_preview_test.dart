import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/widgets/product_photo_preview.dart';
import '../helpers/pump_app.dart';

/// A minimal 1x1 transparent PNG so [Image.file] decodes in tests.
final Uint8List kTransparentPng = Uint8List.fromList(const <int>[
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0x00,
  0x01,
  0x00,
  0x00,
  0x05,
  0x00,
  0x01,
  0x0D,
  0x0A,
  0x2D,
  0xB4,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
]);

/// Holds the [Navigator.push] result future so tests can await it after
/// performing the action under test without triggering future flattening.
class PreviewHarness {
  /// Completes with the [PhotoPreviewAction] when the preview route pops.
  Future<PhotoPreviewAction?>? routeFuture;
}

/// Pushes [ProductPhotoPreview] and returns a [PreviewHarness].
Future<PreviewHarness> pushPreview(
  WidgetTester tester,
  File image, {
  required String label,
  Locale? locale,
}) async {
  final harness = PreviewHarness();
  await pumpApp(
    tester,
    Builder(
      builder: (context) => ElevatedButton(
        onPressed: () {
          harness.routeFuture = Navigator.push<PhotoPreviewAction>(
            context,
            MaterialPageRoute<PhotoPreviewAction>(
              builder: (_) => ProductPhotoPreview(image: image, label: label),
            ),
          );
        },
        child: const Text('Open preview'),
      ),
    ),
    locale: locale,
  );
  await tester.tap(find.text('Open preview'));
  await tester.pumpAndSettle();
  return harness;
}

void main() {
  late Directory tempDir;
  late File imageFile;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('preview_test_');
    imageFile = File('${tempDir.path}/photo.png')
      ..writeAsBytesSync(kTransparentPng);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('ProductPhotoPreview', () {
    testWidgets('shows the image and photo type label', (tester) async {
      await pushPreview(tester, imageFile, label: 'Nutrition table photo');

      expect(find.byType(ProductPhotoPreview), findsOneWidget);
      expect(find.byType(Image), findsWidgets);
      expect(find.text('Nutrition table photo'), findsOneWidget);
    });

    testWidgets('shows all actions without requiring a custom gesture', (
      tester,
    ) async {
      await pushPreview(tester, imageFile, label: 'Product photo');

      expect(find.text('Retake photo'), findsOneWidget);
      expect(find.text('Replace photo'), findsOneWidget);
      expect(find.text('Delete photo'), findsOneWidget);
      expect(find.byTooltip('Close'), findsOneWidget);
    });

    testWidgets('retake pops with PhotoPreviewAction.retake', (tester) async {
      final harness = await pushPreview(
        tester,
        imageFile,
        label: 'Product photo',
      );

      await tester.tap(find.text('Retake photo'));
      await tester.pumpAndSettle();

      expect(find.byType(ProductPhotoPreview), findsNothing);
      expect(await harness.routeFuture, PhotoPreviewAction.retake);
    });

    testWidgets('replace pops with PhotoPreviewAction.replace', (tester) async {
      final harness = await pushPreview(
        tester,
        imageFile,
        label: 'Product photo',
      );

      await tester.tap(find.text('Replace photo'));
      await tester.pumpAndSettle();

      expect(find.byType(ProductPhotoPreview), findsNothing);
      expect(await harness.routeFuture, PhotoPreviewAction.replace);
    });

    testWidgets('delete pops with PhotoPreviewAction.delete', (tester) async {
      final harness = await pushPreview(
        tester,
        imageFile,
        label: 'Product photo',
      );

      await tester.tap(find.text('Delete photo'));
      await tester.pumpAndSettle();

      expect(find.byType(ProductPhotoPreview), findsNothing);
      expect(await harness.routeFuture, PhotoPreviewAction.delete);
    });

    testWidgets('close pops with PhotoPreviewAction.close', (tester) async {
      final harness = await pushPreview(
        tester,
        imageFile,
        label: 'Product photo',
      );

      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();

      expect(find.byType(ProductPhotoPreview), findsNothing);
      expect(await harness.routeFuture, PhotoPreviewAction.close);
    });

    testWidgets('actions are exposed as accessible buttons', (tester) async {
      await pushPreview(tester, imageFile, label: 'Product photo');

      for (final label in [
        'Retake photo',
        'Replace photo',
        'Delete photo',
        'Close',
      ]) {
        final node = tester.getSemantics(find.bySemanticsLabel(label));
        expect(
          node.flagsCollection.isButton,
          isTrue,
          reason: '$label must be announced as a button',
        );
      }
    });

    testWidgets('action bar fits without overflow on a narrow screen', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await pushPreview(
        tester,
        imageFile,
        label: 'Foto do produto',
        locale: const Locale('pt', 'BR'),
      );

      expect(find.text('Tirar foto novamente'), findsOneWidget);
      expect(find.text('Substituir foto'), findsOneWidget);
      expect(find.text('Excluir foto'), findsOneWidget);
    });
  });
}
