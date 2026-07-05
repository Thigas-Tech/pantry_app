import 'package:filegate/filegate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/providers/active_inventory_provider.dart';
import 'package:pantry_app/providers/csv_service_provider.dart';
import 'package:pantry_app/providers/database_provider.dart';
import 'package:pantry_app/providers/filegate_provider.dart';
import 'package:pantry_app/screens/settings_screen.dart';
import 'package:pantry_app/screens/stats_screen.dart';
import 'package:pantry_app/services/csv_service.dart';
import '../helpers/pump_app.dart';

class MockDatabaseHelper extends Mock implements DatabaseHelper {}

class MockCsvService extends Mock implements CsvService {}

class MockFilegate extends Mock implements Filegate {}

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
  late MockFilegate mockFilegate;

  setUp(() {
    mockDb = MockDatabaseHelper();
    mockCsv = MockCsvService();
    mockFilegate = MockFilegate();

    when(() => mockDb.getProductCount()).thenAnswer((_) async => 5);
    when(() => mockDb.getInventoryCount()).thenAnswer((_) async => 10);
  });

  List<Override> baseOverrides() => [
    databaseProvider.overrideWithValue(mockDb),
    activeInventoryProvider.overrideWith(FakeActiveInventoryNotifier.new),
    csvServiceProvider.overrideWithValue(mockCsv),
    filegateProvider.overrideWithValue(mockFilegate),
  ];

  testWidgets('StatsScreen golden', (tester) async {
    await pumpApp(
      tester,
      const StatsScreen(),
      overrides: baseOverrides(),
    );

    await expectLater(
      find.byType(StatsScreen),
      matchesGoldenFile('goldens/stats_screen.png'),
    );
  });

  testWidgets('SettingsScreen golden', (tester) async {
    await pumpApp(tester, const SettingsScreen());

    await expectLater(
      find.byType(SettingsScreen),
      matchesGoldenFile('goldens/settings_screen.png'),
    );
  });
}
