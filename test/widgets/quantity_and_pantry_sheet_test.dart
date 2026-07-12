import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/providers/database_provider.dart';
import 'package:pantry_app/widgets/quantity_and_pantry_sheet.dart';
import '../helpers/pump_app.dart';

class MockDatabaseHelper extends Mock implements DatabaseHelper {}

void main() {
  late MockDatabaseHelper mockDb;

  setUp(() {
    mockDb = MockDatabaseHelper();
    when(mockDb.getInventories).thenAnswer(
      (_) async => [
        {'id': 1, 'name': 'Home', 'created_at': 1},
      ],
    );
  });

  Future<void> openSheet(WidgetTester tester) async {
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  testWidgets('shows title and quantity field', (tester) async {
    await pumpApp(
      tester,
      Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => QuantityAndPantrySheet.show(context),
          child: const Text('Open'),
        ),
      ),
      overrides: [
        databaseProvider.overrideWithValue(mockDb),
      ],
    );

    await openSheet(tester);

    expect(find.text('Add to your pantry?'), findsOneWidget);
    expect(find.text('How many did you buy?'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('shows pantry picker when multiple pantries exist', (
    tester,
  ) async {
    when(mockDb.getInventories).thenAnswer(
      (_) async => [
        {'id': 1, 'name': 'Home', 'created_at': 1},
        {'id': 2, 'name': 'Summer Cabin', 'created_at': 2},
      ],
    );

    await pumpApp(
      tester,
      Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => QuantityAndPantrySheet.show(context),
          child: const Text('Open'),
        ),
      ),
      overrides: [
        databaseProvider.overrideWithValue(mockDb),
      ],
    );

    await openSheet(tester);

    expect(find.byType(DropdownButtonFormField<int>), findsOneWidget);
  });

  testWidgets('hides pantry picker when only one pantry', (tester) async {
    await pumpApp(
      tester,
      Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => QuantityAndPantrySheet.show(context),
          child: const Text('Open'),
        ),
      ),
      overrides: [
        databaseProvider.overrideWithValue(mockDb),
      ],
    );

    await openSheet(tester);

    expect(find.byType(RadioListTile<int>), findsNothing);
  });

  testWidgets('returns result on confirm', (tester) async {
    QuantityAndPantryResult? result;

    await pumpApp(
      tester,
      Builder(
        builder: (context) => ElevatedButton(
          onPressed: () async {
            result = await QuantityAndPantrySheet.show(context);
          },
          child: const Text('Open'),
        ),
      ),
      overrides: [
        databaseProvider.overrideWithValue(mockDb),
      ],
    );

    await openSheet(tester);

    await tester.tap(find.text('Add to Inventory'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.quantity, 1);
    expect(result!.inventoryId, 1);
  });

  testWidgets('returns null on cancel', (tester) async {
    QuantityAndPantryResult? result;

    await pumpApp(
      tester,
      Builder(
        builder: (context) => ElevatedButton(
          onPressed: () async {
            result = await QuantityAndPantrySheet.show(context);
          },
          child: const Text('Open'),
        ),
      ),
      overrides: [
        databaseProvider.overrideWithValue(mockDb),
      ],
    );

    await openSheet(tester);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(result, isNull);
  });
}
