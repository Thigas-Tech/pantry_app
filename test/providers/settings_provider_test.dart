import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/providers/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    dotenv.loadFromString(isOptional: true, mergeWith: {});
  });

  group('Settings', () {
    test('copyWith preserves unchanged fields', () {
      const original = Settings(notificationsEnabled: true);
      final copy = original.copyWith(notificationsEnabled: false);
      expect(copy.notificationsEnabled, false);
      expect(copy.retentionDays, original.retentionDays);
    });

    test('copyWith changes multiple fields', () {
      const original = Settings(notificationsEnabled: true, retentionDays: 60);
      final copy = original.copyWith(
        notificationsEnabled: false,
        retentionDays: 30,
      );
      expect(copy.notificationsEnabled, false);
      expect(copy.retentionDays, 30);
    });
  });

  group('SettingsNotifier', () {
    test('value setter updates state immediately', () {
      final container = ProviderContainer();
      final notifier = container.read(settingsProvider.notifier);

      notifier.value = const Settings(notificationsEnabled: false);
      expect(container.read(settingsProvider).notificationsEnabled, false);

      container.dispose();
    });

    test('value setter persists to SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      final notifier = container.read(settingsProvider.notifier);

      notifier.value = const Settings(
        notificationsEnabled: false,
        retentionDays: 90,
        amoledDarkMode: true,
        baseCurrency: 'EUR',
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
      final notifier = container.read(settingsProvider.notifier);

      notifier.value = const Settings(
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
      final container = ProviderContainer();
      final settings = container.read(settingsProvider);
      expect(settings, isA<Settings>());
      expect(settings.notificationsEnabled, isA<bool>());
      expect(settings.retentionDays, isA<int>());
      expect(settings.baseCurrency, isNotEmpty);
      container.dispose();
    });
  });
}
