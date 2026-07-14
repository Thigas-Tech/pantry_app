import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/models/price.dart';
import 'package:pantry_app/models/store.dart';
import 'package:pantry_app/providers/database_provider.dart';
import 'package:pantry_app/providers/settings_provider.dart';
import 'package:pantry_app/widgets/price_entry_sheet.dart';
import '../helpers/pump_app.dart';

FakeSettingsNotifier _defaultSettings() => FakeSettingsNotifier();
FakeSettingsNotifier _brlSettings() =>
    FakeSettingsNotifier(const Settings(baseCurrency: 'BRL'));

class FakeSettingsNotifier extends SettingsNotifier {
  FakeSettingsNotifier([this.initial = const Settings()]);

  final Settings initial;

  @override
  Settings build() => initial;
}

void main() {
  Future<void> openSheet(WidgetTester tester) async {
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  group('decimal separator', () {
    testWidgets('shows comma for BRL existing price', (tester) async {
      final price = Price(
        barcode: '123',
        price: 10.50,
        currency: 'BRL',
        dateAdded: DateTime.now().millisecondsSinceEpoch,
      );

      await pumpApp(
        tester,
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => PriceEntrySheet.show(
              context,
              barcode: '123',
              existingPrice: price,
            ),
            child: const Text('Open'),
          ),
        ),
        overrides: [
          settingsProvider.overrideWith(_brlSettings),
          storesProvider.overrideWith((ref) => const <Store>[]),
        ],
      );

      await openSheet(tester);

      final field = tester.widget<TextField>(find.byType(TextField).first);
      expect(field.controller?.text, '10,50');
    });

    testWidgets('shows dot for USD existing price', (tester) async {
      final price = Price(
        barcode: '123',
        price: 5.99,
        dateAdded: DateTime.now().millisecondsSinceEpoch,
      );

      await pumpApp(
        tester,
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => PriceEntrySheet.show(
              context,
              barcode: '123',
              existingPrice: price,
            ),
            child: const Text('Open'),
          ),
        ),
        overrides: [
          settingsProvider.overrideWith(_defaultSettings),
          storesProvider.overrideWith((ref) => const <Store>[]),
        ],
      );

      await openSheet(tester);

      final field = tester.widget<TextField>(find.byType(TextField).first);
      expect(field.controller?.text, '5.99');
    });

    testWidgets('accepts comma input for BRL', (tester) async {
      await pumpApp(
        tester,
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => PriceEntrySheet.show(context, barcode: '123'),
            child: const Text('Open'),
          ),
        ),
        overrides: [
          settingsProvider.overrideWith(_brlSettings),
          storesProvider.overrideWith((ref) => const <Store>[]),
        ],
      );

      await openSheet(tester);

      final field = find.byType(TextField).first;
      await tester.enterText(field, '15,90');
      await tester.pumpAndSettle();

      expect(
        tester.widget<TextField>(field).controller?.text,
        '15,90',
      );
    });

    testWidgets('accepts dot input for USD', (tester) async {
      await pumpApp(
        tester,
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => PriceEntrySheet.show(context, barcode: '123'),
            child: const Text('Open'),
          ),
        ),
        overrides: [
          settingsProvider.overrideWith(_defaultSettings),
          storesProvider.overrideWith((ref) => const <Store>[]),
        ],
      );

      await openSheet(tester);

      final field = find.byType(TextField).first;
      await tester.enterText(field, '15.90');
      await tester.pumpAndSettle();

      expect(
        tester.widget<TextField>(field).controller?.text,
        '15.90',
      );
    });
  });
}
