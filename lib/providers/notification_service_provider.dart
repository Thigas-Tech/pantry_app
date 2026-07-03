import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/services/notification_service.dart';

/// Provides the [NotificationService] instance.
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});
