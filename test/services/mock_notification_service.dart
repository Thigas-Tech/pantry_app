import 'package:mocktail/mocktail.dart';
import 'package:pantry_app/services/notification_service_interface.dart';

/// A mock [NotificationService] for use in tests.
///
/// All methods return null/false by default. Stub the ones you need:
/// ```dart
/// when(() => mock.requestPermission()).thenAnswer((_) => Future.value(true));
/// ```
class MockNotificationService extends Mock implements NotificationService {
  /// Creates a [MockNotificationService] reported as initialized.
  ///
  /// Services that consume this mock (such as the notification coordinator)
  /// gate on [initialized]; defaulting to true keeps tests focused on the
  /// behavior they exercise. Override with a new stub when a test needs the
  /// not-initialized path.
  MockNotificationService() {
    when(() => initialized).thenReturn(true);
  }
}
