// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'connectivity_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides a reactive stream of internet connectivity status.
///
/// Uses [InternetConnectionChecker.instance] to monitor whether the
/// device has internet access. Emits true when connected, false
/// when offline.
///
/// Unlike the default [StreamProvider] which starts as [AsyncLoading],
/// this implementation yields the initial connectivity state as the
/// first event so that downstream code never sees a null/loading state.
/// A 3-second timeout prevents slow DNS lookups from blocking the
/// initial emission.
///
/// Offline transitions are debounced for 3 seconds to suppress transient
/// network blips (DNS hiccups, mobile network handovers, slow server
/// responses).

@ProviderFor(connectivity)
final connectivityProvider = ConnectivityProvider._();

/// Provides a reactive stream of internet connectivity status.
///
/// Uses [InternetConnectionChecker.instance] to monitor whether the
/// device has internet access. Emits true when connected, false
/// when offline.
///
/// Unlike the default [StreamProvider] which starts as [AsyncLoading],
/// this implementation yields the initial connectivity state as the
/// first event so that downstream code never sees a null/loading state.
/// A 3-second timeout prevents slow DNS lookups from blocking the
/// initial emission.
///
/// Offline transitions are debounced for 3 seconds to suppress transient
/// network blips (DNS hiccups, mobile network handovers, slow server
/// responses).

final class ConnectivityProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, Stream<bool>>
    with $FutureModifier<bool>, $StreamProvider<bool> {
  /// Provides a reactive stream of internet connectivity status.
  ///
  /// Uses [InternetConnectionChecker.instance] to monitor whether the
  /// device has internet access. Emits true when connected, false
  /// when offline.
  ///
  /// Unlike the default [StreamProvider] which starts as [AsyncLoading],
  /// this implementation yields the initial connectivity state as the
  /// first event so that downstream code never sees a null/loading state.
  /// A 3-second timeout prevents slow DNS lookups from blocking the
  /// initial emission.
  ///
  /// Offline transitions are debounced for 3 seconds to suppress transient
  /// network blips (DNS hiccups, mobile network handovers, slow server
  /// responses).
  ConnectivityProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'connectivityProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$connectivityHash();

  @$internal
  @override
  $StreamProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<bool> create(Ref ref) {
    return connectivity(ref);
  }
}

String _$connectivityHash() => r'e9c0b486920b998ea8a07100d732be45303924f4';

/// Provides a one-shot connectivity check.
///
/// Unlike [connectivityProvider] (a stream), this resolves once and
/// is ideal for cache-flush flows and other places where you need a
/// simple true/false answer at a single point in time.

@ProviderFor(hasConnection)
final hasConnectionProvider = HasConnectionProvider._();

/// Provides a one-shot connectivity check.
///
/// Unlike [connectivityProvider] (a stream), this resolves once and
/// is ideal for cache-flush flows and other places where you need a
/// simple true/false answer at a single point in time.

final class HasConnectionProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  /// Provides a one-shot connectivity check.
  ///
  /// Unlike [connectivityProvider] (a stream), this resolves once and
  /// is ideal for cache-flush flows and other places where you need a
  /// simple true/false answer at a single point in time.
  HasConnectionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'hasConnectionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$hasConnectionHash();

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    return hasConnection(ref);
  }
}

String _$hasConnectionHash() => r'3582db61b19b716462c196c704a591c1fc8e1134';
