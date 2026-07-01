import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/providers/active_inventory_provider.dart';
import 'package:pantry_app/providers/database_provider.dart';
import 'package:pantry_app/services/csv_service.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:pantry_app/utils/snackbar_helper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// A statistics and data‑export screen for Android.
///
/// Shows aggregate pantry counts (across all inventories) and allows the
/// user to:
/// - **Export** the currently active pantry's inventory as a CSV file via
///   the system share sheet. The export is scoped to the pantry selected
///   on the home screen.
/// - **Import** a previously exported CSV file (planned – currently shows
///   a “coming soon” message).
///
/// ## Export
///
/// The CSV is written to a temporary directory and then shared using
/// `share_plus`. The exported data corresponds to the active inventory
/// managed by [activeInventoryProvider].
///
/// ## Import (planned)
///
/// CSV import is not yet implemented. The button displays a snackbar
/// informing the user that the feature is coming in a future update.
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
                  onPressed: () => _exportCsv(context, ref, db),
                  icon: const Icon(Icons.file_download),
                  label: const Text('Export as CSV'),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    SnackbarHelper.showInfo(context, 'CSV import coming soon.');
                  },
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

  Future<void> _exportCsv(
    BuildContext context,
    WidgetRef ref,
    DatabaseHelper db,
  ) async {
    logInfo('Export button pressed');

    try {
      final csvService = CsvService(db);
      final activeId = ref.read<int>(activeInventoryProvider);
      final csvString = await csvService.generateCsv(inventoryId: activeId);

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
}
