import 'package:flutter/material.dart';
import 'package:pantry_app/services/produce_icon_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProduceIconService', () {
    test('returns icon for known produce name', () {
      expect(ProduceIconService.forName('apple'), Icons.apple);
    });

    test('returns fallback icon for unknown produce name', () {
      expect(ProduceIconService.forName('durian'), Icons.eco);
    });

    test('case insensitive lookup', () {
      expect(ProduceIconService.forName('APPLE'), Icons.apple);
      expect(ProduceIconService.forName('Apple'), Icons.apple);
    });

    test('trims whitespace', () {
      expect(ProduceIconService.forName('  apple  '), Icons.apple);
    });

    test('returns fallback for empty string', () {
      expect(ProduceIconService.forName(''), Icons.eco);
    });
  });
}
