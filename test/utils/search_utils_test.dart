import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/models/recipe.dart';
import 'package:pantry_app/utils/search_utils.dart';

void main() {
  group('normalizeForSearch', () {
    test('returns empty string for empty input', () {
      expect(normalizeForSearch(''), '');
    });

    test('passes through plain ASCII unchanged', () {
      expect(normalizeForSearch('hello'), 'hello');
    });

    test('lowercases ASCII input', () {
      expect(normalizeForSearch('Hello World'), 'hello world');
    });

    test('strips acute accent from é', () {
      expect(normalizeForSearch('café'), 'cafe');
    });

    test('strips grave accent from è', () {
      expect(normalizeForSearch('crème'), 'creme');
    });

    test('strips umlaut from ü', () {
      expect(normalizeForSearch('Müsli'), 'musli');
    });

    test(
      'strips tilde from ñ',
      () => expect(normalizeForSearch('jalapeño'), 'jalapeno'),
    );

    test(
      'strips cedilla from ç',
      () => expect(normalizeForSearch('garçon'), 'garcon'),
    );

    test('handles ß (sharp s) correctly', () {
      expect(normalizeForSearch('Straße'), 'strase');
    });

    test('handles mixed input with multiple diacritics', () {
      expect(normalizeForSearch('Café crème'), 'cafe creme');
    });

    test('handles accented uppercase', () {
      expect(normalizeForSearch('CRÈME BRÛLÉE'), 'creme brulee');
    });

    test(
      'passes non-Latin characters through unchanged (except lowering)',
      () {
        // CJK, Cyrillic, and emoji.
        expect(normalizeForSearch('日本語'), '日本語');
        expect(normalizeForSearch('Привет'), 'привет');
        expect(normalizeForSearch('12 + 3 = 15'), '12 + 3 = 15');
      },
    );

    test('handles digits and barcodes', () {
      expect(normalizeForSearch('123456'), '123456');
    });

    test('strips multiple diacritics from a single character', () {
      expect(normalizeForSearch('français'), 'francais');
    });

    test('handles Latin Extended-A characters (Ą Č Ę Į Š Ų Ū Ž)', () {
      expect(normalizeForSearch('ĄČĘĮŠŲŪŽ'), 'aceisuuz');
      expect(normalizeForSearch('ąčęįšųūž'), 'aceisuuz');
    });

    test('handles å (angstrom / ring above) and ø (slashed o)', () {
      expect(normalizeForSearch('å'), 'a');
      expect(normalizeForSearch('ø'), 'o');
    });

    test('passes through punctuation and special chars', () {
      expect(normalizeForSearch(r'hello!@#$%^&*()'), r'hello!@#$%^&*()');
    });

    test('collapses multiple whitespace', () {
      expect(normalizeForSearch('a   b\tc\n\rd'), 'a b c d');
    });
  });

  group('buildSearchText', () {
    test('concatenates name, brand, barcode, and category', () {
      const p = Product(
        barcode: '12345',
        name: 'Café',
        brand: 'Nestlé',
        category: 'Snacks',
      );
      expect(buildSearchText(p), 'cafe nestle 12345 snacks');
    });

    test('handles missing optional fields', () {
      const p = Product(
        barcode: '12345',
        name: 'Café',
      );
      expect(buildSearchText(p), 'cafe 12345');
    });
  });

  group('buildRecipeSearchText', () {
    test('combines name and instructions with diacritics removed', () {
      const recipe = Recipe(
        name: 'Crème Brûlée',
        instructions: 'à la mode',
      );
      expect(buildRecipeSearchText(recipe), 'creme brulee a la mode');
    });

    test('returns only the name when instructions are empty', () {
      const recipe = Recipe(name: 'Test Recipe');
      expect(buildRecipeSearchText(recipe), 'test recipe');
    });

    test('lowercases and collapses whitespace', () {
      const recipe = Recipe(
        name: '  Café   CRÈME  ',
        instructions: '  ',
      );
      expect(buildRecipeSearchText(recipe), 'cafe creme');
    });

    test('matches the v30 migration composition', () {
      const recipe = Recipe(
        name: 'Crème Brûlée',
        instructions: 'à la mode',
      );
      expect(
        buildRecipeSearchText(recipe),
        normalizeForSearch('${recipe.name} ${recipe.instructions}'),
      );
    });
  });
}
