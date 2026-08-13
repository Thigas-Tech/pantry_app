import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/services/app_update_handler.dart';
import 'package:pantry_app/services/image_cache_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<({String version, String buildNumber})> fakeVersionInfo({
  required String version,
  required String buildNumber,
}) async {
  return (version: version, buildNumber: buildNumber);
}

class _MockDatabaseHelper extends Mock implements DatabaseHelper {}

class _MockImageCacheService extends Mock implements ImageCacheService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late _MockDatabaseHelper mockDb;
  late _MockImageCacheService mockImageCache;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    mockDb = _MockDatabaseHelper();
    mockImageCache = _MockImageCacheService();
    when(() => mockDb.clearCachedProducts()).thenAnswer((_) async {});
    when(() => mockImageCache.clearCache()).thenAnswer((_) async {});
  });

  AppUpdateHandler handler({
    String version = '1.0',
    String buildNumber = '1',
  }) {
    return AppUpdateHandler(
      prefs: prefs,
      db: mockDb,
      imageCache: mockImageCache,
      versionInfo: () =>
          fakeVersionInfo(version: version, buildNumber: buildNumber),
    );
  }

  test(
    'checkVersionChanged returns true and persists on a version change',
    () async {
      final result = await handler(
        version: '1.1',
        buildNumber: '3',
      ).checkVersionChanged();

      expect(result, isTrue);
      expect(prefs.getString('app_version'), '1.1+3');
    },
  );

  test(
    'checkVersionChanged returns false when the version is unchanged',
    () async {
      await prefs.setString('app_version', '1.0+1');

      final result = await handler().checkVersionChanged();

      expect(result, isFalse);
    },
  );

  test('flushCaches clears the image cache and cached products', () async {
    await handler().flushCaches();

    verify(() => mockImageCache.clearCache()).called(1);
    verify(() => mockDb.clearCachedProducts()).called(1);
  });

  test(
    'updateChangelogFlag returns true when the content hash changes',
    () async {
      await prefs.setString('changelog_content_hash', 'old-hash');

      final changed = await handler().updateChangelogFlag();

      expect(changed, isTrue);
      expect(prefs.getString('changelog_show_pending'), isNull);
      expect(prefs.getString('changelog_content_hash'), isNot('old-hash'));
    },
  );

  test(
    'updateChangelogFlag stores the hash on first run without flagging',
    () async {
      final changed = await handler().updateChangelogFlag();

      expect(changed, isFalse);
      expect(prefs.getString('changelog_show_pending'), isNull);
      expect(prefs.getString('changelog_content_hash'), isNotNull);
    },
  );
}
