import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'settings_provider.g.dart';

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
    this.weeklyRecipeSuggestionEnabled = false,
    this.weeklyRecipeSuggestionDay = 7,
    this.weeklyRecipeSuggestionHour = 18,
    this.weeklyRecipeSuggestionMinute = 0,
    this.amoledDarkMode = false,
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

  /// Whether the weekly recipe-suggestion notification is enabled.
  ///
  /// When disabled, no recipe-suggestion notification is scheduled.
  final bool weeklyRecipeSuggestionEnabled;

  /// Day of the week for the recipe suggestion, 1 = Monday ... 7 = Sunday.
  ///
  /// Defaults to Sunday (7).
  final int weeklyRecipeSuggestionDay;

  /// Hour of the day (0-23) for the recipe-suggestion notification.
  ///
  /// Defaults to 18 (6 PM).
  final int weeklyRecipeSuggestionHour;

  /// Minute of the hour (0-59) for the recipe-suggestion notification.
  ///
  /// Defaults to 0.
  final int weeklyRecipeSuggestionMinute;

  /// Whether pure-black surfaces should be used in dark mode.
  ///
  /// When enabled, surfaces use [Colors.black] instead of the default dark
  /// surface colours, which reduces power consumption on AMOLED displays.
  final bool amoledDarkMode;

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
    bool? weeklyRecipeSuggestionEnabled,
    int? weeklyRecipeSuggestionDay,
    int? weeklyRecipeSuggestionHour,
    int? weeklyRecipeSuggestionMinute,
    bool? amoledDarkMode,
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
      weeklyRecipeSuggestionEnabled:
          weeklyRecipeSuggestionEnabled ?? this.weeklyRecipeSuggestionEnabled,
      weeklyRecipeSuggestionDay:
          weeklyRecipeSuggestionDay ?? this.weeklyRecipeSuggestionDay,
      weeklyRecipeSuggestionHour:
          weeklyRecipeSuggestionHour ?? this.weeklyRecipeSuggestionHour,
      weeklyRecipeSuggestionMinute:
          weeklyRecipeSuggestionMinute ?? this.weeklyRecipeSuggestionMinute,
      amoledDarkMode: amoledDarkMode ?? this.amoledDarkMode,
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

