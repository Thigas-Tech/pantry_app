import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/database/inventory_dao.dart';
import 'package:pantry_app/providers/cache_refresh_coordinator_provider.dart';
import 'package:pantry_app/providers/database_provider.dart';
import 'package:pantry_app/providers/firebase_cache_provider.dart';
import 'package:pantry_app/providers/image_cache_provider.dart';
import 'package:pantry_app/providers/notification_service_provider.dart';
import 'package:pantry_app/providers/product_submission_provider.dart';
import 'package:pantry_app/services/app_startup_service.dart';
import 'package:pantry_app/services/cache_refresh_coordinator.dart';
import 'package:pantry_app/services/firebase_cache_service.dart';
import 'package:pantry_app/services/image_cache_service.dart';
import 'package:pantry_app/services/product_submission_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import 'mock_notification_service.dart';

class _MockDb extends Mock implements DatabaseHelper {}

class _MockInventoryDao extends Mock implements InventoryDao {}

class _MockDatabase extends Mock implements Database {}

class _MockImageCache extends Mock implements ImageCacheService {}

class _MockRefreshCoordinator extends Mock implements CacheRefreshCoordinator {}

class _MockSubmissionService extends Mock implements ProductSubmissionService {}

class _MockFirebaseCache extends Mock implements FirebaseCacheService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  registerFallbackValue(_MockDatabase());

  setUp(() {
    dotenv.loadFromString(isOptional: true, mergeWith: {});
  });

  group('app update', () {
    test('version change flushes caches post-frame', () async {
      SharedPreferences.setMockInitialValues({'app_version': '0.9+1'});
      final db = _MockDb();
      final imageCache = _MockImageCache();
      when(db.clearCachedProducts).thenAnswer((_) async {});
      when(imageCache.clearCache).thenAnswer((_) async {});
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          imageCacheProvider.overrideWithValue(imageCache),
        ],
      );
      addTearDown(container.dispose);

      final service = AppStartupService(
        container: container,
        versionInfo: () async => (version: '1.0', buildNumber: '2'),
      );
      await service.checkAppUpdateBeforeFrame();
      await service.runAppUpdatePostFrame();

      verify(db.clearCachedProducts).called(1);
      verify(imageCache.clearCache).called(1);
    });

    test('no cache flush when the version is unchanged', () async {
      SharedPreferences.setMockInitialValues({'app_version': '1.0+2'});
      final db = _MockDb();
      final imageCache = _MockImageCache();
      when(db.clearCachedProducts).thenAnswer((_) async {});
      when(imageCache.clearCache).thenAnswer((_) async {});
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          imageCacheProvider.overrideWithValue(imageCache),
        ],
      );
      addTearDown(container.dispose);

      final service = AppStartupService(
        container: container,
        versionInfo: () async => (version: '1.0', buildNumber: '2'),
      );
      await service.checkAppUpdateBeforeFrame();
      await service.runAppUpdatePostFrame();

      verifyNever(db.clearCachedProducts);
      verifyNever(imageCache.clearCache);
    });

    test('changed changelog content flags the whats-new badge', () async {
      SharedPreferences.setMockInitialValues({'changelog_content_hash': '0'});
      final db = _MockDb();
      final imageCache = _MockImageCache();
      when(db.clearCachedProducts).thenAnswer((_) async {});
      when(imageCache.clearCache).thenAnswer((_) async {});
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          imageCacheProvider.overrideWithValue(imageCache),
        ],
      );
      addTearDown(container.dispose);

      final service = AppStartupService(
        container: container,
        versionInfo: () async => (version: '1.0', buildNumber: '2'),
      );
      await service.checkAppUpdateBeforeFrame();
      await service.runAppUpdatePostFrame();
      await Future<void>.delayed(Duration.zero);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('changelog_show_pending'), 'true');
    });
  });

  group('sign in', () {
    test('is a no-op when firebase is disabled', () async {
      final calls = <bool>[];
      final service = AppStartupService(
        container: ProviderContainer(),
        anonymousSignIn: () async => calls.add(true),
      );
      await service.signInAnonymously();
      expect(calls, isEmpty);
    });

    test('calls the injected sign-in when firebase is enabled', () async {
      dotenv.loadFromString(
        isOptional: true,
        mergeWith: {'FIREBASE_ENABLED': 'true'},
      );
      final calls = <bool>[];
      final service = AppStartupService(
        container: ProviderContainer(),
        anonymousSignIn: () async => calls.add(true),
      );
      await service.signInAnonymously();
      expect(calls, [true]);
    });
  });

  group('notification permission', () {
    test('defers when the rationale has not been shown', () async {
      SharedPreferences.setMockInitialValues({});
      final notif = MockNotificationService();
      final container = ProviderContainer(
        overrides: [notificationServiceProvider.overrideWithValue(notif)],
      );
      addTearDown(container.dispose);

      final service = AppStartupService(container: container);
      await service.requestNotificationPermission();

      verifyNever(notif.requestPermission);
    });

    test('granted permission reschedules expiry reminders', () async {
      SharedPreferences.setMockInitialValues({
        'notification_rationale_shown': true,
      });
      final notif = MockNotificationService();
      when(notif.requestPermission).thenAnswer((_) async => true);
      _stubNotifScheduling(notif);
      final db = _stubSchedulingDb();
      final container = ProviderContainer(
        overrides: [
          notificationServiceProvider.overrideWithValue(notif),
          databaseProvider.overrideWithValue(db),
        ],
      );
      addTearDown(container.dispose);

      final service = AppStartupService(container: container);
      await service.requestNotificationPermission();
      await Future<void>.delayed(Duration.zero);

      verify(
        () => notif.rescheduleAllItems(
          any(),
          expiringSoonTitle: any(named: 'expiringSoonTitle'),
          expiringTodayTitle: any(named: 'expiringTodayTitle'),
          buildExpiringSoonBody: any(named: 'buildExpiringSoonBody'),
          buildExpiringTodayBody: any(named: 'buildExpiringTodayBody'),
          barcodeToName: any(named: 'barcodeToName'),
          notificationsEnabled: any(named: 'notificationsEnabled'),
        ),
      ).called(1);
    });

    test('denied permission flags the shell warning', () async {
      SharedPreferences.setMockInitialValues({
        'notification_rationale_shown': true,
      });
      final notif = MockNotificationService();
      when(notif.requestPermission).thenAnswer((_) async => false);
      final db = _stubSchedulingDb();
      final container = ProviderContainer(
        overrides: [
          notificationServiceProvider.overrideWithValue(notif),
          databaseProvider.overrideWithValue(db),
        ],
      );
      addTearDown(container.dispose);

      final service = AppStartupService(container: container);
      await service.requestNotificationPermission();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('notification_denied_warning'), isTrue);
      verifyNever(
        () => notif.rescheduleAllItems(
          any(),
          expiringSoonTitle: any(named: 'expiringSoonTitle'),
          expiringTodayTitle: any(named: 'expiringTodayTitle'),
          buildExpiringSoonBody: any(named: 'buildExpiringSoonBody'),
          buildExpiringTodayBody: any(named: 'buildExpiringTodayBody'),
          barcodeToName: any(named: 'barcodeToName'),
          notificationsEnabled: any(named: 'notificationsEnabled'),
        ),
      );
    });
  });

  group('notification tap', () {
    test('ignores the inactivity reminder payload', () {
      final db = _MockDb();
      final container = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)],
      );
      addTearDown(container.dispose);

      AppStartupService(container: container).handleNotificationTap(
        const NotificationResponse(
          payload: 'inactivity_reminder',
          notificationResponseType:
              NotificationResponseType.selectedNotification,
        ),
      );

      verifyNever(() => db.getProduct(any()));
    });

    test('ignores an empty payload', () {
      final db = _MockDb();
      final container = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)],
      );
      addTearDown(container.dispose);

      AppStartupService(container: container).handleNotificationTap(
        const NotificationResponse(
          payload: '',
          notificationResponseType:
              NotificationResponseType.selectedNotification,
        ),
      );

      verifyNever(() => db.getProduct(any()));
    });
  });

  group('schedulePostInitTasks', () {
    test('runs every post-init task', () async {
      SharedPreferences.setMockInitialValues({'app_version': '1.0+2'});
      final db = _MockDb();
      final inventoryDao = _MockInventoryDao();
      final notif = MockNotificationService();
      final imageCache = _MockImageCache();
      final refresh = _MockRefreshCoordinator();
      final submission = _MockSubmissionService();
      final firebaseCache = _MockFirebaseCache();
      final database = _MockDatabase();

      when(() => db.inventoryDao).thenReturn(inventoryDao);
      when(() => db.database).thenAnswer((_) async => database);
      when(db.getInventories).thenAnswer((_) async => []);
      when(
        () => inventoryDao.list(
          any(),
          inventoryId: any(named: 'inventoryId'),
        ),
      ).thenAnswer((_) async => []);
      when(db.getLastAddDate).thenAnswer((_) async => 0);
      when(
        () => db.cleanupOldEntries(retentionDays: any(named: 'retentionDays')),
      ).thenAnswer((_) async {});
      when(db.clearCachedProducts).thenAnswer((_) async {});
      when(() => db.getProduct(any())).thenAnswer((_) async => null);
      when(imageCache.clearCache).thenAnswer((_) async {});
      when(notif.getLaunchDetails).thenAnswer((_) async => null);
      when(
        () => notif.rescheduleAllItems(
          any(),
          expiringSoonTitle: any(named: 'expiringSoonTitle'),
          expiringTodayTitle: any(named: 'expiringTodayTitle'),
          buildExpiringSoonBody: any(named: 'buildExpiringSoonBody'),
          buildExpiringTodayBody: any(named: 'buildExpiringTodayBody'),
          barcodeToName: any(named: 'barcodeToName'),
          notificationsEnabled: any(named: 'notificationsEnabled'),
        ),
      ).thenAnswer((_) => Future<void>.value());
      when(
        notif.cancelInactivityReminder,
      ).thenAnswer((_) => Future<void>.value());
      when(
        () => notif.scheduleInactivityReminder(
          lastAddDateEpoch: any(named: 'lastAddDateEpoch'),
          thresholdDays: any(named: 'thresholdDays'),
          title: any(named: 'title'),
          buildBody: any(named: 'buildBody'),
          channelName: any(named: 'channelName'),
          channelDescription: any(named: 'channelDescription'),
          notificationsEnabled: any(named: 'notificationsEnabled'),
        ),
      ).thenAnswer((_) => Future<void>.value());
      when(refresh.refreshIfOverdue).thenAnswer((_) async => 0);
      when(submission.flushQueue).thenAnswer((_) async => 0);
      when(() => firebaseCache.isAvailable).thenReturn(true);
      when(firebaseCache.refreshStaleEntries).thenAnswer((_) async => 0);

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          imageCacheProvider.overrideWithValue(imageCache),
          notificationServiceProvider.overrideWithValue(notif),
          cacheRefreshCoordinatorProvider.overrideWithValue(refresh),
          productSubmissionServiceProvider.overrideWithValue(submission),
          firebaseCacheProvider.overrideWithValue(firebaseCache),
        ],
      );
      addTearDown(container.dispose);

      final service = AppStartupService(
        container: container,
        versionInfo: () async => (version: '1.0', buildNumber: '2'),
        delay: (d) async {},
      );
      await service.checkAppUpdateBeforeFrame();
      await service.schedulePostInitTasks();

      verify(notif.getLaunchDetails).called(1);
      verify(refresh.refreshIfOverdue).called(1);
      verify(
        () => db.cleanupOldEntries(retentionDays: any(named: 'retentionDays')),
      ).called(1);
      verify(
        () => notif.rescheduleAllItems(
          any(),
          expiringSoonTitle: any(named: 'expiringSoonTitle'),
          expiringTodayTitle: any(named: 'expiringTodayTitle'),
          buildExpiringSoonBody: any(named: 'buildExpiringSoonBody'),
          buildExpiringTodayBody: any(named: 'buildExpiringTodayBody'),
          barcodeToName: any(named: 'barcodeToName'),
          notificationsEnabled: any(named: 'notificationsEnabled'),
        ),
      ).called(1);
      verify(
        () => notif.scheduleInactivityReminder(
          lastAddDateEpoch: any(named: 'lastAddDateEpoch'),
          thresholdDays: any(named: 'thresholdDays'),
          title: any(named: 'title'),
          buildBody: any(named: 'buildBody'),
          channelName: any(named: 'channelName'),
          channelDescription: any(named: 'channelDescription'),
          notificationsEnabled: any(named: 'notificationsEnabled'),
        ),
      ).called(1);
      verify(submission.flushQueue).called(1);
      verify(firebaseCache.refreshStaleEntries).called(1);
    });
  });
}

