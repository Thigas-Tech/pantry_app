import 'dart:async';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The available theme modes for the app.
enum ThemeModeOption {
  /// Follow the system setting.
  system,

  /// Always use the light theme.
  light,

  /// Always use the dark theme.
  dark,
}

/// A [Notifier] that holds the current `ThemeModeOption` and persists it to
/// [SharedPreferences] under the `theme_mode` key.
///
/// Used by [themeModeProvider] so that any widget can read or change the
/// theme mode.
class ThemeModeNotifier extends Notifier<ThemeModeOption> {
  static const _key = 'theme_mode';

  @override
  ThemeModeOption build() {
    unawaited(_loadFromPrefs());
    return ThemeModeOption.system;
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_key);
      if (stored != null) {
        state = ThemeModeOption.values.firstWhere(
          (e) => e.name == stored,
          orElse: () => ThemeModeOption.system,
        );
      }
    } on Exception catch (_) {}
  }

  /// The current theme mode.
  ThemeModeOption get value => state;

  /// Updates the theme mode and persists the choice.
  set value(ThemeModeOption mode) {
    state = mode;
    unawaited(_persist(mode));
  }

  Future<void> _persist(ThemeModeOption mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, mode.name);
    } on Exception catch (_) {}
  }
}

/// A [NotifierProvider] for [ThemeModeNotifier].
///
/// Changing the value triggers a rebuild of the [DynamicColorBuilder] and
/// the widget tree, switching between light, dark, and system themes.
final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeModeOption>(
  ThemeModeNotifier.new,
);
