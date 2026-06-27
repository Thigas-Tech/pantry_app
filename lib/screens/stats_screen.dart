import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/providers/database_provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// A statistics and data‑export screen.
///
/// Shows aggregate pantry counts and allows the user to export their
/// entire inventory as a CSV file, which can then be shared or saved.
///
/// ## Platform behaviour
///
/// - **Android, iOS, macOS, Windows** – the file is written to a temporary
///   directory and then passed to the system share sheet via `share_plus`.
/// - **Linux** – `share_plus` does not support Linux, so the file is
///   saved directly to the user’s **Downloads** folder (or a fallback
///   temporary directory). A snackbar displays the full path, and the
///   containing folder is opened automatically in the default file manager.
///
/// ## CSV format
///
/// The exported CSV uses `\r\n` line endings (RFC 4180). On all platforms
/// (including Linux) the file is written as‑is, so it opens correctly in
/// any spreadsheet application.
class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Pantry Stats')),
      body: FutureBuilder(
        future: Future.wait([db.getProductCount(), db.getInventoryCount()]),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final counts = snapshot.data as List<int>;
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total products: ${counts[0]}'),
                Text('Inventory items: ${counts[1]}'),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => _exportCsv(context, db),
                  icon: const Icon(Icons.file_download),
                  label: const Text('Export as CSV'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Generates the CSV and either shares it (Android/iOS/macOS/Windows) or
  /// saves it locally (Linux).
  ///
  /// ### Linux behaviour
  /// The file is placed in `~/Downloads/pantry_export.csv` (or a temporary
  /// directory if Downloads is unavailable). A snackbar shows the exact path,
  /// and the folder is opened with `xdg-open`. The user can then attach the
  /// file manually to an email, move it, or open it directly.
  Future<void> _exportCsv(BuildContext context, DatabaseHelper db) async {
    try {
      // 1. Fetch all inventory data with product details.
      final rows = await db.getExportData();
      if (rows.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('No data to export.')));
        }
        return;
      }

      // 2. Build CSV content.
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

      final csvString = csv.encode(csvData);

      // 3. Write the file to an appropriate location.
      final String filePath;
      if (Platform.isLinux) {
        filePath = await _writeToDownloads(csvString);
      } else {
        // Temporary directory for sharing.
        final directory = await getTemporaryDirectory();
        filePath = '${directory.path}/pantry_export.csv';
        await File(filePath).writeAsString(csvString);
      }

      // 4. Share or notify.
      if (!context.mounted) return;

      if (Platform.isLinux) {
        // Linux: show path and open folder.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('CSV saved to $filePath'),
            duration: const Duration(seconds: 5),
          ),
        );
        _openContainingFolder(filePath);
      } else {
        // All other platforms: use the system share sheet.
        await SharePlus.instance.share(
          ShareParams(files: [XFile(filePath)], subject: 'Pantry Export'),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    }
  }

  /// Writes the CSV data to the user’s Downloads folder if possible, falling
  /// back to a temporary directory.
  ///
  /// Returns the absolute path of the written file.
  Future<String> _writeToDownloads(String csvString) async {
    Directory? downloadsDir;
    try {
      downloadsDir = await getDownloadsDirectory();
    } catch (_) {
      // getDownloadsDirectory() is not supported on very old Linux setups.
    }

    final dir = downloadsDir ?? await getTemporaryDirectory();
    final filePath = '${dir.path}/pantry_export.csv';
    await File(filePath).writeAsString(csvString);
    return filePath;
  }

  /// Opens the folder containing [filePath] in the default file manager.
  ///
  /// On Linux this uses `xdg-open <directory>`. If the command fails, the
  /// error is silently ignored – the user still sees the path in the snackbar.
  void _openContainingFolder(String filePath) {
    try {
      final dir = File(filePath).parent.path;
      Process.run('xdg-open', [dir]);
    } catch (_) {
      // Silently ignore; snackbar already gives the location.
    }
  }
}
