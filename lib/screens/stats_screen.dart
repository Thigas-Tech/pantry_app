import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/providers/database_provider.dart';

/// A simple statistics screen showing aggregate pantry data.
///
/// [StatsScreen] displays:
/// - The total number of unique products in the local cache (`products` table).
/// - The total number of inventory items currently stored (`inventory` table).
/// - A placeholder button for exporting pantry data as a CSV file.
///
/// ## Access
///
/// This screen is reached via the chart icon in the [HomeScreen] app bar. It
/// is a read‑only informational view and performs no mutations.
///
/// ## Data sources
///
/// Both counts are fetched in parallel using [Future.wait] on two separate
/// queries:
/// - [DatabaseHelper.getProductCount] – `SELECT COUNT(*) FROM products`.
/// - [DatabaseHelper.getInventoryCount] – `SELECT COUNT(*) FROM inventory`.
///
/// Running both queries at the same time halves the perceived loading time.
///
/// ## CSV export
///
/// The export button is currently a **placeholder**. When implemented, it
/// should collect all inventory items (joined with product names) and write
/// them to a CSV file, then open a share sheet so the user can email or
/// save the file.
class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Pantry Stats')),
      body: FutureBuilder(
        // Fetch both counts in parallel to reduce perceived loading time.
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
                ElevatedButton(
                  onPressed: () {
                    // TODO(ThiagoAssis): implement CSV export
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('CSV export coming soon')),
                    );
                  },
                  child: const Text('Export as CSV'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
