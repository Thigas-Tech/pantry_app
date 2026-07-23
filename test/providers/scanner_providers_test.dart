import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/providers/api_service_provider.dart';
import 'package:pantry_app/providers/product_repository_provider.dart';
import 'package:pantry_app/providers/scanner_providers.dart';
import 'package:pantry_app/services/exceptions.dart';
import 'package:pantry_app/services/off_adapter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/pump_app.dart';

/// Fake [ScannerCamera] that skips platform controller creation.
class FakeScannerCamera extends ScannerCamera {
  @override
  ScannerCameraState build() => const ScannerCameraState();

  @override
  Future<void> requestPermission() async {
    state = state.copyWith(clearError: true);
  }

  @override
  Future<void> retryScanner() async {
    state = state.copyWith(
      isStreaming: false,
      scannerKey: state.scannerKey + 1,
      clearError: true,
    );
  }

  @override
  Future<void> stopCamera() async {
    state = state.copyWith(isStreaming: false);
  }
}

class MockOffAdapter extends Mock implements OffAdapter {}

void main() {
  group('ScannerCameraState', () {
    test('initial state has overlay hidden', () {
      const state = ScannerCameraState();
      expect(state.isStreaming, false);
      expect(state.cameraError, isNull);
      expect(state.showOverlay, false);
      expect(state.scannerKey, 0);
      expect(state.torchState, TorchState.unavailable);
    });

    test('showOverlay true when streaming without error', () {
      const state = ScannerCameraState(isStreaming: true);
      expect(state.showOverlay, true);
    });

    test('showOverlay false with error even when streaming', () {
      const state = ScannerCameraState(
        isStreaming: true,
        cameraError: MobileScannerException(
          errorCode: MobileScannerErrorCode.genericError,
        ),
      );
      expect(state.showOverlay, false);
    });

    test('copyWith preserves unset fields', () {
      const original = ScannerCameraState(isStreaming: true, scannerKey: 3);
      final copy = original.copyWith(isStreaming: false);
      expect(copy.isStreaming, false);
      expect(copy.scannerKey, 3);
      expect(copy.cameraError, isNull);
    });

    test('copyWith clearError removes error', () {
      const error = MobileScannerException(
        errorCode: MobileScannerErrorCode.genericError,
      );
      const state = ScannerCameraState(cameraError: error);
      final cleared = state.copyWith(clearError: true);
      expect(cleared.cameraError, isNull);
    });
  });

  group('ScanResolution', () {
    test('ScanResolving is a ScanResolution', () {
      expect(const ScanResolving(), isA<ScanResolution>());
    });

    test('ScanResolved holds a Product', () {
      const product = Product(barcode: '123', name: 'Test');
      const resolved = ScanResolved(product);
      expect(resolved, isA<ScanResolution>());
      expect(resolved.product.barcode, '123');
    });

    test('ScanFailed holds a message', () {
      const failed = ScanFailed('error');
      expect(failed, isA<ScanResolution>());
      expect(failed.message, 'error');
    });
  });

  group('ScannerCameraProvider', () {
    late ProviderContainer container;
    late MockProductRepository mockRepo;
    late MockOffAdapter mockOff;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      mockRepo = createMockProductRepository();
      mockOff = MockOffAdapter();
      container = ProviderContainer(
        overrides: [
          productRepositoryProvider.overrideWithValue(mockRepo),
          apiServiceProvider.overrideWithValue(mockOff),
          scannerCameraProvider.overrideWith(FakeScannerCamera.new),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state is not streaming', () {
      final state = container.read(scannerCameraProvider);
      expect(state.isStreaming, false);
      expect(state.cameraError, isNull);
      expect(state.showOverlay, false);
    });

    test('permission grant clears camera error', () async {
      final notifier =
          container.read(scannerCameraProvider.notifier) as FakeScannerCamera;
      await notifier.requestPermission();
      expect(container.read(scannerCameraProvider).cameraError, isNull);
    });

    test('resolveBarcode succeeds and sets ScanResolved', () async {
      const barcode = '5012345678900';
      const product = Product(barcode: barcode, name: 'Test Product');
      when(
        () => mockRepo.getProduct(barcode),
      ).thenAnswer((_) async => product);

      final notifier = container.read(scannerCameraProvider.notifier);
      await notifier.resolveBarcode(barcode);

      final state = container.read(scannerCameraProvider);
      expect(state.scanResolution, isA<ScanResolved>());
      final resolved = state.scanResolution! as ScanResolved;
      expect(resolved.product.barcode, barcode);
    });

    test('resolveBarcode handles ProductNotFoundException', () async {
      const barcode = '9999999999999';
      when(
        () => mockRepo.getProduct(barcode),
      ).thenThrow(ProductNotFoundException(barcode));

      final notifier = container.read(scannerCameraProvider.notifier);
      await notifier.resolveBarcode(barcode);

      final state = container.read(scannerCameraProvider);
      expect(state.scanResolution, isA<ScanFailed>());
      final failed = state.scanResolution! as ScanFailed;
      expect(failed.message, 'PRODUCT_NOT_FOUND');
    });

    test('resolveBarcode handles generic exceptions', () async {
      const barcode = '1234567890123';
      when(
        () => mockRepo.getProduct(barcode),
      ).thenThrow(Exception('Network error'));

      final notifier = container.read(scannerCameraProvider.notifier);
      await notifier.resolveBarcode(barcode);

      final state = container.read(scannerCameraProvider);
      expect(state.scanResolution, isA<ScanFailed>());
      final failed = state.scanResolution! as ScanFailed;
      expect(failed.message, contains('Network error'));
    });

    test('resolveBarcode ignores duplicate calls while resolving', () async {
      const barcode = '5012345678900';
      when(
        () => mockRepo.getProduct(barcode),
      ).thenAnswer((_) async => const Product(barcode: barcode, name: 'Test'));

      final notifier = container.read(scannerCameraProvider.notifier);
      // First call puts state in ScanResolving; second should be ignored.
      final first = notifier.resolveBarcode(barcode);
      await notifier.resolveBarcode(barcode);
      await first;

      final state = container.read(scannerCameraProvider);
      expect(state.scanResolution, isA<ScanResolved>());
    });

    test('resolveBarcode ignored when ScanResolved is already set', () async {
      const barcode = '5012345678900';
      const product = Product(barcode: barcode, name: 'Test');
      when(
        () => mockRepo.getProduct(barcode),
      ).thenAnswer((_) async => product);

      final notifier = container.read(scannerCameraProvider.notifier);
      await notifier.resolveBarcode(barcode);
      expect(
        container.read(scannerCameraProvider).scanResolution,
        isA<ScanResolved>(),
      );

      // Second resolve must be a no-op when ScanResolved is active.
      await notifier.resolveBarcode('9999999999999');
      final state = container.read(scannerCameraProvider);
      expect(state.scanResolution, isA<ScanResolved>());
      final resolved = state.scanResolution! as ScanResolved;
      // Verify the product is still from the first call, not overwritten.
      expect(resolved.product.barcode, barcode);
    });

    test(
      'resolveBarcode timeout sets ScanFailed with TIMEOUT message',
      () async {
        const barcode = '5012345678900';
        final completer = Completer<Product>();
        when(() => mockRepo.getProduct(barcode)).thenAnswer(
          (_) => completer.future,
        );

        // Keep provider alive during the async gap.
        final sub = container.listen<ScannerCameraState>(
          scannerCameraProvider,
          (_, __) {},
        );
        addTearDown(sub.close);
        final notifier = container.read(scannerCameraProvider.notifier);
        await notifier.resolveBarcode(
          barcode,
          timeout: const Duration(milliseconds: 100),
        );

        final state = container.read(scannerCameraProvider);
        expect(state.scanResolution, isA<ScanFailed>());
        expect(
          (state.scanResolution! as ScanFailed).message,
          'TIMEOUT',
        );
      },
    );

    test('after timeout, clearResolution unblocks scanner', () async {
      const barcode = '5012345678900';
      final completer = Completer<Product>();
      when(() => mockRepo.getProduct(barcode)).thenAnswer(
        (_) => completer.future,
      );

      final sub = container.listen<ScannerCameraState>(
        scannerCameraProvider,
        (_, __) {},
      );
      addTearDown(sub.close);
      final notifier = container.read(scannerCameraProvider.notifier);
      await notifier.resolveBarcode(
        barcode,
        timeout: const Duration(milliseconds: 100),
      );
      notifier.clearResolution();

      expect(container.read(scannerCameraProvider).scanResolution, isNull);
    });

    test('resolvePlu succeeds and sets ScanResolved', () async {
      const pluCode = '4011';
      const produceName = 'Banana';
      when(
        () => mockOff.searchProducts(
          produceName,
          languageCode: any(named: 'languageCode'),
        ),
      ).thenAnswer(
        (_) async => [const Product(barcode: '000', name: 'Banana')],
      );

      final notifier = container.read(scannerCameraProvider.notifier);
      await notifier.resolvePlu(
        pluCode: pluCode,
        produceName: produceName,
        languageCode: 'en',
      );

      final state = container.read(scannerCameraProvider);
      expect(state.scanResolution, isA<ScanResolved>());
      final resolved = state.scanResolution! as ScanResolved;
      expect(resolved.product.pluCode, pluCode);
    });

    test('resolvePlu timeout sets ScanFailed with TIMEOUT', () async {
      const pluCode = '4011';
      const produceName = 'Banana';
      final completer = Completer<List<Product>>();
      when(
        () => mockOff.searchProducts(
          produceName,
          languageCode: any(named: 'languageCode'),
        ),
      ).thenAnswer((_) => completer.future);

      final sub = container.listen<ScannerCameraState>(
        scannerCameraProvider,
        (_, __) {},
      );
      addTearDown(sub.close);
      final notifier = container.read(scannerCameraProvider.notifier);
      await notifier.resolvePlu(
        pluCode: pluCode,
        produceName: produceName,
        languageCode: 'en',
        timeout: const Duration(milliseconds: 100),
      );

      final state = container.read(scannerCameraProvider);
      expect(state.scanResolution, isA<ScanFailed>());
      expect(
        (state.scanResolution! as ScanFailed).message,
        'TIMEOUT',
      );
    });

    test('clearResolution resets scan resolution', () async {
      const barcode = '5012345678900';
      const product = Product(barcode: barcode, name: 'Test');
      when(
        () => mockRepo.getProduct(barcode),
      ).thenAnswer((_) async => product);

      final notifier = container.read(scannerCameraProvider.notifier);
      await notifier.resolveBarcode(barcode);
      expect(
        container.read(scannerCameraProvider).scanResolution,
        isA<ScanResolved>(),
      );

      notifier.clearResolution();
      expect(
        container.read(scannerCameraProvider).scanResolution,
        isNull,
      );
    });

    test('retryScanner increments scannerKey', () async {
      final notifier = container.read(scannerCameraProvider.notifier);
      final initialKey = container.read(scannerCameraProvider).scannerKey;
      await notifier.retryScanner();
      expect(
        container.read(scannerCameraProvider).scannerKey,
        greaterThan(initialKey),
      );
    });

    test('stopCamera sets isStreaming to false', () async {
      final notifier = container.read(scannerCameraProvider.notifier);
      // Simulate streaming state
      final current = container.read(scannerCameraProvider);
      notifier.state = current.copyWith(isStreaming: true);
      await notifier.stopCamera();
      expect(
        container.read(scannerCameraProvider).isStreaming,
        false,
      );
    });
  });
}
