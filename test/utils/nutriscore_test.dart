/// @file Nutri-Score utility unit tests.
///
/// Tests for the pure functions in
/// [package:pantry_app/utils/nutriscore.dart].
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/utils/nutriscore.dart';

void main() {
  group('nutriscoreGradeToNumeric', () {
    test('a -> 5', () {
      expect(nutriscoreGradeToNumeric('a'), 5);
    });

    test('b -> 4', () {
      expect(nutriscoreGradeToNumeric('b'), 4);
    });

    test('c -> 3', () {
      expect(nutriscoreGradeToNumeric('c'), 3);
    });

    test('d -> 2', () {
      expect(nutriscoreGradeToNumeric('d'), 2);
    });

    test('e -> 1', () {
      expect(nutriscoreGradeToNumeric('e'), 1);
    });

    test('null grade returns null', () {
      expect(nutriscoreGradeToNumeric(null), isNull);
    });

    test('not-applicable returns null', () {
      expect(nutriscoreGradeToNumeric('not-applicable'), isNull);
    });

    test('invalid grade returns null', () {
      expect(nutriscoreGradeToNumeric('x'), isNull);
    });

    test('case insensitive', () {
      expect(nutriscoreGradeToNumeric('A'), 5);
      expect(nutriscoreGradeToNumeric('B'), 4);
    });
  });

  group('nutriscoreNumericToGrade', () {
    test('5 -> a', () {
      expect(nutriscoreNumericToGrade(5), 'a');
    });

    test('4 -> b', () {
      expect(nutriscoreNumericToGrade(4), 'b');
    });

    test('3 -> c', () {
      expect(nutriscoreNumericToGrade(3), 'c');
    });

    test('2 -> d', () {
      expect(nutriscoreNumericToGrade(2), 'd');
    });

    test('1 -> e', () {
      expect(nutriscoreNumericToGrade(1), 'e');
    });

    test('out of range returns null', () {
      expect(nutriscoreNumericToGrade(0), isNull);
      expect(nutriscoreNumericToGrade(6), isNull);
    });
  });

  group('nutriscoreNumericToLetter', () {
    test('5 -> A', () {
      expect(nutriscoreNumericToLetter(5), 'A');
    });

    test('4 -> B', () {
      expect(nutriscoreNumericToLetter(4), 'B');
    });

    test('3 -> C', () {
      expect(nutriscoreNumericToLetter(3), 'C');
    });

    test('2 -> D', () {
      expect(nutriscoreNumericToLetter(2), 'D');
    });

    test('1 -> E', () {
      expect(nutriscoreNumericToLetter(1), 'E');
    });

    test('4.2 rounds to 4 -> B', () {
      expect(nutriscoreNumericToLetter(4.2), 'B');
    });

    test('3.6 rounds to 4 -> B', () {
      expect(nutriscoreNumericToLetter(3.6), 'B');
    });

    test('3.4 rounds to 3 -> C', () {
      expect(nutriscoreNumericToLetter(3.4), 'C');
    });

    test('values outside [1,5] clamp to range', () {
      expect(nutriscoreNumericToLetter(0.5), 'E');
      expect(nutriscoreNumericToLetter(5.5), 'A');
    });
  });

  group('nutriscoreColorForGrade', () {
    test('a returns canonical dark green', () {
      expect(nutriscoreColorForGrade('a'), const Color(0xFF038141));
    });

    test('b returns canonical light green', () {
      expect(nutriscoreColorForGrade('b'), const Color(0xFF85BB2F));
    });

    test('c returns canonical yellow', () {
      expect(nutriscoreColorForGrade('c'), const Color(0xFFFECB02));
    });

    test('d returns canonical orange', () {
      expect(nutriscoreColorForGrade('d'), const Color(0xFFEE8200));
    });

    test('e returns canonical red', () {
      expect(nutriscoreColorForGrade('e'), const Color(0xFFE73F0B));
    });

    test('null grade returns null', () {
      expect(nutriscoreColorForGrade(null), isNull);
    });

    test('invalid grade returns null', () {
      expect(nutriscoreColorForGrade('x'), isNull);
    });
  });

  group('nutriscoreColorForNumeric', () {
    test('5 -> A color', () {
      expect(nutriscoreColorForNumeric(5), const Color(0xFF038141));
    });

    test('4 -> B color', () {
      expect(nutriscoreColorForNumeric(4), const Color(0xFF85BB2F));
    });

    test('3 -> C color', () {
      expect(nutriscoreColorForNumeric(3), const Color(0xFFFECB02));
    });

    test('2 -> D color', () {
      expect(nutriscoreColorForNumeric(2), const Color(0xFFEE8200));
    });

    test('1 -> E color', () {
      expect(nutriscoreColorForNumeric(1), const Color(0xFFE73F0B));
    });

    test('4.2 rounds to 4 -> B color', () {
      expect(nutriscoreColorForNumeric(4.2), const Color(0xFF85BB2F));
    });

    test('clamps out-of-range values', () {
      expect(nutriscoreColorForNumeric(0.5), const Color(0xFFE73F0B));
      expect(nutriscoreColorForNumeric(5.5), const Color(0xFF038141));
    });
  });

  group('nutriscoreIsNotApplicable', () {
    test('not-applicable returns true', () {
      expect(nutriscoreIsNotApplicable('not-applicable'), isTrue);
    });

    test('case insensitive', () {
      expect(nutriscoreIsNotApplicable('Not-Applicable'), isTrue);
    });

    test('valid grade returns false', () {
      expect(nutriscoreIsNotApplicable('a'), isFalse);
    });

    test('null returns false', () {
      expect(nutriscoreIsNotApplicable(null), isFalse);
    });
  });
}
