import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:mocktail/mocktail.dart';
import 'package:pantry_app/services/image_cache_service.dart';

/// A mock of [http.Client] to control network responses.
class MockHttpClient extends Mock implements http.Client {}

/// Tests for [ImageCacheService].
///
/// A test directory is provided so the service doesn't touch the real
/// application documents directory. Network calls are mocked via
/// [MockHttpClient].
void main() {
  late ImageCacheService service;
  late MockHttpClient mockClient;
  late Directory cacheDir;

  setUpAll(() {
    registerFallbackValue(Uri());
  });

  setUp(() {
    mockClient = MockHttpClient();
    cacheDir = Directory.systemTemp.createTempSync('pantry_cache_test_');
    service = ImageCacheService(
      httpClient: mockClient,
      cacheDirectory: cacheDir,
    );
  });

  tearDown(() {
    if (cacheDir.existsSync()) {
      cacheDir.deleteSync(recursive: true);
    }
  });

  /// Creates a minimal 1x1 red PNG image as bytes.
  Uint8List createTestImage() {
    final image = img.Image(width: 1, height: 1)
      ..setPixelRgba(0, 0, 255, 0, 0, 255); // red pixel
    return Uint8List.fromList(img.encodePng(image));
  }

  group('cacheImage', () {
    test('returns null for null or empty URL', () async {
      /// Null and empty URLs return null immediately without any network call.
      expect(await service.cacheImage(null, 'b1'), isNull);
      expect(await service.cacheImage('', 'b1'), isNull);
      verifyNever(() => mockClient.get(any()));
    });

    test('returns cached file if already exists', () async {
      /// If the file already exists on disk, it is returned without network.
      final file = File('${cacheDir.path}/b1.webp');
      await file.writeAsBytes([1, 2, 3]);

      final path = await service.cacheImage('http://example.com/img.png', 'b1');
      expect(path, file.path);
      verifyNever(() => mockClient.get(any()));
    });

    test('downloads, converts to WebP, and caches the file', () async {
      /// A successful download results in a WebP-encoded cache file.
      final pngBytes = createTestImage();

      when(
        () => mockClient.get(any()),
      ).thenAnswer((_) async => http.Response.bytes(pngBytes, 200));

      final path = await service.cacheImage('http://example.com/img.png', 'b1');
      expect(path, isNotNull);
      expect(File(path!).existsSync(), isTrue);

      // Read the cached file and verify it is a valid WebP image.
      final cachedBytes = File(path).readAsBytesSync();
      final decoded = img.decodeImage(cachedBytes);
      expect(decoded, isNotNull);
    });

    test('returns null for non-200 response', () async {
      /// If the server returns a non-200 status, null is returned.
      when(
        () => mockClient.get(any()),
      ).thenAnswer((_) async => http.Response('Not Found', 404));

      final path = await service.cacheImage('http://example.com/img.png', 'b1');
      expect(path, isNull);
    });

    test('returns null on network error', () async {
      /// An exception is caught and null is returned.
      when(() => mockClient.get(any())).thenThrow(Exception('Network error'));

      final path = await service.cacheImage('http://example.com/img.png', 'b1');
      expect(path, isNull);
    });

    test('returns null when image decode fails', () async {
      /// Non-image bytes (corrupted data) cause decodeImage to return
      /// null, and cacheImage returns null.
      when(
        () => mockClient.get(any()),
      ).thenAnswer(
        (_) async => http.Response.bytes(
          Uint8List.fromList([1, 2, 3]),
          200,
        ),
      );

      final path = await service.cacheImage('http://example.com/img.png', 'b1');
      expect(path, isNull);
    });
  });

  group('clearCache', () {
    test('deletes cached files and recreates directory', () async {
      /// Create a test file in the cache directory, call clearCache, then
      /// verify the file is gone and the directory still exists.
      final testFile = File('${cacheDir.path}/test.webp');
      await testFile.writeAsBytes([1, 2, 3]);
      expect(testFile.existsSync(), isTrue);

      await service.clearCache();

      expect(testFile.existsSync(), isFalse);
      expect(cacheDir.existsSync(), isTrue);
    });

    test('does not throw when directory does not exist', () async {
      /// If the cache directory does not exist yet, clearCache should
      /// handle it gracefully without throwing.
      cacheDir.deleteSync(recursive: true);
      expect(cacheDir.existsSync(), isFalse);

      await service.clearCache();
      // No exception should be thrown.
    });
  });
}
