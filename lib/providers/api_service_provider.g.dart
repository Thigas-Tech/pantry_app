// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_service_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the configured [OffAdapter] instance.
///
/// Uses [AppConfig.useOffStaging] to select between OFF production
/// and staging servers. No credentials are needed for read operations;
/// the adapter uses a test user (smoothie-app/strawberrybanana)
/// following the convention established by the official smooth-app.

@ProviderFor(apiService)
final apiServiceProvider = ApiServiceProvider._();

/// Provides the configured [OffAdapter] instance.
///
/// Uses [AppConfig.useOffStaging] to select between OFF production
/// and staging servers. No credentials are needed for read operations;
/// the adapter uses a test user (smoothie-app/strawberrybanana)
/// following the convention established by the official smooth-app.

final class ApiServiceProvider
    extends $FunctionalProvider<OffAdapter, OffAdapter, OffAdapter>
    with $Provider<OffAdapter> {
  /// Provides the configured [OffAdapter] instance.
  ///
  /// Uses [AppConfig.useOffStaging] to select between OFF production
  /// and staging servers. No credentials are needed for read operations;
  /// the adapter uses a test user (smoothie-app/strawberrybanana)
  /// following the convention established by the official smooth-app.
  ApiServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'apiServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$apiServiceHash();

  @$internal
  @override
  $ProviderElement<OffAdapter> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  OffAdapter create(Ref ref) {
    return apiService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(OffAdapter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<OffAdapter>(value),
    );
  }
}

String _$apiServiceHash() => r'412c0e53127dc81a90762bdc0a80ad7e5810b433';
