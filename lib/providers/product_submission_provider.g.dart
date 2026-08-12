// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_submission_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Exposes observable, durable progress for an Open Food Facts submission.
///
/// The notifier owns the submission lifecycle: submit starts a background
/// submission, state holds the latest progress snapshot (null when idle),
/// and isSubmitting reports whether a submission is running. Because
/// [productSubmissionProvider] is a plain keep-alive notifier provider (not
/// autoDispose), progress outlives the screen that started the submission,
/// so a user can navigate away while uploads continue.

@ProviderFor(ProductSubmissionNotifier)
final productSubmissionProvider = ProductSubmissionNotifierProvider._();

/// Exposes observable, durable progress for an Open Food Facts submission.
///
/// The notifier owns the submission lifecycle: submit starts a background
/// submission, state holds the latest progress snapshot (null when idle),
/// and isSubmitting reports whether a submission is running. Because
/// [productSubmissionProvider] is a plain keep-alive notifier provider (not
/// autoDispose), progress outlives the screen that started the submission,
/// so a user can navigate away while uploads continue.
final class ProductSubmissionNotifierProvider
    extends $NotifierProvider<ProductSubmissionNotifier, SubmissionProgress?> {
  /// Exposes observable, durable progress for an Open Food Facts submission.
  ///
  /// The notifier owns the submission lifecycle: submit starts a background
  /// submission, state holds the latest progress snapshot (null when idle),
  /// and isSubmitting reports whether a submission is running. Because
  /// [productSubmissionProvider] is a plain keep-alive notifier provider (not
  /// autoDispose), progress outlives the screen that started the submission,
  /// so a user can navigate away while uploads continue.
  ProductSubmissionNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'productSubmissionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$productSubmissionNotifierHash();

  @$internal
  @override
  ProductSubmissionNotifier create() => ProductSubmissionNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SubmissionProgress? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SubmissionProgress?>(value),
    );
  }
}

String _$productSubmissionNotifierHash() =>
    r'cf57d5cd1d6c11d9de9c3535647f410108e5b121';

/// Exposes observable, durable progress for an Open Food Facts submission.
///
/// The notifier owns the submission lifecycle: submit starts a background
/// submission, state holds the latest progress snapshot (null when idle),
/// and isSubmitting reports whether a submission is running. Because
/// [productSubmissionProvider] is a plain keep-alive notifier provider (not
/// autoDispose), progress outlives the screen that started the submission,
/// so a user can navigate away while uploads continue.

abstract class _$ProductSubmissionNotifier
    extends $Notifier<SubmissionProgress?> {
  SubmissionProgress? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<SubmissionProgress?, SubmissionProgress?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SubmissionProgress?, SubmissionProgress?>,
              SubmissionProgress?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Provider for [ProductSubmissionService].

@ProviderFor(productSubmissionService)
final productSubmissionServiceProvider = ProductSubmissionServiceProvider._();

/// Provider for [ProductSubmissionService].

final class ProductSubmissionServiceProvider
    extends
        $FunctionalProvider<
          ProductSubmissionService,
          ProductSubmissionService,
          ProductSubmissionService
        >
    with $Provider<ProductSubmissionService> {
  /// Provider for [ProductSubmissionService].
  ProductSubmissionServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'productSubmissionServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$productSubmissionServiceHash();

  @$internal
  @override
  $ProviderElement<ProductSubmissionService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ProductSubmissionService create(Ref ref) {
    return productSubmissionService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProductSubmissionService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProductSubmissionService>(value),
    );
  }
}

String _$productSubmissionServiceHash() =>
    r'2dacf4a457db593b0e9282f234b4f0332bab557a';
