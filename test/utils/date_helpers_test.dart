import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/utils/date_helpers.dart';

void main() {
  group('parseExpiryDate', () {
    test('returns null for null input', () {
      expect(parseExpiryDate(null), null);
    });

    test('returns null for empty string', () {
      expect(parseExpiryDate(''), null);
    });

    test('parses valid ISO date', () {
      final date = parseExpiryDate('2026-07-15');
      expect(date, isNotNull);
      expect(date!.year, 2026);
      expect(date.month, 7);
      expect(date.day, 15);
    });

    test('returns null for invalid date string', () {
      expect(parseExpiryDate('not-a-date'), null);
    });
  });

  group('isExpired', () {
    test('returns false for null', () {
      expect(isExpired(null), false);
    });

    test('returns false for empty string', () {
      expect(isExpired(''), false);
    });

    test('returns true for a date in the past', () {
      expect(isExpired('2020-01-01'), true);
    });

    test('returns false for a date far in the future', () {
      expect(isExpired('2099-12-31'), false);
    });
  });

  group('isExpiringSoon', () {
    test('returns false for null', () {
      expect(isExpiringSoon(null, 3), false);
    });

    test('returns false for empty string', () {
      expect(isExpiringSoon('', 3), false);
    });

    test('returns false for an already expired date', () {
      expect(isExpiringSoon('2020-01-01', 3), false);
    });

    test('returns false for a date far in the future', () {
      expect(isExpiringSoon('2099-12-31', 3), false);
    });

    test('returns true for tomorrow (within 3 days)', () {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final dateStr =
          '${tomorrow.year}-'
          '${tomorrow.month.toString().padLeft(2, '0')}-'
          '${tomorrow.day.toString().padLeft(2, '0')}';
      expect(isExpiringSoon(dateStr, 3), true);
    });
  });
}
