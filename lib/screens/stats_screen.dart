import 'dart:async';
import 'dart:io';

import 'package:filegate/filegate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/providers/database_provider.dart';
import 'package:pantry_app/services/csv_service.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:pantry_app/utils/snackbar_helper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// A statistics and data‑export/import screen for Android.
///
/// Shows aggregate pantry counts and allows the user to:
/// - **Export** all inventory as a CSV file via the system share sheet.
/// - **Import** a previously exported CSV file by picking it with a native
///   file picker powered by `filegate`. The chosen file is then processed
///   and its data merged into the pantry.
///
/// ## Export
///
/// The CSV is written to a temporary directory and then shared using
/// `share_plus`. The system share sheet offers apps like email,
/// messaging, or cloud storage.
///
/// ## Import
///
/// The user taps “Import CSV” and is presented with the device’s file picker
/// filtered to `.csv` files. After selecting a file, a loading indicator
/// appears while the import runs, and a result dialog shows the number of
/// products updated and items added.
///
/// ## Import logic
///
/// - Every row is processed independently.
/// - Products are **upserted** (existing barcodes are updated with the CSV
///   data).
/// - Inventory items are always **added as new** entries.
/// - The original inventory IDs are not preserved.
class StatsScreen extends ConsumerWidget {
  /// Creates a [StatsScreen] widget.
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
          final data = snapshot.data;
          if (data == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final counts = data;
          return Padding(
            padding: const EdgeInsets.all(24),
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
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () => _importCsv(context, db),
                  icon: const Icon(Icons.file_upload),
                  label: const Text('Import CSV'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _exportCsv(BuildContext context, DatabaseHelper db) async {
    logInfo('Export button pressed');

    try {
      final csvService = CsvService(db);
      final csvString = await csvService.generateCsv();

      if (csvString.isEmpty) {
        if (context.mounted) {
          SnackbarHelper.showInfo(context, 'No data to export.');
        }
        return;
      }

      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/pantry_export.csv';
      await File(filePath).writeAsString(csvString);

      if (context.mounted) {
        await SharePlus.instance.share(
          ShareParams(files: [XFile(filePath)], subject: 'Pantry Export'),
        );
      }
    } on Exception catch (e) {
      if (context.mounted) {
        SnackbarHelper.showError(context, 'Export failed: $e');
      }
    }
  }

  Future<void> _importCsv(BuildContext context, DatabaseHelper db) async {
    logInfo('Import button pressed');

    try {
      // Open the native file picker via filegate.
      const filegate = Filegate();
      final files = await filegate.pickFiles(
        allowedExtensions: ['csv'],
      );

      if (files == null || files.isEmpty) return; // user cancelled

      final filePath = files.first.path;

      // Show a loading indicator while the import runs.
      if (context.mounted) {
        unawaited(
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => const Center(child: CircularProgressIndicator()),
          ),
        );
      }

      final csvService = CsvService(db);
      final counts = await csvService.importCsv(filePath);

      // Dismiss the loading indicator.
      if (context.mounted) Navigator.of(context).pop();

      // Show the import result.
      if (context.mounted) {
        unawaited(
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Import complete'),
              content: Text(
                'Products updated: ${counts['products']}\n'
                'Items added: ${counts['items']}',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          ),
        );
      }
    } on Exception catch (e) {
      // Dismiss the loading indicator if it's still shown.
      if (context.mounted) Navigator.of(context).pop();
      if (context.mounted) {
        SnackbarHelper.showError(context, 'Import failed: $e');
      }
    }
  }
}
