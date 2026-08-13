import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pantry_app/providers/image_cache_provider.dart';
import 'package:pantry_app/services/image_cache_service.dart';


class _MockImageCacheService extends Mock implements ImageCacheService {}

void main() {
  late _MockImageCacheService mockCache;

  setUp(() {
    mockCache = _MockImageCacheService();
    when(
      () => mockCache.cacheImage(any(), any()),
    ).thenAnswer((_) async => '/tmp/cached/001.webp');
  });

  test('shares one in-flight call across reads for the same key', () async {
    final container = ProviderContainer(
      overrides: [imageCacheProvider.overrideWithValue(mockCache)],
    );
    addTearDown(container.dispose);

    final first = await container.read(
      cachedImageProvider(('https://example.com/1.jpg', '001')).future,
    );
    final second = await container.read(
      cachedImageProvider(('https://example.com/1.jpg', '001')).future,
    );

    expect(first, '/tmp/cached/001.webp');
    expect(second, '/tmp/cached/001.webp');
    verify(() => mockCache.cacheImage(any(), any())).called(1);
  });

  test('calls the cache per distinct (url, barcode) key', () async {
    final container = ProviderContainer(
      overrides: [imageCacheProvider.overrideWithValue(mockCache)],
    );
    addTearDown(container.dispose);

    await container.read(
      cachedImageProvider(('https://example.com/1.jpg', '001')).future,
    );
    await container.read(
      cachedImageProvider(('https://example.com/2.jpg', '002')).future,
    );

    verify(() => mockCache.cacheImage(any(), any())).called(2);
  });
}
