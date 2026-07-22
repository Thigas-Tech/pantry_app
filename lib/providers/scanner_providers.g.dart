// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scanner_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Notifier that manages the scanner camera lifecycle and scan resolution.
///
/// Owns the [MobileScannerController] (created with `autoStart` `false`),
/// tracks camera streaming state, handles permission requests, and resolves
/// barcodes/PLU codes via [productRepositoryProvider].

@ProviderFor(ScannerCamera)
final scannerCameraProvider = ScannerCameraProvider._();

/// Notifier that manages the scanner camera lifecycle and scan resolution.
///
/// Owns the [MobileScannerController] (created with `autoStart` `false`),
/// tracks camera streaming state, handles permission requests, and resolves
/// barcodes/PLU codes via [productRepositoryProvider].
final class ScannerCameraProvider
    extends $NotifierProvider<ScannerCamera, ScannerCameraState> {
  /// Notifier that manages the scanner camera lifecycle and scan resolution.
  ///
  /// Owns the [MobileScannerController] (created with `autoStart` `false`),
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

String _$scannerCameraHash() => r'761e3885760a67ba5393b7c50836c52630e48a11';

/// Notifier that manages the scanner camera lifecycle and scan resolution.
///
/// Owns the [MobileScannerController] (created with `autoStart` `false`),
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
