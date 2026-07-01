import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Persistent settings for the pantry app.
class Settings {
  /// Creates a [Settings] instance.
  ///
  /// [notificationsEnabled] defaults to `true`.
  /// [retentionDays] defaults to `60`.
  const Settings({
    this.notificationsEnabled = true,
    this.retentionDays = 60,
  });

  /// Whether expiry notifications are enabled.
  final bool notificationsEnabled;

  /// Number of days before an old inventory item is automatically cleaned up.
  final int retentionDays;
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
