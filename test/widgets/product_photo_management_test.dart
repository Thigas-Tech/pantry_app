import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pantry_app/models/image_field.dart';
import 'package:pantry_app/models/photo_pick_result.dart';
import 'package:pantry_app/models/product_photo_slots.dart';
import 'package:pantry_app/providers/product_image_service_provider.dart';
import 'package:pantry_app/providers/product_photo_picker_provider.dart';
import 'package:pantry_app/services/product_image_service.dart';
import 'package:pantry_app/services/product_photo_picker.dart';
import 'package:pantry_app/widgets/photo_source_chooser.dart';
import 'package:pantry_app/widgets/product_photo_management.dart';
import 'package:pantry_app/widgets/product_photo_preview.dart';
import '../helpers/pump_app.dart';

class MockProductPhotoPicker extends Mock implements ProductPhotoPicker {}

class MockProductImageService extends Mock implements ProductImageService {}

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

  setUpAll(() {
    registerFallbackValue(PhotoSource.camera);
    registerFallbackValue(ImageField.nutrition);
    registerFallbackValue(const ProductPhotoSlots.empty());
    registerFallbackValue(File('/fallback.jpg'));
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'photo_management_test_',
    );
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
      () => mockImageService.cleanupUncommitted(
        any(),
        barcode: any(named: 'barcode'),
        committedPaths: any(named: 'committedPaths'),
      ),
    ).thenAnswer((_) async {});
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  /// Pumps a [ProductPhotoManagement] inside a scaffold with a mocked image
  /// service (real file I/O does not settle under testWidgets FakeAsync)
  /// and a mocked picker.
  Future<List<ProductPhotoSlots>> pumpManagement(
    WidgetTester tester, {
    ProductPhotoSlots initial = const ProductPhotoSlots.empty(),
  }) async {
    final changed = <ProductPhotoSlots>[];
    await pumpApp(
      tester,
      Scaffold(
        body: ProductPhotoManagement(
          barcode: '123',
          initialSlots: initial,
          onChanged: changed.add,
        ),
      ),
      overrides: [
        productPhotoPickerProvider.overrideWithValue(mockPicker),
        productImageServiceProvider.overrideWithValue(mockImageService),
      ],
    );
    return changed;
  }

  group('ProductPhotoManagement', () {
    testWidgets('renders the three photo tile labels', (tester) async {
      await pumpManagement(tester);

      expect(find.text('Nutrition table photo'), findsOneWidget);
      expect(find.text('Ingredients list photo'), findsOneWidget);
      expect(find.text('Product photo'), findsOneWidget);
    });

    testWidgets('adding a photo assigns the slot and reports via onChanged', (
      tester,
    ) async {
      final changed = await pumpManagement(tester);

      await tester.tap(find.byIcon(Icons.add_a_photo).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Take a new photo'));
      await tester.pumpAndSettle();

      expect(changed, hasLength(1));
      expect(changed.single.nutrition, isNotNull);
      expect(changed.single.nutrition!.path, imageFile.path);
    });

    testWidgets('delete clears the slot, reports, and undo restores it', (
      tester,
    ) async {
      final changed = await pumpManagement(
        tester,
        initial: ProductPhotoSlots(nutrition: imageFile),
      );

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      expect(changed, hasLength(1));
      expect(changed.single.nutrition, isNull);
      expect(find.text('Photo removed.'), findsOneWidget);

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();

      expect(changed, hasLength(2));
      expect(changed.last.nutrition, isNotNull);
      expect(changed.last.nutrition!.path, imageFile.path);
    });

    testWidgets('tapping a filled tile opens the photo preview', (
      tester,
    ) async {
      await pumpManagement(
        tester,
        initial: ProductPhotoSlots(nutrition: imageFile),
      );

      await tester.tap(find.text('Nutrition table photo'));
      await tester.pumpAndSettle();

      expect(find.byType(ProductPhotoPreview), findsOneWidget);
    });
  });
}
