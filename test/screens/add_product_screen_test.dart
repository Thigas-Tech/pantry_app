import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
  });
}
