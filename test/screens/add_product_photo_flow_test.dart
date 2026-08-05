import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pantry_app/models/photo_pick_result.dart';
import 'package:pantry_app/providers/product_photo_picker_provider.dart';
import 'package:pantry_app/screens/add_product_screen.dart';
import 'package:pantry_app/services/product_photo_picker.dart';
import 'package:pantry_app/widgets/photo_source_chooser.dart';
import 'package:pantry_app/widgets/product_photo_preview.dart';
import 'package:pantry_app/widgets/product_photo_tile.dart';
import '../helpers/pump_app.dart';

class MockProductPhotoPicker extends Mock implements ProductPhotoPicker {}

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

void main() {
  late Directory tempDir;
  late File imageFile;
  late MockProductPhotoPicker mockPicker;

  setUpAll(() {
    registerFallbackValue(PhotoSource.camera);
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('add_photo_test_');
    imageFile = File('${tempDir.path}/photo.png')
      ..writeAsBytesSync(kTransparentPng);
    mockPicker = MockProductPhotoPicker();
    when(
      () => mockPicker.pick(any()),
    ).thenAnswer((_) async => PhotoPicked(imageFile));
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await pumpApp(
      tester,
      const AddProductScreen(barcode: '123'),
      overrides: [
        productPhotoPickerProvider.overrideWithValue(mockPicker),
      ],
    );
    await tester.pumpAndSettle();
  }

  Future<File?> attachNutritionPhoto(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.add_a_photo).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Take a new photo'));
    await tester.pumpAndSettle();
    return imageFile;
  }

  group('AddProductScreen photo flow', () {
    testWidgets('empty slot add opens camera and gallery actions', (
      tester,
    ) async {
      await pumpScreen(tester);

      await tester.tap(find.byIcon(Icons.add_a_photo).first);
      await tester.pumpAndSettle();

      expect(find.text('Choose photo source'), findsOneWidget);
      expect(find.text('Take a new photo'), findsOneWidget);
      expect(find.text('Choose an existing photo'), findsOneWidget);
    });

    testWidgets('choosing camera fills the slot via the picker', (
      tester,
    ) async {
      await pumpScreen(tester);

      await tester.tap(find.byIcon(Icons.add_a_photo).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Take a new photo'));
      await tester.pumpAndSettle();

      verify(() => mockPicker.pick(PhotoSource.camera)).called(1);
      final tile = find.widgetWithText(
        ProductPhotoTile,
        'Nutrition table photo',
      );
      expect(tile, findsOneWidget);
      expect(
        find.descendant(of: tile, matching: find.byType(Image)),
        findsOneWidget,
      );
    });

    testWidgets('choosing gallery picks from the gallery source', (
      tester,
    ) async {
      await pumpScreen(tester);

      await tester.tap(find.byIcon(Icons.add_a_photo).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Choose an existing photo'));
      await tester.pumpAndSettle();

      verify(() => mockPicker.pick(PhotoSource.gallery)).called(1);
    });

    testWidgets('tapping a filled tile opens the preview', (tester) async {
      await pumpScreen(tester);
      await attachNutritionPhoto(tester);

      await tester.tap(
        find.widgetWithText(ProductPhotoTile, 'Nutrition table photo'),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ProductPhotoPreview), findsOneWidget);
      expect(find.text('Nutrition table photo'), findsOneWidget);
    });

    testWidgets('closing the preview keeps form values and other images', (
      tester,
    ) async {
      await pumpScreen(tester);
      await attachNutritionPhoto(tester);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Product name'),
        'Test Product',
      );

      await tester.tap(
        find.widgetWithText(ProductPhotoTile, 'Nutrition table photo'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();

      expect(find.byType(AddProductScreen), findsOneWidget);
      expect(find.text('Test Product'), findsOneWidget);
      final tile = find.widgetWithText(
        ProductPhotoTile,
        'Nutrition table photo',
      );
      expect(
        find.descendant(of: tile, matching: find.byType(Image)),
        findsOneWidget,
      );
    });

    testWidgets('preview replace returns to the source chooser', (
      tester,
    ) async {
      await pumpScreen(tester);
      await attachNutritionPhoto(tester);

      await tester.tap(
        find.widgetWithText(ProductPhotoTile, 'Nutrition table photo'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Replace photo'));
      await tester.pumpAndSettle();

      expect(find.byType(ProductPhotoPreview), findsNothing);
      expect(find.text('Choose photo source'), findsOneWidget);
      expect(find.text('Take a new photo'), findsOneWidget);
      expect(find.text('Choose an existing photo'), findsOneWidget);
    });

    testWidgets('preview retake opens the camera path directly', (
      tester,
    ) async {
      await pumpScreen(tester);
      await attachNutritionPhoto(tester);

      await tester.tap(
        find.widgetWithText(ProductPhotoTile, 'Nutrition table photo'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Retake photo'));
      await tester.pumpAndSettle();

      expect(find.byType(ProductPhotoPreview), findsNothing);
      verify(() => mockPicker.pick(PhotoSource.camera)).called(2);
    });

    testWidgets('tile delete empties the slot and undo restores it', (
      tester,
    ) async {
      await pumpScreen(tester);
      await attachNutritionPhoto(tester);

      final deleteButton = find.descendant(
        of: find.widgetWithText(ProductPhotoTile, 'Nutrition table photo'),
        matching: find.byIcon(Icons.delete_outline),
      );
      await tester.tap(deleteButton);
      await tester.pumpAndSettle();

      final tile = find.widgetWithText(
        ProductPhotoTile,
        'Nutrition table photo',
      );
      expect(
        find.descendant(of: tile, matching: find.byType(Image)),
        findsNothing,
      );
      expect(find.text('Photo removed.'), findsOneWidget);

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();

      final restored = find.widgetWithText(
        ProductPhotoTile,
        'Nutrition table photo',
      );
      expect(
        find.descendant(of: restored, matching: find.byType(Image)),
        findsOneWidget,
      );
    });

    testWidgets('preview delete empties the slot', (tester) async {
      await pumpScreen(tester);
      await attachNutritionPhoto(tester);

      await tester.tap(
        find.widgetWithText(ProductPhotoTile, 'Nutrition table photo'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete photo'));
      await tester.pumpAndSettle();

      final tile = find.widgetWithText(
        ProductPhotoTile,
        'Nutrition table photo',
      );
      expect(
        find.descendant(of: tile, matching: find.byType(Image)),
        findsNothing,
      );
    });

    testWidgets('undo after the slot was refilled keeps the new photo', (
      tester,
    ) async {
      await pumpScreen(tester);
      await attachNutritionPhoto(tester);

      final deleteButton = find.descendant(
        of: find.widgetWithText(ProductPhotoTile, 'Nutrition table photo'),
        matching: find.byIcon(Icons.delete_outline),
      );
      await tester.tap(deleteButton);
      await tester.pumpAndSettle();

      final replacement = File('${tempDir.path}/replacement.png')
        ..writeAsBytesSync(kTransparentPng);
      when(
        () => mockPicker.pick(any()),
      ).thenAnswer((_) async => PhotoPicked(replacement));

      await tester.tap(find.byIcon(Icons.add_a_photo).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Take a new photo'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();

      final tile = find.widgetWithText(
        ProductPhotoTile,
        'Nutrition table photo',
      );
      final image = tester.widget<Image>(
        find.descendant(of: tile, matching: find.byType(Image)),
      );
      final fileImage = image.image as FileImage;
      expect(
        fileImage.file.path,
        replacement.path,
        reason: 'Undo must not restore the deleted photo over the new one',
      );
    });

    testWidgets('camera permission denied shows the settings dialog', (
      tester,
    ) async {
      when(
        () => mockPicker.pick(any()),
      ).thenAnswer((_) async => const PhotoPermissionDenied());
      await pumpScreen(tester);

      await tester.tap(find.byIcon(Icons.add_a_photo).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Take a new photo'));
      await tester.pumpAndSettle();

      expect(find.text('Camera permission needed'), findsOneWidget);
      expect(find.text('Open Settings'), findsOneWidget);
    });

    testWidgets('preview shows accessible retake replace and delete actions', (
      tester,
    ) async {
      await pumpScreen(tester);
      await attachNutritionPhoto(tester);

      await tester.tap(
        find.widgetWithText(ProductPhotoTile, 'Nutrition table photo'),
      );
      await tester.pumpAndSettle();

      for (final label in ['Retake photo', 'Replace photo', 'Delete photo']) {
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
