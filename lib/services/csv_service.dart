import 'dart:io';

import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/models/inventory_item.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/utils/logger.dart';

/// Handles CSV export and import for the pantry database.
///
/// All operations work with the local SQLite database and are
/// platform‑independent within the Android app.
class CsvService {
  /// Creates a [CsvService] that uses the given [DatabaseHelper].
  CsvService(this._db);

  final DatabaseHelper _db;

  // ---------- Export ----------

  /// Generates a CSV string of all inventory items with product details for
  /// the given [inventoryId].
  Future<String> generateCsv({required int inventoryId}) async {
    logInfo('Generating CSV export for inventory $inventoryId');
    final rows = await _db.getExportData(inventoryId: inventoryId);
    logInfo('CSV export: ${rows.length} rows');
    if (rows.isEmpty) {
      logInfo('No data to export');
      return '';
    }

    final headers = <String>[
      'Product Name',
      'Brand',
      'Category',
      'Barcode',
      'Quantity',
      'Unit',
      'Expiry Date',
      'Location',
      'Notes',
      'Date Added',
      'Energy (kcal/100g)',
      'Protein (g/100g)',
      'Carbs (g/100g)',
      'Fat (g/100g)',
      'Fiber (g/100g)',
      'Salt (g/100g)',
      'Inventory Name',
    ];

    final buffer = StringBuffer()..writeln(headers.join(','));

    for (final row in rows) {
      final values = <String>[
        _escapeCsvField(row['product_name']),
        _escapeCsvField(row['brand']),
        _escapeCsvField(row['category']),
        _escapeCsvField(row['barcode']),
        row['quantity']?.toString() ?? '',
        _escapeCsvField(row['unit']),
        row['expiry_date'].toString(),
        _escapeCsvField(row['location']),
        _escapeCsvField(row['notes']),
        if (row['date_added'] != null)
          DateTime.fromMillisecondsSinceEpoch(
            row['date_added'] as int,
          ).toIso8601String()
        else
          '',
        row['energy_kcal']?.toString() ?? '',
        row['protein_g']?.toString() ?? '',
        row['carbs_g']?.toString() ?? '',
        row['fat_g']?.toString() ?? '',
        row['fiber_g']?.toString() ?? '',
        row['salt_g']?.toString() ?? '',
        _escapeCsvField(row['inventory_name']),
      ];
      buffer.writeln(values.join(','));
    }

    logInfo('CSV export generated successfully');
    return buffer.toString();
  }

  /// Wraps a field in double quotes if it contains a comma, quote, or newline.
  String _escapeCsvField(dynamic value) {
    final string = value?.toString() ?? '';
    if (string.contains(',') || string.contains('"') || string.contains('\n')) {
      return '"${string.replaceAll('"', '""')}"';
    }
    return string;
  }

  // ---------- Import ----------

  /// Parses the CSV file at [filePath] and inserts/updates the database.
  ///
  /// The [inventoryId] is assigned to every new inventory item created from
  /// the CSV data.
  ///
  /// Returns a map with `products` (count) and `items` (count) imported.
  Future<Map<String, int>> importCsv(
    String filePath, {
    required int inventoryId,
  }) async {
    logInfo('CSV import from $filePath (inventory $inventoryId)');

    final file = File(filePath);
    if (!file.existsSync()) {
      logError('File not found: $filePath');
      throw Exception('File not found.');
    }

    final csvString = await file.readAsString();
    if (csvString.trim().isEmpty) {
      logError('CSV file is empty');
      throw Exception('CSV file is empty.');
    }

    // Parse CSV manually to handle quoted fields correctly.
    final rows = _parseCsv(csvString);
    if (rows.isEmpty) {
      logError('CSV file has no data rows');
      throw Exception('CSV file is empty.');
    }

    final headers = rows.first;
    logInfo('CSV headers: $headers');
    _validateHeaders(headers);

    var productsImported = 0;
    var itemsImported = 0;

    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.every((field) => field.isEmpty)) {
        logInfo('Skipping empty row $i');
        continue;
      }

