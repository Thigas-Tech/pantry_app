import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pantry_app/models/image_field.dart';
import 'package:pantry_app/models/photo_pick_result.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/models/product_photo_slots.dart';
import 'package:pantry_app/models/submission_progress.dart';
import 'package:pantry_app/providers/product_image_service_provider.dart';
import 'package:pantry_app/providers/product_photo_picker_provider.dart';
import 'package:pantry_app/providers/product_repository_provider.dart';
import 'package:pantry_app/providers/product_submission_provider.dart';
import 'package:pantry_app/screens/add_product_screen.dart';
import 'package:pantry_app/services/product_image_service.dart';
import 'package:pantry_app/services/product_photo_picker.dart';
import 'package:pantry_app/services/product_submission_service.dart';
import 'package:pantry_app/widgets/photo_source_chooser.dart';
import 'package:pantry_app/widgets/product_photo_preview.dart';
import 'package:pantry_app/widgets/product_photo_tile.dart';
import '../helpers/pump_app.dart';

class MockProductPhotoPicker extends Mock implements ProductPhotoPicker {}

class MockProductImageService extends Mock implements ProductImageService {}

class MockProductSubmissionService extends Mock
    implements ProductSubmissionService {}

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
  late MockProductImageService mockImageService;
  late MockProductSubmissionService mockSubmissionService;
  late MockProductRepository mockRepo;

  setUpAll(() {
    registerFallbackValue(PhotoSource.camera);
    registerFallbackValue(File('/fallback.jpg'));
    registerFallbackValue(ImageField.nutrition);
    registerFallbackValue(const ProductPhotoSlots.empty());
    registerFallbackValue(const Product(barcode: '', name: ''));
    registerFallbackValue('123');
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('add_photo_test_');
    imageFile = File('${tempDir.path}/photo.png')
      ..writeAsBytesSync(kTransparentPng);
    mockPicker = MockProductPhotoPicker();
    when(
      () => mockPicker.pick(any()),
    ).thenAnswer((_) async => PhotoPicked(imageFile));
    mockImageService = MockProductImageService();
    when(
      () => mockImageService.assign(
        any(),
        any(),
        any(),
        barcode: any(named: 'barcode'),
      ),
    ).thenAnswer((invocation) async {
      final slots = invocation.positionalArguments[0] as ProductPhotoSlots;
      final field = invocation.positionalArguments[1] as ImageField;
      final file = invocation.positionalArguments[2] as File;
      return slots.withField(field, file);
    });
    when(
      () => mockImageService.remove(any(), any()),
    ).thenAnswer((invocation) {
      final slots = invocation.positionalArguments[0] as ProductPhotoSlots;
      final field = invocation.positionalArguments[1] as ImageField;
      return slots.withField(field, null);
    });
    when(
      () => mockImageService.save(any(), barcode: any(named: 'barcode')),
    ).thenAnswer((invocation) async {
      final slots = invocation.positionalArguments[0] as ProductPhotoSlots;
      return (
        nutrition: slots.nutrition?.path,
        ingredients: slots.ingredients?.path,
        product: slots.product?.path,
      );
    });
    when(
      () => mockImageService.cleanupUncommitted(
        any(),
        barcode: any(named: 'barcode'),
        committedPaths: any(named: 'committedPaths'),
      ),
    ).thenAnswer((_) async {});

    mockSubmissionService = MockProductSubmissionService();
    when(
      () => mockSubmissionService.submitProduct(
        any(),
        onProgress: any(named: 'onProgress'),
      ),
    ).thenAnswer((invocation) async {
      final onProgress =
          invocation.namedArguments[#onProgress]
              as void Function(SubmissionProgress)?;
      onProgress?.call(
        const SubmissionProgress(
          barcode: '123',
          step: SubmissionStep.completed,
        ),
      );
      return const Product(barcode: '123', name: 'Test');
    });

    mockRepo = createMockProductRepository();
    when(() => mockRepo.cacheProduct(any())).thenAnswer((_) async {});
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
        productImageServiceProvider.overrideWithValue(
          mockImageService,
        ),
        productSubmissionServiceProvider.overrideWithValue(
          mockSubmissionService,
        ),
        productRepositoryProvider.overrideWithValue(mockRepo),
      ],
    );
    await tester.pumpAndSettle();
  }

  /// Pumps the screen inside a pushed route so the popped [Product] can be
  /// captured and dispose cleanup can be observed.
  Future<void> pumpScreenPushed(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await pumpApp(
      tester,
      Builder(
        builder: (context) => ElevatedButton(
          onPressed: () async {
            await Navigator.push<void>(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const AddProductScreen(barcode: '123'),
              ),
            );
          },
          child: const Text('Open form'),
        ),
      ),
      overrides: [
        productPhotoPickerProvider.overrideWithValue(mockPicker),
        productImageServiceProvider.overrideWithValue(
          mockImageService,
        ),
        productSubmissionServiceProvider.overrideWithValue(
          mockSubmissionService,
        ),
        productRepositoryProvider.overrideWithValue(mockRepo),
      ],
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open form'));
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

    testWidgets(
      'permanently denied camera permission shows the settings dialog',
      (tester) async {
        when(
          () => mockPicker.pick(any()),
        ).thenAnswer(
          (_) async => const PhotoPermissionDenied(permanentlyDenied: true),
        );
        await pumpScreen(tester);

        await tester.tap(find.byIcon(Icons.add_a_photo).first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Take a new photo'));
        await tester.pumpAndSettle();

        expect(find.text('Camera permission needed'), findsOneWidget);
        expect(find.text('Open Settings'), findsOneWidget);
      },
    );

    testWidgets(
      'one-time camera denial shows a recoverable snackbar and keeps the slot',
      (tester) async {
        when(
          () => mockPicker.pick(any()),
        ).thenAnswer((_) async => const PhotoPermissionDenied());
        await pumpScreen(tester);

        await tester.tap(find.byIcon(Icons.add_a_photo).first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Take a new photo'));
        await tester.pumpAndSettle();

        expect(
          find.text('Camera permission denied. Grant access in Settings.'),
          findsOneWidget,
        );
        expect(find.text('Camera permission needed'), findsNothing);
        verifyNever(
          () => mockImageService.assign(
            any(),
            any(),
            any(),
            barcode: any(named: 'barcode'),
          ),
        );
      },
    );

    testWidgets(
      'gallery permission denied shows the gallery settings dialog',
      (tester) async {
        when(
          () => mockPicker.pick(any()),
        ).thenAnswer((_) async => const PhotoGalleryPermissionDenied());
        await pumpScreen(tester);

        await tester.tap(find.byIcon(Icons.add_a_photo).first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Choose an existing photo'));
        await tester.pumpAndSettle();

        expect(find.text('Gallery access needed'), findsOneWidget);
        expect(
          find.text(
            'Pantry needs access to your photos to choose an existing photo. '
            'Open Settings to allow access.',
          ),
          findsOneWidget,
        );
        expect(find.text('Open Settings'), findsOneWidget);
        verifyNever(
          () => mockImageService.assign(
            any(),
            any(),
            any(),
            barcode: any(named: 'barcode'),
          ),
        );
      },
    );

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

  group('AddProductScreen photo persistence', () {
    testWidgets('canceled selection leaves the slot empty and never assigns', (
      tester,
    ) async {
      when(
        () => mockPicker.pick(any()),
      ).thenAnswer((_) async => const PhotoPickCancelled());
      await pumpScreen(tester);

      await tester.tap(find.byIcon(Icons.add_a_photo).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Take a new photo'));
      await tester.pumpAndSettle();

      final tile = find.widgetWithText(
        ProductPhotoTile,
        'Nutrition table photo',
      );
      expect(
        find.descendant(of: tile, matching: find.byType(Image)),
        findsNothing,
      );
      expect(
        find.descendant(of: tile, matching: find.byIcon(Icons.add_a_photo)),
        findsOneWidget,
      );
      verifyNever(
        () => mockImageService.assign(
          any(),
          any(),
          any(),
          barcode: any(named: 'barcode'),
        ),
      );
    });

    testWidgets(
      'validation failure preserves picked photos and does not save',
      (
        tester,
      ) async {
        await pumpScreen(tester);
        await attachNutritionPhoto(tester);

        await tester.tap(find.text('Save product'));
        await tester.pumpAndSettle();

        expect(find.text('This field is required'), findsOneWidget);
        final tile = find.widgetWithText(
          ProductPhotoTile,
          'Nutrition table photo',
        );
        expect(
          find.descendant(of: tile, matching: find.byType(Image)),
          findsOneWidget,
          reason: 'Picked photos must survive failed validation',
        );
        verifyNever(
          () => mockImageService.save(any(), barcode: any(named: 'barcode')),
        );
      },
    );

    testWidgets('replacing a photo assigns the slot again', (tester) async {
      await pumpScreen(tester);
      await attachNutritionPhoto(tester);

      final replacement = File('${tempDir.path}/replacement.png')
        ..writeAsBytesSync(kTransparentPng);
      when(
        () => mockPicker.pick(any()),
      ).thenAnswer((_) async => PhotoPicked(replacement));

      await tester.tap(
        find.widgetWithText(ProductPhotoTile, 'Nutrition table photo'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Replace photo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Take a new photo'));
      await tester.pumpAndSettle();

      verify(
        () => mockImageService.assign(
          any(),
          any(),
          any(),
          barcode: any(named: 'barcode'),
        ),
      ).called(2);
    });

    testWidgets('saving delegates every filled slot to the service', (
      tester,
    ) async {
      await pumpScreenPushed(tester);

      for (var i = 0; i < 3; i++) {
        await tester.tap(find.byIcon(Icons.add_a_photo).first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Take a new photo'));
        await tester.pumpAndSettle();
      }
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Product name'),
        'Test Product',
      );
      await tester.tap(find.text('Save product'));
      await tester.pumpAndSettle();

      final savedSlots =
          verify(
                () => mockImageService.save(captureAny(), barcode: '123'),
              ).captured.single
              as ProductPhotoSlots;
      expect(savedSlots.nutrition, isNotNull);
      expect(savedSlots.ingredients, isNotNull);
      expect(savedSlots.product, isNotNull);
    });

    testWidgets('popping without saving asks cleanup for no committed paths', (
      tester,
    ) async {
      await pumpScreenPushed(tester);
      await tester.tap(find.byIcon(Icons.add_a_photo).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Take a new photo'));
      await tester.pumpAndSettle();

      await tester.pageBack();
      await tester.pumpAndSettle();

      verify(
        () => mockImageService.cleanupUncommitted(
          any(),
          barcode: '123',
          committedPaths: <String>{},
        ),
      ).called(1);
    });

    testWidgets('saving asks cleanup to keep the committed photo paths', (
      tester,
    ) async {
      await pumpScreenPushed(tester);
      await tester.tap(find.byIcon(Icons.add_a_photo).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Take a new photo'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Product name'),
        'Test Product',
      );
      await tester.tap(find.text('Save product'));
      await tester.pumpAndSettle();

      verify(
        () => mockImageService.cleanupUncommitted(
          any(),
          barcode: '123',
          committedPaths: {imageFile.path},
        ),
      ).called(1);
    });

    testWidgets('saved product carries the service-returned photo paths', (
      tester,
    ) async {
      Product? captured;
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await pumpApp(
        tester,
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              captured = await Navigator.push<Product>(
                context,
                MaterialPageRoute<Product>(
                  builder: (_) => const AddProductScreen(barcode: '123'),
                ),
              );
            },
            child: const Text('Open form'),
          ),
        ),
        overrides: [
          productPhotoPickerProvider.overrideWithValue(mockPicker),
          productImageServiceProvider.overrideWithValue(mockImageService),
          productSubmissionServiceProvider.overrideWithValue(
            mockSubmissionService,
          ),
          productRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      await tester.tap(find.text('Open form'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add_a_photo).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Take a new photo'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Product name'),
        'Test Product',
      );
      await tester.tap(find.text('Save product'));
      await tester.pumpAndSettle();

      expect(captured, isNotNull);
      expect(captured!.nutritionImagePath, imageFile.path);
      expect(captured!.ingredientsImagePath, isNull);
      expect(captured!.productImagePath, isNull);
    });
  });
}
