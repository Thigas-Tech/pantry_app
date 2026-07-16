/// Tests for [ProduceCategoryMapper].
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/services/produce_category_mapper.dart';

void main() {
  group('forName', () {
    test('returns "Fruit" for apple', () {
      expect(ProduceCategoryMapper.forName('Apple'), 'Fruit');
    });

    test('returns "Vegetables" for broccoli', () {
      expect(ProduceCategoryMapper.forName('Broccoli'), 'Vegetables');
    });

    test('returns "Nuts and their products" for almond', () {
      expect(
        ProduceCategoryMapper.forName('Almond'),
        'Nuts and their products',
      );
    });

    test('returns "Spices and herbs" for basil', () {
      expect(ProduceCategoryMapper.forName('Basil'), 'Spices and herbs');
    });

    test('returns "Legumes and their products" for chickpea', () {
      expect(
        ProduceCategoryMapper.forName('Chickpea'),
        'Legumes and their products',
      );
    });

    test('is case insensitive', () {
      expect(ProduceCategoryMapper.forName('BANANA'), 'Fruit');
    });

    test('strips organic prefix', () {
      expect(
        ProduceCategoryMapper.forName('Organic Apple'),
        'Fruit',
      );
    });

    test('fallback for unknown produce', () {
      expect(
        ProduceCategoryMapper.forName('UnknownFruit123'),
        'Fruits and vegetables based foods',
      );
    });

    test('returns null for empty name', () {
      expect(ProduceCategoryMapper.forName(''), isNull);
    });
  });
}
