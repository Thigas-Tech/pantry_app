import 'dart:convert';
import 'dart:io';

import 'package:filegate/filegate.dart' as fg;
import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/models/inventory_item.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/utils/logger.dart';

/// Handles CSV export and import for the pantry database.
///
/// All operations are scoped to a specific inventory via its
/// [InventoryItem.inventoryId]. Export generates a CSV for the given
/// inventory; import adds all parsed items to the given inventory.
///
/// ## Round‑trip fidelity
///
/// Export and import use the same header names so exported CSV files can
/// be re‑imported later without data loss. Fields that are null are
/// written as empty strings (never the literal `"null"`).
///
/// ## Edge cases handled
///
/// - Windows CRLF (`\r\n`) line endings.
/// - UTF‑8 BOM prefix.
/// - Fields containing commas, double quotes, and newlines (RFC‑4180).
/// - Content‑URI paths from platform file pickers (Android).
/// - Empty barcodes (logged, skipped, does not crash).
class CsvService {
  /// Creates a [CsvService] that uses the given [DatabaseHelper].
  CsvService(this._db);

  final DatabaseHelper _db;

  // ---------- Column definitions ----------

  static const _columns = <String>[
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
    'Serving Size',
    'Nutri-Score',
    'Energy (kcal/100g)',
    'Protein (g/100g)',
    'Carbs (g/100g)',
    'Fat (g/100g)',
    'Fiber (g/100g)',
    'Salt (g/100g)',
    'Inventory Name',
  ];

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

    final buffer = StringBuffer()..writeln(_columns.join(','));

    for (final row in rows) {
      final dateAddedStr = row['date_added'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              row['date_added'] as int,
            ).toIso8601String()
          : '';

      final values = <String>[
        _escapeField(row['product_name']),
        _escapeField(row['brand']),
        _escapeField(row['category']),
        _escapeField(row['barcode']),
        row['quantity']?.toString() ?? '',
        _escapeField(row['unit']),
        row['expiry_date'] as String? ?? '',
        _escapeField(row['location']),
        _escapeField(row['notes']),
        dateAddedStr,
        _escapeField(row['serving_size']),
        _escapeField(row['nutriscore_grade']),
        row['energy_kcal']?.toString() ?? '',
        row['protein_g']?.toString() ?? '',
        row['carbs_g']?.toString() ?? '',
        row['fat_g']?.toString() ?? '',
        row['fiber_g']?.toString() ?? '',
        row['salt_g']?.toString() ?? '',
        _escapeField(row['inventory_name']),
      ];
      buffer.writeln(values.join(','));
    }

