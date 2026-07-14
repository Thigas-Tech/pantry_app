import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/l10n/app_localizations.dart';
import 'package:pantry_app/l10n/l10n_extensions.dart';

void main() {
  group('formatQuantityUnit', () {
    late AppLocalizations l10n;

    setUpAll(() async {
      l10n = await AppLocalizations.delegate.load(const Locale('en'));
    });

    test('singular: 1 piece displays as "1 unit"', () {
      expect(l10n.formatQuantityUnit(1, 'pieces'), '1 unit');
    });

    test('plural: 5 pieces displays as "5 units"', () {
      expect(l10n.formatQuantityUnit(5, 'pieces'), '5 units');
    });

    test('zero is plural: 0 pieces displays as "0 units"', () {
      expect(l10n.formatQuantityUnit(0, 'pieces'), '0 units');
    });

    test('grams unit unchanged: 1 g displays as "1 g"', () {
      expect(l10n.formatQuantityUnit(1, 'g'), '1 g');
    });

    test('kg unit unchanged', () {
      expect(l10n.formatQuantityUnit(3, 'kg'), '3 kg');
    });

    test('null quantity returns empty', () {
      expect(l10n.formatQuantityUnit(null, 'pieces'), '');
    });

    test('null unit returns empty', () {
      expect(l10n.formatQuantityUnit(1, null), '');
    });
  });

  group('localizeUnit', () {
    late AppLocalizations l10n;

    setUpAll(() async {
      l10n = await AppLocalizations.delegate.load(const Locale('en'));
    });

    test('pieces maps to unitSingular', () {
      expect(l10n.localizeUnit('pieces'), 'unit');
    });

    test('g maps to g', () {
      expect(l10n.localizeUnit('g'), 'g');
    });

    test('medium apple falls through as-is', () {
      expect(l10n.localizeUnit('medium apple'), 'medium apple');
    });
  });
}
