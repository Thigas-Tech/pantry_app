import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/models/image_field.dart';
import 'package:pantry_app/models/product_photo_slots.dart';
import 'package:pantry_app/services/product_image_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late Directory imageDir;
  late ProductImageService service;

  const suffixFor = <ImageField, String>{
    ImageField.nutrition: 'nutrition',
    ImageField.ingredients: 'ingredients',
    ImageField.product: 'product',
  };

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('product_image_test_');
    imageDir = Directory('${tempDir.path}/product_images');
    service = ProductImageService(imageDirectory: imageDir);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  String managedPath(String barcode, ImageField field) {
    return '${imageDir.path}/${barcode}_${suffixFor[field]}.jpg';
  }

  Future<File> createSource(String name, List<int> bytes) async {
    final file = File('${tempDir.path}/$name');
    await file.writeAsBytes(bytes);
    return file;
  }

  group('ProductImageService.assign', () {
    for (final field in ImageField.values) {
      test('copies the picked file into the ${field.name} slot', () async {
        final picked = await createSource('pick.png', <int>[1, 2, 3]);

        final slots = await service.assign(
          const ProductPhotoSlots.empty(),
          field,
          picked,
          barcode: '123',
        );

        final file = slots.forField(field);
        expect(file, isNotNull);
        expect(file!.path, managedPath('123', field));
        expect(await file.readAsBytes(), <int>[1, 2, 3]);
      });
    }

    test('replacing a photo overwrites the same managed file', () async {
      final first = await createSource('first.png', <int>[1, 2, 3]);
      final second = await createSource('second.png', <int>[4, 5, 6]);

      final slotsA = await service.assign(
        const ProductPhotoSlots.empty(),
        ImageField.nutrition,
        first,
        barcode: '123',
      );
      final slotsB = await service.assign(
        slotsA,
        ImageField.nutrition,
        second,
        barcode: '123',
      );

      final managed = File(managedPath('123', ImageField.nutrition));
      expect(await managed.readAsBytes(), <int>[4, 5, 6]);
      final remaining = imageDir.listSync().whereType<File>().where(
        (f) => f.path.endsWith('_nutrition.jpg'),
      );
      expect(remaining.length, 1);
      expect(slotsB.forField(ImageField.nutrition)!.path, managed.path);
    });

    test('assigning a file already at the managed path is a no-op', () async {
      await imageDir.create(recursive: true);
      final managed = File(managedPath('123', ImageField.nutrition));
      await managed.writeAsBytes(<int>[9]);
      final slots = ProductPhotoSlots(nutrition: managed);

      final result = await service.assign(
        slots,
        ImageField.nutrition,
        managed,
        barcode: '123',
      );

      expect(result.forField(ImageField.nutrition)!.path, managed.path);
      expect(await managed.readAsBytes(), <int>[9]);
    });

    test(
      'returns the slots unchanged when the picked file is missing',
      () async {
        final missing = File('${tempDir.path}/missing.png');

        final slots = await service.assign(
          const ProductPhotoSlots.empty(),
          ImageField.nutrition,
          missing,
          barcode: '123',
        );

        expect(slots.forField(ImageField.nutrition), isNull);
      },
    );

    test('sanitizes barcode characters in the managed file name', () async {
      final picked = await createSource('pick.png', <int>[1, 2, 3]);

      final slots = await service.assign(
        const ProductPhotoSlots.empty(),
        ImageField.nutrition,
        picked,
        barcode: 'produce-Apple/1',
      );

      final path = slots.forField(ImageField.nutrition)!.path;
      expect(path, managedPath('produce-Apple_1', ImageField.nutrition));
    });
  });

  group('ProductImageService.remove', () {
    test('clears the slot without deleting the managed file', () async {
      final picked = await createSource('pick.png', <int>[1, 2, 3]);
      final slots = await service.assign(
        const ProductPhotoSlots.empty(),
        ImageField.nutrition,
        picked,
        barcode: '123',
      );

      final cleared = service.remove(slots, ImageField.nutrition);

      expect(cleared.forField(ImageField.nutrition), isNull);
      expect(
        await File(managedPath('123', ImageField.nutrition)).exists(),
        isTrue,
        reason: 'Deletion must be deferred so undo can restore the photo',
      );
    });
  });

  group('ProductImageService.save', () {
    test('persists every assigned slot and returns its managed path', () async {
      final nutrition = await createSource('n.png', <int>[1]);
      final ingredients = await createSource('i.png', <int>[2]);
      final product = await createSource('p.png', <int>[3]);
      var slots = const ProductPhotoSlots.empty();
      slots = await service.assign(
        slots,
        ImageField.nutrition,
        nutrition,
        barcode: '123',
      );
      slots = await service.assign(
        slots,
        ImageField.ingredients,
        ingredients,
        barcode: '123',
      );
      slots = await service.assign(
        slots,
        ImageField.product,
        product,
        barcode: '123',
      );

      final saved = await service.save(slots, barcode: '123');

      expect(saved.nutrition, managedPath('123', ImageField.nutrition));
      expect(saved.ingredients, managedPath('123', ImageField.ingredients));
      expect(saved.product, managedPath('123', ImageField.product));
      expect(
        await File(saved.nutrition!).exists(),
        isTrue,
      );
      expect(
        await File(saved.ingredients!).exists(),
        isTrue,
      );
      expect(
        await File(saved.product!).exists(),
        isTrue,
      );
    });

    test('returns null paths when no photos are assigned', () async {
      final saved = await service.save(
        const ProductPhotoSlots.empty(),
        barcode: '123',
      );

      expect(saved.nutrition, isNull);
      expect(saved.ingredients, isNull);
      expect(saved.product, isNull);
    });

    test('deletes the managed file of a removed photo on save', () async {
      final picked = await createSource('pick.png', <int>[1, 2, 3]);
      final slots = await service.assign(
        const ProductPhotoSlots.empty(),
        ImageField.nutrition,
        picked,
        barcode: '123',
      );
      final managed = File(managedPath('123', ImageField.nutrition));
      expect(await managed.exists(), isTrue);

      final cleared = service.remove(slots, ImageField.nutrition);
      final saved = await service.save(cleared, barcode: '123');

      expect(saved.nutrition, isNull);
      expect(await managed.exists(), isFalse);
    });

    test(
      'does not delete a managed file still referenced by another slot',
      () async {
        final picked = await createSource('pick.png', <int>[1, 2, 3]);
        final slots = await service.assign(
          const ProductPhotoSlots.empty(),
          ImageField.nutrition,
          picked,
          barcode: '123',
        );
        final shared = File(managedPath('123', ImageField.nutrition));
        final sharedSlots = ProductPhotoSlots(
          product: shared,
          ingredients: slots.ingredients,
        );

        final saved = await service.save(sharedSlots, barcode: '123');

        expect(
          await shared.exists(),
          isTrue,
          reason: 'The file is still owned by the product slot',
        );
        expect(saved.product, isNotNull);
      },
    );

    test(
      'is a no-op when the managed file of an empty slot is missing',
      () async {
        final picked = await createSource('pick.png', <int>[1, 2, 3]);
        final slots = await service.assign(
          const ProductPhotoSlots.empty(),
          ImageField.nutrition,
          picked,
          barcode: '123',
        );
        final managed = File(managedPath('123', ImageField.nutrition));
        await managed.delete();

        final saved = await service.save(
          service.remove(slots, ImageField.nutrition),
          barcode: '123',
        );

        expect(saved.nutrition, isNull);
        expect(await managed.exists(), isFalse);
      },
    );

    test(
      'returns a null path when a non-managed source file is missing',
      () async {
        final missing = File('${tempDir.path}/missing.png');
        final slots = ProductPhotoSlots(nutrition: missing);

        final saved = await service.save(slots, barcode: '123');

        expect(saved.nutrition, isNull);
      },
    );

    test('copies a non-managed source into the managed path', () async {
      final picked = await createSource('pick.png', <int>[1, 2, 3]);
      final slots = ProductPhotoSlots(nutrition: picked);

      final saved = await service.save(slots, barcode: '123');

      expect(saved.nutrition, managedPath('123', ImageField.nutrition));
      expect(
        await File(saved.nutrition!).readAsBytes(),
        <int>[1, 2, 3],
      );
    });
  });

  group('ProductImageService.cleanupUncommitted', () {
    test('deletes managed files that were never committed', () async {
      final picked = await createSource('pick.png', <int>[1, 2, 3]);
      final slots = await service.assign(
        const ProductPhotoSlots.empty(),
        ImageField.nutrition,
        picked,
        barcode: '123',
      );
      final managed = File(managedPath('123', ImageField.nutrition));
      expect(await managed.exists(), isTrue);

      await service.cleanupUncommitted(
        slots,
        barcode: '123',
        committedPaths: const <String>{},
      );

      expect(await managed.exists(), isFalse);
    });

    test(
      'keeps managed files that were committed to a saved product',
      () async {
        final picked = await createSource('pick.png', <int>[1, 2, 3]);
        final slots = await service.assign(
          const ProductPhotoSlots.empty(),
          ImageField.nutrition,
          picked,
          barcode: '123',
        );
        final saved = await service.save(slots, barcode: '123');
        final committed = {saved.nutrition!};

        await service.cleanupUncommitted(
          slots,
          barcode: '123',
          committedPaths: committed,
        );

        expect(await File(saved.nutrition!).exists(), isTrue);
      },
    );

    test('keeps a managed file still referenced by another slot', () async {
      final picked = await createSource('pick.png', <int>[1, 2, 3]);
      await service.assign(
        const ProductPhotoSlots.empty(),
        ImageField.nutrition,
        picked,
        barcode: '123',
      );
      final shared = File(managedPath('123', ImageField.nutrition));
      final sharedSlots = ProductPhotoSlots(product: shared);

      await service.cleanupUncommitted(
        sharedSlots,
        barcode: '123',
        committedPaths: const <String>{},
      );

      expect(await shared.exists(), isTrue);
    });

    test('is a no-op when no files exist for the barcode', () async {
      await service.cleanupUncommitted(
        const ProductPhotoSlots.empty(),
        barcode: '123',
        committedPaths: const <String>{},
      );
    });
  });
}
