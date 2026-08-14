// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_coordinator_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the shared [NotificationCoordinator] instance.
///
/// keepAlive because notification scheduling is needed by startup tasks
/// (via the app container), the settings toggle, and the product detail
/// screen for the whole session.

@ProviderFor(notificationCoordinator)
final notificationCoordinatorProvider = NotificationCoordinatorProvider._();

/// Provides the shared [NotificationCoordinator] instance.
///
/// keepAlive because notification scheduling is needed by startup tasks
/// (via the app container), the settings toggle, and the product detail
/// screen for the whole session.

final class NotificationCoordinatorProvider
    extends
        $FunctionalProvider<
          NotificationCoordinator,
          NotificationCoordinator,
          NotificationCoordinator
        >
    with $Provider<NotificationCoordinator> {
  /// Provides the shared [NotificationCoordinator] instance.
  ///
  /// keepAlive because notification scheduling is needed by startup tasks
  /// (via the app container), the settings toggle, and the product detail
  /// screen for the whole session.
  NotificationCoordinatorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notificationCoordinatorProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notificationCoordinatorHash();

  @$internal
  @override
  $ProviderElement<NotificationCoordinator> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  NotificationCoordinator create(Ref ref) {
    return notificationCoordinator(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NotificationCoordinator value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NotificationCoordinator>(value),
    );
  }
}

String _$notificationCoordinatorHash() =>
    r'6a929546d3e9e50ab33efdb52e2f70e3f203b99b';
