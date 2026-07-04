import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart'; // Override
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pantry_app/l10n/app_localizations.dart';
import 'package:pantry_app/providers/image_cache_provider.dart';
import 'package:pantry_app/services/image_cache_service.dart';
import 'package:pantry_app/services/product_repository.dart';

// Reusable mock classes
class MockProductRepository extends Mock implements ProductRepository {}

class MockImageCacheService extends Mock implements ImageCacheService {}

/// Pumps [child] into a test‑friendly app shell.
///
/// - ProviderScope with a default stub for [ImageCacheService] (avoids
///   type errors in InventoryCard's FutureBuilder).
/// - MaterialApp with English locale and full localisation support.
///
/// Additional [overrides] take precedence over the defaults.
///
/// If [settle] is `false` (default `true`), only a single frame is pumped
/// after [WidgetTester.pumpWidget] – useful when you need
/// to keep an async future pending.
Future<void> pumpApp(
  WidgetTester tester,
  Widget child, {
  List<Override> overrides = const [],
  MockImageCacheService? imageCacheMock,
  bool settle = true,
}) async {
  final effectiveImageCache = imageCacheMock ?? MockImageCacheService();

  // Always stub cacheImage so any widget using the image cache doesn't crash.
  when(
    () => effectiveImageCache.cacheImage(any(), any()),
  ).thenAnswer((_) async => null);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        // Default: provide a stubbed image cache.
        imageCacheProvider.overrideWithValue(effectiveImageCache),
        // All other overrides (e.g., productRepositoryProvider) must be
        // supplied by the test.
        ...overrides,
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    ),
  );

  if (settle) {
    await tester.pumpAndSettle();
  } else {
    // Pump at least one frame so the widget builds, but don't wait for
    // pending futures.
    await tester.pump();
  }
}
