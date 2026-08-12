import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/providers/theme_provider.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

/// A preferences store whose every operation throws, simulating a broken
/// platform channel.
class _ThrowingPrefsStore extends SharedPreferencesStorePlatform {
  @override
  bool get isMock => true;

  @override
  Future<bool> clear() => throw Exception('boom');

  @override
  Future<Map<String, Object>> getAll() => throw Exception('boom');

  @override
  Future<bool> remove(String key) => throw Exception('boom');

  @override
  Future<bool> setValue(String valueType, String key, Object value) =>
      throw Exception('boom');
}

void main() {
  test('logs a warning when the theme mode cannot be loaded', () async {
    SharedPreferencesStorePlatform.instance = _ThrowingPrefsStore();

    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(themeModeProvider.future);

    expect(
      recentLogs,
      contains('Failed to load theme mode from preferences'),
    );
    expect(container.read(themeModeProvider).value, ThemeModeOption.system);
  });

  test('logs a warning when the theme mode cannot be persisted', () async {
    SharedPreferencesStorePlatform.instance = _ThrowingPrefsStore();

    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(themeModeProvider.future);

    container
        .read(themeModeProvider.notifier)
        .setThemeMode(ThemeModeOption.dark);

    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(recentLogs, contains('Failed to persist theme mode dark'));
    expect(container.read(themeModeProvider).value, ThemeModeOption.dark);
  });

  test('loads the persisted theme mode', () async {
    SharedPreferences.setMockInitialValues({'theme_mode': 'dark'});

    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(themeModeProvider);
    await container.read(themeModeProvider.future);

    expect(container.read(themeModeProvider).value, ThemeModeOption.dark);
  });
}