/// A notifier that holds the current [Settings] and persists every field
/// to [SharedPreferences].
@Riverpod(keepAlive: true)
class SettingsNotifier extends _$SettingsNotifier {
  @override
  Future<Settings> build() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return Settings(
        notificationsEnabled: prefs.getBool('notificationsEnabled') ?? true,
        retentionDays: prefs.getInt('retentionDays') ?? 60,
        expiringSoonDays: prefs.getInt('expiringSoonDays') ?? 3,
        inactivityReminderEnabled:
            prefs.getBool('inactivityReminderEnabled') ?? true,
        inactivityThresholdDays: prefs.getInt('inactivityThresholdDays') ?? 10,
        weeklyRecipeSuggestionEnabled:
            prefs.getBool('weeklyRecipeSuggestionEnabled') ?? false,
        weeklyRecipeSuggestionDay:
            prefs.getInt('weeklyRecipeSuggestionDay') ?? 7,
        weeklyRecipeSuggestionHour:
            prefs.getInt('weeklyRecipeSuggestionHour') ?? 18,
        weeklyRecipeSuggestionMinute:
            prefs.getInt('weeklyRecipeSuggestionMinute') ?? 0,
        amoledDarkMode: prefs.getBool('amoledDarkMode') ?? false,
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
      return const Settings();
    }
  }

  /// Replaces the entire settings and persists every field.
  ///
  /// Prefer the specific setter methods over this bulk replacement.
  /// Deprecated: use individual setter methods instead.
  @Deprecated('Use individual setter methods instead')
  void replace(Settings settings) {
    state = AsyncValue.data(settings);
    unawaited(_persist(settings));
  }

  /// Sets whether expiry notifications are enabled.
  void setNotificationsEnabled({required bool value}) {
    final updated = (state.value ?? const Settings()).copyWith(
      notificationsEnabled: value,
    );
    state = AsyncValue.data(updated);
    unawaited(_persist(updated));
  }

  /// Sets the number of days before cleanup.
  void setRetentionDays(int value) {
    final updated = (state.value ?? const Settings()).copyWith(
      retentionDays: value,
    );
    state = AsyncValue.data(updated);
    unawaited(_persist(updated));
  }

  /// Sets the number of days for "expiring soon".
  void setExpiringSoonDays(int value) {
    final updated = (state.value ?? const Settings()).copyWith(
      expiringSoonDays: value,
    );
    state = AsyncValue.data(updated);
    unawaited(_persist(updated));
  }

  /// Sets whether the inactivity reminder is enabled.
  void setInactivityReminderEnabled({required bool value}) {
    final updated = (state.value ?? const Settings()).copyWith(
      inactivityReminderEnabled: value,
    );
    state = AsyncValue.data(updated);
    unawaited(_persist(updated));
  }

  /// Sets the inactivity threshold in days.
  void setInactivityThresholdDays(int value) {
    final updated = (state.value ?? const Settings()).copyWith(
      inactivityThresholdDays: value,
    );
    state = AsyncValue.data(updated);
    unawaited(_persist(updated));
  }

  /// Sets whether the weekly recipe-suggestion notification is enabled.
  void setWeeklyRecipeSuggestionEnabled({required bool value}) {
    final updated = (state.value ?? const Settings()).copyWith(
      weeklyRecipeSuggestionEnabled: value,
    );
    state = AsyncValue.data(updated);
    unawaited(_persist(updated));
  }

  /// Sets the day of the week for the recipe suggestion.
  ///
  /// [value] follows [DateTime.weekday]: 1 = Monday ... 7 = Sunday.
  void setWeeklyRecipeSuggestionDay(int value) {
    final updated = (state.value ?? const Settings()).copyWith(
      weeklyRecipeSuggestionDay: value,
    );
    state = AsyncValue.data(updated);
    unawaited(_persist(updated));
  }

  /// Sets the hour (0-23) of the recipe-suggestion notification.
  void setWeeklyRecipeSuggestionHour(int value) {
    final updated = (state.value ?? const Settings()).copyWith(
      weeklyRecipeSuggestionHour: value,
    );
    state = AsyncValue.data(updated);
    unawaited(_persist(updated));
  }

  /// Sets the minute (0-59) of the recipe-suggestion notification.
  void setWeeklyRecipeSuggestionMinute(int value) {
    final updated = (state.value ?? const Settings()).copyWith(
      weeklyRecipeSuggestionMinute: value,
    );
    state = AsyncValue.data(updated);
    unawaited(_persist(updated));
  }

  /// Sets whether AMOLED dark mode is enabled.
  void setAmoledDarkMode({required bool value}) {
    final updated = (state.value ?? const Settings()).copyWith(
      amoledDarkMode: value,
    );
    state = AsyncValue.data(updated);
    unawaited(_persist(updated));
  }

  /// Sets the global unit system.
  void setUnitSystem(UnitSystem value) {
    final updated = (state.value ?? const Settings()).copyWith(
      unitSystem: value,
    );
    state = AsyncValue.data(updated);
    unawaited(_persist(updated));
  }

  /// Sets the per-context override for serving size display.
  void setUnitSystemServingSize(UnitSystem? value) {
    final updated = (state.value ?? const Settings()).copyWith(
      unitSystemServingSize: value,
    );
    state = AsyncValue.data(updated);
    unawaited(_persist(updated));
  }

  /// Sets the per-context override for recipe ingredients.
  void setUnitSystemRecipeIngredients(UnitSystem? value) {
    final updated = (state.value ?? const Settings()).copyWith(
      unitSystemRecipeIngredients: value,
    );
    state = AsyncValue.data(updated);
    unawaited(_persist(updated));
  }

  /// Sets the per-context override for inventory display.
  void setUnitSystemInventory(UnitSystem? value) {
    final updated = (state.value ?? const Settings()).copyWith(
      unitSystemInventory: value,
    );
    state = AsyncValue.data(updated);
    unawaited(_persist(updated));
  }

  /// Sets the preferred weight unit for imperial mode.
  void setPreferredWeightUnit(WeightUnitPreference value) {
    final updated = (state.value ?? const Settings()).copyWith(
      preferredWeightUnit: value,
    );
    state = AsyncValue.data(updated);
    unawaited(_persist(updated));
  }

  /// Sets the preferred volume unit for imperial mode.
  void setPreferredVolumeUnit(VolumeUnitPreference value) {
    final updated = (state.value ?? const Settings()).copyWith(
      preferredVolumeUnit: value,
    );
    state = AsyncValue.data(updated);
    unawaited(_persist(updated));
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
      await prefs.setBool(
        'weeklyRecipeSuggestionEnabled',
        settings.weeklyRecipeSuggestionEnabled,
      );
      await prefs.setInt(
        'weeklyRecipeSuggestionDay',
        settings.weeklyRecipeSuggestionDay,
      );
      await prefs.setInt(
        'weeklyRecipeSuggestionHour',
        settings.weeklyRecipeSuggestionHour,
      );
      await prefs.setInt(
        'weeklyRecipeSuggestionMinute',
        settings.weeklyRecipeSuggestionMinute,
      );
      await prefs.setBool('amoledDarkMode', settings.amoledDarkMode);
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
