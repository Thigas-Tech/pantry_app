import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/services/notification_service.dart';
import 'package:pantry_app/services/notification_service_interface.dart';

/// Provides the [NotificationService] instance.
///
/// The service is created immediately but initialization
/// ([NotificationService.initialize]) must be called separately at app
/// startup (see main.dart) because it requires platform channels.
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return FlutterNotificationService();
});
