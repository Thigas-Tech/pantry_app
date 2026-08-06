/// @file ARB locale integrity tests.
///
/// Asserts that the three ARB locale files stay in sync with the English
/// template: every locale has the same translation keys, every value is a
/// non-empty string, and every metadata block present in the template also
/// exists in the other locales.
///
/// gen-l10n silently falls back to the template language for keys a locale
/// is missing, so without this test a missing Portuguese translation would
/// only ever display English text. Making the drift a hard failure keeps
/// the app fully localized.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const localeFiles = <String, String>{
    'en': 'lib/l10n/app_en.arb',
    'pt': 'lib/l10n/app_pt.arb',
    'pt_BR': 'lib/l10n/app_pt_BR.arb',
  };

  Map<String, Object?> loadArb(String path) =>
      jsonDecode(File(path).readAsStringSync()) as Map<String, Object?>;

  Map<String, String> translationKeys(Map<String, Object?> arb) {
    final result = <String, String>{};
    for (final entry in arb.entries) {
      if (entry.key.startsWith('@')) continue;
      final value = entry.value;
      if (value is String) result[entry.key] = value;
    }
    return result;
  }

  Map<String, Object?> metadataKeys(Map<String, Object?> arb) => {
    for (final entry in arb.entries)
      if (entry.key.startsWith('@') && !entry.key.startsWith('@@'))
        entry.key: entry.value,
  };

  final arbByLocale = {
    for (final entry in localeFiles.entries) entry.key: loadArb(entry.value),
  };

  group('ARB files stay in sync', () {
    test('every locale has the same translation keys as en', () {
      final enKeys = translationKeys(arbByLocale['en']!).keys.toSet();
      for (final entry in localeFiles.entries) {
        final localeKeys = translationKeys(
          arbByLocale[entry.key]!,
        ).keys.toSet();
        expect(
          localeKeys,
          enKeys,
          reason: '${entry.key} translation keys differ from en',
        );
      }
    });

    test('every translation value is a non-empty string', () {
      for (final entry in localeFiles.entries) {
        for (final value in translationKeys(arbByLocale[entry.key]!).values) {
          expect(
            value.trim(),
            isNotEmpty,
            reason: '${entry.key} contains an empty translation',
          );
        }
      }
    });

    test('every metadata block in en exists in pt and pt_BR', () {
      final enMeta = metadataKeys(arbByLocale['en']!);
      for (final entry in localeFiles.entries) {
        if (entry.key == 'en') continue;
        final localeMeta = metadataKeys(arbByLocale[entry.key]!);
        for (final key in enMeta.keys) {
          expect(
            localeMeta.containsKey(key),
            isTrue,
            reason: '${entry.key} is missing the $key metadata block',
          );
        }
      }
    });
  });
}
