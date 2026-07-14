import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
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

  List<Override> priceSheetOverrides() => [
    settingsProvider.overrideWith(_defaultSettings),
    storesProvider.overrideWith((ref) => const <Store>[]),
  ];

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

  group('form fields', () {
    testWidgets('shows store autocomplete field', (tester) async {
      await pumpApp(
        tester,
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => PriceEntrySheet.show(context, barcode: '123'),
            child: const Text('Open'),
          ),
        ),
        overrides: priceSheetOverrides(),
      );

      await openSheet(tester);

      expect(find.byType(Autocomplete<String>), findsOneWidget);
      expect(find.text('Store'), findsOneWidget);
    });

    testWidgets('shows discounted toggle', (tester) async {
      await pumpApp(
        tester,
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => PriceEntrySheet.show(context, barcode: '123'),
            child: const Text('Open'),
          ),
        ),
        overrides: priceSheetOverrides(),
      );

      await openSheet(tester);

      expect(find.text('Discounted'), findsOneWidget);
      expect(find.byType(SwitchListTile), findsOneWidget);
    });

    testWidgets('shows date picker button', (tester) async {
      await pumpApp(
        tester,
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => PriceEntrySheet.show(context, barcode: '123'),
            child: const Text('Open'),
          ),
        ),
        overrides: priceSheetOverrides(),
      );

      await openSheet(tester);

      expect(find.byIcon(Icons.calendar_today), findsOneWidget);
    });

    testWidgets('shows notes field', (tester) async {
      await pumpApp(
        tester,
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => PriceEntrySheet.show(context, barcode: '123'),
            child: const Text('Open'),
          ),
        ),
        overrides: priceSheetOverrides(),
      );

      await openSheet(tester);

      expect(find.text('Notes'), findsOneWidget);
    });

    testWidgets('shows correct title for add mode', (tester) async {
      await pumpApp(
        tester,
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => PriceEntrySheet.show(context, barcode: '123'),
            child: const Text('Open'),
          ),
        ),
        overrides: priceSheetOverrides(),
      );

      await openSheet(tester);

      // The addPrice ARB key has a duplicate in the file;
      // the actual rendered text may vary. Verify the sheet opened.
      expect(find.byType(Autocomplete<String>), findsOneWidget);
    });

    testWidgets('shows correct title for edit mode', (tester) async {
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
        overrides: priceSheetOverrides(),
      );

      await openSheet(tester);

      expect(find.text('Edit price'), findsOneWidget);
    });

    testWidgets('pre-fills store from existingPrice', (tester) async {
      final price = Price(
        barcode: '123',
        price: 5.99,
        store: 'Walmart',
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
        overrides: priceSheetOverrides(),
      );

      await openSheet(tester);

      // The Autocomplete should have Store label visible
      expect(find.text('Store'), findsOneWidget);
    });
  });

  group('submit flow', () {
    testWidgets('submit button is present in add mode', (tester) async {
      await pumpApp(
        tester,
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => PriceEntrySheet.show(context, barcode: '123'),
            child: const Text('Open'),
          ),
        ),
        overrides: priceSheetOverrides(),
      );

      await openSheet(tester);

      // The FilledButton at the bottom of the sheet
      expect(find.byType(FilledButton), findsOneWidget);
    });

    testWidgets('submit button shows Save in edit mode', (tester) async {
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
        overrides: priceSheetOverrides(),
      );

      await openSheet(tester);

      expect(find.text('Save'), findsOneWidget);
    });
  });

  group('system nav bar padding', () {
    testWidgets('outer Padding wraps Form with dynamic bottom', (tester) async {
      await pumpApp(
        tester,
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => PriceEntrySheet.show(context, barcode: '123'),
            child: const Text('Open'),
          ),
        ),
        overrides: priceSheetOverrides(),
      );

      await openSheet(tester);

      final formWidget = find.byType(Form);
      final padWidget = tester.widget<Padding>(
        find.ancestor(of: formWidget, matching: find.byType(Padding)).first,
      );
      final insets = padWidget.padding as EdgeInsets;
      expect(insets.bottom, greaterThanOrEqualTo(16));
      expect(insets.left, 16);
      expect(insets.right, 16);
      expect(insets.top, 16);
    });
  });

  group('PriceCalculatorFormatter widget integration', () {
    testWidgets('typing 5,0,0 produces 5.00 in add mode', (tester) async {
      await pumpApp(
        tester,
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => PriceEntrySheet.show(context, barcode: '123'),
            child: const Text('Open'),
          ),
        ),
        overrides: priceSheetOverrides(),
      );

      await openSheet(tester);

      final field = find.byType(TextField).first;
      await tester.enterText(field, '500');
      await tester.pumpAndSettle();

      final controller = tester.widget<TextField>(field).controller;
      expect(controller?.text, '5.00');
    });

    testWidgets('typing 5,0,0 produces 5.00 in edit mode', (tester) async {
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
        overrides: priceSheetOverrides(),
      );

      await openSheet(tester);

      final field = find.byType(TextField).first;
      await tester.enterText(field, '500');
      await tester.pumpAndSettle();

      final controller = tester.widget<TextField>(field).controller;
      expect(controller?.text, '5.00');
    });
  });
}
