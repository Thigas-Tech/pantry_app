import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Returns the asset path for the changelog file for the given [locale].
///
/// Locales without a dedicated translation file fall back to English.
String changelogAssetPath(Locale locale) {
  if (locale.languageCode == 'en') {
    return 'USER_CHANGELOG.md';
  }

  final country = locale.countryCode;
  final localeTag = (country != null && country.isNotEmpty)
      ? '${locale.languageCode}_$country'
      : locale.languageCode;

  return 'USER_CHANGELOG_$localeTag.md';
}

/// Loads the localized `USER_CHANGELOG.md` content for the given [locale].
///
/// Falls back to English if a translation file is not available or cannot be
/// loaded.
Future<String> loadLocalizedChangelog(Locale locale) async {
  final path = changelogAssetPath(locale);

  try {
    return await rootBundle.loadString(path);
  } on Object catch (_) {
    return rootBundle.loadString('USER_CHANGELOG.md');
  }
}
