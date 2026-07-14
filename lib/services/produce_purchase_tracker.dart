import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/database/produce_frequency_dao.dart';

/// Tracks how often each produce item is purchased.
///
/// Stores frequency counts in the `produce_purchase_frequency` SQLite
/// table via [ProduceFrequencyDao]. Used by the quick-add carousel to
/// show the user's most frequent produce.
class ProducePurchaseTracker {
  /// Creates a [ProducePurchaseTracker].
  ///
  /// [dbHelper] can be injected for testing. When omitted, the default
  /// [DatabaseHelper] singleton is used.
  ProducePurchaseTracker({DatabaseHelper? dbHelper})
    : _dbHelper = dbHelper ?? DatabaseHelper();

  final DatabaseHelper _dbHelper;
  final ProduceFrequencyDao _dao = const ProduceFrequencyDao();

  /// Default produce list shown when the user has no purchase history.
  static List<String> getDefaultList() => const [
    'Apple',
    'Banana',
    'Orange',
    'Tomato',
    'Potato',
    'Carrot',
    'Onion',
    'Lettuce',
  ];

  /// Records a purchase of [produceName].
  Future<void> recordPurchase(String produceName) async {
    final db = await _dbHelper.database;
    await _dao.increment(produceName, db);
  }

  /// Reverts a purchase of [produceName] (undo).
  ///
  /// The count is reduced by 1 but never below 0.
  Future<void> undoPurchase(String produceName) async {
    final db = await _dbHelper.database;
    await _dao.decrement(produceName, db);
  }

  /// Returns the top [limit] most frequently purchased produce items.
  ///
  /// Names are capitalized for display. Returns only items with count > 0
  /// from the purchase history. An empty list means no purchases yet.
  Future<List<String>> getTopPurchases({int limit = 8}) async {
    final db = await _dbHelper.database;
    final top = await _dao.getTopPurchases(db, limit: limit);

    return top
        .where((row) => (row['count'] as int) > 0)
        .map((row) {
          final name = row['produce_key'] as String;
          return name[0].toUpperCase() + name.substring(1);
        })
        .take(limit)
        .toList();
  }
}
