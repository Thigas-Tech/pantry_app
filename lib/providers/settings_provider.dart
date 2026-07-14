import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/config.dart';
import 'package:pantry_app/models/hemisphere.dart';
import 'package:pantry_app/utils/logger.dart';
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
    this.priceTrackingEnabled = false,
    this.priceRetentionDays = 0,
    this.pricesHidden = false,
    this.baseCurrency = 'USD',
    this.openPricesSyncEnabled = false,
    this.openPricesToken = '',
    this.hemisphereOverride = Hemisphere.auto,
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
  /// When enabled, surfaces use [Colors.black] instead of the default dark
  /// surface colours, which reduces power consumption on AMOLED displays.
  final bool amoledDarkMode;

  /// Whether price tracking is enabled.
  ///
  /// When disabled, all price UI surfaces are hidden.
  final bool priceTrackingEnabled;

  /// Number of days to retain price history (0 = keep forever).
  final int priceRetentionDays;

  /// Whether all prices should be masked for privacy.
  final bool pricesHidden;

  /// ISO 4217 currency code for displaying prices.
  ///
  /// Auto-detected from the device locale on first launch.
  /// Common values: `'USD'`, `'BRL'`, `'EUR'`, `'GBP'`, `'JPY'`.
  final String baseCurrency;

  /// Whether syncing to the Open Prices community database is enabled.
  final bool openPricesSyncEnabled;

  /// Bearer token for the Open Prices API.
  final String openPricesToken;

  /// Manual hemisphere override for seasonal produce.
  ///
  /// [Hemisphere.auto] means detect from device locale country code.
  final Hemisphere hemisphereOverride;

  /// Returns a copy with the given fields replaced.
  Settings copyWith({
    bool? notificationsEnabled,
    int? retentionDays,
    int? expiringSoonDays,
    bool? inactivityReminderEnabled,
    int? inactivityThresholdDays,
    bool? amoledDarkMode,
    bool? priceTrackingEnabled,
    int? priceRetentionDays,
    bool? pricesHidden,
    String? baseCurrency,
    bool? openPricesSyncEnabled,
    String? openPricesToken,
    Hemisphere? hemisphereOverride,
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
      priceTrackingEnabled: priceTrackingEnabled ?? this.priceTrackingEnabled,
      priceRetentionDays: priceRetentionDays ?? this.priceRetentionDays,
      pricesHidden: pricesHidden ?? this.pricesHidden,
      baseCurrency: baseCurrency ?? this.baseCurrency,
      openPricesSyncEnabled:
          openPricesSyncEnabled ?? this.openPricesSyncEnabled,
      openPricesToken: openPricesToken ?? this.openPricesToken,
      hemisphereOverride: hemisphereOverride ?? this.hemisphereOverride,
    );
  }
}

/// A [Notifier] that holds the current [Settings] and persists every field
/// to [SharedPreferences].
class SettingsNotifier extends Notifier<Settings> {
  @override
  Settings build() {
    unawaited(_loadFromPrefs());
    return Settings(
      baseCurrency: _detectLocaleCurrency(),
    );
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
        priceTrackingEnabled: prefs.getBool('priceTrackingEnabled') ?? false,
        priceRetentionDays: prefs.getInt('priceRetentionDays') ?? 0,
        pricesHidden: prefs.getBool('pricesHidden') ?? false,
        baseCurrency:
            prefs.getString('baseCurrency') ?? _detectLocaleCurrency(),
        openPricesSyncEnabled: prefs.getBool('openPricesSyncEnabled') ?? false,
        openPricesToken:
            prefs.getString('openPricesToken') ?? AppConfig.openPricesToken,
        hemisphereOverride: _parseHemisphere(
          prefs.getString('hemisphereOverride'),
        ),
      );
    } on Exception catch (e) {
      logWarning('Failed to load settings from SharedPreferences: $e');
    }
  }

  /// The current settings.
  Settings get value => state;

  /// Replaces the entire settings and persists every field.
  set value(Settings settings) {
    state = settings;
    unawaited(_persist(settings));
  }

  static Hemisphere _parseHemisphere(String? value) {
    if (value == null) return Hemisphere.auto;
    for (final h in Hemisphere.values) {
      if (h.name == value) return h;
    }
    return Hemisphere.auto;
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
      await prefs.setBool(
        'priceTrackingEnabled',
        settings.priceTrackingEnabled,
      );
      await prefs.setInt(
        'priceRetentionDays',
        settings.priceRetentionDays,
      );
      await prefs.setBool('pricesHidden', settings.pricesHidden);
      await prefs.setString('baseCurrency', settings.baseCurrency);
      await prefs.setBool(
        'openPricesSyncEnabled',
        settings.openPricesSyncEnabled,
      );
      await prefs.setString('openPricesToken', settings.openPricesToken);
      await prefs.setString(
        'hemisphereOverride',
        settings.hemisphereOverride.name,
      );
    } on Exception catch (e) {
      logWarning('Failed to persist settings to SharedPreferences: $e');
    }
  }
}

/// The provider for [SettingsNotifier].
final settingsProvider = NotifierProvider<SettingsNotifier, Settings>(
  SettingsNotifier.new,
);

/// Maps the device locale to an ISO 4217 currency code.
///
/// Uses [Platform.localeName] (e.g. `pt_BR`, `en_US`) to infer the most
/// likely currency. Falls back to `'USD'` for unknown locales.
String _detectLocaleCurrency() {
  try {
    final locale = Platform.localeName;
    final code = locale.contains('_') ? locale.split('_').last : '';
    return switch (code.toUpperCase()) {
      'BR' => 'BRL',
      'US' => 'USD',
      'GB' => 'GBP',
      'EU' ||
      'DE' ||
      'FR' ||
      'ES' ||
      'IT' ||
      'PT' ||
      'NL' ||
      'BE' ||
      'AT' ||
      'IE' ||
      'FI' ||
      'GR' ||
      'LU' ||
      'SK' ||
      'SI' ||
      'EE' ||
      'LV' ||
      'LT' ||
      'MT' ||
      'CY' ||
      'HR' => 'EUR',
      'JP' => 'JPY',
      'CA' => 'CAD',
      'AU' => 'AUD',
      'MX' => 'MXN',
      'CN' => 'CNY',
      'IN' => 'INR',
      'RU' => 'RUB',
      'KR' => 'KRW',
      'CH' => 'CHF',
      'SE' => 'SEK',
      'NO' => 'NOK',
      'DK' => 'DKK',
      'PL' => 'PLN',
      'CZ' => 'CZK',
      'AR' => 'ARS',
      'CL' => 'CLP',
      'CO' => 'COP',
      'ZA' => 'ZAR',
      'NG' => 'NGN',
      'TR' => 'TRY',
      'IL' => 'ILS',
      'SG' => 'SGD',
      'HK' => 'HKD',
      'TW' => 'TWD',
      'TH' => 'THB',
      'MY' => 'MYR',
      'PH' => 'PHP',
      'ID' => 'IDR',
      'VN' => 'VND',
      _ => 'USD',
    };
  } on Object catch (_) {
    return 'USD';
  }
}
