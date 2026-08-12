import 'dart:async';

import 'package:pantry_app/utils/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'theme_provider.g.dart';

/// The available theme modes for the app.
enum ThemeModeOption {
  /// Follow the system setting.
  system,

  /// Always use the light theme.
  light,

  /// Always use the dark theme.
  dark,
}

/// A notifier that holds the current [ThemeModeOption] and persists it to
/// [SharedPreferences] under the theme_mode key.
///
/// Loads the persisted mode in [build] so no placeholder value flashes.
/// Used by [themeModeProvider] so that any widget can read or change the
/// theme mode.
@Riverpod(keepAlive: true)
class ThemeModeNotifier extends _$ThemeModeNotifier {
  static const _key = 'theme_mode';

  @override
  Future<ThemeModeOption> build() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_key);
      if (stored != null) {
        return ThemeModeOption.values.firstWhere(
          (e) => e.name == stored,
          orElse: () => ThemeModeOption.system,
        );
      }
    } on Exception catch (e) {
      logWarning('Failed to load theme mode from preferences: $e');
    }
    return ThemeModeOption.system;
  }

  /// Updates the theme mode and persists the choice.
  void setThemeMode(ThemeModeOption mode) {
    state = AsyncValue.data(mode);
    unawaited(_persist(mode));
  }

  Future<void> _persist(ThemeModeOption mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, mode.name);
    } on Exception catch (e) {
      logWarning('Failed to persist theme mode ${mode.name}: $e');
    }
  }
}
