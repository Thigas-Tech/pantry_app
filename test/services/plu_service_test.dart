import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/services/plu_service.dart';

void main() {
  group('PluService', () {
    late PluService service;

    setUp(() {
      service = const PluService();
    });

    group('lookup', () {
      test('returns Banana for PLU code 4011', () {
        final result = service.lookup('4011');
        expect(result, isNotNull);
        expect(result!.code, '4011');
        expect(result.name, 'Banana');
        expect(result.category, 'Fruits');
      });

      test('returns Apple for PLU code 4032', () {
        final result = service.lookup('4032');
        expect(result, isNotNull);
        expect(result!.name, 'Apple');
      });

      test('returns null for invalid PLU code', () {
        final result = service.lookup('99999');
        expect(result, isNull);
      });

      test('strips leading zeros from PLU code', () {
        final result = service.lookup('0004011');
        expect(result, isNotNull);
        expect(result!.code, '4011');
        expect(result.name, 'Banana');
      });

      test('handles organic PLU code (prefix 9)', () {
        final result = service.lookup('94011');
        expect(result, isNotNull);
        expect(result!.code, '94011');
        expect(result.name, 'Organic Banana');
      });

      test('handles empty code', () {
        final result = service.lookup('');
        expect(result, isNull);
      });
    });

    group('search', () {
      test('matches by name (case insensitive)', () {
        final results = service.search('apple');
        expect(results, isNotEmpty);
        expect(results.any((r) => r.name == 'Apple'), isTrue);
      });

      test('matches by partial name', () {
        final results = service.search('tom');
        expect(results, isNotEmpty);
        expect(results.any((r) => r.name == 'Tomato'), isTrue);
      });

      test('returns empty for no match', () {
        final results = service.search('gala');
        expect(results, isEmpty);
      });

      test('matches by category', () {
        final results = service.search('fruit');
        expect(results, isNotEmpty);
        expect(results.any((r) => r.category == 'Fruits'), isTrue);
      });
    });

    group('lookupByStrippedCode', () {
      test('both 4-digit and organic 5-digit map to same base', () {
        final standard = service.lookup('4011');
        final organic = service.lookup('94011');
        expect(standard, isNotNull);
        expect(organic, isNotNull);
        expect(standard!.name, 'Banana');
        expect(organic!.name, 'Organic Banana');
      });
    });
  });
}
