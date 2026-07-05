import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/screens/add_product_screen.dart';
import '../helpers/pump_app.dart';

/// Pumps [screen] with a viewport tall enough so all [ListView] children
/// are built. Resets the viewport on teardown.
Future<void> pumpTall(WidgetTester tester, Widget screen) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await pumpApp(tester, screen);
  await tester.pumpAndSettle();
}

void main() {
  group('AddProductScreen', () {
    testWidgets('renders without crashing', (tester) async {
      await pumpApp(tester, const AddProductScreen(barcode: '123'));
      expect(find.byType(AddProductScreen), findsOneWidget);
    });

    testWidgets('shows product name field', (tester) async {
      await pumpApp(tester, const AddProductScreen(barcode: '123'));
      expect(find.text('Product name'), findsOneWidget);
    });

    testWidgets('shows nutrition section', (tester) async {
      await pumpApp(tester, const AddProductScreen(barcode: '123'));
      expect(find.text('Nutrition (per 100 g / 100 ml)'), findsOneWidget);
    });

    testWidgets('shows all nutrition field labels', (tester) async {
      await pumpApp(tester, const AddProductScreen(barcode: '123'));
      for (final label in [
        'Energy',
        'Protein',
        'Carbs',
        'Fat',
        'Fiber',
        'Salt',
      ]) {
        expect(find.text(label), findsOneWidget);
      }
    });

    testWidgets('shows brand and category fields', (tester) async {
      await pumpApp(tester, const AddProductScreen(barcode: '123'));
      expect(find.text('Brand'), findsOneWidget);
      expect(find.text('Category'), findsOneWidget);
    });

    testWidgets('shows serving size field', (tester) async {
      await pumpApp(tester, const AddProductScreen(barcode: '123'));
      expect(find.text('Serving size'), findsOneWidget);
    });

    testWidgets('shows below-the-fold content', (tester) async {
      await pumpTall(tester, const AddProductScreen(barcode: '123'));

      expect(find.text('Ingredients'), findsOneWidget);
      expect(find.text('Save product'), findsOneWidget);
      expect(find.text('Nutrition table photo'), findsOneWidget);
      expect(find.text('Ingredients list photo'), findsOneWidget);
      expect(find.text('Product photo'), findsOneWidget);
    });

    testWidgets('shows validation error when name is empty', (tester) async {
      await pumpTall(tester, const AddProductScreen(barcode: '123'));

      await tester.tap(find.text('Save product'));
      await tester.pumpAndSettle();

      expect(find.text('This field is required'), findsOneWidget);
    });

    testWidgets('entering name and saving pops the route', (tester) async {
      await pumpTall(tester, const AddProductScreen(barcode: '123'));

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Product name'),
        'Test Product',
      );
      await tester.tap(find.text('Save product'));
      await tester.pumpAndSettle();

      expect(find.byType(AddProductScreen), findsNothing);
    });

    testWidgets('saves all nutrition fields and serving size', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      Product? captured;

      await pumpApp(
        tester,
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              captured = await Navigator.push<Product>(
                context,
                MaterialPageRoute(
                  builder: (_) => const AddProductScreen(barcode: '123'),
                ),
              );
            },
            child: const Text('Open form'),
          ),
        ),
      );

      await tester.tap(find.text('Open form'));
      await tester.pumpAndSettle();

      // Fill every editable field.
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Product name'),
        'Test Product',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Brand'),
        'Test Brand',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Category'),
        'Test Category',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Serving size'),
        '100 g',
      );

      // Nutrition fields — identify each by its label Text sibling in a Row.
      Future<void> enterNutrition(String label, String value) async {
        final row = find.ancestor(
          of: find.text(label),
          matching: find.byType(Row),
        );
        await tester.enterText(
          find.descendant(of: row, matching: find.byType(TextFormField)),
          value,
        );
      }

      await enterNutrition('Energy', '200');
      await enterNutrition('Protein', '10');
      await enterNutrition('Carbs', '30');
      await enterNutrition('Fat', '8');
      await enterNutrition('Fiber', '2');
      await enterNutrition('Salt', '0.5');

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Ingredients'),
        'Milk, Sugar',
      );

      await tester.tap(find.text('Save product'));
      await tester.pumpAndSettle();

      expect(captured, isNotNull);
      expect(captured!.barcode, '123');
      expect(captured!.name, 'Test Product');
      expect(captured!.brand, 'Test Brand');
      expect(captured!.category, 'Test Category');
      expect(captured!.servingSize, '100 g');
      expect(captured!.energyKcal, 200);
      expect(captured!.proteinG, 10);
      expect(captured!.carbsG, 30);
      expect(captured!.fatG, 8);
      expect(captured!.fiberG, 2);
      expect(captured!.saltG, 0.5);
      expect(captured!.ingredients, 'Milk, Sugar');
      expect(captured!.source, 'manual');
      expect(captured!.nutriscoreGrade, isNull);
    });

    testWidgets('saves with empty optional fields as null', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      Product? captured;

      await pumpApp(
        tester,
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              captured = await Navigator.push<Product>(
                context,
                MaterialPageRoute(
                  builder: (_) => const AddProductScreen(barcode: '123'),
                ),
              );
            },
            child: const Text('Open form'),
          ),
        ),
      );

      await tester.tap(find.text('Open form'));
      await tester.pumpAndSettle();

      // Only fill the required name field, leave everything else empty.
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Product name'),
        'Minimal Product',
      );

      await tester.tap(find.text('Save product'));
      await tester.pumpAndSettle();

      expect(captured, isNotNull);
      expect(captured!.name, 'Minimal Product');
      expect(captured!.brand, isNull);
      expect(captured!.category, isNull);
      expect(captured!.servingSize, isNull);
      expect(captured!.energyKcal, isNull);
      expect(captured!.proteinG, isNull);
      expect(captured!.carbsG, isNull);
      expect(captured!.fatG, isNull);
      expect(captured!.fiberG, isNull);
      expect(captured!.saltG, isNull);
      expect(captured!.ingredients, isNull);
      expect(captured!.source, 'manual');
      expect(captured!.nutriscoreGrade, isNull);
    });
  });
}
