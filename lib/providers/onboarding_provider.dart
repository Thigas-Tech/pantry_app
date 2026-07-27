import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences key for the onboarding completion flag.
const kOnboardingKey = 'onboarding_complete';

/// Tracks whether the user has completed the empty-pantry onboarding.
///
/// Returns `true` once the user has added their first item to any inventory.
/// Once set to `true` the flag is never cleared, so the onboarding is never
/// shown again — even if the user later empties their pantry.
class OnboardingNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  /// Sets the persisted state from [SharedPreferences] before the first frame.
  ///
  /// Called synchronously from `main` so the correct value is available on
  /// the very first frame, avoiding a flash of the onboarding flow for
  /// returning users.
  void initial({required bool value}) {
    state = value;
  }

  /// Marks the onboarding as permanently complete.
  Future<void> markComplete() async {
    state = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(kOnboardingKey, true);
    } on Exception catch (e) {
      logWarning('Failed to persist onboarding flag: $e');
    }
  }
}

/// Provider for [OnboardingNotifier].
final onboardingProvider = NotifierProvider<OnboardingNotifier, bool>(
  OnboardingNotifier.new,
);
