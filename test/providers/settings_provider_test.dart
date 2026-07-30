import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/providers/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    dotenv.loadFromString(isOptional: true, mergeWith: {});
  });

  group('Settings', () {
    test('copyWith preserves unchanged fields', () {
      const original = Settings();
      final copy = original.copyWith(notificationsEnabled: false);
      expect(copy.notificationsEnabled, false);
      expect(copy.retentionDays, original.retentionDays);
    });

    test('copyWith changes multiple fields', () {
      const original = Settings();
      final copy = original.copyWith(
        notificationsEnabled: false,
        retentionDays: 30,
      );
      expect(copy.notificationsEnabled, false);
      expect(copy.retentionDays, 30);
    });

    test('unit system defaults to metric', () {
      const settings = Settings();
      expect(settings.unitSystem, UnitSystem.metric);
    });

    test('unit system overrides default to null', () {
      const settings = Settings();
      expect(settings.unitSystemServingSize, isNull);
      expect(settings.unitSystemRecipeIngredients, isNull);
      expect(settings.unitSystemInventory, isNull);
    });

    test('preferred units default to ounces and fluidOunces', () {
      const settings = Settings();
      expect(settings.preferredWeightUnit, WeightUnitPreference.ounces);
      expect(settings.preferredVolumeUnit, VolumeUnitPreference.fluidOunces);
    });

    test('copyWith changes unitSystem', () {
      const original = Settings();
      final copy = original.copyWith(unitSystem: UnitSystem.imperial);
      expect(copy.unitSystem, UnitSystem.imperial);
      expect(copy.preferredWeightUnit, original.preferredWeightUnit);
    });

    test('copyWith sets override to a specific value', () {
      const original = Settings();
      final copy = original.copyWith(
        unitSystemServingSize: UnitSystem.imperial,
      );
      expect(copy.unitSystemServingSize, UnitSystem.imperial);
      expect(copy.unitSystem, UnitSystem.metric);
    });

    test('copyWith clears override when set to null', () {
      final original = Settings(
        unitSystemServingSize: UnitSystem.imperial,
      );
      final copy = original.copyWith(unitSystemServingSize: null);
      expect(copy.unitSystemServingSize, isNull);
    });

    test('copyWith changes preferredWeightUnit', () {
      const original = Settings();
      final copy = original.copyWith(
        preferredWeightUnit: WeightUnitPreference.pounds,
      );
      expect(copy.preferredWeightUnit, WeightUnitPreference.pounds);
    });

    test('copyWith changes preferredVolumeUnit', () {
      const original = Settings();
      final copy = original.copyWith(
        preferredVolumeUnit: VolumeUnitPreference.cups,
      );
      expect(copy.preferredVolumeUnit, VolumeUnitPreference.cups);
    });
  });

  group('SettingsNotifier', () {
    test('replace updates state immediately', () {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      container
          .read(settingsProvider.notifier)
          .replace(
            const Settings(
              notificationsEnabled: false,
            ),
          );
      expect(container.read(settingsProvider).notificationsEnabled, false);

      container.dispose();
    });

    test('replace persists to SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      container
          .read(settingsProvider.notifier)
          .replace(
            const Settings(
              notificationsEnabled: false,
              retentionDays: 90,
              amoledDarkMode: true,
              baseCurrency: 'EUR',
            ),
          );

      await Future<void>.delayed(const Duration(milliseconds: 200));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('notificationsEnabled'), false);
      expect(prefs.getInt('retentionDays'), 90);
      expect(prefs.getBool('amoledDarkMode'), true);
      expect(prefs.getString('baseCurrency'), 'EUR');

      container.dispose();
    });

    test('persists all settings fields', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      container
          .read(settingsProvider.notifier)
          .replace(
            const Settings(
              notificationsEnabled: false,
              retentionDays: 45,
              expiringSoonDays: 7,
              inactivityReminderEnabled: false,
              inactivityThresholdDays: 14,
              amoledDarkMode: true,
              priceTrackingEnabled: true,
              priceRetentionDays: 365,
              pricesHidden: true,
              baseCurrency: 'BRL',
              openPricesSyncEnabled: true,
              openPricesToken: 'tok_abc',
            ),
          );

      await Future<void>.delayed(const Duration(milliseconds: 200));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('notificationsEnabled'), false);
      expect(prefs.getInt('retentionDays'), 45);
      expect(prefs.getInt('expiringSoonDays'), 7);
      expect(prefs.getBool('inactivityReminderEnabled'), false);
      expect(prefs.getInt('inactivityThresholdDays'), 14);
      expect(prefs.getBool('amoledDarkMode'), true);
      expect(prefs.getBool('priceTrackingEnabled'), true);
      expect(prefs.getInt('priceRetentionDays'), 365);
      expect(prefs.getBool('pricesHidden'), true);
      expect(prefs.getString('baseCurrency'), 'BRL');
      expect(prefs.getBool('openPricesSyncEnabled'), true);
      expect(prefs.getString('openPricesToken'), 'tok_abc');

      container.dispose();
    });

    test('build returns a valid Settings object', () {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      final settings = container.read(settingsProvider);
      expect(settings, isA<Settings>());
      expect(settings.notificationsEnabled, isA<bool>());
      expect(settings.retentionDays, isA<int>());
      expect(settings.baseCurrency, isNotEmpty);
      container.dispose();
    });

    test('setUnitSystem updates state immediately', () {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      container
          .read(settingsProvider.notifier)
          .setUnitSystem(
            UnitSystem.imperial,
          );
      expect(container.read(settingsProvider).unitSystem, UnitSystem.imperial);
      container.dispose();
    });

    test('setUnitSystem persists to SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      container
          .read(settingsProvider.notifier)
          .setUnitSystem(
            UnitSystem.imperial,
          );

      await Future<void>.delayed(const Duration(milliseconds: 200));
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('unitSystem'), 'imperial');
      container.dispose();
    });

    test('setUnitSystemServingSize persists override', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      container
          .read(settingsProvider.notifier)
          .setUnitSystemServingSize(
            UnitSystem.imperial,
          );

      await Future<void>.delayed(const Duration(milliseconds: 200));
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('unitSystemServingSize'), 'imperial');
      container.dispose();
    });

    test('setUnitSystemServingSize clears override on null', () async {
      SharedPreferences.setMockInitialValues({
        'unitSystemServingSize': 'imperial',
      });
      final container = ProviderContainer();
      container.read(settingsProvider.notifier).setUnitSystemServingSize(null);

      await Future<void>.delayed(const Duration(milliseconds: 200));
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('unitSystemServingSize'), isFalse);
      container.dispose();
    });

    test('setUnitSystemRecipeIngredients persists override', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      container
          .read(settingsProvider.notifier)
          .setUnitSystemRecipeIngredients(
            UnitSystem.imperial,
          );

      await Future<void>.delayed(const Duration(milliseconds: 200));
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('unitSystemRecipeIngredients'), 'imperial');
      container.dispose();
    });

    test('setUnitSystemRecipeIngredients clears override on null', () async {
      SharedPreferences.setMockInitialValues({
        'unitSystemRecipeIngredients': 'imperial',
      });
      final container = ProviderContainer();
      container
          .read(settingsProvider.notifier)
          .setUnitSystemRecipeIngredients(null);

      await Future<void>.delayed(const Duration(milliseconds: 200));
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('unitSystemRecipeIngredients'), isFalse);
      container.dispose();
    });

    test('setUnitSystemInventory persists override', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      container
          .read(settingsProvider.notifier)
          .setUnitSystemInventory(
            UnitSystem.imperial,
          );

      await Future<void>.delayed(const Duration(milliseconds: 200));
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('unitSystemInventory'), 'imperial');
      container.dispose();
    });

    test('setUnitSystemInventory clears override on null', () async {
      SharedPreferences.setMockInitialValues({
        'unitSystemInventory': 'imperial',
      });
      final container = ProviderContainer();
      container.read(settingsProvider.notifier).setUnitSystemInventory(null);

      await Future<void>.delayed(const Duration(milliseconds: 200));
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('unitSystemInventory'), isFalse);
      container.dispose();
    });

    test('setPreferredWeightUnit persists', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      container
          .read(settingsProvider.notifier)
          .setPreferredWeightUnit(
            WeightUnitPreference.pounds,
          );

      await Future<void>.delayed(const Duration(milliseconds: 200));
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('preferredWeightUnit'), 'pounds');
      container.dispose();
    });

    test('setPreferredVolumeUnit persists', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      container
          .read(settingsProvider.notifier)
          .setPreferredVolumeUnit(
            VolumeUnitPreference.cups,
          );

      await Future<void>.delayed(const Duration(milliseconds: 200));
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('preferredVolumeUnit'), 'cups');
      container.dispose();
    });
  });
}
