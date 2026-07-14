import 'package:pantry_app/models/hemisphere.dart';
import 'package:pantry_app/models/produce_quick_add_item.dart';
import 'package:pantry_app/services/produce_icon_service.dart';
import 'package:pantry_app/services/produce_purchase_tracker.dart';
import 'package:pantry_app/services/produce_serving_presets.dart';
import 'package:pantry_app/services/seasonal_produce_service.dart';

/// Composes the ordered carousel item list from purchase history
/// and seasonal data.
class CarouselCompositionService {
  /// Creates a [CarouselCompositionService].
  CarouselCompositionService({required this.purchaseTracker});

  /// Tracker for purchase frequency data.
  final ProducePurchaseTracker purchaseTracker;

  /// Builds the ordered carousel item list.
  ///
  /// Top 3 personalized items (from purchase history, by frequency)
  /// appear first, followed by up to 5 seasonal items (excluding
  /// already-shown names). Returns an empty list if no items are
  /// available.
  Future<List<ProduceQuickAddItem>> buildCarousel({
    required DateTime date,
    required Hemisphere hemisphere,
  }) async {
    final topPurchases = await purchaseTracker.getTopPurchases(limit: 8);
    final personalizedNames = topPurchases.take(3).toList();

    final exclude = personalizedNames.map((n) => n.toLowerCase()).toSet();
    final seasonalNames = SeasonalProduceService.getSeasonalProduce(
      date,
      hemisphere,
      excludeNames: exclude,
    ).take(5).toList();

    final items = <ProduceQuickAddItem>[];

    for (final name in personalizedNames) {
      items.add(_toItem(name, ProduceItemSource.personalized));
    }

    for (final name in seasonalNames) {
      items.add(_toItem(name, ProduceItemSource.seasonal));
    }

    return items;
  }

  ProduceQuickAddItem _toItem(String name, ProduceItemSource source) {
    final displayName = name[0].toUpperCase() + name.substring(1);
    final icon = ProduceIconService.forName(name);
    final presets = ProduceServingPresets.forName(name);
    final weightHintG = presets?['Medium'];
    return ProduceQuickAddItem(
      name: name.toLowerCase(),
      displayName: displayName,
      icon: icon,
      weightHintG: weightHintG,
      source: source,
    );
  }
}
