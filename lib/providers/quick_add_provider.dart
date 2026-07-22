import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/services/produce_purchase_tracker.dart';

/// Provides the list of frequently-purchased produce names.
///
/// Used by the home screen's quick-add carousel.
final quickAddItemsProvider = FutureProvider<List<String>>((ref) async {
  try {
    final tracker = ProducePurchaseTracker();
    return await tracker.getTopPurchases();
  } on Exception {
    return ProducePurchaseTracker.getDefaultList();
  }
});
