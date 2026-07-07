import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persistent settings for the pantry app.
///
/// All fields have sensible defaults for a new user.
class Settings {
  /// Creates a [Settings] instance with the given values.
  const Settings({
    this.notificationsEnabled = true,
    this.retentionDays = 60,
    this.expiringSoonDays = 3,
    this.inactivityReminderEnabled = true,
    this.inactivityThresholdDays = 10,
    this.amoledDarkMode = false,
  });

  /// Whether expiry notifications are enabled.
  final bool notificationsEnabled;

  /// Number of days before an old inventory item is automatically cleaned up.
  final int retentionDays;

  /// Number of days within which an item is considered "expiring soon".
  final int expiringSoonDays;

  /// Whether the inactivity reminder is enabled.
  ///
  /// When disabled, no notification is scheduled even if the inactivity
  /// threshold is exceeded.
  final bool inactivityReminderEnabled;

  /// Number of days of inactivity before a reminder is sent.
  ///
  /// The reminder fires at 9 AM on the day after this threshold is crossed.
  /// Defaults to 10.
  final int inactivityThresholdDays;

  /// Whether pure-black surfaces should be used in dark mode.
  ///
  /// When enabled, surfaces use `Colors.black` instead of the default dark
  /// surface colours, which reduces power consumption on AMOLED displays.
  final bool amoledDarkMode;

  /// Returns a copy with the given fields replaced.
  Settings copyWith({
    bool? notificationsEnabled,
    int? retentionDays,
    int? expiringSoonDays,
    bool? inactivityReminderEnabled,
    int? inactivityThresholdDays,
    bool? amoledDarkMode,
  }) {
    return Settings(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      retentionDays: retentionDays ?? this.retentionDays,
      expiringSoonDays: expiringSoonDays ?? this.expiringSoonDays,
      inactivityReminderEnabled:
          inactivityReminderEnabled ?? this.inactivityReminderEnabled,
      inactivityThresholdDays:
          inactivityThresholdDays ?? this.inactivityThresholdDays,
      amoledDarkMode: amoledDarkMode ?? this.amoledDarkMode,
    );
  }
}

/// A [Notifier] that holds the current [Settings] and persists every field
/// to [SharedPreferences].
class SettingsNotifier extends Notifier<Settings> {
  @override
  Settings build() {
    unawaited(_loadFromPrefs());
    return const Settings();
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      state = Settings(
        notificationsEnabled: prefs.getBool('notificationsEnabled') ?? true,
        retentionDays: prefs.getInt('retentionDays') ?? 60,
        expiringSoonDays: prefs.getInt('expiringSoonDays') ?? 3,
        inactivityReminderEnabled:
            prefs.getBool('inactivityReminderEnabled') ?? true,
        inactivityThresholdDays: prefs.getInt('inactivityThresholdDays') ?? 10,
        amoledDarkMode: prefs.getBool('amoledDarkMode') ?? false,
      );
    } on Exception catch (_) {}
  }

  /// The current settings.
  Settings get value => state;

  /// Replaces the entire settings and persists every field.
  set value(Settings settings) {
    state = settings;
    unawaited(_persist(settings));
  }

  Future<void> _persist(Settings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(
        'notificationsEnabled',
        settings.notificationsEnabled,
      );
      await prefs.setInt('retentionDays', settings.retentionDays);
      await prefs.setInt('expiringSoonDays', settings.expiringSoonDays);
      await prefs.setBool(
        'inactivityReminderEnabled',
        settings.inactivityReminderEnabled,
      );
      await prefs.setInt(
        'inactivityThresholdDays',
        settings.inactivityThresholdDays,
      );
      await prefs.setBool('amoledDarkMode', settings.amoledDarkMode);
    } on Exception catch (_) {}
  }
}

/// The provider for [SettingsNotifier].
final settingsProvider = NotifierProvider<SettingsNotifier, Settings>(
  SettingsNotifier.new,
);
