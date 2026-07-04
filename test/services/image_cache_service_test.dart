import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:mocktail/mocktail.dart';
import 'package:pantry_app/services/image_cache_service.dart';

/// A mock of [Dio] to control network responses.
class MockDio extends Mock implements Dio {}

/// Tests for [ImageCacheService].
///
/// A test directory is provided so the service doesn't touch the real
/// application documents directory. Network calls are mocked via
/// [MockDio].
void main() {
  late ImageCacheService service;
  late MockDio mockDio;
  late Directory cacheDir;

  setUp(() {
    mockDio = MockDio();
    cacheDir = Directory.systemTemp.createTempSync('pantry_cache_test_');
    service = ImageCacheService(dio: mockDio, cacheDirectory: cacheDir);
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
      verifyNever(() => mockDio.get<List<int>>(any()));
    });

    test('returns cached file if already exists', () async {
      /// If the file already exists on disk, it is returned without network.
      final file = File('${cacheDir.path}/b1.webp');
      await file.writeAsBytes([1, 2, 3]);

      final path = await service.cacheImage('http://example.com/img.png', 'b1');
      expect(path, file.path);
      verifyNever(() => mockDio.get<List<int>>(any()));
    });

    test('downloads, converts to WebP, and caches the file', () async {
      /// A successful download results in a WebP‑encoded cache file.
      final pngBytes = createTestImage();

      when(
        () => mockDio.get<List<int>>(
          'http://example.com/img.png',
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response<List<int>>(
          requestOptions: RequestOptions(),
          data: pngBytes,
        ),
      );

      final path = await service.cacheImage('http://example.com/img.png', 'b1');
      expect(path, isNotNull);
      expect(File(path!).existsSync(), isTrue);

      // Read the cached file and verify it is a valid WebP image.
      final cachedBytes = File(path).readAsBytesSync();
      final decoded = img.decodeImage(cachedBytes);
      expect(decoded, isNotNull);
    });

    test('returns null when response data is null', () async {
      /// If the server returns no data, null is returned.
      when(
        () => mockDio.get<List<int>>(
          'http://example.com/img.png',
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response<List<int>>(
          requestOptions: RequestOptions(),
        ),
      );

      final path = await service.cacheImage('http://example.com/img.png', 'b1');
      expect(path, isNull);
    });

    test('returns null on network error', () async {
      /// A [DioException] is caught and null is returned.
      when(
        () => mockDio.get<List<int>>(
          'http://example.com/img.png',
          options: any(named: 'options'),
        ),
      ).thenThrow(
        DioException(requestOptions: RequestOptions()),
      );

      final path = await service.cacheImage('http://example.com/img.png', 'b1');
      expect(path, isNull);
    });
  });
}
