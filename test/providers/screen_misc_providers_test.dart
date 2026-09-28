import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pantry_app/providers/notification_service_provider.dart';

import '../services/mock_notification_service.dart';

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
}
