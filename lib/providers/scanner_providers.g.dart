// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scanner_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides a [MobileScannerController] for the scanner camera.
///
/// Created lazily and disposed when the provider is no longer watched
/// (auto-dispose). The controller is created with autoStart false so
/// that permission is checked before calling [MobileScannerController.start].

@ProviderFor(mobileScannerController)
final mobileScannerControllerProvider = MobileScannerControllerProvider._();

/// Provides a [MobileScannerController] for the scanner camera.
///
/// Created lazily and disposed when the provider is no longer watched
/// (auto-dispose). The controller is created with autoStart false so
/// that permission is checked before calling [MobileScannerController.start].

final class MobileScannerControllerProvider
    extends
        $FunctionalProvider<
          MobileScannerController,
          MobileScannerController,
          MobileScannerController
        >
    with $Provider<MobileScannerController> {
  /// Provides a [MobileScannerController] for the scanner camera.
  ///
  /// Created lazily and disposed when the provider is no longer watched
  /// (auto-dispose). The controller is created with autoStart false so
  /// that permission is checked before calling [MobileScannerController.start].
  MobileScannerControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mobileScannerControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mobileScannerControllerHash();

  @$internal
  @override
  $ProviderElement<MobileScannerController> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MobileScannerController create(Ref ref) {
    return mobileScannerController(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MobileScannerController value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MobileScannerController>(value),
    );
  }
}

String _$mobileScannerControllerHash() =>
    r'b019d09656f10f09958f869de6316d5135f1f45f';

/// Notifier that manages the scanner camera lifecycle and scan resolution.
///
/// Owns the [MobileScannerController] (created with autoStart false),
/// tracks camera streaming state, handles permission requests, and resolves
/// barcodes/PLU codes via [productRepositoryProvider].

@ProviderFor(ScannerCamera)
final scannerCameraProvider = ScannerCameraProvider._();

/// Notifier that manages the scanner camera lifecycle and scan resolution.
///
/// Owns the [MobileScannerController] (created with autoStart false),
/// tracks camera streaming state, handles permission requests, and resolves
/// barcodes/PLU codes via [productRepositoryProvider].
final class ScannerCameraProvider
    extends $NotifierProvider<ScannerCamera, ScannerCameraState> {
  /// Notifier that manages the scanner camera lifecycle and scan resolution.
  ///
  /// Owns the [MobileScannerController] (created with autoStart false),
  /// tracks camera streaming state, handles permission requests, and resolves
  /// barcodes/PLU codes via [productRepositoryProvider].
  ScannerCameraProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'scannerCameraProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$scannerCameraHash();

  @$internal
  @override
  ScannerCamera create() => ScannerCamera();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ScannerCameraState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ScannerCameraState>(value),
    );
  }
}

String _$scannerCameraHash() => r'9852a2047c0c33696cf1fbe64b653957a5d4f290';

/// Notifier that manages the scanner camera lifecycle and scan resolution.
///
/// Owns the [MobileScannerController] (created with autoStart false),
/// tracks camera streaming state, handles permission requests, and resolves
/// barcodes/PLU codes via [productRepositoryProvider].

abstract class _$ScannerCamera extends $Notifier<ScannerCameraState> {
  ScannerCameraState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ScannerCameraState, ScannerCameraState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ScannerCameraState, ScannerCameraState>,
              ScannerCameraState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
