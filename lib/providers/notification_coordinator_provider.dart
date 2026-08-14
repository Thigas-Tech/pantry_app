import 'package:pantry_app/providers/database_provider.dart';
import 'package:pantry_app/providers/notification_service_provider.dart';
import 'package:pantry_app/providers/recipe_suggestion_provider.dart';
import 'package:pantry_app/services/notification_coordinator.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'notification_coordinator_provider.g.dart';

/// Provides the shared [NotificationCoordinator] instance.
///
/// keepAlive because notification scheduling is needed by startup tasks
/// (via the app container), the settings toggle, and the product detail
/// screen for the whole session.
@Riverpod(keepAlive: true)
NotificationCoordinator notificationCoordinator(Ref ref) {
  return NotificationCoordinator(
    notificationService: ref.read(notificationServiceProvider),
    db: ref.read(databaseProvider),
    recipeSuggestionService: ref.read(recipeSuggestionServiceProvider),
  );
}
