import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The available theme modes for the app.
enum ThemeModeOption {
  /// Follow the system setting.
  system,

  /// Always use the light theme.
  light,

  /// Always use the dark theme.
  dark,
}

/// A [Notifier] that holds the current `ThemeModeOption`.
///
/// Used by [themeModeProvider] so that any widget can read or change the
/// theme mode.
class ThemeModeNotifier extends Notifier<ThemeModeOption> {
  @override
  ThemeModeOption build() => ThemeModeOption.system;

  /// The current theme mode.
  ThemeModeOption get value => state;

  /// Updates the theme mode.
  set value(ThemeModeOption mode) => state = mode;
}

/// A [NotifierProvider] for [ThemeModeNotifier].
///
/// Changing the value triggers a rebuild of the [DynamicColorBuilder] and
/// the widget tree, switching between light, dark, and system themes.
final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeModeOption>(
  ThemeModeNotifier.new,
);
