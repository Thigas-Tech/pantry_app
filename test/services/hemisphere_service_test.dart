import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/models/hemisphere.dart';
import 'package:pantry_app/services/hemisphere_service.dart';

void main() {
  group('HemisphereService.detectFromCountryCode', () {
    test('returns northern for US', () {
      expect(
        HemisphereService.detectFromCountryCode('US'),
        Hemisphere.northern,
      );
    });

    test('returns southern for BR', () {
      expect(
        HemisphereService.detectFromCountryCode('BR'),
        Hemisphere.southern,
      );
    });

    test('returns southern for AU', () {
      expect(
        HemisphereService.detectFromCountryCode('AU'),
        Hemisphere.southern,
      );
    });

    test('returns northern for unknown country', () {
      expect(
        HemisphereService.detectFromCountryCode('SG'),
        Hemisphere.northern,
      );
    });

    test('returns northern for null country code', () {
      expect(
        HemisphereService.detectFromCountryCode(null),
        Hemisphere.northern,
      );
    });

    test('returns northern for empty country code', () {
      expect(
        HemisphereService.detectFromCountryCode(''),
        Hemisphere.northern,
      );
    });
  });

  group('HemisphereService.resolveEffectiveHemisphere', () {
    test('returns detected hemisphere when override is auto', () {
      final result = HemisphereService.resolveEffectiveHemisphere(
        Hemisphere.auto,
        'BR',
      );
      expect(result, Hemisphere.southern);
    });

    test('returns override when override is northern', () {
      final result = HemisphereService.resolveEffectiveHemisphere(
        Hemisphere.northern,
        'BR',
      );
      expect(result, Hemisphere.northern);
    });

    test('returns southern override regardless of country', () {
      final result = HemisphereService.resolveEffectiveHemisphere(
        Hemisphere.southern,
        'US',
      );
      expect(result, Hemisphere.southern);
    });
  });

  test('southernCountries has expected entries', () {
    const countries = HemisphereService.southernCountries;
    expect(countries, contains('BR'));
    expect(countries, contains('AU'));
    expect(countries, contains('NZ'));
    expect(countries, contains('AR'));
    expect(countries, contains('ZA'));
    expect(countries, contains('CL'));
    expect(countries, contains('UY'));
    expect(countries, contains('PY'));
    expect(countries, contains('PE'));
    expect(countries, contains('BO'));
    expect(countries, contains('EC'));
    expect(countries, contains('NA'));
    expect(countries, contains('BW'));
    expect(countries, contains('MZ'));
    expect(countries, contains('AO'));
    expect(countries, contains('ID'));
    expect(countries, contains('PG'));
    expect(countries, contains('TL'));
    expect(countries, contains('LS'));
    expect(countries, contains('MG'));
    expect(countries, contains('MW'));
    expect(countries, contains('SZ'));
    expect(countries, contains('ZM'));
    expect(countries, contains('ZW'));
  });
}
