import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/models/produce_quick_add_item.dart';

void main() {
  group('ProduceQuickAddItem', () {
    test('equality by field', () {
      const a = ProduceQuickAddItem(
        name: 'apple',
        displayName: 'Apple',
        icon: Icons.apple,
        weightHintG: 182,
        source: ProduceItemSource.personalized,
      );
      const b = ProduceQuickAddItem(
        name: 'apple',
        displayName: 'Apple',
        icon: Icons.apple,
        weightHintG: 182,
        source: ProduceItemSource.personalized,
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('inequality by name', () {
      const a = ProduceQuickAddItem(
        name: 'apple',
        displayName: 'Apple',
        icon: Icons.apple,
        source: ProduceItemSource.seasonal,
      );
      const b = ProduceQuickAddItem(
        name: 'banana',
        displayName: 'Banana',
        icon: Icons.eco,
        source: ProduceItemSource.seasonal,
      );
      expect(a, isNot(b));
    });

    test('weightHintG is optional (null)', () {
      const item = ProduceQuickAddItem(
        name: 'carrot',
        displayName: 'Carrot',
        icon: Icons.eco,
        source: ProduceItemSource.fallback,
      );
      expect(item.weightHintG, isNull);
    });
  });
}
