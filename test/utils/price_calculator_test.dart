import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/utils/price_calculator.dart';

void main() {
  group('scaledIngredientCost', () {
    test('scales a piece count by package size (2 eggs from a 12-pack)', () {
      final cost = PriceCalculator.scaledIngredientCost(
        price: 9.99,
        ingredientQuantity: 2,
        ingredientUnit: 'pieces',
        packageQuantity: 12,
        packageUnit: 'pieces',
      );
      expect(cost, closeTo(1.67, 0.001));
    });

    test('scales a volume from ml to L package (250 ml from 1 L)', () {
      final cost = PriceCalculator.scaledIngredientCost(
        price: 5,
        ingredientQuantity: 250,
        ingredientUnit: 'ml',
        packageQuantity: 1,
        packageUnit: 'L',
      );
      expect(cost, closeTo(1.25, 0.001));
    });

    test('scales a weight from g to kg package (500 g from 1 kg)', () {
      final cost = PriceCalculator.scaledIngredientCost(
        price: 8,
        ingredientQuantity: 500,
        ingredientUnit: 'g',
        packageQuantity: 1,
        packageUnit: 'kg',
      );
      expect(cost, closeTo(4.0, 0.001));
    });

    test('converts mixed compatible units (1.5 kg ingredient, 500 g pack)', () {
      final cost = PriceCalculator.scaledIngredientCost(
        price: 10,
        ingredientQuantity: 1.5,
        ingredientUnit: 'kg',
        packageQuantity: 500,
        packageUnit: 'g',
      );
      expect(cost, closeTo(30.0, 0.001));
    });

    test('returns 0.0 when the ingredient quantity is zero', () {
      final cost = PriceCalculator.scaledIngredientCost(
        price: 9.99,
        ingredientQuantity: 0,
        ingredientUnit: 'pieces',
        packageQuantity: 12,
        packageUnit: 'pieces',
      );
      expect(cost, 0.0);
    });

    test('returns null when packageQuantity is missing', () {
      final cost = PriceCalculator.scaledIngredientCost(
        price: 9.99,
        ingredientQuantity: 2,
        ingredientUnit: 'pieces',
        packageUnit: 'pieces',
      );
      expect(cost, isNull);
    });

    test('returns null when packageQuantity is zero', () {
      final cost = PriceCalculator.scaledIngredientCost(
        price: 9.99,
        ingredientQuantity: 2,
        ingredientUnit: 'pieces',
        packageQuantity: 0,
        packageUnit: 'pieces',
      );
      expect(cost, isNull);
    });

    test('returns null when packageQuantity is negative', () {
      final cost = PriceCalculator.scaledIngredientCost(
        price: 9.99,
        ingredientQuantity: 2,
        ingredientUnit: 'pieces',
        packageQuantity: -3,
        packageUnit: 'pieces',
      );
      expect(cost, isNull);
    });

    test('returns null when packageQuantity is not finite', () {
      final cost = PriceCalculator.scaledIngredientCost(
        price: 9.99,
        ingredientQuantity: 2,
        ingredientUnit: 'pieces',
        packageQuantity: double.infinity,
        packageUnit: 'pieces',
      );
      expect(cost, isNull);
    });

    test('returns null when packageUnit is missing', () {
      final cost = PriceCalculator.scaledIngredientCost(
        price: 9.99,
        ingredientQuantity: 2,
        ingredientUnit: 'pieces',
        packageQuantity: 12,
      );
      expect(cost, isNull);
    });

    test('returns null when units are incompatible (g vs pieces)', () {
      final cost = PriceCalculator.scaledIngredientCost(
        price: 9.99,
        ingredientQuantity: 2,
        ingredientUnit: 'pieces',
        packageQuantity: 500,
        packageUnit: 'g',
      );
      expect(cost, isNull);
    });

    test('returns null when the price is not finite', () {
      final cost = PriceCalculator.scaledIngredientCost(
        price: double.nan,
        ingredientQuantity: 2,
        ingredientUnit: 'pieces',
        packageQuantity: 12,
        packageUnit: 'pieces',
      );
      expect(cost, isNull);
    });

    test('returns null when the price is negative', () {
      final cost = PriceCalculator.scaledIngredientCost(
        price: -9.99,
        ingredientQuantity: 2,
        ingredientUnit: 'pieces',
        packageQuantity: 12,
        packageUnit: 'pieces',
      );
      expect(cost, isNull);
    });

    test('rounds the scaled cost to cents', () {
      final cost = PriceCalculator.scaledIngredientCost(
        price: 9.99,
        ingredientQuantity: 2,
        ingredientUnit: 'pieces',
        packageQuantity: 12,
        packageUnit: 'pieces',
      );
      expect(cost, 1.67);
    });
  });

  group('unitPrice', () {
    test('computes price per piece', () {
      final unitPrice = PriceCalculator.unitPrice(
        price: 9.99,
        packageQuantity: 12,
        packageUnit: 'pieces',
      );
      expect(unitPrice, isNotNull);
      expect(unitPrice!.amount, closeTo(0.8325, 0.001));
      expect(unitPrice.unit, 'pieces');
    });

    test('computes price per gram for a weight package', () {
      final unitPrice = PriceCalculator.unitPrice(
        price: 8,
        packageQuantity: 1,
        packageUnit: 'kg',
      );
      expect(unitPrice, isNotNull);
      expect(unitPrice!.amount, closeTo(0.008, 0.0001));
      expect(unitPrice.unit, 'g');
    });

    test('computes price per milliliter for a volume package', () {
      final unitPrice = PriceCalculator.unitPrice(
        price: 5,
        packageQuantity: 1,
        packageUnit: 'L',
      );
      expect(unitPrice, isNotNull);
      expect(unitPrice!.amount, closeTo(0.005, 0.0001));
      expect(unitPrice.unit, 'ml');
    });

    test('returns null when packageQuantity is missing', () {
      final unitPrice = PriceCalculator.unitPrice(
        price: 9.99,
        packageUnit: 'pieces',
      );
      expect(unitPrice, isNull);
    });

    test('returns null when packageQuantity is zero', () {
      final unitPrice = PriceCalculator.unitPrice(
        price: 9.99,
        packageQuantity: 0,
        packageUnit: 'pieces',
      );
      expect(unitPrice, isNull);
    });

    test('returns null when packageUnit is missing', () {
      final unitPrice = PriceCalculator.unitPrice(
        price: 9.99,
        packageQuantity: 12,
      );
      expect(unitPrice, isNull);
    });
  });
}
