/// Tests for the onboarding completion flag provider.
///
/// Verifies that the flag can be set, read, and persisted via
/// [SharedPreferences]. It starts at `false` for a fresh install and
/// is never cleared once set to `true`.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/providers/onboarding_provider.dart'
    show onboardingProvider;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('OnboardingProvider', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('initial state is false', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(onboardingProvider), false);
    });

    test('initial setter sets state to true', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(onboardingProvider.notifier).initial(value: true);
      expect(container.read(onboardingProvider), true);
    });

    test('initial setter sets state to false', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(onboardingProvider.notifier).initial(value: false);
      expect(container.read(onboardingProvider), false);
    });

    test('markComplete sets state to true', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(onboardingProvider.notifier).markComplete();

      expect(container.read(onboardingProvider), true);
    });

    test('markComplete persists to SharedPreferences', () async {
      var container = ProviderContainer();
      await container.read(onboardingProvider.notifier).markComplete();
      container.dispose();

      container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(onboardingProvider.notifier).initial(value: true);
      expect(container.read(onboardingProvider), true);
    });
  });
}
