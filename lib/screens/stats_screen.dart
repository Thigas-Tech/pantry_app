import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/providers/database_provider.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Pantry Stats')),
      body: FutureBuilder(
        future: Future.wait([
          db.getProductCount(), // we'll add this helper
          db.getInventoryCount(),
        ]),
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
