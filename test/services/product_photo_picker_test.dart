import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pantry_app/models/photo_pick_result.dart';
import 'package:pantry_app/services/product_photo_picker.dart';
import 'package:pantry_app/widgets/photo_source_chooser.dart';

class MockImagePicker extends Mock implements ImagePicker {}

void main() {
  late MockImagePicker mockPicker;
  late Directory tempDir;
  late bool cameraGranted;

  setUpAll(() {
    registerFallbackValue(ImageSource.camera);
  });

  setUp(() async {
    mockPicker = MockImagePicker();
    tempDir = await Directory.systemTemp.createTemp('picker_test_');
    cameraGranted = true;
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  ProductPhotoPicker buildPicker() {
    return ProductPhotoPicker(
      imagePicker: mockPicker,
      cameraPermissionCheck: () async => cameraGranted,
    );
  }

  Future<File> createImage() async {
    final file = File('${tempDir.path}/photo.png')
      ..writeAsBytesSync(const <int>[1, 2, 3]);
    return file;
  }

  group('ProductPhotoPicker.pick', () {
    test('picks a camera photo when permission is granted', () async {
      final file = await createImage();
      when(
        () => mockPicker.pickImage(
          source: ImageSource.camera,
          maxWidth: any(named: 'maxWidth'),
          maxHeight: any(named: 'maxHeight'),
          imageQuality: any(named: 'imageQuality'),
        ),
      ).thenAnswer((_) async => XFile(file.path));

      final result = await buildPicker().pick(PhotoSource.camera);

      expect(result, isA<PhotoPicked>());
      expect((result as PhotoPicked).file.path, file.path);
    });

    test(
      'returns PhotoPermissionDenied when camera permission is denied',
      () async {
        cameraGranted = false;

        final result = await buildPicker().pick(PhotoSource.camera);

        expect(result, isA<PhotoPermissionDenied>());
        verifyNever(
          () => mockPicker.pickImage(source: any(named: 'source')),
        );
      },
    );

    test(
      'returns PhotoPickCancelled when the user cancels the picker',
      () async {
        when(
          () => mockPicker.pickImage(
            source: any(named: 'source'),
            maxWidth: any(named: 'maxWidth'),
            maxHeight: any(named: 'maxHeight'),
            imageQuality: any(named: 'imageQuality'),
          ),
        ).thenAnswer((_) async => null);

        final result = await buildPicker().pick(PhotoSource.gallery);

        expect(result, isA<PhotoPickCancelled>());
      },
    );

    test('gallery pick never checks the camera permission', () async {
      final file = await createImage();
      when(
        () => mockPicker.pickImage(
          source: ImageSource.gallery,
          maxWidth: any(named: 'maxWidth'),
          maxHeight: any(named: 'maxHeight'),
          imageQuality: any(named: 'imageQuality'),
        ),
      ).thenAnswer((_) async => XFile(file.path));

      final result = await buildPicker().pick(PhotoSource.gallery);

      expect(result, isA<PhotoPicked>());
      expect((result as PhotoPicked).file.path, file.path);
    });

    test('requests a constrained image to keep OFF uploads small', () async {
      final file = await createImage();
      when(
        () => mockPicker.pickImage(
          source: ImageSource.camera,
          maxWidth: 1600,
          maxHeight: 1600,
          imageQuality: 85,
        ),
      ).thenAnswer((_) async => XFile(file.path));

      final result = await buildPicker().pick(PhotoSource.camera);

      expect(result, isA<PhotoPicked>());
      verify(
        () => mockPicker.pickImage(
          source: ImageSource.camera,
          maxWidth: 1600,
          maxHeight: 1600,
          imageQuality: 85,
        ),
      ).called(1);
    });
  });
}
