import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pantry_app/models/photo_permission.dart';
import 'package:pantry_app/models/photo_pick_result.dart';
import 'package:pantry_app/services/product_photo_picker.dart';
import 'package:pantry_app/widgets/photo_source_chooser.dart';

class MockImagePicker extends Mock implements ImagePicker {}

void main() {
  late MockImagePicker mockPicker;
  late Directory tempDir;
  late PhotoPermissionStatus cameraStatus;
  late PhotoPermissionStatus galleryStatus;
  late bool galleryRequired;
  var cameraCheckCalls = 0;
  var galleryCheckCalls = 0;

  setUpAll(() {
    registerFallbackValue(ImageSource.camera);
    registerFallbackValue(ImageSource.gallery);
  });

  setUp(() async {
    mockPicker = MockImagePicker();
    tempDir = await Directory.systemTemp.createTemp('picker_test_');
    cameraStatus = PhotoPermissionStatus.granted;
    galleryStatus = PhotoPermissionStatus.granted;
    galleryRequired = false;
    cameraCheckCalls = 0;
    galleryCheckCalls = 0;
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  ProductPhotoPicker buildPicker() {
    return ProductPhotoPicker(
      imagePicker: mockPicker,
      cameraPermissionCheck: () async {
        cameraCheckCalls++;
        return cameraStatus;
      },
      galleryPermissionCheck: () async {
        galleryCheckCalls++;
        return galleryStatus;
      },
      isGalleryPermissionRequired: () => galleryRequired,
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
        cameraStatus = PhotoPermissionStatus.denied;

        final result = await buildPicker().pick(PhotoSource.camera);

        expect(result, isA<PhotoPermissionDenied>());
        expect((result as PhotoPermissionDenied).permanentlyDenied, isFalse);
        verifyNever(
          () => mockPicker.pickImage(source: any(named: 'source')),
        );
      },
    );

    test(
      'returns permanently denied when camera permission is permanent',
      () async {
        cameraStatus = PhotoPermissionStatus.permanentlyDenied;

        final result = await buildPicker().pick(PhotoSource.camera);

        expect(result, isA<PhotoPermissionDenied>());
        expect((result as PhotoPermissionDenied).permanentlyDenied, isTrue);
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
      expect(cameraCheckCalls, 0);
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

  group('ProductPhotoPicker gallery permission', () {
    test(
      'returns PhotoGalleryPermissionDenied when required and denied',
      () async {
        galleryRequired = true;
        galleryStatus = PhotoPermissionStatus.denied;

        final result = await buildPicker().pick(PhotoSource.gallery);

        expect(result, isA<PhotoGalleryPermissionDenied>());
        expect(cameraCheckCalls, 0);
        verifyNever(
          () => mockPicker.pickImage(source: any(named: 'source')),
        );
      },
    );

    test('picks a gallery photo when required and granted', () async {
      galleryRequired = true;
      galleryStatus = PhotoPermissionStatus.granted;
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
      expect(cameraCheckCalls, 0);
    });

    test('skips the gallery permission check when not required', () async {
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
      expect(galleryCheckCalls, 0);
    });

    test(
      'maps a photo_access_denied platform error to a denied result',
      () async {
        when(
          () => mockPicker.pickImage(
            source: ImageSource.gallery,
            maxWidth: any(named: 'maxWidth'),
            maxHeight: any(named: 'maxHeight'),
            imageQuality: any(named: 'imageQuality'),
          ),
        ).thenThrow(
          PlatformException(code: 'photo_access_denied'),
        );

        final result = await buildPicker().pick(PhotoSource.gallery);

        expect(result, isA<PhotoGalleryPermissionDenied>());
      },
    );

    test('rethrows platform errors unrelated to access', () {
      when(
        () => mockPicker.pickImage(
          source: ImageSource.gallery,
          maxWidth: any(named: 'maxWidth'),
          maxHeight: any(named: 'maxHeight'),
          imageQuality: any(named: 'imageQuality'),
        ),
      ).thenThrow(PlatformException(code: 'unexpected'));

      expect(
        () => buildPicker().pick(PhotoSource.gallery),
        throwsA(isA<PlatformException>()),
      );
    });
  });
}
