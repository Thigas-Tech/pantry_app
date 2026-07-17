import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
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

  group('debounceConnectivityStatus', () {
    test('emits true immediately for connected', () async {
      final controller = StreamController<InternetConnectionStatus>();
      final debounced = debounceConnectivityStatus(
        controller.stream,
        debounceDuration: const Duration(milliseconds: 200),
      );

      final emitted = <bool>[];
      final sub = debounced.listen(emitted.add);
      addTearDown(() async {
        await sub.cancel();
        await controller.close();
      });

      controller.add(InternetConnectionStatus.connected);
      await Future<void>.delayed(Duration.zero);

      expect(emitted, [true]);
    });

    test(
      'emits false after debounce window when disconnected is sustained',
      () async {
        final controller = StreamController<InternetConnectionStatus>();
        final debounced = debounceConnectivityStatus(
          controller.stream,
          debounceDuration: const Duration(milliseconds: 50),
        );

        final emitted = <bool>[];
        final sub = debounced.listen(emitted.add);
        addTearDown(() async {
          await sub.cancel();
          await controller.close();
        });

        controller.add(InternetConnectionStatus.connected);
        await Future<void>.delayed(Duration.zero);
        expect(emitted, [true]);

        controller.add(InternetConnectionStatus.disconnected);
        await Future<void>.delayed(const Duration(milliseconds: 100));
        expect(emitted, [true, false]);
      },
    );

    test(
      'suppresses offline when reconnected within debounce window',
      () async {
        final controller = StreamController<InternetConnectionStatus>();
        final debounced = debounceConnectivityStatus(
          controller.stream,
          debounceDuration: const Duration(milliseconds: 200),
        );

        final emitted = <bool>[];
        final sub = debounced.listen(emitted.add);
        addTearDown(() async {
          await sub.cancel();
          await controller.close();
        });

        controller.add(InternetConnectionStatus.connected);
        await Future<void>.delayed(Duration.zero);
        expect(emitted, [true]);

        // Disconnect then reconnect within debounce window
        controller.add(InternetConnectionStatus.disconnected);
        await Future<void>.delayed(const Duration(milliseconds: 50));
        controller.add(InternetConnectionStatus.connected);
        await Future<void>.delayed(const Duration(milliseconds: 50));

        // Offline event should have been suppressed
        expect(emitted, [true]);

        // Wait past the original debounce deadline to confirm no delayed emit
        await Future<void>.delayed(const Duration(milliseconds: 200));
        expect(emitted, [true]);
      },
    );

    test(
      'emits false after sustained disconnect even with intermediate '
      'connected within window',
      () async {
        final controller = StreamController<InternetConnectionStatus>();
        final debounced = debounceConnectivityStatus(
          controller.stream,
          debounceDuration: const Duration(milliseconds: 50),
        );

        final emitted = <bool>[];
        final sub = debounced.listen(emitted.add);
        addTearDown(() async {
          await sub.cancel();
          await controller.close();
        });

        controller.add(InternetConnectionStatus.connected);
        await Future<void>.delayed(Duration.zero);

        controller.add(InternetConnectionStatus.disconnected);
        await Future<void>.delayed(const Duration(milliseconds: 100));

        expect(emitted, [true, false]);
      },
    );

    test('handles multiple disconnected oscillations', () async {
      final controller = StreamController<InternetConnectionStatus>();
      final debounced = debounceConnectivityStatus(
        controller.stream,
        debounceDuration: const Duration(milliseconds: 100),
      );

      final emitted = <bool>[];
      final sub = debounced.listen(emitted.add);
      addTearDown(() async {
        await sub.cancel();
        await controller.close();
      });

      controller.add(InternetConnectionStatus.connected);
      await Future<void>.delayed(Duration.zero);

      // Quick oscillation 1
      controller.add(InternetConnectionStatus.disconnected);
      await Future<void>.delayed(const Duration(milliseconds: 30));
      controller.add(InternetConnectionStatus.connected);
      await Future<void>.delayed(const Duration(milliseconds: 30));

      // Quick oscillation 2
      controller.add(InternetConnectionStatus.disconnected);
      await Future<void>.delayed(const Duration(milliseconds: 30));
      controller.add(InternetConnectionStatus.connected);
      await Future<void>.delayed(const Duration(milliseconds: 30));

      // Should still be connected
      expect(emitted, [true]);

      // Now actually go offline for longer than debounce
      controller.add(InternetConnectionStatus.disconnected);
      await Future<void>.delayed(const Duration(milliseconds: 150));

      expect(emitted, [true, false]);
    });

    test('stream completion closes cleanly mid-debounce', () async {
      final controller = StreamController<InternetConnectionStatus>();
      final debounced = debounceConnectivityStatus(
        controller.stream,
        debounceDuration: const Duration(milliseconds: 100),
      );

      final emitted = <bool>[];
      final sub = debounced.listen(emitted.add);
      addTearDown(() async {
        await sub.cancel();
      });

      controller.add(InternetConnectionStatus.connected);
      await Future<void>.delayed(Duration.zero);

      controller.add(InternetConnectionStatus.disconnected);

      // Close the source before debounce fires
      await controller.close();
      await Future<void>.delayed(const Duration(milliseconds: 150));

      // No false emitted because source closed before timer fired
      expect(emitted, [true]);
    });
  });
}
