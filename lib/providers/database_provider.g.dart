// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the singleton [DatabaseHelper] instance to the widget tree.
///
/// Because [DatabaseHelper] is already a singleton (factory constructor),
/// this provider simply returns that same instance. It is registered as a
/// plain [Provider] (not a FutureProvider) because the database is lazily
/// initialised on first access and does not require asynchronous setup
/// before the UI can render.
///
/// ## Usage
///
/// - ref.watch(databaseProvider) in widgets that need access to the
///   database (usually via repository providers).
/// - ref.read(databaseProvider) in async callbacks.

@ProviderFor(database)
final databaseProvider = DatabaseProvider._();

/// Provides the singleton [DatabaseHelper] instance to the widget tree.
///
/// Because [DatabaseHelper] is already a singleton (factory constructor),
/// this provider simply returns that same instance. It is registered as a
/// plain [Provider] (not a FutureProvider) because the database is lazily
/// initialised on first access and does not require asynchronous setup
/// before the UI can render.
///
/// ## Usage
///
/// - ref.watch(databaseProvider) in widgets that need access to the
///   database (usually via repository providers).
/// - ref.read(databaseProvider) in async callbacks.

final class DatabaseProvider
    extends $FunctionalProvider<DatabaseHelper, DatabaseHelper, DatabaseHelper>
    with $Provider<DatabaseHelper> {
  /// Provides the singleton [DatabaseHelper] instance to the widget tree.
  ///
  /// Because [DatabaseHelper] is already a singleton (factory constructor),
  /// this provider simply returns that same instance. It is registered as a
  /// plain [Provider] (not a FutureProvider) because the database is lazily
  /// initialised on first access and does not require asynchronous setup
  /// before the UI can render.
  ///
  /// ## Usage
  ///
  /// - ref.watch(databaseProvider) in widgets that need access to the
  ///   database (usually via repository providers).
  /// - ref.read(databaseProvider) in async callbacks.
  DatabaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'databaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$databaseHash();

  @$internal
  @override
  $ProviderElement<DatabaseHelper> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DatabaseHelper create(Ref ref) {
    return database(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DatabaseHelper value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DatabaseHelper>(value),
    );
  }
}

String _$databaseHash() => r'8eb18c5b38e91eeca2474154280b61cbbbff45a6';

/// Lists all saved stores alphabetically for autocomplete suggestions.

@ProviderFor(stores)
final storesProvider = StoresProvider._();

/// Lists all saved stores alphabetically for autocomplete suggestions.

final class StoresProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Store>>,
          List<Store>,
          FutureOr<List<Store>>
        >
    with $FutureModifier<List<Store>>, $FutureProvider<List<Store>> {
  /// Lists all saved stores alphabetically for autocomplete suggestions.
  StoresProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'storesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$storesHash();

  @$internal
  @override
  $FutureProviderElement<List<Store>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Store>> create(Ref ref) {
    return stores(ref);
  }
}

String _$storesHash() => r'c73611bb5b5ce7ae725687731e59aa160da7a1f8';
