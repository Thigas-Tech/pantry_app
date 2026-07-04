import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/providers/active_inventory_provider.dart';
import 'package:pantry_app/providers/csv_service_provider.dart';
import 'package:pantry_app/providers/database_provider.dart';
import 'package:pantry_app/screens/stats_screen.dart';
import 'package:pantry_app/services/csv_service.dart';
import '../helpers/pump_app.dart';

class MockDatabaseHelper extends Mock implements DatabaseHelper {}

class MockCsvService extends Mock implements CsvService {}

class FakeActiveInventoryNotifier extends Notifier<int>
    implements ActiveInventoryNotifier {
  @override
  int build() => 1;

  @override
  int get value => state;

  @override
  set value(int id) => state = id;
}

void main() {
  late MockDatabaseHelper mockDb;
  late MockCsvService mockCsv;

  setUp(() {
    mockDb = MockDatabaseHelper();
    mockCsv = MockCsvService();
  });

  testWidgets('shows product and inventory counts', (tester) async {
    when(() => mockDb.getProductCount()).thenAnswer((_) async => 5);
    when(() => mockDb.getInventoryCount()).thenAnswer((_) async => 10);

    await pumpApp(
      tester,
      const StatsScreen(),
      overrides: [
        databaseProvider.overrideWithValue(mockDb),
        activeInventoryProvider.overrideWith(FakeActiveInventoryNotifier.new),
        csvServiceProvider.overrideWithValue(mockCsv),
      ],
    );

    expect(find.textContaining('Total products'), findsOneWidget);
    expect(find.textContaining('Inventory items'), findsOneWidget);
  });

  testWidgets('shows export and import buttons', (tester) async {
    when(() => mockDb.getProductCount()).thenAnswer((_) async => 5);
    when(() => mockDb.getInventoryCount()).thenAnswer((_) async => 10);

    await pumpApp(
      tester,
      const StatsScreen(),
      overrides: [
        databaseProvider.overrideWithValue(mockDb),
        activeInventoryProvider.overrideWith(FakeActiveInventoryNotifier.new),
        csvServiceProvider.overrideWithValue(mockCsv),
      ],
    );

    expect(
      find.widgetWithText(ElevatedButton, 'Export as CSV'),
      findsOneWidget,
    );
    expect(
      find.widgetWithText(ElevatedButton, 'Import CSV'),
      findsOneWidget,
    );
  });

  testWidgets('displays count of zero', (tester) async {
    when(() => mockDb.getProductCount()).thenAnswer((_) async => 0);
    when(() => mockDb.getInventoryCount()).thenAnswer((_) async => 0);

    await pumpApp(
      tester,
      const StatsScreen(),
      overrides: [
        databaseProvider.overrideWithValue(mockDb),
        activeInventoryProvider.overrideWith(FakeActiveInventoryNotifier.new),
        csvServiceProvider.overrideWithValue(mockCsv),
      ],
    );

    expect(find.textContaining('Total products: 0'), findsOneWidget);
    expect(find.textContaining('Inventory items: 0'), findsOneWidget);
  });
}
