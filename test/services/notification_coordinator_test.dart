import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/database/inventory_dao.dart';
import 'package:pantry_app/l10n/app_localizations.dart';
import 'package:pantry_app/models/inventory_item.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/models/recipe_suggestion.dart';
import 'package:pantry_app/providers/settings_provider.dart';
import 'package:pantry_app/services/notification_coordinator.dart';
import 'package:pantry_app/services/recipe_suggestion_service.dart';
import 'package:sqflite/sqflite.dart';

import 'mock_notification_service.dart';

class _MockDatabaseHelper extends Mock implements DatabaseHelper {}

class _MockInventoryDao extends Mock implements InventoryDao {}

class _MockDatabase extends Mock implements Database {}

class _MockRecipeSuggestionService extends Mock
    implements RecipeSuggestionService {}

void main() {
  registerFallbackValue(_MockDatabase());

  late _MockDatabaseHelper db;
  late _MockInventoryDao inventoryDao;
  late _MockDatabase database;
  late MockNotificationService notif;
  late _MockRecipeSuggestionService suggestionService;
  late NotificationCoordinator coordinator;
  late AppLocalizations l10n;

  const expiringItem = InventoryItem(
    id: 1,
    barcode: '123',
    expiryDate: '2026-09-01',
  );
  const noExpiryItem = InventoryItem(
    id: 2,
    barcode: '456',
  );

  setUp(() {
    db = _MockDatabaseHelper();
    inventoryDao = _MockInventoryDao();
    database = _MockDatabase();
    notif = MockNotificationService();
    suggestionService = _MockRecipeSuggestionService();
    when(() => db.inventoryDao).thenReturn(inventoryDao);
    when(() => db.database).thenAnswer((_) async => database);
    when(() => db.getInventories()).thenAnswer(
      (_) async => [
        {'id': 1, 'name': 'Fridge', 'created_at': 0, 'item_count': 0},
      ],
    );
    when(
      () => inventoryDao.list(
        any(),
        inventoryId: any(named: 'inventoryId'),
      ),
    ).thenAnswer((_) async => [expiringItem, noExpiryItem]);
    when(
      () => inventoryDao.listWithProduct(
        any(),
        inventoryId: any(named: 'inventoryId'),
      ),
    ).thenAnswer((_) async => const <Map<String, dynamic>>[]);
    when(
      () => db.getProductsByBarcodes(any()),
    ).thenAnswer((_) async => <Product>[]);
    when(
      () => db.getLastAddDate(),
    ).thenAnswer((_) async => 0);
    when(() => notif.initialized).thenReturn(true);
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
      () => notif.cancelInactivityReminder(),
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
    when(
      () => notif.cancelWeeklyRecipeSuggestion(),
    ).thenAnswer((_) => Future<void>.value());
    when(
      () => notif.scheduleWeeklyRecipeSuggestion(
        title: any(named: 'title'),
        body: any(named: 'body'),
        dayOfWeek: any(named: 'dayOfWeek'),
        hour: any(named: 'hour'),
        minute: any(named: 'minute'),
        channelName: any(named: 'channelName'),
        channelDescription: any(named: 'channelDescription'),
        notificationsEnabled: any(named: 'notificationsEnabled'),
      ),
    ).thenAnswer((_) => Future<void>.value());
    coordinator = NotificationCoordinator(
      notificationService: notif,
      db: db,
      recipeSuggestionService: suggestionService,
    );
    l10n = lookupAppLocalizations(const Locale('en'));
  });

  group('rescheduleExpiryReminders', () {
    test('resolves names only for items that have an expiry date', () async {
      when(
        () => db.getProductsByBarcodes(['123']),
      ).thenAnswer(
        (_) async => [
          const Product(barcode: '123', name: 'Milk'),
          const Product(barcode: '999', name: 'Unknown'),
        ],
      );

      await coordinator.rescheduleExpiryReminders(
        l10n: l10n,
        settings: const Settings(),
      );

      verify(
        () => db.getProductsByBarcodes(['123']),
      ).called(1);
      final captured = verify(
        () => notif.rescheduleAllItems(
          any(),
          expiringSoonTitle: any(named: 'expiringSoonTitle'),
          expiringTodayTitle: any(named: 'expiringTodayTitle'),
          buildExpiringSoonBody: any(named: 'buildExpiringSoonBody'),
          buildExpiringTodayBody: any(named: 'buildExpiringTodayBody'),
          barcodeToName: captureAny(named: 'barcodeToName'),
          notificationsEnabled: any(named: 'notificationsEnabled'),
        ),
      ).captured;
      expect(captured.single, {'123': 'Milk'});
    });

    test('skips when the notification service is not initialized', () async {
      when(() => notif.initialized).thenReturn(false);

      await coordinator.rescheduleExpiryReminders(
        l10n: l10n,
        settings: const Settings(),
      );

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

    test('skips when notifications are disabled in settings', () async {
      await coordinator.rescheduleExpiryReminders(
        l10n: l10n,
        settings: const Settings(notificationsEnabled: false),
      );

      verifyNever(() => db.getProductsByBarcodes(any()));
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

    test('still reschedules when nothing is expiring', () async {
      when(
        () => inventoryDao.list(
          any(),
          inventoryId: any(named: 'inventoryId'),
        ),
      ).thenAnswer((_) async => [noExpiryItem]);

      await coordinator.rescheduleExpiryReminders(
        l10n: l10n,
        settings: const Settings(),
      );

      verifyNever(() => db.getProductsByBarcodes(any()));
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
  });

  group('rescheduleInactivityReminder', () {
    test('cancels then schedules the reminder', () async {
      await coordinator.rescheduleInactivityReminder(
        l10n: l10n,
        settings: const Settings(),
      );

      verify(() => notif.cancelInactivityReminder()).called(1);
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
    });

    test('skips when the inactivity reminder is disabled', () async {
      await coordinator.rescheduleInactivityReminder(
        l10n: l10n,
        settings: const Settings(inactivityReminderEnabled: false),
      );

      verifyNever(() => notif.cancelInactivityReminder());
      verifyNever(
        () => notif.scheduleInactivityReminder(
          lastAddDateEpoch: any(named: 'lastAddDateEpoch'),
          thresholdDays: any(named: 'thresholdDays'),
          title: any(named: 'title'),
          buildBody: any(named: 'buildBody'),
          channelName: any(named: 'channelName'),
          channelDescription: any(named: 'channelDescription'),
          notificationsEnabled: any(named: 'notificationsEnabled'),
        ),
      );
    });
  });

  group('rescheduleAll', () {
    test('runs both expiry and inactivity reminders', () async {
      await coordinator.rescheduleAll(
        l10n: l10n,
        settings: const Settings(),
      );

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
      verify(() => notif.cancelInactivityReminder()).called(1);
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
    });
  });

  group('rescheduleWeeklyRecipeSuggestion', () {
    const recipeSuggestion = RecipeSuggestion(name: 'Curry', idMeal: '42');

    Settings enabledSettings() => const Settings(
      weeklyRecipeSuggestionEnabled: true,
      weeklyRecipeSuggestionDay: 1,
      weeklyRecipeSuggestionHour: 9,
      weeklyRecipeSuggestionMinute: 30,
    );

    test('cancels then schedules when enabled and ingredients exist', () async {
      when(
        () => inventoryDao.listWithProduct(
          any(),
          inventoryId: any(named: 'inventoryId'),
        ),
      ).thenAnswer(
        (_) async => [
          {'product_name': 'Chicken', 'expiry_date': '2026-09-01'},
          {'product_name': 'Rice', 'expiry_date': null},
        ],
      );
      when(
        () => suggestionService.pickSuggestion(any()),
      ).thenAnswer((_) async => recipeSuggestion);

      await coordinator.rescheduleWeeklyRecipeSuggestion(
        l10n: l10n,
        settings: enabledSettings(),
      );

      verify(() => notif.cancelWeeklyRecipeSuggestion()).called(1);
      verify(
        () => notif.scheduleWeeklyRecipeSuggestion(
          title: any(named: 'title'),
          body: any(named: 'body'),
          dayOfWeek: 1,
          hour: 9,
          minute: 30,
          channelName: any(named: 'channelName'),
          channelDescription: any(named: 'channelDescription'),
          notificationsEnabled: any(named: 'notificationsEnabled'),
        ),
      ).called(1);
      verify(
        () => suggestionService.pickSuggestion(['Chicken', 'Rice']),
      ).called(1);
    });

    test('prefers expiring ingredients first', () async {
      when(
        () => inventoryDao.listWithProduct(
          any(),
          inventoryId: any(named: 'inventoryId'),
        ),
      ).thenAnswer(
        (_) async => [
          {'product_name': 'Rice', 'expiry_date': null},
          {'product_name': 'Chicken', 'expiry_date': '2026-09-01'},
        ],
      );
      when(
        () => suggestionService.pickSuggestion(any()),
      ).thenAnswer((_) async => recipeSuggestion);

      await coordinator.rescheduleWeeklyRecipeSuggestion(
        l10n: l10n,
        settings: enabledSettings(),
      );

      verify(
        () => suggestionService.pickSuggestion(['Chicken', 'Rice']),
      ).called(1);
    });

    test('skips when the weekly suggestion is disabled', () async {
      await coordinator.rescheduleWeeklyRecipeSuggestion(
        l10n: l10n,
        settings: const Settings(),
      );

      verifyNever(() => notif.cancelWeeklyRecipeSuggestion());
      verifyNever(
        () => notif.scheduleWeeklyRecipeSuggestion(
          title: any(named: 'title'),
          body: any(named: 'body'),
          dayOfWeek: any(named: 'dayOfWeek'),
          hour: any(named: 'hour'),
          minute: any(named: 'minute'),
          channelName: any(named: 'channelName'),
          channelDescription: any(named: 'channelDescription'),
          notificationsEnabled: any(named: 'notificationsEnabled'),
        ),
      );
    });

    test('skips when notifications are disabled', () async {
      await coordinator.rescheduleWeeklyRecipeSuggestion(
        l10n: l10n,
        settings: const Settings(
          weeklyRecipeSuggestionEnabled: true,
          notificationsEnabled: false,
        ),
      );

      verifyNever(() => notif.cancelWeeklyRecipeSuggestion());
      verifyNever(
        () => notif.scheduleWeeklyRecipeSuggestion(
          title: any(named: 'title'),
          body: any(named: 'body'),
          dayOfWeek: any(named: 'dayOfWeek'),
          hour: any(named: 'hour'),
          minute: any(named: 'minute'),
          channelName: any(named: 'channelName'),
          channelDescription: any(named: 'channelDescription'),
          notificationsEnabled: any(named: 'notificationsEnabled'),
        ),
      );
    });

    test('skips when the inventory has no product names', () async {
      when(
        () => inventoryDao.listWithProduct(
          any(),
          inventoryId: any(named: 'inventoryId'),
        ),
      ).thenAnswer(
        (_) async => [
          {'product_name': 'Unknown', 'expiry_date': null},
          {'product_name': '', 'expiry_date': null},
        ],
      );

      await coordinator.rescheduleWeeklyRecipeSuggestion(
        l10n: l10n,
        settings: enabledSettings(),
      );

      verifyNever(
        () => suggestionService.pickSuggestion(any()),
      );
      verifyNever(
        () => notif.scheduleWeeklyRecipeSuggestion(
          title: any(named: 'title'),
          body: any(named: 'body'),
          dayOfWeek: any(named: 'dayOfWeek'),
          hour: any(named: 'hour'),
          minute: any(named: 'minute'),
          channelName: any(named: 'channelName'),
          channelDescription: any(named: 'channelDescription'),
          notificationsEnabled: any(named: 'notificationsEnabled'),
        ),
      );
    });

    test('cancels without scheduling when no suggestion is returned', () async {
      when(
        () => inventoryDao.listWithProduct(
          any(),
          inventoryId: any(named: 'inventoryId'),
        ),
      ).thenAnswer(
        (_) async => [
          {'product_name': 'Chicken', 'expiry_date': '2026-09-01'},
        ],
      );
      when(
        () => suggestionService.pickSuggestion(any()),
      ).thenAnswer((_) async => null);

      await coordinator.rescheduleWeeklyRecipeSuggestion(
        l10n: l10n,
        settings: enabledSettings(),
      );

      verify(() => notif.cancelWeeklyRecipeSuggestion()).called(1);
      verifyNever(
        () => notif.scheduleWeeklyRecipeSuggestion(
          title: any(named: 'title'),
          body: any(named: 'body'),
          dayOfWeek: any(named: 'dayOfWeek'),
          hour: any(named: 'hour'),
          minute: any(named: 'minute'),
          channelName: any(named: 'channelName'),
          channelDescription: any(named: 'channelDescription'),
          notificationsEnabled: any(named: 'notificationsEnabled'),
        ),
      );
    });

    test('skips when the notification service is not initialized', () async {
      when(() => notif.initialized).thenReturn(false);

      await coordinator.rescheduleWeeklyRecipeSuggestion(
        l10n: l10n,
        settings: enabledSettings(),
      );

      verifyNever(() => notif.cancelWeeklyRecipeSuggestion());
      verifyNever(() => suggestionService.pickSuggestion(any()));
    });
  });
}
