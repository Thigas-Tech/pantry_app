import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/models/product_nutrient.dart';
import 'package:pantry_app/widgets/nutrition_table.dart';
import '../helpers/pump_app.dart';

void main() {
  group('NutritionTable', () {
    const product = Product(
      barcode: '123',
      name: 'Test',
      energyKcal: 200,
      proteinG: 10,
    );

    Widget wrap(Product p) => Scaffold(body: NutritionTable(product: p));

    testWidgets('shows the six core rows', (tester) async {
      await pumpApp(tester, wrap(product));
      expect(find.text('Energy'), findsOneWidget);
      expect(find.text('Protein'), findsOneWidget);
      expect(find.text('Carbs'), findsOneWidget);
      expect(find.text('Fat'), findsOneWidget);
      expect(find.text('Fiber'), findsOneWidget);
      expect(find.text('Salt'), findsOneWidget);
      expect(find.text('200.0 kcal'), findsOneWidget);
      expect(find.text('10.0 g'), findsOneWidget);
    });

    testWidgets('shows additional nutrients with their units', (tester) async {
      const p = Product(
        barcode: '123',
        name: 'Test',
        energyKcal: 200,
        additionalNutrients: [
          ProductNutrient(offTag: 'sugars', value: 5, unit: 'g'),
          ProductNutrient(offTag: 'vitamin-c', value: 20, unit: 'mg'),
        ],
      );
      await pumpApp(tester, wrap(p));
      expect(find.text('Sugars'), findsOneWidget);
      expect(find.text('5 g'), findsOneWidget);
      expect(find.text('Vitamin C'), findsOneWidget);
      expect(find.text('20 mg'), findsOneWidget);
    });

    testWidgets('hides additional nutrients when empty', (tester) async {
      await pumpApp(tester, wrap(product));
      expect(find.text('Sugars'), findsNothing);
      expect(find.text('Vitamin C'), findsNothing);
    });
  });
}
