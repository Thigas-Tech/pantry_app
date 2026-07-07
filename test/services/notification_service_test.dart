import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pantry_app/models/inventory_item.dart';
import 'package:pantry_app/services/notification_background_handler.dart';
import 'package:pantry_app/services/notification_service.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class MockFlutterLocalNotificationsPlugin extends Mock
    implements FlutterLocalNotificationsPlugin {}

class MockAndroidFlutterLocalNotificationsPlugin extends Mock
    implements AndroidFlutterLocalNotificationsPlugin {}

void main() {
  setUpAll(() {
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.UTC);

    registerFallbackValue(
      const InitializationSettings(
        android: AndroidInitializationSettings('ic_notification'),
        iOS: DarwinInitializationSettings(),
      ),
    );
    registerFallbackValue(tz.TZDateTime.now(tz.UTC));
    registerFallbackValue(
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'expiry_channel',
          'Expiry reminders',
          channelDescription: 'Warns about expiring food',
          importance: Importance.high,
          category: AndroidNotificationCategory.reminder,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
    registerFallbackValue(AndroidScheduleMode.inexactAllowWhileIdle);
    registerFallbackValue(
      const AndroidNotificationChannel(
        'expiry_channel',
        'Expiry reminders',
        description: 'Warns about expiring food',
        importance: Importance.high,
      ),
    );
    registerFallbackValue(
      const AndroidNotificationChannel(
        'inactivity_channel',
        'Inactivity reminders',
        description: 'Reminds you to add products regularly',
        importance: Importance.low,
      ),
    );
    registerFallbackValue(
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'inactivity_channel',
          'Inactivity reminders',
          channelDescription: 'Reminds you to add products regularly',
          importance: Importance.low,
          category: AndroidNotificationCategory.recommendation,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  });

  late MockFlutterLocalNotificationsPlugin mockPlugin;
  late MockAndroidFlutterLocalNotificationsPlugin mockAndroidPlugin;
  late NotificationService service;

  setUp(() {
    mockPlugin = MockFlutterLocalNotificationsPlugin();
    mockAndroidPlugin = MockAndroidFlutterLocalNotificationsPlugin();
    service = NotificationService(
      plugin: mockPlugin,
      defaultLocation: tz.UTC,
    );

    when(
      () => mockPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >(),
    ).thenReturn(mockAndroidPlugin);
    when(
      () => mockAndroidPlugin.createNotificationChannel(any()),
    ).thenAnswer((_) => Future.value());
  });

  group('initialize', () {
    test('is idempotent', () async {
      when(
        () => mockPlugin.initialize(
          settings: any(named: 'settings'),
          onDidReceiveNotificationResponse: any(
            named: 'onDidReceiveNotificationResponse',
          ),
          onDidReceiveBackgroundNotificationResponse: any(
            named: 'onDidReceiveBackgroundNotificationResponse',
          ),
        ),
      ).thenAnswer((_) => Future.value(true));
      await service.initialize();
      await service.initialize();

      verify(
        () => mockPlugin.initialize(
          settings: any(named: 'settings'),
          onDidReceiveNotificationResponse: any(
            named: 'onDidReceiveNotificationResponse',
          ),
          onDidReceiveBackgroundNotificationResponse: any(
            named: 'onDidReceiveBackgroundNotificationResponse',
          ),
        ),
      ).called(1);
      expect(service.initialized, isTrue);
    });

    test('passes onDidReceiveResponse callback to plugin', () async {
      when(
        () => mockPlugin.initialize(
          settings: any(named: 'settings'),
          onDidReceiveNotificationResponse: any(
            named: 'onDidReceiveNotificationResponse',
          ),
          onDidReceiveBackgroundNotificationResponse: any(
            named: 'onDidReceiveBackgroundNotificationResponse',
          ),
        ),
      ).thenAnswer((_) => Future.value(true));
      await service.initialize(onDidReceiveResponse: (_) {});

      verify(
        () => mockPlugin.initialize(
          settings: any(named: 'settings'),
          onDidReceiveNotificationResponse: any(
            named: 'onDidReceiveNotificationResponse',
          ),
        ),
      ).called(1);
    });

    test(
      'passes onDidReceiveBackgroundResponse callback',
      () async {
        when(
          () => mockPlugin.initialize(
            settings: any(named: 'settings'),
            onDidReceiveNotificationResponse: any(
              named: 'onDidReceiveNotificationResponse',
            ),
            onDidReceiveBackgroundNotificationResponse: any(
              named: 'onDidReceiveBackgroundNotificationResponse',
            ),
          ),
        ).thenAnswer((_) => Future.value(true));
        await service.initialize(
          onDidReceiveBackgroundResponse: notificationTapBackground,
        );

        verify(
          () => mockPlugin.initialize(
            settings: any(named: 'settings'),
            onDidReceiveBackgroundNotificationResponse: any(
              named: 'onDidReceiveBackgroundNotificationResponse',
            ),
          ),
        ).called(1);
      },
    );

    test('handles channel creation failure gracefully', () async {
      final failingAndroid = MockAndroidFlutterLocalNotificationsPlugin();
      when(
        () => mockPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >(),
      ).thenReturn(failingAndroid);
      when(
        () => failingAndroid.createNotificationChannel(any()),
      ).thenThrow(Exception('channel error'));
      when(
        () => mockPlugin.initialize(
          settings: any(named: 'settings'),
          onDidReceiveNotificationResponse: any(
            named: 'onDidReceiveNotificationResponse',
          ),
          onDidReceiveBackgroundNotificationResponse: any(
            named: 'onDidReceiveBackgroundNotificationResponse',
          ),
        ),
      ).thenAnswer((_) => Future.value(true));

      await service.initialize();
      // Channel failure is non-fatal; the service still initialises.
      expect(service.initialized, isTrue);
      verify(
        () => failingAndroid.createNotificationChannel(any()),
      ).called(1);
    });
  });

  group('ensureNotificationChannel', () {
    test('creates channel with correct parameters', () async {
      await service.ensureNotificationChannel();

      verify(
        () => mockAndroidPlugin.createNotificationChannel(any()),
      ).called(1);
    });

    test('handles exception gracefully', () async {
      when(
        () => mockAndroidPlugin.createNotificationChannel(any()),
      ).thenThrow(Exception('create failed'));

      await expectLater(service.ensureNotificationChannel(), completes);
    });
  });

  group('requestPermission', () {
    test('returns true when granted', () async {
      when(
        mockAndroidPlugin.requestNotificationsPermission,
      ).thenAnswer((_) => Future.value(true));

      final result = await service.requestPermission();
      expect(result, isTrue);
    });

    test('returns false when denied', () async {
      when(
        mockAndroidPlugin.requestNotificationsPermission,
      ).thenAnswer((_) => Future.value(false));

      final result = await service.requestPermission();
      expect(result, isFalse);
    });

    test('returns null when not on Android', () async {
      when(
        () => mockPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >(),
      ).thenReturn(null);

      final result = await service.requestPermission();
      expect(result, isNull);
    });
  });

  group('areNotificationsEnabled', () {
    test('returns true when Android reports enabled', () async {
      when(
        mockAndroidPlugin.areNotificationsEnabled,
      ).thenAnswer((_) => Future.value(true));

      expect(await service.areNotificationsEnabled(), isTrue);
    });

    test('returns null when not on Android', () async {
      when(
        () => mockPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >(),
      ).thenReturn(null);

      expect(await service.areNotificationsEnabled(), isNull);
    });
  });

  group('scheduleExpiryReminders', () {
    const expiringSoonTitle = 'Expiring soon';
    const expiringTodayTitle = 'Food expiring today';
    String buildExpiringSoonBody(String b) => '$b expires tomorrow';
    String buildExpiringTodayBody(String b) => '$b expires today!';

    void stubZonedSchedule() {
      when(
        () => mockPlugin.zonedSchedule(
          id: any(named: 'id'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          scheduledDate: any(named: 'scheduledDate'),
          notificationDetails: any(named: 'notificationDetails'),
          androidScheduleMode: any(named: 'androidScheduleMode'),
          payload: any(named: 'payload'),
        ),
      ).thenAnswer((_) => Future.value());
    }

    void stubNotificationsEnabled() {
      when(
        mockAndroidPlugin.areNotificationsEnabled,
      ).thenAnswer((_) => Future.value(true));
    }

    test('skips when expiryDate is null', () async {
      const item = InventoryItem(barcode: '123', id: 1);
      await service.scheduleExpiryReminders(
        item,
        expiringSoonTitle: expiringSoonTitle,
        buildExpiringSoonBody: buildExpiringSoonBody,
        expiringTodayTitle: expiringTodayTitle,
        buildExpiringTodayBody: buildExpiringTodayBody,
      );

      verifyNever(
        () => mockPlugin.zonedSchedule(
          id: any(named: 'id'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          scheduledDate: any(named: 'scheduledDate'),
          notificationDetails: any(named: 'notificationDetails'),
          androidScheduleMode: any(named: 'androidScheduleMode'),
          payload: any(named: 'payload'),
        ),
      );
    });

    test('skips when id is null', () async {
      const item = InventoryItem(
        barcode: '123',
        expiryDate: '2099-12-31',
      );
      await service.scheduleExpiryReminders(
        item,
        expiringSoonTitle: expiringSoonTitle,
        buildExpiringSoonBody: buildExpiringSoonBody,
        expiringTodayTitle: expiringTodayTitle,
        buildExpiringTodayBody: buildExpiringTodayBody,
      );

      verifyNever(
        () => mockPlugin.zonedSchedule(
          id: any(named: 'id'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          scheduledDate: any(named: 'scheduledDate'),
          notificationDetails: any(named: 'notificationDetails'),
          androidScheduleMode: any(named: 'androidScheduleMode'),
          payload: any(named: 'payload'),
        ),
      );
    });

    test('skips when notificationsEnabled is false', () async {
      const item = InventoryItem(
        barcode: '123',
        id: 1,
        expiryDate: '2099-12-31',
      );
      await service.scheduleExpiryReminders(
        item,
        expiringSoonTitle: expiringSoonTitle,
        buildExpiringSoonBody: buildExpiringSoonBody,
        expiringTodayTitle: expiringTodayTitle,
        buildExpiringTodayBody: buildExpiringTodayBody,
        notificationsEnabled: false,
      );

      verifyNever(
        () => mockPlugin.zonedSchedule(
          id: any(named: 'id'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          scheduledDate: any(named: 'scheduledDate'),
          notificationDetails: any(named: 'notificationDetails'),
          androidScheduleMode: any(named: 'androidScheduleMode'),
          payload: any(named: 'payload'),
        ),
      );
    });

    test('skips when system notifications are disabled', () async {
      when(
        mockAndroidPlugin.areNotificationsEnabled,
      ).thenAnswer((_) => Future.value(false));

      const item = InventoryItem(
        barcode: '123',
        id: 1,
        expiryDate: '2099-12-31',
      );
      await service.scheduleExpiryReminders(
        item,
        expiringSoonTitle: expiringSoonTitle,
        buildExpiringSoonBody: buildExpiringSoonBody,
        expiringTodayTitle: expiringTodayTitle,
        buildExpiringTodayBody: buildExpiringTodayBody,
      );

      verifyNever(
        () => mockPlugin.zonedSchedule(
          id: any(named: 'id'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          scheduledDate: any(named: 'scheduledDate'),
          notificationDetails: any(named: 'notificationDetails'),
          androidScheduleMode: any(named: 'androidScheduleMode'),
          payload: any(named: 'payload'),
        ),
      );
    });

    test('skips when expiryDate is invalid', () async {
      const item = InventoryItem(
        barcode: '123',
        id: 1,
        expiryDate: 'not-a-date',
      );
      await service.scheduleExpiryReminders(
        item,
        expiringSoonTitle: expiringSoonTitle,
        buildExpiringSoonBody: buildExpiringSoonBody,
        expiringTodayTitle: expiringTodayTitle,
        buildExpiringTodayBody: buildExpiringTodayBody,
      );

      verifyNever(
        () => mockPlugin.zonedSchedule(
          id: any(named: 'id'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          scheduledDate: any(named: 'scheduledDate'),
          notificationDetails: any(named: 'notificationDetails'),
          androidScheduleMode: any(named: 'androidScheduleMode'),
          payload: any(named: 'payload'),
        ),
      );
    });

    test('schedules two notifications for far-future expiry', () async {
      stubNotificationsEnabled();
      stubZonedSchedule();

      const item = InventoryItem(
        barcode: '123',
        id: 1,
        expiryDate: '2099-12-31',
      );
      await service.scheduleExpiryReminders(
        item,
        expiringSoonTitle: expiringSoonTitle,
        buildExpiringSoonBody: buildExpiringSoonBody,
        expiringTodayTitle: expiringTodayTitle,
        buildExpiringTodayBody: buildExpiringTodayBody,
      );

      verify(
        () => mockPlugin.zonedSchedule(
          id: any(named: 'id'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          scheduledDate: any(named: 'scheduledDate'),
          notificationDetails: any(named: 'notificationDetails'),
          androidScheduleMode: any(named: 'androidScheduleMode'),
          payload: any(named: 'payload'),
        ),
      ).called(2);
    });

    test('sets notification payload to barcode', () async {
      stubNotificationsEnabled();
      stubZonedSchedule();

      const item = InventoryItem(
        barcode: '789123456',
        id: 1,
        expiryDate: '2099-12-31',
      );
      await service.scheduleExpiryReminders(
        item,
        expiringSoonTitle: expiringSoonTitle,
        buildExpiringSoonBody: buildExpiringSoonBody,
        expiringTodayTitle: expiringTodayTitle,
        buildExpiringTodayBody: buildExpiringTodayBody,
      );

      verify(
        () => mockPlugin.zonedSchedule(
          id: any(named: 'id'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          scheduledDate: any(named: 'scheduledDate'),
          notificationDetails: any(named: 'notificationDetails'),
          androidScheduleMode: any(named: 'androidScheduleMode'),
          payload: '789123456',
        ),
      ).called(2);
    });

    test('uses itemId * 2 and itemId * 2 + 1 as notification ids', () async {
      stubNotificationsEnabled();
      stubZonedSchedule();

      const item = InventoryItem(
        barcode: '123',
        id: 7,
        expiryDate: '2099-12-31',
      );
      await service.scheduleExpiryReminders(
        item,
        expiringSoonTitle: expiringSoonTitle,
        buildExpiringSoonBody: buildExpiringSoonBody,
        expiringTodayTitle: expiringTodayTitle,
        buildExpiringTodayBody: buildExpiringTodayBody,
      );

      verify(
        () => mockPlugin.zonedSchedule(
          id: 14,
          title: any(named: 'title'),
          body: any(named: 'body'),
          scheduledDate: any(named: 'scheduledDate'),
          notificationDetails: any(named: 'notificationDetails'),
          androidScheduleMode: any(named: 'androidScheduleMode'),
          payload: any(named: 'payload'),
        ),
      ).called(1);
      verify(
        () => mockPlugin.zonedSchedule(
          id: 15,
          title: any(named: 'title'),
          body: any(named: 'body'),
          scheduledDate: any(named: 'scheduledDate'),
          notificationDetails: any(named: 'notificationDetails'),
          androidScheduleMode: any(named: 'androidScheduleMode'),
          payload: any(named: 'payload'),
        ),
      ).called(1);
    });

    test('handles zonedSchedule throwing gracefully', () async {
      stubNotificationsEnabled();
      when(
        () => mockPlugin.zonedSchedule(
          id: any(named: 'id'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          scheduledDate: any(named: 'scheduledDate'),
          notificationDetails: any(named: 'notificationDetails'),
          androidScheduleMode: any(named: 'androidScheduleMode'),
          payload: any(named: 'payload'),
        ),
      ).thenThrow(Exception('schedule failed'));

      const item = InventoryItem(
        barcode: '123',
        id: 1,
        expiryDate: '2099-12-31',
      );

      await expectLater(
        service.scheduleExpiryReminders(
          item,
          expiringSoonTitle: expiringSoonTitle,
          buildExpiringSoonBody: buildExpiringSoonBody,
          expiringTodayTitle: expiringTodayTitle,
          buildExpiringTodayBody: buildExpiringTodayBody,
        ),
        completes,
      );
    });
  });

  group('scheduleInactivityReminder', () {
    const title = 'Time to restock your pantry?';
    const channelName = 'Inactivity reminders';
    const channelDescription = 'Reminds you to add products regularly';

    late void Function() stubZonedSchedule;
    late void Function() stubNotificationsEnabled;

    const inactivityReminderId = 999_999_001;

    setUp(() {
      stubZonedSchedule = () {
        when(
          () => mockPlugin.zonedSchedule(
            id: any(named: 'id'),
            title: any(named: 'title'),
            body: any(named: 'body'),
            scheduledDate: any(named: 'scheduledDate'),
            notificationDetails: any(named: 'notificationDetails'),
            androidScheduleMode: any(named: 'androidScheduleMode'),
            payload: any(named: 'payload'),
          ),
        ).thenAnswer((_) => Future.value());
      };

      stubNotificationsEnabled = () {
        when(
          mockAndroidPlugin.areNotificationsEnabled,
        ).thenAnswer((_) => Future.value(true));
      };
    });

    test('skips when notifications disabled', () async {
      await service.scheduleInactivityReminder(
        lastAddDateEpoch: 0,
        thresholdDays: 10,
        title: title,
        buildBody: (_) => 'body',
        channelName: channelName,
        channelDescription: channelDescription,
        notificationsEnabled: false,
      );

      verifyNever(
        () => mockPlugin.zonedSchedule(
          id: any(named: 'id'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          scheduledDate: any(named: 'scheduledDate'),
          notificationDetails: any(named: 'notificationDetails'),
          androidScheduleMode: any(named: 'androidScheduleMode'),
          payload: any(named: 'payload'),
        ),
      );
    });

    test('skips when lastAddDateEpoch is null', () async {
      await service.scheduleInactivityReminder(
        lastAddDateEpoch: null,
        thresholdDays: 10,
        title: title,
        buildBody: (_) => 'body',
        channelName: channelName,
        channelDescription: channelDescription,
      );

      verifyNever(
        () => mockPlugin.zonedSchedule(
          id: any(named: 'id'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          scheduledDate: any(named: 'scheduledDate'),
          notificationDetails: any(named: 'notificationDetails'),
          androidScheduleMode: any(named: 'androidScheduleMode'),
          payload: any(named: 'payload'),
        ),
      );
    });

    test('skips when days since last add is under threshold', () async {
      stubNotificationsEnabled();
      when(
        () => mockAndroidPlugin.createNotificationChannel(any()),
      ).thenAnswer((_) => Future.value());

      final recentEpoch = DateTime.now()
          .subtract(const Duration(days: 2))
          .millisecondsSinceEpoch;

      await service.scheduleInactivityReminder(
        lastAddDateEpoch: recentEpoch,
        thresholdDays: 10,
        title: title,
        buildBody: (_) => 'body',
        channelName: channelName,
        channelDescription: channelDescription,
      );

      verifyNever(
        () => mockPlugin.zonedSchedule(
          id: any(named: 'id'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          scheduledDate: any(named: 'scheduledDate'),
          notificationDetails: any(named: 'notificationDetails'),
          androidScheduleMode: any(named: 'androidScheduleMode'),
          payload: any(named: 'payload'),
        ),
      );
    });

    test('schedules when days since last add exceeds threshold', () async {
      stubNotificationsEnabled();
      when(
        () => mockAndroidPlugin.createNotificationChannel(any()),
      ).thenAnswer((_) => Future.value());
      stubZonedSchedule();

      final oldEpoch = DateTime.now()
          .subtract(const Duration(days: 15))
          .millisecondsSinceEpoch;

      await service.scheduleInactivityReminder(
        lastAddDateEpoch: oldEpoch,
        thresholdDays: 10,
        title: title,
        buildBody: (days) => 'You have not added products in $days days.',
        channelName: channelName,
        channelDescription: channelDescription,
      );

      verify(
        () => mockPlugin.zonedSchedule(
          id: inactivityReminderId,
          title: title,
          body: any(named: 'body'),
          scheduledDate: any(named: 'scheduledDate'),
          notificationDetails: any(named: 'notificationDetails'),
          androidScheduleMode: any(named: 'androidScheduleMode'),
          payload: any(named: 'payload'),
        ),
      ).called(1);
    });

    test('handles exception gracefully', () async {
      stubNotificationsEnabled();
      when(
        () => mockAndroidPlugin.createNotificationChannel(any()),
      ).thenAnswer((_) => Future.value());
      when(
        () => mockPlugin.zonedSchedule(
          id: any(named: 'id'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          scheduledDate: any(named: 'scheduledDate'),
          notificationDetails: any(named: 'notificationDetails'),
          androidScheduleMode: any(named: 'androidScheduleMode'),
          payload: any(named: 'payload'),
        ),
      ).thenThrow(Exception('schedule failed'));

      await expectLater(
        service.scheduleInactivityReminder(
          lastAddDateEpoch: DateTime.now()
              .subtract(const Duration(days: 15))
              .millisecondsSinceEpoch,
          thresholdDays: 10,
          title: title,
          buildBody: (_) => 'body',
          channelName: channelName,
          channelDescription: channelDescription,
        ),
        completes,
      );
    });
  });

  group('cancelInactivityReminder', () {
    test('cancels the fixed inactivity ID', () async {
      when(
        () => mockPlugin.cancel(id: any(named: 'id')),
      ).thenAnswer((_) => Future.value());

      await service.cancelInactivityReminder();

      verify(() => mockPlugin.cancel(id: 999_999_001)).called(1);
    });

    test('handles cancel throwing gracefully', () async {
      when(
        () => mockPlugin.cancel(id: any(named: 'id')),
      ).thenThrow(Exception('cancel failed'));

      await expectLater(service.cancelInactivityReminder(), completes);
    });
  });

  group('cancelReminders', () {
    test('cancels both notification IDs', () async {
      when(
        () => mockPlugin.cancel(id: any(named: 'id')),
      ).thenAnswer((_) => Future.value());

      await service.cancelReminders(42);

      verify(() => mockPlugin.cancel(id: 84)).called(1);
      verify(() => mockPlugin.cancel(id: 85)).called(1);
    });

    test('handles cancel throwing gracefully', () async {
      when(
        () => mockPlugin.cancel(id: any(named: 'id')),
      ).thenThrow(Exception('cancel failed'));

      await expectLater(service.cancelReminders(42), completes);
    });
  });

  group('cancelAllReminders', () {
    test('calls plugin.cancelAll', () async {
      when(() => mockPlugin.cancelAll()).thenAnswer((_) => Future.value());

      await service.cancelAllReminders();

      verify(() => mockPlugin.cancelAll()).called(1);
    });
  });

  group('rescheduleAllItems', () {
    const expiringSoonTitle = 'Expiring soon';
    const expiringTodayTitle = 'Food expiring today';
    String buildExpiringSoonBody(String b) => '$b expires tomorrow';
    String buildExpiringTodayBody(String b) => '$b expires today!';

    test('no-op when notifications disabled', () async {
      when(() => mockPlugin.cancelAll()).thenAnswer((_) => Future.value());

      await service.rescheduleAllItems(
        [],
        expiringSoonTitle: expiringSoonTitle,
        buildExpiringSoonBody: buildExpiringSoonBody,
        expiringTodayTitle: expiringTodayTitle,
        buildExpiringTodayBody: buildExpiringTodayBody,
        notificationsEnabled: false,
      );

      verifyNever(() => mockPlugin.cancelAll());
    });

    test('cancels all before rescheduling', () async {
      when(() => mockPlugin.cancelAll()).thenAnswer((_) => Future.value());
      when(
        mockAndroidPlugin.areNotificationsEnabled,
      ).thenAnswer((_) => Future.value(true));
      when(
        () => mockPlugin.zonedSchedule(
          id: any(named: 'id'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          scheduledDate: any(named: 'scheduledDate'),
          notificationDetails: any(named: 'notificationDetails'),
          androidScheduleMode: any(named: 'androidScheduleMode'),
          payload: any(named: 'payload'),
        ),
      ).thenAnswer((_) => Future.value());

      const item = InventoryItem(
        barcode: '123',
        id: 1,
        expiryDate: '2099-12-31',
      );
      await service.rescheduleAllItems(
        [item],
        expiringSoonTitle: expiringSoonTitle,
        buildExpiringSoonBody: buildExpiringSoonBody,
        expiringTodayTitle: expiringTodayTitle,
        buildExpiringTodayBody: buildExpiringTodayBody,
      );

      verify(() => mockPlugin.cancelAll()).called(1);
    });

    test('prevents concurrent reschedule', () async {
      when(() => mockPlugin.cancelAll()).thenAnswer(
        (_) => Future<void>.delayed(const Duration(milliseconds: 50)),
      );

      final first = service.rescheduleAllItems(
        [],
        expiringSoonTitle: expiringSoonTitle,
        buildExpiringSoonBody: buildExpiringSoonBody,
        expiringTodayTitle: expiringTodayTitle,
        buildExpiringTodayBody: buildExpiringTodayBody,
      );
      final second = service.rescheduleAllItems(
        [],
        expiringSoonTitle: expiringSoonTitle,
        buildExpiringSoonBody: buildExpiringSoonBody,
        expiringTodayTitle: expiringTodayTitle,
        buildExpiringTodayBody: buildExpiringTodayBody,
      );

      await Future.wait([first, second]);

      verify(() => mockPlugin.cancelAll()).called(1);
    });
  });

  group('getLaunchDetails', () {
    test('returns launch details from plugin', () async {
      const details = NotificationAppLaunchDetails(false);
      when(
        () => mockPlugin.getNotificationAppLaunchDetails(),
      ).thenAnswer((_) => Future.value(details));

      final result = await service.getLaunchDetails();
      expect(result, same(details));
    });
  });
}
