import 'package:flutter/material.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/models/product_type.dart';
import 'package:pantry_app/models/search_result.dart';

/// A swipeable, tappable list of [SearchResult]s.
///
/// Each row shows the product avatar, name, brand and barcode, plus badges
/// for pantry membership, produce type, and API provenance. Rows can be
/// swiped to trigger [onResultDismissed], tapped to trigger
/// [onResultTapped], and long-pressed to trigger [onResultLongPressed].
/// All user-visible strings are passed in so the caller controls
/// localization.
class SearchResultsList extends StatelessWidget {
  /// Creates a [SearchResultsList].
  ///
  /// [results] are the rows to show. [onResultTapped], [onResultLongPressed],
  /// and [onResultDismissed] receive the product or result that was
  /// interacted with.
  const SearchResultsList({
    required this.results,
    required this.inPantrySwipeLabel,
    required this.addToInventoryLabel,
    required this.inPantryIndicatorLabel,
    required this.onResultTapped,
    required this.onResultLongPressed,
    required this.onResultDismissed,
    super.key,
  });

  /// The search results to display, already filtered by the caller.
  final List<SearchResult> results;

  /// Label shown behind an in-pantry row while swiping.
  final String inPantrySwipeLabel;

  /// Label shown behind a row that is not in the pantry while swiping.
  final String addToInventoryLabel;

  /// Accessible label for the in-pantry indicator icon.
  final String inPantryIndicatorLabel;

  /// Called with the product when a row is tapped.
  final ValueChanged<Product> onResultTapped;

  /// Called with the product when a row is long-pressed.
  final ValueChanged<Product> onResultLongPressed;

  /// Called with the result when a row is swiped away.
  final ValueChanged<SearchResult> onResultDismissed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      itemCount: results.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final result = results[index];
        final product = result.product;
        return Dismissible(
          key: ValueKey('search-result-${product.barcode}'),
          direction: DismissDirection.startToEnd,
          background: Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 20),
            color: result.isInPantry ? Colors.blue.shade200 : Colors.green,
            child: Text(
              result.isInPantry ? inPantrySwipeLabel : addToInventoryLabel,
              style: const TextStyle(color: Colors.white),
            ),
          ),
          onDismissed: (_) => onResultDismissed(result),
          child: ListTile(
            leading: _avatar(product, theme, context),
            title: Text(
              product.name != 'Unknown' ? product.name : product.barcode,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              [
                if (product.brand != null && product.brand!.isNotEmpty)
                  product.brand,
                product.barcode,
              ].join(' \u2014 '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (result.isInPantry)
                  Semantics(
                    label: inPantryIndicatorLabel,
                    child: Icon(
                      Icons.kitchen,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                if (result.isInPantry) const SizedBox(width: 4),
                if (product.productType == ProductType.produce)
                  Icon(
                    Icons.eco_outlined,
                    size: 16,
                    color: Colors.green.shade600,
                  )
                else if (result.source == ResultSource.api)
                  Icon(
                    Icons.cloud_outlined,
                    size: 16,
                    color: theme.colorScheme.outline,
                  ),
              ],
            ),
            onTap: () => onResultTapped(product),
            onLongPress: () => onResultLongPressed(product),
          ),
        );
      },
    );
  }

  Widget _avatar(Product product, ThemeData theme, BuildContext context) {
    if (product.imageUrl != null) {
      final ratio = MediaQuery.devicePixelRatioOf(context);
      return ClipOval(
        child: Image.network(
          product.imageUrl!,
          width: 40,
          height: 40,
          cacheWidth: (40 * ratio).round(),
          cacheHeight: (40 * ratio).round(),
          fit: BoxFit.cover,
          loadingBuilder: (_, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return _produceOrBarcodeAvatar(product, theme);
          },
          errorBuilder: (_, _, _) => _produceOrBarcodeAvatar(product, theme),
        ),
      );
    }
    return _produceOrBarcodeAvatar(product, theme);
  }

  Widget _produceOrBarcodeAvatar(Product product, ThemeData theme) {
    if (product.productType == ProductType.produce) {
      return CircleAvatar(
        backgroundColor: Colors.green.shade100,
        child: Icon(Icons.eco_outlined, color: Colors.green.shade600, size: 18),
      );
    }
    return _barcodeAvatar(product.barcode, theme);
  }

  Widget _barcodeAvatar(String barcode, ThemeData theme) {
    return CircleAvatar(
      backgroundColor: theme.colorScheme.secondaryContainer,
      child: Text(
        barcode.length >= 3
            ? barcode.substring(0, 3)
            : barcode.padRight(3, '0'),
        style: TextStyle(
          color: theme.colorScheme.onSecondaryContainer,
          fontSize: 11,
        ),
      ),
    );
  }
}
