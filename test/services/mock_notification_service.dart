import 'package:mocktail/mocktail.dart';
import 'package:pantry_app/services/notification_service_interface.dart';

/// A mock [NotificationService] for use in tests.
///
/// All methods return null/false by default. Stub the ones you need:
/// ```dart
/// when(() => mock.requestPermission()).thenAnswer((_) => Future.value(true));
/// ```
class MockNotificationService extends Mock implements NotificationService {}
