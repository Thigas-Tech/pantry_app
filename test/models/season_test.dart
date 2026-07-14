import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/models/hemisphere.dart';
import 'package:pantry_app/models/season.dart';

void main() {
  group('Season.current', () {
    test('northern summer in July', () {
      final date = DateTime(2024, 7, 15);
      expect(Season.current(date, Hemisphere.northern), Season.summer);
    });

    test('northern winter in January', () {
      final date = DateTime(2024, 1, 15);
      expect(Season.current(date, Hemisphere.northern), Season.winter);
    });

    test('northern spring on March 1 (boundary)', () {
      final date = DateTime(2024, 3, 1);
      expect(Season.current(date, Hemisphere.northern), Season.spring);
    });

    test('northern autumn on September 1 (boundary)', () {
      final date = DateTime(2024, 9, 1);
      expect(Season.current(date, Hemisphere.northern), Season.autumn);
    });

    test('May 31 is still northern spring', () {
      final date = DateTime(2024, 5, 31);
      expect(Season.current(date, Hemisphere.northern), Season.spring);
    });

    test('June 1 is northern summer', () {
      final date = DateTime(2024, 6, 1);
      expect(Season.current(date, Hemisphere.northern), Season.summer);
    });

    test('November 30 is northern autumn', () {
      final date = DateTime(2024, 11, 30);
      expect(Season.current(date, Hemisphere.northern), Season.autumn);
    });

    test('December 1 is northern winter', () {
      final date = DateTime(2024, 12, 1);
      expect(Season.current(date, Hemisphere.northern), Season.winter);
    });

    test('February 28 is northern winter', () {
      final date = DateTime(2024, 2, 28);
      expect(Season.current(date, Hemisphere.northern), Season.winter);
    });

    test('southern summer in January', () {
      final date = DateTime(2024, 1, 15);
      expect(Season.current(date, Hemisphere.southern), Season.summer);
    });

    test('southern winter in July', () {
      final date = DateTime(2024, 7, 15);
      expect(Season.current(date, Hemisphere.southern), Season.winter);
    });

    test('southern spring in September (boundary)', () {
      final date = DateTime(2024, 9, 1);
      expect(Season.current(date, Hemisphere.southern), Season.spring);
    });

    test('southern autumn in March (boundary)', () {
      final date = DateTime(2024, 3, 1);
      expect(Season.current(date, Hemisphere.southern), Season.autumn);
    });
  });
}
