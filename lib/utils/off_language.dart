import 'package:flutter/widgets.dart' show Locale;

/// Returns the two-letter language code that should be sent to the Open
/// Food Facts API for the given device locale.
///
/// Open Food Facts serves product data in many languages, so the device
/// language is passed through as-is (`fr` stays `fr`, `es` stays `es`).
/// Two normalizations are applied:
///
/// - `pt_BR` maps to `pt`, because Open Food Facts has no Brazilian
///   Portuguese variant and only understands the `pt` tag.
/// - An empty or `und` language code maps to `en` as a safe fallback.
String offLanguageFromLocale(Locale locale) {
  final code = locale.languageCode;
  if (code.isEmpty || code == 'und') return 'en';
  if (code == 'pt') return 'pt';
  return code;
}
