import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show Locale;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'current_locale_provider.g.dart';

/// Provides the current platform locale (from the dart:ui dispatcher).
///
/// keepAlive because the locale rarely changes during a session and is
/// needed by non-widget code (such as the stats provider) that cannot
/// read the resolved app locale from the widget tree. Tests can override
/// this provider to simulate a device language.
@Riverpod(keepAlive: true)
Locale currentLocale(Ref ref) {
  return PlatformDispatcher.instance.locale;
}