    logInfo('CSV export generated successfully');
    return buffer.toString();
  }

  /// Wraps a field in double quotes if it contains a comma, quote, or
  /// newline. Internal double quotes are escaped by doubling.
  String _escapeField(dynamic value) {
    final string = value?.toString() ?? '';
    if (string.contains(',') ||
        string.contains('"') ||
        string.contains('\n') ||
        string.contains('\r')) {
      return '"${string.replaceAll('"', '""')}"';
    }
    return string;
  }

  // ---------- Import ----------

  /// Parses [csvContent] and inserts/updates the database.
  ///
  /// The [inventoryId] is assigned to every new inventory item created from
  /// the CSV data. Use [importCsvFromFile] if you have a file path instead
  /// of raw CSV text.
  ///
  /// Returns a map with `products` (count) and `items` (count) imported.
  Future<Map<String, int>> importCsv(
    String csvContent, {
    required int inventoryId,
  }) {
    logInfo('CSV import (inventory $inventoryId)');
    return _import(csvContent, inventoryId: inventoryId);
  }

  /// Reads the file at [filePath] and imports its CSV content.
  ///
  /// Preferred over [importCsv] when the content is already on disk.
  /// Handles both `file://` and `content://` paths by copying via
  /// `readFromPath` first.
  Future<Map<String, int>> importCsvFromFile(
    String filePath, {
    required int inventoryId,
    fg.Filegate? filegate,
  }) async {
    logInfo('CSV import from $filePath (inventory $inventoryId)');

    final content = await readFromPath(filePath, filegate: filegate);
    return _import(content, inventoryId: inventoryId);
  }

  /// Imports CSV from raw bytes (useful for content:// URIs).
  Future<Map<String, int>> importCsvFromBytes(
    List<int> bytes, {
    required int inventoryId,
  }) {
    logInfo('CSV import from bytes (inventory $inventoryId)');
    final content = utf8.decode(bytes);
    return _import(content, inventoryId: inventoryId);
  }

  /// Core import logic shared by all import methods.
  Future<Map<String, int>> _import(
    String csvBody, {
    required int inventoryId,
  }) async {
    if (csvBody.trim().isEmpty) {
      logError('CSV content is empty');
      throw Exception('CSV content is empty.');
    }

    final rows = _parseCsv(csvBody);
    if (rows.length < 2) {
      logError('CSV has no data rows');
      throw Exception('CSV has no data rows.');
    }

    final headers = rows.first;
    logInfo('CSV headers: $headers');
    _validateHeaders(headers);

    var productsImported = 0;
    var itemsImported = 0;

    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.isEmpty || row.every((f) => f.isEmpty)) {
        logInfo('Skipping empty row $i');
        continue;
      }

      try {
        final map = <String, String>{};
        for (var j = 0; j < headers.length && j < row.length; j++) {
          map[headers[j]] = row[j];
        }

        final barcode = (map['Barcode'] ?? '').trim();
        if (barcode.isEmpty) {
          logWarning('Row $i: empty barcode, skipping');
          continue;
        }

        final product = Product(
          barcode: barcode,
          name: map['Product Name'] ?? 'Imported Product',
          brand: map['Brand'].emptyAsNull,
          category: map['Category'].emptyAsNull,
          servingSize: map['Serving Size'].emptyAsNull,
          nutriscoreGrade: map['Nutri-Score'].emptyAsNull,
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
          unit: map['Unit'] ?? 'pieces',
          location: map['Location'] ?? 'pantry',
          expiryDate: (expiryStr == null || expiryStr.isEmpty)
              ? null
              : expiryStr,
          notes: map['Notes'].emptyAsNull,
          dateAdded: dateAdded,
          inventoryId: inventoryId,
        );

        await _db.insertInventoryItem(item);
        itemsImported++;
        logInfo('Imported row $i: $barcode — ${product.name}');
      } on Exception catch (e) {
        logError('Error importing row $i: $e');
      }
    }

    logInfo(
      'CSV import done: $productsImported products, $itemsImported items',
    );
    return {'products': productsImported, 'items': itemsImported};
  }

  /// Reads the file at [path] into a UTF‑8 string.
  ///
  /// Handles both file‑system paths and `content://` URIs by falling back
  /// to a platform‑specific read when `File` cannot open the path.
  static Future<String> readFromPath(
    String path, {
    fg.Filegate? filegate,
  }) async {
    final file = File(path);
    if (await file.exists()) {
      return file.readAsString();
    }
    if (filegate != null && path.startsWith('content://')) {
      final bytes = await filegate.readAllBytes(path);
      return utf8.decode(bytes);
    }
    throw Exception('Cannot read file at $path');
  }

  // ---------- CSV parser ----------

  /// Parses a CSV string into rows of fields.
  ///
  /// Follows RFC‑4180: handles quoted fields, embedded commas, escaped
  /// double quotes (`""`), and both LF and CRLF line endings. A leading
  /// UTF‑8 BOM is stripped. Fields are NOT trimmed — leading/trailing
  /// whitespace within a field is preserved.
  List<List<String>> _parseCsv(String csv) {
    var body = csv;
    if (body.startsWith('\uFEFF')) {
      body = body.substring(1);
    }

    final rows = <List<String>>[];
    final currentRow = <String>[];
    final currentField = StringBuffer();
    var inQuotes = false;

    for (var i = 0; i < body.length; i++) {
      final char = body[i];

      if (inQuotes) {
        if (char == '"') {
          if (i + 1 < body.length && body[i + 1] == '"') {
            currentField.write('"');
            i++;
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
          currentRow.add(currentField.toString());
          currentField.clear();
        } else if (char == '\n') {
          currentRow.add(currentField.toString());
          rows.add(List.of(currentRow));
          currentRow.clear();
          currentField.clear();
        } else if (char == '\r') {
          // skip carriage returns
        } else {
          currentField.write(char);
        }
      }
    }

    if (currentField.isNotEmpty || currentRow.isNotEmpty) {
      currentRow.add(currentField.toString());
      rows.add(List.of(currentRow));
    }

    return rows;
  }

  /// Checks that the CSV has the required columns.
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