      try {
        final map = <String, String>{};
        for (var j = 0; j < headers.length && j < row.length; j++) {
          map[headers[j]] = row[j];
        }

        final product = Product(
          barcode: map['Barcode'] ?? '',
          name: map['Product Name'] ?? 'Imported Product',
          brand: map['Brand'].emptyAsNull,
          category: map['Category'].emptyAsNull,
          energyKcal: double.tryParse(map['Energy (kcal/100g)'] ?? ''),
          proteinG: double.tryParse(map['Protein (g/100g)'] ?? ''),
          carbsG: double.tryParse(map['Carbs (g/100g)'] ?? ''),
          fatG: double.tryParse(map['Fat (g/100g)'] ?? ''),
          fiberG: double.tryParse(map['Fiber (g/100g)'] ?? ''),
          saltG: double.tryParse(map['Salt (g/100g)'] ?? ''),
          lastSynced: DateTime.now().millisecondsSinceEpoch,
        );

        await _db.insertProduct(product);
        productsImported++;

        final quantity = double.tryParse(map['Quantity'] ?? '') ?? 1;
        final expiryStr = map['Expiry Date'];
        final dateAddedStr = map['Date Added'];
        var dateAdded = DateTime.now().millisecondsSinceEpoch;
        if (dateAddedStr != null && dateAddedStr.isNotEmpty) {
          dateAdded =
              DateTime.tryParse(dateAddedStr)?.millisecondsSinceEpoch ??
              DateTime.now().millisecondsSinceEpoch;
        }

        final item = InventoryItem(
          barcode: product.barcode,
          quantity: quantity,
          unit: map['Unit'] ?? 'pcs',
          location: map['Location'] ?? 'pantry',
          expiryDate: expiryStr?.isEmpty == true ? null : expiryStr,
          notes: map['Notes'].emptyAsNull,
          dateAdded: dateAdded,
          inventoryId: inventoryId,
        );

        await _db.insertInventoryItem(item);
        itemsImported++;
        logInfo('Imported row $i: ${product.barcode} - ${product.name}');
      } on Exception catch (e) {
        logError('Error importing row $i: $e');
        // Continue with next row instead of aborting the whole import.
      }
    }

    logInfo(
      'CSV import done: $productsImported products, $itemsImported items',
    );
    return {'products': productsImported, 'items': itemsImported};
  }

  /// Parses a CSV string into a list of rows (each row is a list of fields).
  ///
  /// Handles quoted fields containing commas, quotes, and newlines.
  List<List<String>> _parseCsv(String csv) {
    final rows = <List<String>>[];
    final currentRow = <String>[];
    var currentField = StringBuffer();
    var inQuotes = false;

    for (var i = 0; i < csv.length; i++) {
      final char = csv[i];

      if (inQuotes) {
        if (char == '"') {
          // Check for escaped quote (two consecutive quotes).
          if (i + 1 < csv.length && csv[i + 1] == '"') {
            currentField.write('"');
            i++; // skip the next quote
          } else {
            inQuotes = false;
          }
        } else {
          currentField.write(char);
        }
      } else {
        if (char == '"') {
          inQuotes = true;
        } else if (char == ',') {
          currentRow.add(currentField.toString().trim());
          currentField = StringBuffer();
        } else if (char == '\n') {
          currentRow.add(currentField.toString().trim());
          rows.add(currentRow.map((e) => e).toList());
          currentRow.clear();
          currentField = StringBuffer();
        } else if (char == '\r') {
          // Ignore carriage returns; they often precede \n.
        } else {
          currentField.write(char);
        }
      }
    }

    // Add the last field and row if any.
    if (currentField.isNotEmpty || currentRow.isNotEmpty) {
      currentRow.add(currentField.toString().trim());
      rows.add(currentRow.map((e) => e).toList());
    }

    return rows;
  }

  /// Checks that the CSV has the required columns
  /// (at minimum 'Barcode' and 'Product Name').
  void _validateHeaders(List<String> headers) {
    if (!headers.contains('Barcode') || !headers.contains('Product Name')) {
      logError('CSV missing required columns. Found: $headers');
      throw Exception(
        'Invalid CSV format. Required columns: Barcode, Product Name.',
      );
    }
  }
}

extension _StringEmptyExtension on String? {
  String? get emptyAsNull => (this == null || this!.isEmpty) ? null : this;
}
