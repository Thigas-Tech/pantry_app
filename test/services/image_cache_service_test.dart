import 'dart:async';
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

  /// Creates a PNG of [width] x [height] filled with red.
  Uint8List createLargeImage(int width, int height) {
    final image = img.Image(width: width, height: height);
    img.fill(image, color: img.ColorRgba8(255, 0, 0, 255));
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

    test('downscales large images to the maximum cached dimension', () async {
      /// A 1200x600 source image must be stored at most 400px on its
      /// longest side, keeping the aspect ratio.
      when(
        () => mockClient.get(any()),
      ).thenAnswer(
        (_) async => http.Response.bytes(createLargeImage(1200, 600), 200),
      );

      final path = await service.cacheImage(
        'http://example.com/big.png',
        'big',
      );
      expect(path, isNotNull);

      final decoded = img.decodeImage(File(path!).readAsBytesSync());
      expect(decoded, isNotNull);
      expect(decoded!.width, lessThanOrEqualTo(400));
      expect(decoded.height, lessThanOrEqualTo(400));
      expect(decoded.width / decoded.height, closeTo(2.0, 0.01));
    });

    test('keeps images smaller than the maximum dimension unchanged', () async {
      /// A small source image must not be upscaled.
      when(
        () => mockClient.get(any()),
      ).thenAnswer((_) async => http.Response.bytes(createTestImage(), 200));

      final path = await service.cacheImage(
        'http://example.com/small.png',
        's1',
      );
      expect(path, isNotNull);

      final decoded = img.decodeImage(File(path!).readAsBytesSync());
      expect(decoded, isNotNull);
      expect(decoded!.width, 1);
      expect(decoded.height, 1);
    });

    test('deduplicates concurrent downloads for the same barcode', () async {
      /// Two concurrent cacheImage calls for the same barcode must result
      /// in a single network request.
      final completer = Completer<http.Response>();
      when(() => mockClient.get(any())).thenAnswer((_) => completer.future);

      final first = service.cacheImage('http://example.com/img.png', 'dedup');
      final second = service.cacheImage('http://example.com/img.png', 'dedup');

      completer.complete(http.Response.bytes(createTestImage(), 200));
      final path1 = await first;
      final path2 = await second;

      expect(path1, isNotNull);
      expect(path2, path1);
      verify(() => mockClient.get(any())).called(1);
    });

    test('deduplicates a slow download that is already in flight', () async {
      /// A third call while the first is still downloading shares the
      /// in-flight future without starting a new request.
      final completer = Completer<http.Response>();
      when(() => mockClient.get(any())).thenAnswer((_) => completer.future);

      final first = service.cacheImage('http://example.com/img.png', 'b3');
      final second = service.cacheImage('http://example.com/img.png', 'b3');
      final third = service.cacheImage('http://example.com/img.png', 'b3');

      completer.complete(http.Response.bytes(createTestImage(), 200));
      await Future.wait([first, second, third]);

      verify(() => mockClient.get(any())).called(1);
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

    test('evicts the oldest files when the cache exceeds its cap', () async {
      /// A service with a tiny cap keeps only the newest files and evicts
      /// the oldest ones until the total size fits under the cap.
      final tinyService = ImageCacheService(
        httpClient: mockClient,
        cacheDirectory: cacheDir,
        maxCacheBytes: 100,
      );
      when(
        () => mockClient.get(any()),
      ).thenAnswer((_) async => http.Response.bytes(createTestImage(), 200));

      await tinyService.cacheImage('http://example.com/a.png', 'a1');
      await tinyService.cacheImage('http://example.com/b.png', 'b2');
      await tinyService.cacheImage('http://example.com/c.png', 'c3');
      await tinyService.cacheImage('http://example.com/d.png', 'd4');

      final remaining = cacheDir
          .listSync()
          .whereType<File>()
          .map((f) => f.path)
          .toList();
      expect(remaining, hasLength(lessThan(4)));
      expect(File('${cacheDir.path}/a1.webp').existsSync(), isFalse);
      expect(File('${cacheDir.path}/d4.webp').existsSync(), isTrue);
    });

    test('does not evict when the cache stays under the cap', () async {
      /// With a generous cap all files are kept.
      when(
        () => mockClient.get(any()),
      ).thenAnswer((_) async => http.Response.bytes(createTestImage(), 200));

      await service.cacheImage('http://example.com/a.png', 'k1');
      await service.cacheImage('http://example.com/b.png', 'k2');

      expect(File('${cacheDir.path}/k1.webp').existsSync(), isTrue);
      expect(File('${cacheDir.path}/k2.webp').existsSync(), isTrue);
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
