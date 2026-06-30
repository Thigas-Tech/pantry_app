import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/providers/database_provider.dart';
import 'package:pantry_app/services/csv_service.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// A statistics and data‑export/import screen for Android.
///
/// Shows aggregate pantry counts and allows the user to:
/// - **Export** all inventory as a CSV file via the system share sheet.
/// - **Import** a previously exported CSV file by entering its file path.
///
/// ## Export
///
/// The CSV is written to a temporary directory and then shared using
/// `share_plus`. The system share sheet offers apps like email,
/// messaging, or cloud storage.
///
/// ## Import
///
/// Since Android does not have a straightforward native file picker in
/// this build, the user is prompted to type or paste the full path of
/// the CSV file (e.g., `/storage/emulated/0/Download/pantry_export.csv`).
/// After import, a dialog shows the number of products updated and
/// items added.
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
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('No data to export.')));
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    }
  }

  Future<void> _importCsv(BuildContext context, DatabaseHelper db) async {
    logInfo('Import button pressed');
    try {
      final controller = TextEditingController();
      final filePath = await showDialog<String>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Import CSV'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: '/path/to/pantry_export.csv',
              labelText: 'File path',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Import'),
            ),
          ],
        ),
      );

      if (filePath == null || filePath.isEmpty) return; // user cancelled

      // Show loading indicator while importing.
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

      // Dismiss loading.
      if (context.mounted) Navigator.of(context).pop();

      // Show import result.
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
      if (context.mounted) Navigator.of(context).pop();
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Import failed: $e')));
      }
    }
  }
}
