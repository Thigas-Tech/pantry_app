import 'package:pantry_app/utils/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'onboarding_provider.g.dart';

/// SharedPreferences key for the onboarding completion flag.
const kOnboardingKey = 'onboarding_complete';

/// Tracks whether the user has completed the empty-pantry onboarding.
///
/// Loads the persisted flag from [SharedPreferences] during its build so
/// the correct value is available on the first frame — no pre-runApp
/// seeding needed and no flash of the onboarding flow for returning users.
/// Returns true once the user has added their first item to any inventory.
/// Once set to true the flag is never cleared, so the onboarding is never
/// shown again — even if the user later empties their pantry.
@Riverpod(keepAlive: true)
class OnboardingNotifier extends _$OnboardingNotifier {
  @override
  Future<bool> build() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(kOnboardingKey) ?? false;
    } on Exception catch (e) {
      logWarning('Failed to load onboarding flag: $e');
      return false;
    }
  }

  /// Marks the onboarding as permanently complete.
  Future<void> markComplete() async {
    state = const AsyncValue.data(true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(kOnboardingKey, true);
    } on Exception catch (e) {
      logWarning('Failed to persist onboarding flag: $e');
    }
  }
}
