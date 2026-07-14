import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pantry_app/services/photo_service.dart';

class MockImagePicker extends Mock implements ImagePicker {}

void main() {
  setUpAll(() {
    registerFallbackValue(ImageSource.camera);
  });

  late PhotoService service;
  late MockImagePicker mockPicker;
  late Directory tempDir;

  setUp(() async {
    mockPicker = MockImagePicker();
    tempDir = await Directory.systemTemp.createTemp('photo_test_');
    service = PhotoService(picker: mockPicker, photoDirectory: tempDir);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('capturePhoto', () {
    test('returns path when photo is captured', () async {
      final tempFile = File('${tempDir.path}/source.jpg');
      await tempFile.writeAsBytes([1, 2, 3]);
      final xFile = XFile(tempFile.path);

      when(
        () => mockPicker.pickImage(
          source: ImageSource.camera,
          maxWidth: 1024,
          maxHeight: 1024,
        ),
      ).thenAnswer((_) async => xFile);

      final result = await service.capturePhoto(42);
      expect(result, isNotNull);
      expect(result, contains('42.jpg'));
    });

    test('returns null when user cancels', () async {
      when(
        () => mockPicker.pickImage(
          source: ImageSource.camera,
          maxWidth: 1024,
          maxHeight: 1024,
        ),
      ).thenAnswer((_) async => null);

      final result = await service.capturePhoto(42);
      expect(result, isNull);
    });

    test('returns null on exception', () async {
      when(
        () => mockPicker.pickImage(
          source: any(named: 'source'),
          maxWidth: any(named: 'maxWidth'),
          maxHeight: any(named: 'maxHeight'),
        ),
      ).thenThrow(Exception('Camera error'));

      final result = await service.capturePhoto(42);
      expect(result, isNull);
    });
  });

  group('pickFromGallery', () {
    test('returns path when photo is picked', () async {
      final tempFile = File('${tempDir.path}/gallery_source.jpg');
      await tempFile.writeAsBytes([1, 2, 3]);
      final xFile = XFile(tempFile.path);

      when(
        () => mockPicker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1024,
          maxHeight: 1024,
        ),
      ).thenAnswer((_) async => xFile);

      final result = await service.pickFromGallery(7);
      expect(result, isNotNull);
      expect(result, contains('7.jpg'));
    });

    test('returns null when user cancels', () async {
      when(
        () => mockPicker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1024,
          maxHeight: 1024,
        ),
      ).thenAnswer((_) async => null);

      final result = await service.pickFromGallery(7);
      expect(result, isNull);
    });

    test('returns null on exception', () async {
      when(
        () => mockPicker.pickImage(
          source: any(named: 'source'),
          maxWidth: any(named: 'maxWidth'),
          maxHeight: any(named: 'maxHeight'),
        ),
      ).thenThrow(Exception('Gallery error'));

      final result = await service.pickFromGallery(7);
      expect(result, isNull);
    });
  });

  group('deletePhoto', () {
    test('deletes existing file', () async {
      final file = File('${tempDir.path}/test.jpg');
      await file.writeAsBytes([1, 2, 3]);
      expect(await file.exists(), true);

      await service.deletePhoto(file.path);
      expect(await file.exists(), false);
    });

    test('no-op when path is null', () async {
      await service.deletePhoto(null);
    });

    test('no-op when file does not exist', () async {
      await service.deletePhoto('${tempDir.path}/nope.jpg');
    });
  });

  group('deletePhotoForItem', () {
    test('deletes photo by item ID', () async {
      final file = File('${tempDir.path}/99.jpg');
      await file.writeAsBytes([1, 2, 3]);

      await service.deletePhotoForItem(99);
      expect(await file.exists(), false);
    });

    test('no-op when file does not exist', () async {
      await service.deletePhotoForItem(999);
    });
  });

  group('clearAllPhotos', () {
    test('deletes all files in photo directory', () async {
      await File('${tempDir.path}/1.jpg').writeAsBytes([1]);
      await File('${tempDir.path}/2.jpg').writeAsBytes([2]);
      await File('${tempDir.path}/3.jpg').writeAsBytes([3]);

      await service.clearAllPhotos();

      expect(await File('${tempDir.path}/1.jpg').exists(), false);
      expect(await File('${tempDir.path}/2.jpg').exists(), false);
      expect(await File('${tempDir.path}/3.jpg').exists(), false);
    });

    test('does nothing when directory is empty', () async {
      await service.clearAllPhotos();
    });
  });
}
