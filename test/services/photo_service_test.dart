import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/services/photo_service.dart';

void main() {
  late PhotoService service;
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('photo_test_');
    service = PhotoService(photoDirectory: tempDir);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
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
}
