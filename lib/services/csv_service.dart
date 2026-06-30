import 'dart:io';

import 'package:csv/csv.dart';
import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/models/inventory_item.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/utils/logger.dart';

/// Handles CSV export and import for the pantry database.
///
/// All operations work with the local SQLite database and are
/// platform‑independent within the Android app.
class CsvService {
  CsvService(this._db);
  final DatabaseHelper _db;
  // ---------- Export ----------

  /// Generates a CSV string of all inventory items with product details.
  Future<String> generateCsv() async {
    final rows = await _db.getExportData();
    logInfo('CSV export: ${rows.length} rows');
    if (rows.isEmpty) return '';

    final headers = [
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
    ];
    final csvData = <List<dynamic>>[headers];
    for (final row in rows) {
      csvData.add([
        row['product_name'] ?? '',
        row['brand'] ?? '',
        row['category'] ?? '',
        row['barcode'] ?? '',
        row['quantity']?.toString() ?? '',
        row['unit'] ?? '',
        row['expiry_date'] ?? '',
        row['location'] ?? '',
        row['notes'] ?? '',
        row['date_added'] != null
            ? DateTime.fromMillisecondsSinceEpoch(
                row['date_added'] as int,
              ).toIso8601String()
            : '',
        row['energy_kcal']?.toString() ?? '',
        row['protein_g']?.toString() ?? '',
        row['carbs_g']?.toString() ?? '',
        row['fat_g']?.toString() ?? '',
        row['fiber_g']?.toString() ?? '',
        row['salt_g']?.toString() ?? '',
      ]);
    }
    // v8 API: csv.encode() returns a String.
    return csv.encode(csvData);
  }

  // ---------- Import ----------

  /// Parses the CSV file at [filePath] and inserts/updates the database.
  ///
  /// Returns a map with `products` (count) and `items` (count) imported.
  Future<Map<String, int>> importCsv(String filePath) async {
    logInfo('CSV import from $filePath');
    // Read the entire file as a string (v8 csv.decode works on a string).
    final csvString = await File(filePath).readAsString();
    if (csvString.trim().isEmpty) throw Exception('CSV file is empty.');

    // Decode: returns List<List<dynamic>>
    final rows = csv.decode(csvString);
    if (rows.isEmpty) throw Exception('CSV file is empty.');

    // First row is headers
    final headers = rows.first.map((e) => e.toString().trim()).toList();
    _validateHeaders(headers);

    int productsImported = 0;
    int itemsImported = 0;

    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.isEmpty) continue;

      final map = _rowToMap(headers, row);

      // Build a Product (minimal info; optional nutrition)
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

      // Upsert product
      await _db.insertProduct(product);
      productsImported++;

      // Build an InventoryItem (always new, ignore IDs)
      final quantity = double.tryParse(map['Quantity'] ?? '') ?? 1;
      final expiryStr = map['Expiry Date'];
      final dateAddedStr = map['Date Added'];
      int? dateAdded;
      if (dateAddedStr != null && dateAddedStr.isNotEmpty) {
        dateAdded = DateTime.tryParse(dateAddedStr)?.millisecondsSinceEpoch;
      }

      final item = InventoryItem(
        barcode: product.barcode,
        quantity: quantity,
        unit: map['Unit'] ?? 'pcs',
        location: map['Location'] ?? 'pantry',
        expiryDate: expiryStr?.isEmpty == true ? null : expiryStr,
        notes: map['Notes'].emptyAsNull,
        dateAdded: dateAdded ?? DateTime.now().millisecondsSinceEpoch,
      );

      await _db.insertInventoryItem(item);
      itemsImported++;
    }

    logInfo(
      'CSV import done: $productsImported products, $itemsImported items',
    );
    return {'products': productsImported, 'items': itemsImported};
  }

  /// Checks that the CSV has the required columns
  /// (at minimum 'Barcode' and 'Product Name').
  void _validateHeaders(List<String> headers) {
    if (!headers.contains('Barcode') || !headers.contains('Product Name')) {
      throw Exception(
        'Invalid CSV format. Required columns: Barcode, Product Name.',
      );
    }
  }

  /// Converts a header list and a row of values into a map.
  Map<String, String> _rowToMap(List<String> headers, List<dynamic> row) {
    final map = <String, String>{};
    for (int i = 0; i < headers.length && i < row.length; i++) {
      map[headers[i]] = row[i].toString().trim();
    }
    return map;
  }
}

/// Extension to treat empty strings as null.
extension _StringEmptyExtension on String? {
  String? get emptyAsNull => (this == null || this!.isEmpty) ? null : this;
}
