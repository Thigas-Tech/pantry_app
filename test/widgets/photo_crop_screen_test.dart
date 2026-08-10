import 'dart:io';

import 'package:crop_image/crop_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:mocktail/mocktail.dart';
import 'package:pantry_app/providers/product_photo_cropper_provider.dart';
import 'package:pantry_app/services/product_photo_cropper.dart';
import 'package:pantry_app/widgets/photo_crop_screen.dart';
import '../helpers/pump_app.dart';

class MockProductPhotoCropper extends Mock implements ProductPhotoCropper {}

/// Holds the [Navigator.push] result future so tests can await it after
/// performing the action under test without triggering future flattening.
class CropHarness {
  /// Completes with the cropped file, or null when the crop was cancelled.
  Future<File?>? routeResult;
}

/// Pushes [PhotoCropScreen] and returns a [CropHarness].
Future<CropHarness> pushCropScreen(
  WidgetTester tester, {
  required File input,
  required String label,
  required MockProductPhotoCropper cropper,
  Locale? locale,
}) async {
  final harness = CropHarness();
  await pumpApp(
    tester,
    Builder(
      builder: (context) => ElevatedButton(
        onPressed: () {
          harness.routeResult = showPhotoCropScreen(
            context,
            inputFile: input,
            label: label,
          );
        },
        child: const Text('Open crop'),
      ),
    ),
    overrides: [
      productPhotoCropperProvider.overrideWithValue(cropper),
    ],
    locale: locale,
    settle: false,
  );
  // CropImage shows an animated placeholder until the real PNG decodes, which
  // only happens on the live event loop. Warm the image cache BEFORE the
  // screen mounts (runAsync must not touch the widget tree, and a resolve
  // started in fake async never completes), then push the route so the crop
  // grid renders instead of a spinning placeholder.
  await tester.runAsync(() async {
    final context = tester.element(find.byType(ElevatedButton));
    await precacheImage(FileImage(input), context);
  });
  await tester.tap(find.text('Open crop'));
  await tester.pumpAndSettle();
  return harness;
}

