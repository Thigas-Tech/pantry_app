// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_service_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the [NotificationService] instance.
///
/// The service is created immediately but initialization
/// ([NotificationService.initialize]) must be called separately at app
/// startup (see main.dart) because it requires platform channels.

@ProviderFor(notificationService)
final notificationServiceProvider = NotificationServiceProvider._();

/// Provides the [NotificationService] instance.
///
/// The service is created immediately but initialization
/// ([NotificationService.initialize]) must be called separately at app
/// startup (see main.dart) because it requires platform channels.

final class NotificationServiceProvider
    extends
        $FunctionalProvider<
          NotificationService,
          NotificationService,
          NotificationService
        >
    with $Provider<NotificationService> {
  /// Provides the [NotificationService] instance.
  ///
  /// The service is created immediately but initialization
  /// ([NotificationService.initialize]) must be called separately at app
  /// startup (see main.dart) because it requires platform channels.
  NotificationServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notificationServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notificationServiceHash();

  @$internal
  @override
  $ProviderElement<NotificationService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  NotificationService create(Ref ref) {
    return notificationService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NotificationService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NotificationService>(value),
    );
  }
}

String _$notificationServiceHash() =>
    r'aead8fb05f3d3e0c009fa6d2604d2fd06e032d84';

/// Provides whether the platform allows scheduling exact alarms.
///
/// autoDispose: only needed while the settings screen is visible.

@ProviderFor(canScheduleExactNotifications)
final canScheduleExactNotificationsProvider =
    CanScheduleExactNotificationsProvider._();

/// Provides whether the platform allows scheduling exact alarms.
///
/// autoDispose: only needed while the settings screen is visible.

final class CanScheduleExactNotificationsProvider
    extends $FunctionalProvider<AsyncValue<bool?>, bool?, FutureOr<bool?>>
    with $FutureModifier<bool?>, $FutureProvider<bool?> {
  /// Provides whether the platform allows scheduling exact alarms.
  ///
  /// autoDispose: only needed while the settings screen is visible.
  CanScheduleExactNotificationsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'canScheduleExactNotificationsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$canScheduleExactNotificationsHash();

  @$internal
  @override
  $FutureProviderElement<bool?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool?> create(Ref ref) {
    return canScheduleExactNotifications(ref);
  }
}

String _$canScheduleExactNotificationsHash() =>
    r'31d349b3a35998556f8205d898b5b42058f5fd7f';