MockNotificationService _stubNotifScheduling(MockNotificationService notif) {
  when(
    () => notif.rescheduleAllItems(
      any(),
      expiringSoonTitle: any(named: 'expiringSoonTitle'),
      expiringTodayTitle: any(named: 'expiringTodayTitle'),
      buildExpiringSoonBody: any(named: 'buildExpiringSoonBody'),
      buildExpiringTodayBody: any(named: 'buildExpiringTodayBody'),
      barcodeToName: any(named: 'barcodeToName'),
      notificationsEnabled: any(named: 'notificationsEnabled'),
    ),
  ).thenAnswer((_) => Future<void>.value());
  return notif;
}

_MockDb _stubSchedulingDb() {
  final db = _MockDb();
  final inventoryDao = _MockInventoryDao();
  final database = _MockDatabase();
  when(() => db.inventoryDao).thenReturn(inventoryDao);
  when(() => db.database).thenAnswer((_) async => database);
  when(db.getInventories).thenAnswer((_) async => []);
  when(
    () => inventoryDao.list(
      any(),
      inventoryId: any(named: 'inventoryId'),
    ),
  ).thenAnswer((_) async => []);
  when(db.getLastAddDate).thenAnswer((_) async => 0);
  when(() => db.getProductsByBarcodes(any())).thenAnswer((_) async => []);
  return db;
}