void main() {
  late Directory tempDir;
  late MockProductPhotoCropper mockCropper;

  setUpAll(() {
    registerFallbackValue(CropRotation.up);
    registerFallbackValue(const Rect.fromLTWH(0, 0, 1, 1));
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('crop_screen_test_');
    mockCropper = MockProductPhotoCropper();
    when(
      () => mockCropper.crop(
        sourcePath: any(named: 'sourcePath'),
        cropRect: any(named: 'cropRect'),
        rotation: any(named: 'rotation'),
      ),
    ).thenAnswer((_) async => null);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  /// Writes a solid-color PNG of [width] x [height] and returns its file.
  ///
  /// Writes synchronously because real async file I/O never completes under
  /// the fake-async zone used by [testWidgets].
  File png(String name, int width, int height) {
    final image = img.Image(width: width, height: height);
    img.fill(image, color: img.ColorRgb8(20, 40, 60));
    return File('${tempDir.path}/$name')
      ..writeAsBytesSync(img.encodePng(image));
  }

  /// A square source large enough that a full crop clears the minimum guard
  /// in both orientations.
  File bigPng(String name) => png(name, 800, 800);

  group('PhotoCropScreen', () {
    testWidgets('shows the photo and the slot label', (tester) async {
      final input = bigPng('input.png');

      await pushCropScreen(
        tester,
        input: input,
        label: 'Nutrition table photo',
        cropper: mockCropper,
      );

      expect(find.byType(PhotoCropScreen), findsOneWidget);
      expect(find.byType(CropImage), findsOneWidget);
      expect(find.text('Nutrition table photo'), findsOneWidget);
    });

    testWidgets('rotate controls are exposed as accessible buttons', (
      tester,
    ) async {
      final input = bigPng('input.png');

      await pushCropScreen(
        tester,
        input: input,
        label: 'Product photo',
        cropper: mockCropper,
      );

      for (final label in ['Rotate left', 'Rotate right']) {
        expect(find.byTooltip(label), findsOneWidget);
        final node = tester.getSemantics(find.bySemanticsLabel(label));
        expect(
          node.flagsCollection.isButton,
          isTrue,
          reason: '$label must be announced as a button',
        );
      }
    });

    testWidgets('apply crops the full image and pops the cropped file', (
      tester,
    ) async {
      final input = bigPng('input.png');
      final cropped = File('${tempDir.path}/cropped.jpg')
        ..writeAsBytesSync(<int>[1, 2, 3]);
      when(
        () => mockCropper.crop(
          sourcePath: any(named: 'sourcePath'),
          cropRect: any(named: 'cropRect'),
          rotation: any(named: 'rotation'),
        ),
      ).thenAnswer((_) async => cropped);
      final harness = await pushCropScreen(
        tester,
        input: input,
        label: 'Product photo',
        cropper: mockCropper,
      );

      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      expect(find.byType(PhotoCropScreen), findsNothing);
      expect(await harness.routeResult, same(cropped));
      verify(
        () => mockCropper.crop(
          sourcePath: input.path,
          cropRect: const Rect.fromLTWH(0, 0, 1, 1),
          rotation: CropRotation.up,
        ),
      ).called(1);
    });

    testWidgets('rotate right then apply requests a right rotation', (
      tester,
    ) async {
      final input = bigPng('input.png');
      final cropped = File('${tempDir.path}/cropped.jpg')
        ..writeAsBytesSync(<int>[1, 2, 3]);
      when(
        () => mockCropper.crop(
          sourcePath: any(named: 'sourcePath'),
          cropRect: any(named: 'cropRect'),
          rotation: any(named: 'rotation'),
        ),
      ).thenAnswer((_) async => cropped);
      final harness = await pushCropScreen(
        tester,
        input: input,
        label: 'Product photo',
        cropper: mockCropper,
      );

      await tester.tap(find.byTooltip('Rotate right'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      expect(find.byType(PhotoCropScreen), findsNothing);
      expect(await harness.routeResult, same(cropped));
      verify(
        () => mockCropper.crop(
          sourcePath: input.path,
          cropRect: const Rect.fromLTWH(0, 0, 1, 1),
          rotation: CropRotation.right,
        ),
      ).called(1);
    });

    testWidgets('close pops null without cropping', (tester) async {
      final input = bigPng('input.png');
      final harness = await pushCropScreen(
        tester,
        input: input,
        label: 'Product photo',
        cropper: mockCropper,
      );

      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();

      expect(find.byType(PhotoCropScreen), findsNothing);
      expect(await harness.routeResult, isNull);
      verifyNever(
        () => mockCropper.crop(
          sourcePath: any(named: 'sourcePath'),
          cropRect: any(named: 'cropRect'),
          rotation: any(named: 'rotation'),
        ),
      );
    });

    testWidgets('a failed crop shows an error and keeps the screen open', (
      tester,
    ) async {
      final input = bigPng('input.png');
      await pushCropScreen(
        tester,
        input: input,
        label: 'Product photo',
        cropper: mockCropper,
      );

      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      expect(find.byType(PhotoCropScreen), findsOneWidget);
      expect(find.text('Could not crop photo.'), findsOneWidget);
    });

    testWidgets('a too-small crop shows a warning and never crops', (
      tester,
    ) async {
      final input = png('small.png', 200, 100);
      await pushCropScreen(
        tester,
        input: input,
        label: 'Product photo',
        cropper: mockCropper,
      );

      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      expect(find.byType(PhotoCropScreen), findsOneWidget);
      expect(
        find.text('The cropped photo is too small. Crop a larger area.'),
        findsOneWidget,
      );
      verifyNever(
        () => mockCropper.crop(
          sourcePath: any(named: 'sourcePath'),
          cropRect: any(named: 'cropRect'),
          rotation: any(named: 'rotation'),
        ),
      );
    });
  });
}
