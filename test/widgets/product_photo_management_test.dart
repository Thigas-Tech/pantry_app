/// @file ProductPhotoManagement widget tests.
///
/// The widget renders the three local photo slots of a manual product with
/// add/preview/replace/delete controls backed by [ProductPhotoPicker] and
/// [ProductImageService]. Tests cover the three filled slots, empty-slot add
/// affordances, replacing a photo from the detail screen, and the delete +
/// undo flow that clears the product path in the database.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/models/image_field.dart';
import 'package:pantry_app/models/photo_pick_result.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/models/product_photo_slots.dart';
import 'package:pantry_app/providers/database_provider.dart';
import 'package:pantry_app/providers/product_image_service_provider.dart';
import 'package:pantry_app/providers/product_photo_picker_provider.dart';
import 'package:pantry_app/services/product_image_service.dart';
import 'package:pantry_app/services/product_photo_picker.dart';
import 'package:pantry_app/widgets/photo_source_chooser.dart';
import 'package:pantry_app/widgets/product_photo_management.dart';
import 'package:pantry_app/widgets/product_photo_preview.dart';
import 'package:pantry_app/widgets/product_photo_tile.dart';
import '../helpers/pump_app.dart';

class MockProductPhotoPicker extends Mock implements ProductPhotoPicker {}

class MockProductImageService extends Mock implements ProductImageService {}

class MockDatabaseHelper extends Mock implements DatabaseHelper {}

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
  late File nutritionFile;
  late File ingredientsFile;
  late File productFile;
  late MockProductPhotoPicker mockPicker;
  late MockProductImageService mockImageService;
  late MockDatabaseHelper mockDb;
  final changedProducts = <Product>[];

  setUpAll(() {
    registerFallbackValue(PhotoSource.camera);
    registerFallbackValue(File('/fallback.jpg'));
    registerFallbackValue(ImageField.nutrition);
    registerFallbackValue(const ProductPhotoSlots.empty());
    registerFallbackValue(const Product(barcode: '', name: ''));
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('photo_mgmt_test_');
    Future<File> png(String name) async {
      final f = File('${tempDir.path}/$name')
        ..writeAsBytesSync(kTransparentPng);
      return f;
    }

    nutritionFile = await png('nutrition.png');
    ingredientsFile = await png('ingredients.png');
    productFile = await png('product.png');

    mockPicker = MockProductPhotoPicker();
    when(
      () => mockPicker.pick(any()),
    ).thenAnswer((_) async => PhotoPicked(nutritionFile));
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
    mockDb = MockDatabaseHelper();
    when(() => mockDb.insertProduct(any())).thenAnswer((_) async {});
    changedProducts.clear();
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  Product manualProduct({
    String? nutrition,
    String? ingredients,
    String? product,
  }) {
    return Product(
      barcode: '123456789',
      name: 'Manual Product',
      source: 'manual',
      nutritionImagePath: nutrition,
      ingredientsImagePath: ingredients,
      productImagePath: product,
    );
  }

  Future<void> pumpWidget(
    WidgetTester tester, {
    required Product product,
  }) async {
    await pumpApp(
      tester,
      Scaffold(
        body: ProductPhotoManagement(
          product: product,
          onChanged: changedProducts.add,
        ),
      ),
      overrides: [
        productPhotoPickerProvider.overrideWithValue(mockPicker),
        productImageServiceProvider.overrideWithValue(mockImageService),
        databaseProvider.overrideWithValue(mockDb),
      ],
    );
    await tester.pumpAndSettle();
  }

  group('ProductPhotoManagement slots', () {
    testWidgets('manual product shows the three filled photo slots', (
      tester,
    ) async {
      await pumpWidget(
        tester,
        product: manualProduct(
          nutrition: nutritionFile.path,
          ingredients: ingredientsFile.path,
          product: productFile.path,
        ),
      );

      for (final label in [
        'Nutrition table photo',
        'Ingredients list photo',
        'Product photo',
      ]) {
        final tile = find.widgetWithText(ProductPhotoTile, label);
        expect(tile, findsOneWidget);
        expect(
          find.descendant(of: tile, matching: find.byType(Image)),
          findsOneWidget,
          reason: '$label must show a thumbnail',
        );
      }
    });

    testWidgets('empty slots expose the add photo affordance', (
      tester,
    ) async {
      await pumpWidget(tester, product: manualProduct());

      expect(find.byIcon(Icons.add_a_photo), findsNWidgets(3));
    });
  });

  group('ProductPhotoManagement replace', () {
    testWidgets('replacing a photo assigns the slot and persists the product', (
      tester,
    ) async {
      await pumpWidget(
        tester,
        product: manualProduct(nutrition: nutritionFile.path),
      );

      final replacement = File('${tempDir.path}/replacement.png')
        ..writeAsBytesSync(kTransparentPng);
      when(
        () => mockPicker.pick(any()),
      ).thenAnswer((_) async => PhotoPicked(replacement));

      await tester.tap(
        find.widgetWithText(ProductPhotoTile, 'Nutrition table photo'),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ProductPhotoPreview), findsOneWidget);

      await tester.tap(find.text('Replace photo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Take a new photo'));
      await tester.pumpAndSettle();

      verify(
        () => mockPicker.pick(PhotoSource.camera),
      ).called(1);
      verify(
        () => mockImageService.assign(
          any(),
          any(),
          any(),
          barcode: '123456789',
        ),
      ).called(1);
      expect(changedProducts, isNotEmpty);
      expect(
        changedProducts.last.nutritionImagePath,
        replacement.path,
      );
      verify(() => mockDb.insertProduct(any())).called(1);
    });
  });

  group('ProductPhotoManagement delete', () {
    testWidgets('delete clears the path, persists, and undo restores it', (
      tester,
    ) async {
      await pumpWidget(
        tester,
        product: manualProduct(
          nutrition: nutritionFile.path,
          ingredients: ingredientsFile.path,
        ),
      );

      final nutritionTile = find.widgetWithText(
        ProductPhotoTile,
        'Nutrition table photo',
      );
      final deleteButton = find.descendant(
        of: nutritionTile,
        matching: find.byIcon(Icons.delete_outline),
      );
      await tester.tap(deleteButton);
      await tester.pumpAndSettle();

      expect(find.text('Photo removed.'), findsOneWidget);
      expect(
        changedProducts.last.nutritionImagePath,
        isNull,
        reason: 'The removed slot must be cleared in the product',
      );
      expect(
        changedProducts.last.ingredientsImagePath,
        ingredientsFile.path,
        reason: 'Other slots must be preserved',
      );
      final cleared =
          verify(
                () => mockDb.insertProduct(captureAny()),
              ).captured.last
              as Product;
      expect(cleared.nutritionImagePath, isNull);

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();

      expect(
        changedProducts.last.nutritionImagePath,
        nutritionFile.path,
        reason: 'Undo must restore the removed photo path',
      );
      final restored =
          verify(
                () => mockDb.insertProduct(captureAny()),
              ).captured.last
              as Product;
      expect(restored.nutritionImagePath, nutritionFile.path);
    });
  });
}
