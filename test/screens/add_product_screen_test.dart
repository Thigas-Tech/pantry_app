import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/screens/add_product_screen.dart';
import '../helpers/pump_app.dart';

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
  });
}
