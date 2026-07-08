import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:pantry_app/services/notification_service.dart';
import 'package:pantry_app/utils/logger.dart';

/// Top-level handler for background notification taps.
///
/// Runs in a separate Dart isolate when the user taps a notification action
/// that does NOT show the UI. This function cannot access Riverpod, the
/// database, or navigation — it only logs that the event occurred.
///
/// The main isolate checks [NotificationService.getLaunchDetails] on next
/// foreground to handle the actual deep-link.
///
/// Must be a top-level function with [pragma('vm:entry-point')] so that
/// tree-shaking does not remove it when it is called from native code.
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  logInfo(
    'Background notification tap: id=${response.id}, '
    'actionId=${response.actionId}, payload=${response.payload}',
  );
}
