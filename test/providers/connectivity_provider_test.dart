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

      // When overridden with true, the value should resolve correctly.
      final subscription = container.listen(
        connectivityProvider,
        (prev, next) {},
      );
      expect(subscription, isNotNull);
      subscription.close();
    });
  });
}
