import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  /// Returns a copy with the given fields replaced.
  Settings copyWith({
    bool? notificationsEnabled,
    int? retentionDays,
    int? expiringSoonDays,
    bool? inactivityReminderEnabled,
    int? inactivityThresholdDays,
  }) {
    return Settings(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      retentionDays: retentionDays ?? this.retentionDays,
      expiringSoonDays: expiringSoonDays ?? this.expiringSoonDays,
      inactivityReminderEnabled:
          inactivityReminderEnabled ?? this.inactivityReminderEnabled,
      inactivityThresholdDays:
          inactivityThresholdDays ?? this.inactivityThresholdDays,
    );
  }
}

/// A [Notifier] that holds the current [Settings].
class SettingsNotifier extends Notifier<Settings> {
  @override
  Settings build() => const Settings();

  /// The current settings.
  Settings get value => state;

  /// Replaces the entire settings.
  set value(Settings settings) => state = settings;
}

/// The provider for [SettingsNotifier].
final settingsProvider = NotifierProvider<SettingsNotifier, Settings>(
  SettingsNotifier.new,
);
