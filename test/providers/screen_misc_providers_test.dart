import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pantry_app/providers/currency_service_provider.dart';
import 'package:pantry_app/providers/notification_service_provider.dart';
import 'package:pantry_app/services/currency_service.dart';

import '../services/mock_notification_service.dart';

class _MockCurrencyService extends Mock implements CurrencyService {}

void main() {
  test(
    'canScheduleExactNotificationsProvider reads the service once',
    () async {
      final mockNotif = MockNotificationService();
      when(
        mockNotif.canScheduleExactNotifications,
      ).thenAnswer((_) async => true);

      final container = ProviderContainer(
        overrides: [notificationServiceProvider.overrideWithValue(mockNotif)],
      );
      addTearDown(container.dispose);

      final first = await container.read(
        canScheduleExactNotificationsProvider.future,
      );
      final second = await container.read(
        canScheduleExactNotificationsProvider.future,
      );

      expect(first, true);
      expect(second, true);
      verify(mockNotif.canScheduleExactNotifications).called(1);
    },
  );

  test('currencyCacheSizeProvider reads the service size', () async {
    final mockCurrency = _MockCurrencyService();
    when(mockCurrency.cacheSizeBytes).thenAnswer((_) async => 2048);

    final container = ProviderContainer(
      overrides: [currencyServiceProvider.overrideWithValue(mockCurrency)],
    );
    addTearDown(container.dispose);

    final size = await container.read(currencyCacheSizeProvider.future);

    expect(size, 2048);
    verify(mockCurrency.cacheSizeBytes).called(1);
  });
}
