import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/providers/connectivity_provider.dart';

void main() {
  group('connectivityProvider', () {
    test('overrides correctly in tests', () {
      final container = ProviderContainer(
        overrides: [
          connectivityProvider.overrideWith(
            (ref) => Stream.value(true),
          ),
        ],
      );
      addTearDown(container.dispose);

      final subscription = container.listen(
        connectivityProvider,
        (prev, next) {},
      );
      expect(subscription, isNotNull);
      subscription.close();
    });

    test('is AsyncLoading before stream emits', () {
      final container = ProviderContainer(
        overrides: [
          connectivityProvider.overrideWith(
            (ref) => Stream.value(true),
          ),
        ],
      );
      addTearDown(container.dispose);

      final state = container.read(connectivityProvider);
      expect(state, isA<AsyncLoading<bool>>());
    });

    test('emits true when overridden with Stream.value(true)', () async {
      final container = ProviderContainer(
        overrides: [
          connectivityProvider.overrideWith(
            (ref) => Stream.value(true),
          ),
        ],
      );
      addTearDown(container.dispose);

      final completer = Completer<AsyncValue<bool>>();
      final sub = container.listen(
        connectivityProvider,
        (prev, next) {
          if (!completer.isCompleted) completer.complete(next);
        },
      );

      final result = await completer.future.timeout(
        const Duration(seconds: 1),
      );
      sub.close();

      expect(result.value, true);
    });

    test('emits false when overridden with Stream.value(false)', () async {
      final container = ProviderContainer(
        overrides: [
          connectivityProvider.overrideWith(
            (ref) => Stream.value(false),
          ),
        ],
      );
      addTearDown(container.dispose);

      final completer = Completer<AsyncValue<bool>>();
      final sub = container.listen(
        connectivityProvider,
        (prev, next) {
          if (!completer.isCompleted) completer.complete(next);
        },
      );

      final result = await completer.future.timeout(
        const Duration(seconds: 1),
      );
      sub.close();

      expect(result.value, false);
    });
  });
}
