import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/l10n/app_localizations.dart';
import 'package:pantry_app/providers/active_inventory_provider.dart';
import 'package:pantry_app/providers/csv_service_provider.dart';
import 'package:pantry_app/providers/database_provider.dart';
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
class StatsScreen extends ConsumerWidget {
  /// Creates a [StatsScreen] widget.
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final db = ref.watch(databaseProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.pantryStats)),
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
                Text('${l10n.totalProducts}: ${counts[0]}'),
                Text('${l10n.inventoryItems}: ${counts[1]}'),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => _exportCsv(context, ref),
                  icon: const Icon(Icons.file_download),
                  label: Text(l10n.exportCsv),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    SnackbarHelper.showInfo(context, l10n.csvImportComingSoon);
                  },
                  icon: const Icon(Icons.file_upload),
                  label: Text(l10n.importCsv),
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
  ) async {
    final l10n = AppLocalizations.of(context)!;
    logInfo('Export button pressed');

    try {
      final csvService = ref.read(csvServiceProvider);
      final activeId = ref.read<int>(activeInventoryProvider);
      final csvString = await csvService.generateCsv(inventoryId: activeId);

      if (csvString.isEmpty) {
        if (context.mounted) {
          SnackbarHelper.showInfo(context, l10n.noDataToExport);
        }
        return;
      }

      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/pantry_export.csv';
      await File(filePath).writeAsString(csvString);

      if (context.mounted) {
        await SharePlus.instance.share(
          ShareParams(files: [XFile(filePath)], subject: l10n.pantryExport),
        );
      }
    } on Exception catch (e) {
      if (context.mounted) {
        SnackbarHelper.showError(context, '${l10n.exportFailed}: $e');
      }
    }
  }
}
