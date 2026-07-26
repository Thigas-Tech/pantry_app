/// Tests for [HomeScreenController] loading state management.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/models/product_type.dart';
import 'package:pantry_app/providers/home_screen_controller.dart';
import 'package:pantry_app/providers/product_repository_provider.dart';
import 'package:pantry_app/services/product_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockProductRepository extends Mock implements ProductRepository {}

void main() {
  group('HomeScreenController loadingProduce', () {
    late MockProductRepository mockRepo;

    setUp(() {
      mockRepo = MockProductRepository();
      SharedPreferences.setMockInitialValues({});
    });

    ProviderContainer createContainer() {
      return ProviderContainer(
        overrides: [
          productRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
    }

    test(
      'sets loadingProduce containing the produce name before resolving',
      () {
        final container = createContainer();
        addTearDown(container.dispose);

        final notifier = container.read(homeScreenControllerProvider.notifier);
        final completer = Completer<Product>();
        when(
          () => mockRepo.resolveProduceProduct('Apple'),
        ).thenAnswer((_) => completer.future);

        // Start the async operation (don't await — we want to check state
        // before it completes)
        unawaited(notifier.handleQuickProduceAdd('Apple'));

        expect(
          container.read(homeScreenControllerProvider).loadingProduce,
          contains('Apple'),
        );
      },
    );

    test('clears loadingProduce after successful resolve', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      final notifier = container.read(homeScreenControllerProvider.notifier);
      const product = Product(
        barcode: 'produce-Apple',
        name: 'Apple',
        productType: ProductType.produce,
        source: 'manual',
      );
      when(
        () => mockRepo.resolveProduceProduct('Apple'),
      ).thenAnswer((_) async => product);

      await notifier.handleQuickProduceAdd('Apple');

      expect(
        container.read(homeScreenControllerProvider).loadingProduce,
        isEmpty,
      );
    });

    test('clears loadingProduce when resolve throws', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      final notifier = container.read(homeScreenControllerProvider.notifier);
      when(
        () => mockRepo.resolveProduceProduct('Apple'),
      ).thenThrow(Exception('Network error'));

      await notifier.handleQuickProduceAdd('Apple');

      expect(
        container.read(homeScreenControllerProvider).loadingProduce,
        isEmpty,
      );
    });

    test('returns null for duplicate call with same produce name', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      final notifier = container.read(homeScreenControllerProvider.notifier);
      final completer = Completer<Product>();
      when(
        () => mockRepo.resolveProduceProduct('Apple'),
      ).thenAnswer((_) => completer.future);

      // First call starts (don't await)
      unawaited(notifier.handleQuickProduceAdd('Apple'));

      // Second call while first is pending
      final result = await notifier.handleQuickProduceAdd('Apple');

      expect(result, isNull);
    });

    test('calls resolveProduceProduct only once for duplicate taps', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      final notifier = container.read(homeScreenControllerProvider.notifier);
      final completer = Completer<Product>();
      when(
        () => mockRepo.resolveProduceProduct('Apple'),
      ).thenAnswer((_) => completer.future);

      // Two rapid calls — first is fire-and-forget to simulate double-tap
      unawaited(notifier.handleQuickProduceAdd('Apple'));
      await notifier.handleQuickProduceAdd('Apple');

      verify(() => mockRepo.resolveProduceProduct('Apple')).called(1);
    });
  });
}
