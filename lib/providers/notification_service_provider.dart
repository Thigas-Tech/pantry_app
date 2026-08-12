import 'package:pantry_app/services/notification_service.dart';
import 'package:pantry_app/services/notification_service_interface.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'notification_service_provider.g.dart';

/// Provides the [NotificationService] instance.
///
/// The service is created immediately but initialization
/// ([NotificationService.initialize]) must be called separately at app
/// startup (see main.dart) because it requires platform channels.
@Riverpod(keepAlive: true)
NotificationService notificationService(Ref ref) {
  return FlutterNotificationService();
}
