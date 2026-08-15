import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/utils/off_language.dart';

void main() {
  group('offLanguageFromLocale', () {
    test('returns en for English locale', () {
      expect(offLanguageFromLocale(const Locale('en')), 'en');
    });

    test('returns pt for Portuguese locale', () {
      expect(offLanguageFromLocale(const Locale('pt')), 'pt');
    });

    test('normalizes pt_BR to pt', () {
      expect(offLanguageFromLocale(const Locale('pt', 'BR')), 'pt');
    });

    test('passes through French locale', () {
      expect(offLanguageFromLocale(const Locale('fr')), 'fr');
    });

    test('passes through Spanish locale', () {
      expect(offLanguageFromLocale(const Locale('es')), 'es');
    });

    test('passes through German locale', () {
      expect(offLanguageFromLocale(const Locale('de')), 'de');
    });

    test('falls back to en for und locale', () {
      expect(offLanguageFromLocale(const Locale('und')), 'en');
    });

    test('falls back to en for a locale with only a script code', () {
      const locale = Locale.fromSubtags(scriptCode: 'Latn');
      expect(offLanguageFromLocale(locale), 'en');
    });
  });
}
