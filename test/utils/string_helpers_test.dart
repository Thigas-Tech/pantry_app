import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/utils/string_helpers.dart';

void main() {
  group('removeDiacritics', () {
    test('returns empty string for empty input', () {
      expect(removeDiacritics(''), '');
    });

    test('passes through plain ASCII unchanged', () {
      expect(removeDiacritics('hello'), 'hello');
    });

    test('lowercases ASCII input', () {
      expect(removeDiacritics('Hello World'), 'hello world');
    });

    test('strips acute accent from é', () {
      expect(removeDiacritics('café'), 'cafe');
    });

    test('strips grave accent from è', () {
      expect(removeDiacritics('crème'), 'creme');
    });

    test('strips umlaut from ü', () {
      expect(removeDiacritics('Müsli'), 'musli');
    });

    test(
      'strips tilde from ñ',
      () => expect(removeDiacritics('jalapeño'), 'jalapeno'),
    );

    test(
      'strips cedilla from ç',
      () => expect(removeDiacritics('garçon'), 'garcon'),
    );

    test('handles ß (sharp s) correctly', () {
      expect(removeDiacritics('Straße'), 'strase');
    });

    test('handles mixed input with multiple diacritics', () {
      expect(removeDiacritics('Café crème'), 'cafe creme');
    });

    test('handles accented uppercase', () {
      expect(removeDiacritics('CRÈME BRÛLÉE'), 'creme brulee');
    });

    test('passes non-Latin characters through unchanged', () {
      // CJK, Cyrillic, and emoji should not be affected.
      expect(removeDiacritics('日本語'), '日本語');
      expect(removeDiacritics('Привет'), 'привет');
      expect(removeDiacritics('12 + 3 = 15'), '12 + 3 = 15');
    });

    test('handles digits and barcodes', () {
      expect(removeDiacritics('123456'), '123456');
    });

    test('strips multiple diacritics from a single character', () {
      // Combining circumflex, caron, etc.
      expect(removeDiacritics('français'), 'francais');
    });

    test('handles Latin Extended-A characters (Ą Č Ę Į Š Ų Ū Ž)', () {
      expect(removeDiacritics('ĄČĘĮŠŲŪŽ'), 'aceisuuz');
      expect(removeDiacritics('ąčęįšųūž'), 'aceisuuz');
    });

    test('handles å (angstrom / ring above) and ø (slashed o)', () {
      expect(removeDiacritics('å'), 'a');
      expect(removeDiacritics('ø'), 'o');
    });

    test('passes through punctuation and special chars', () {
      expect(removeDiacritics(r'hello!@#$%^&*()'), r'hello!@#$%^&*()');
    });
  });

  group('equalsIgnoreCaseAndDiacritics', () {
    test('returns true for identical ASCII strings', () {
      expect(equalsIgnoreCaseAndDiacritics('hello', 'hello'), isTrue);
    });

    test('returns true ignoring case', () {
      expect(equalsIgnoreCaseAndDiacritics('Hello', 'hello'), isTrue);
    });

    test('returns true ignoring diacritics', () {
      expect(equalsIgnoreCaseAndDiacritics('Café', 'cafe'), isTrue);
    });

    test('returns true for both case and diacritics differences', () {
      expect(equalsIgnoreCaseAndDiacritics('Müsli', 'MUSLI'), isTrue);
    });

    test('returns false for different strings', () {
      expect(equalsIgnoreCaseAndDiacritics('apple', 'banana'), isFalse);
    });

    test('returns false when diacritics map to different base', () {
      expect(equalsIgnoreCaseAndDiacritics('ñ', 'n'), isTrue);
      expect(equalsIgnoreCaseAndDiacritics('ñ', 'm'), isFalse);
    });
  });
}
