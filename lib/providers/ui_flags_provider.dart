import 'dart:async';

import 'package:pantry_app/providers/settings_provider.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'ui_flags_provider.g.dart';

/// Transient one-shot UI flags persisted to [SharedPreferences].
///
/// Unlike [Settings] (user preferences), these are cross-cutting one-shot
/// flags read/written ad-hoc across the shell, settings, and startup paths.
/// Routing them through [UiFlagsNotifier] gives them a single owner with
/// typed getters and setters.
class UiFlags {
  /// Creates a [UiFlags] instance with the given values.
  const UiFlags({
    this.notificationDeniedWarning = false,
    this.amoledNudgeShown = false,
    this.changelogShowPending = false,
    this.notificationRationaleShown = false,
  });

  /// Whether the "notification denied" warning snackbar is pending.
  final bool notificationDeniedWarning;

  /// Whether the AMOLED dark-mode nudge dialog has been shown.
  final bool amoledNudgeShown;

  /// Whether the "What's New" sheet should be shown on the next launch.
  final bool changelogShowPending;

  /// Whether the notification-permission rationale dialog has been shown.
  final bool notificationRationaleShown;

  /// Returns a copy with the given fields replaced.
  UiFlags copyWith({
    bool? notificationDeniedWarning,
    bool? amoledNudgeShown,
    bool? changelogShowPending,
    bool? notificationRationaleShown,
  }) {
    return UiFlags(
      notificationDeniedWarning:
          notificationDeniedWarning ?? this.notificationDeniedWarning,
      amoledNudgeShown: amoledNudgeShown ?? this.amoledNudgeShown,
      changelogShowPending: changelogShowPending ?? this.changelogShowPending,
      notificationRationaleShown:
          notificationRationaleShown ?? this.notificationRationaleShown,
    );
  }
}

/// A notifier that holds the current [UiFlags] and persists every field
/// to [SharedPreferences].
@Riverpod(keepAlive: true)
class UiFlagsNotifier extends _$UiFlagsNotifier {
  @override
  Future<UiFlags> build() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return UiFlags(
        notificationDeniedWarning:
            prefs.getBool('notification_denied_warning') ?? false,
        amoledNudgeShown: prefs.getBool('amoled_nudge_shown') ?? false,
        changelogShowPending:
            prefs.getString('changelog_show_pending') == 'true',
        notificationRationaleShown:
            prefs.getBool('notification_rationale_shown') ?? false,
      );
    } on Exception catch (e) {
      logWarning('Failed to load UI flags from SharedPreferences: $e');
      return const UiFlags();
    }
  }

  /// Sets whether the notification-denied warning snackbar is pending.
  void setNotificationDeniedWarning({required bool value}) {
    final updated = (state.value ?? const UiFlags()).copyWith(
      notificationDeniedWarning: value,
    );
    state = AsyncValue.data(updated);
    unawaited(_persist('notification_denied_warning', value));
  }

  /// Sets whether the AMOLED dark-mode nudge has been shown.
  void setAmoledNudgeShown({required bool value}) {
    final updated = (state.value ?? const UiFlags()).copyWith(
      amoledNudgeShown: value,
    );
    state = AsyncValue.data(updated);
    unawaited(_persist('amoled_nudge_shown', value));
  }

  /// Sets whether the "What's New" sheet is pending.
  void setChangelogShowPending({required bool value}) {
    final updated = (state.value ?? const UiFlags()).copyWith(
      changelogShowPending: value,
    );
    state = AsyncValue.data(updated);
    unawaited(
      _persistString('changelog_show_pending', value ? 'true' : 'false'),
    );
  }

  /// Sets whether the notification-permission rationale has been shown.
  void setNotificationRationaleShown({required bool value}) {
    final updated = (state.value ?? const UiFlags()).copyWith(
      notificationRationaleShown: value,
    );
    state = AsyncValue.data(updated);
    unawaited(_persist('notification_rationale_shown', value));
  }

  Future<void> _persist(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
    } on Exception catch (e) {
      logWarning('Failed to persist UI flag $key: $e');
    }
  }

  Future<void> _persistString(String key, String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    } on Exception catch (e) {
      logWarning('Failed to persist UI flag $key: $e');
    }
  }
}
