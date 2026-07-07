/// @file Notification background handler unit test.
///
/// Tests the top-level [notificationTapBackground] function which
/// runs in a separate isolate.  Verifies the function does not throw
/// with valid and edge-case [NotificationResponse] arguments.
library;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/services/notification_background_handler.dart';

void main() {
  group('notificationTapBackground', () {
    /// Verifies the handler does not throw with a typical response payload.
    test('does not throw with valid response', () {
      const response = NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotification,
        payload: 'barcode:123',
      );
      notificationTapBackground(response);
    });

    /// Verifies the handler does not throw when payload is null.
    test('does not throw with null payload', () {
      const response = NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotification,
      );
      notificationTapBackground(response);
    });

    /// Verifies the handler does not throw with empty payload string.
    test('does not throw with empty payload', () {
      const response = NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotification,
        payload: '',
      );
      notificationTapBackground(response);
    });
  });
}
