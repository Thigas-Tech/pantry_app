import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/config.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The measurement system for displaying quantities.
enum UnitSystem {
  /// Metric units (g, kg, ml, L).
  metric,

  /// Imperial units (oz, lb, fl oz, cups).
  imperial,
}

/// Preferred weight unit when using the imperial system.
enum WeightUnitPreference {
  /// Always display ounces.
  ounces,

  /// Always display pounds.
  pounds,

  /// Automatically choose the most readable unit.
  auto,
}

/// Preferred volume unit when using the imperial system.
enum VolumeUnitPreference {
  /// Always display fluid ounces.
  fluidOunces,

  /// Always display cups.
  cups,

  /// Always display tablespoons.
  tablespoons,

  /// Always display teaspoons.
  teaspoons,

  /// Automatically choose the most readable unit.
  auto,
}

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
    this.unitSystem = UnitSystem.metric,
    this.unitSystemServingSize,
    this.unitSystemRecipeIngredients,
    this.unitSystemInventory,
    this.preferredWeightUnit = WeightUnitPreference.ounces,
    this.preferredVolumeUnit = VolumeUnitPreference.fluidOunces,
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
  /// Common values: 'USD', 'BRL', 'EUR', 'GBP', 'JPY'.
  final String baseCurrency;

  /// Whether syncing to the Open Prices community database is enabled.
  final bool openPricesSyncEnabled;

  /// Bearer token for the Open Prices API.
  final String openPricesToken;

  /// Global unit system preference (Metric or Imperial).
  final UnitSystem unitSystem;

  /// Per-context override for serving size display, or null to inherit global.
  final UnitSystem? unitSystemServingSize;

  /// Per-context override for recipe ingredient display, or null to inherit.
  final UnitSystem? unitSystemRecipeIngredients;

  /// Per-context override for inventory display, or null to inherit global.
  final UnitSystem? unitSystemInventory;

  /// Preferred weight unit when system is Imperial.
  final WeightUnitPreference preferredWeightUnit;

  /// Preferred volume unit when system is Imperial.
  final VolumeUnitPreference preferredVolumeUnit;

  /// Returns a copy with the given fields replaced.
  ///
  /// For nullable [UnitSystem] override fields, use a sentinel to distinguish
  /// "not provided" from "set to null".
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
    UnitSystem? unitSystem,
    Object? unitSystemServingSize = _nullSentinel,
    Object? unitSystemRecipeIngredients = _nullSentinel,
    Object? unitSystemInventory = _nullSentinel,
    WeightUnitPreference? preferredWeightUnit,
    VolumeUnitPreference? preferredVolumeUnit,
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
      unitSystem: unitSystem ?? this.unitSystem,
      unitSystemServingSize: identical(unitSystemServingSize, _nullSentinel)
          ? this.unitSystemServingSize
          : unitSystemServingSize as UnitSystem?,
      unitSystemRecipeIngredients:
          identical(unitSystemRecipeIngredients, _nullSentinel)
          ? this.unitSystemRecipeIngredients
          : unitSystemRecipeIngredients as UnitSystem?,
      unitSystemInventory: identical(unitSystemInventory, _nullSentinel)
          ? this.unitSystemInventory
          : unitSystemInventory as UnitSystem?,
      preferredWeightUnit: preferredWeightUnit ?? this.preferredWeightUnit,
      preferredVolumeUnit: preferredVolumeUnit ?? this.preferredVolumeUnit,
    );
  }

  static const _nullSentinel = Object();
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
      if (!ref.mounted) return;
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
        unitSystem: UnitSystem.values.firstWhere(
          (e) => e.name == prefs.getString('unitSystem'),
          orElse: () => UnitSystem.metric,
        ),
        unitSystemServingSize: () {
          final v = prefs.getString('unitSystemServingSize');
          if (v == null) return null;
          return UnitSystem.values.firstWhere(
            (e) => e.name == v,
            orElse: () => UnitSystem.metric,
          );
        }(),
        unitSystemRecipeIngredients: () {
          final v = prefs.getString('unitSystemRecipeIngredients');
          if (v == null) return null;
          return UnitSystem.values.firstWhere(
            (e) => e.name == v,
            orElse: () => UnitSystem.metric,
          );
        }(),
        unitSystemInventory: () {
          final v = prefs.getString('unitSystemInventory');
          if (v == null) return null;
          return UnitSystem.values.firstWhere(
            (e) => e.name == v,
            orElse: () => UnitSystem.metric,
          );
        }(),
        preferredWeightUnit: WeightUnitPreference.values.firstWhere(
          (e) => e.name == prefs.getString('preferredWeightUnit'),
          orElse: () => WeightUnitPreference.ounces,
        ),
        preferredVolumeUnit: VolumeUnitPreference.values.firstWhere(
          (e) => e.name == prefs.getString('preferredVolumeUnit'),
          orElse: () => VolumeUnitPreference.fluidOunces,
        ),
      );
    } on Exception catch (e) {
      logWarning('Failed to load settings from SharedPreferences: $e');
    }
  }

  /// Replaces the entire settings and persists every field.
  ///
  /// Prefer the specific setter methods over this bulk replacement.
  /// Deprecated: use individual setter methods instead.
  @Deprecated('Use individual setter methods instead')
  void replace(Settings settings) {
    state = settings;
    unawaited(_persist(settings));
  }

  /// Sets whether expiry notifications are enabled.
  void setNotificationsEnabled({required bool value}) {
    state = state.copyWith(notificationsEnabled: value);
    unawaited(_persist(state));
  }

  /// Sets the number of days before cleanup.
  void setRetentionDays(int value) {
    state = state.copyWith(retentionDays: value);
    unawaited(_persist(state));
  }

  /// Sets the number of days for "expiring soon".
  void setExpiringSoonDays(int value) {
    state = state.copyWith(expiringSoonDays: value);
    unawaited(_persist(state));
  }

  /// Sets whether the inactivity reminder is enabled.
  void setInactivityReminderEnabled({required bool value}) {
    state = state.copyWith(inactivityReminderEnabled: value);
    unawaited(_persist(state));
  }

  /// Sets the inactivity threshold in days.
  void setInactivityThresholdDays(int value) {
    state = state.copyWith(inactivityThresholdDays: value);
    unawaited(_persist(state));
  }

  /// Sets whether AMOLED dark mode is enabled.
  void setAmoledDarkMode({required bool value}) {
    state = state.copyWith(amoledDarkMode: value);
    unawaited(_persist(state));
  }

  /// Sets whether price tracking is enabled.
  void setPriceTrackingEnabled({required bool value}) {
    state = state.copyWith(priceTrackingEnabled: value);
    unawaited(_persist(state));
  }

  /// Sets the price retention period in days.
  void setPriceRetentionDays(int value) {
    state = state.copyWith(priceRetentionDays: value);
    unawaited(_persist(state));
  }

  /// Sets whether prices are hidden.
  void setPricesHidden({required bool value}) {
    state = state.copyWith(pricesHidden: value);
    unawaited(_persist(state));
  }

  /// Sets the base currency code (ISO 4217).
  void setBaseCurrency(String value) {
    state = state.copyWith(baseCurrency: value);
    unawaited(_persist(state));
  }

  /// Sets whether Open Prices sync is enabled.
  void setOpenPricesSyncEnabled({required bool value}) {
    state = state.copyWith(openPricesSyncEnabled: value);
    unawaited(_persist(state));
  }

  /// Sets the Open Prices API bearer token.
  void setOpenPricesToken(String value) {
    state = state.copyWith(openPricesToken: value);
    unawaited(_persist(state));
  }

  /// Sets the global unit system.
  void setUnitSystem(UnitSystem value) {
    state = state.copyWith(unitSystem: value);
    unawaited(_persist(state));
  }

  /// Sets the per-context override for serving size display.
  void setUnitSystemServingSize(UnitSystem? value) {
    state = state.copyWith(unitSystemServingSize: value);
    unawaited(_persist(state));
  }

  /// Sets the per-context override for recipe ingredients.
  void setUnitSystemRecipeIngredients(UnitSystem? value) {
    state = state.copyWith(unitSystemRecipeIngredients: value);
    unawaited(_persist(state));
  }

  /// Sets the per-context override for inventory display.
  void setUnitSystemInventory(UnitSystem? value) {
    state = state.copyWith(unitSystemInventory: value);
    unawaited(_persist(state));
  }

  /// Sets the preferred weight unit for imperial mode.
  void setPreferredWeightUnit(WeightUnitPreference value) {
    state = state.copyWith(preferredWeightUnit: value);
    unawaited(_persist(state));
  }

  /// Sets the preferred volume unit for imperial mode.
  void setPreferredVolumeUnit(VolumeUnitPreference value) {
    state = state.copyWith(preferredVolumeUnit: value);
    unawaited(_persist(state));
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
        'unitSystem',
        settings.unitSystem.name,
      );
      if (settings.unitSystemServingSize != null) {
        await prefs.setString(
          'unitSystemServingSize',
          settings.unitSystemServingSize!.name,
        );
      } else {
        await prefs.remove('unitSystemServingSize');
      }
      if (settings.unitSystemRecipeIngredients != null) {
        await prefs.setString(
          'unitSystemRecipeIngredients',
          settings.unitSystemRecipeIngredients!.name,
        );
      } else {
        await prefs.remove('unitSystemRecipeIngredients');
      }
      if (settings.unitSystemInventory != null) {
        await prefs.setString(
          'unitSystemInventory',
          settings.unitSystemInventory!.name,
        );
      } else {
        await prefs.remove('unitSystemInventory');
      }
      await prefs.setString(
        'preferredWeightUnit',
        settings.preferredWeightUnit.name,
      );
      await prefs.setString(
        'preferredVolumeUnit',
        settings.preferredVolumeUnit.name,
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
/// Uses [Platform.localeName] (e.g. pt_BR, en_US) to infer the most
/// likely currency. Falls back to 'USD' for unknown locales.
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
