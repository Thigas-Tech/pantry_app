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

    test('initial state is false', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(await container.read(onboardingProvider.future), false);
    });

    test('loads a persisted true flag from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({'onboarding_complete': true});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(await container.read(onboardingProvider.future), true);
    });

    test('loads a persisted false flag from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({'onboarding_complete': false});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(await container.read(onboardingProvider.future), false);
    });

    test('markComplete sets state to true', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(onboardingProvider.notifier).markComplete();

      expect(container.read(onboardingProvider).value, true);
    });

    test('markComplete persists to SharedPreferences', () async {
      var container = ProviderContainer();
      await container.read(onboardingProvider.notifier).markComplete();
      container.dispose();

      container = ProviderContainer();
      addTearDown(container.dispose);

      expect(await container.read(onboardingProvider.future), true);
    });
  });
}
