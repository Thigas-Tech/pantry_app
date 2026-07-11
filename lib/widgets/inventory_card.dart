import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/l10n/app_localizations.dart';
import 'package:pantry_app/models/inventory_with_product.dart';
import 'package:pantry_app/models/shopping_item.dart';
import 'package:pantry_app/providers/image_cache_provider.dart';
import 'package:pantry_app/providers/inventory_provider.dart';
import 'package:pantry_app/providers/price_provider.dart';
import 'package:pantry_app/providers/price_repository_provider.dart';
import 'package:pantry_app/providers/product_repository_provider.dart';
import 'package:pantry_app/providers/settings_provider.dart';
import 'package:pantry_app/providers/shopping_list_provider.dart';
import 'package:pantry_app/screens/product_detail_screen.dart';
import 'package:pantry_app/services/exceptions.dart';
import 'package:pantry_app/utils/date_helpers.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:pantry_app/utils/snackbar_helper.dart';
import 'package:pantry_app/widgets/nutriscore_badge.dart';
import 'package:pantry_app/widgets/price_mask.dart';

/// A tappable card representing one inventory item on the home screen.
///
/// Caches the image future in state to avoid recreating it on rebuilds.
/// Includes semantic labels for accessibility.
///
/// When [showCheckbox] is true, a checkbox replaces the leading image and
/// the card's tap navigation is disabled in favour of selection.
///
/// Long-pressing a card triggers [onLongPress], which enters selection mode
/// and selects this item.
class InventoryCard extends ConsumerStatefulWidget {
  /// Creates an [InventoryCard] for the given [item].
  const InventoryCard({
    required this.item,
    this.showCheckbox = false,
    this.isSelected = false,
    this.onToggleSelection,
    this.onLongPress,
    super.key,
  });

  /// The inventory item to display.
  final InventoryWithProduct item;

  /// Whether to show a selection checkbox instead of the product image.
  final bool showCheckbox;

  /// Whether this item is currently selected.
  final bool isSelected;

  /// Called when the selection checkbox is toggled.
  final VoidCallback? onToggleSelection;

  /// Called when the user long-presses the card (only when not in selection
  /// mode). Enters selection mode and selects this item.
  final VoidCallback? onLongPress;

  @override
  ConsumerState<InventoryCard> createState() => _InventoryCardState();
}

class _InventoryCardState extends ConsumerState<InventoryCard> {
  Future<String?>? _cachedImageFuture;

  @override
  void initState() {
    super.initState();
    _cachedImageFuture = null;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_cachedImageFuture == null) {
      final imageCache = ref.read(imageCacheProvider);
      _cachedImageFuture = imageCache.cacheImage(
        widget.item.productImageUrl,
        widget.item.barcode,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final itemIsExpired = isExpired(widget.item.expiryDate);
    final expiryLabel = itemIsExpired ? l10n.expired : l10n.good;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: GestureDetector(
        onLongPress: widget.showCheckbox
            ? null
            : () {
                unawaited(HapticFeedback.mediumImpact());
                widget.onLongPress?.call();
              },
        child: ListTile(
          leading: widget.showCheckbox
              ? Checkbox(
                  value: widget.isSelected,
                  onChanged: (_) => widget.onToggleSelection?.call(),
                )
              : widget.item.productImageUrl != null
              ? Hero(
                  tag: 'card_${widget.item.barcode}',
                  child: Semantics(
                    label: widget.item.productName,
                    child: _buildLeadingImage(),
                  ),
                )
              : Semantics(
                  label: widget.item.productName,
                  child: _buildLeadingImage(),
                ),
          title: Text(
            widget.item.productName ?? widget.item.barcode,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSubtitle(l10n),
              _buildPriceLine(l10n),
            ],
          ),
          trailing: Semantics(
            label: expiryLabel,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart_outlined, size: 20),
                  tooltip: l10n.addToShoppingListTooltip,
                  onPressed: () {
                    final name = widget.item.productName ?? widget.item.barcode;
                    final item = ShoppingItem(
                      name: name,
                      barcode: widget.item.barcode,
                    );
                    unawaited(addShoppingItem(ref, item));
                    SnackbarHelper.showInfo(context, l10n.addToShoppingList);
                  },
                ),
                NutriScoreBadge(
                  grade: widget.item.nutriscoreGrade,
                  size: 24,
                ),
                if (widget.item.nutriscoreGrade != null)
                  const SizedBox(width: 6),
                Text(
                  expiryLabel,
                  style: TextStyle(
                    fontSize: 11,
                    color: itemIsExpired ? Colors.red : Colors.grey.shade500,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.circle,
                  color: itemIsExpired ? Colors.red : Colors.grey.shade300,
                  size: 12,
                ),
              ],
            ),
          ),
          onTap: widget.showCheckbox
              ? null
              : () async {
                  logInfo('Inventory card tapped: ${widget.item.barcode}');
                  final repo = ref.read(productRepositoryProvider);
                  try {
                    final product = await repo.getProduct(widget.item.barcode);
                    if (!context.mounted) return;
                    await Navigator.of(context).push<void>(
                      MaterialPageRoute(
                        builder: (_) => ProductDetailScreen(product: product),
                      ),
                    );
                    if (context.mounted) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        ref.invalidate(inventoryWithProductProvider);
                      });
                    }
                  } on FetchFailedException {
                    logError(
                      'Product ${widget.item.barcode} unavailable (offline)',
                    );
                    if (context.mounted) {
                      SnackbarHelper.showInfo(
                        context,
                        l10n.productDataUnavailable,
                      );
                    }
                  } on Exception catch (e) {
                    logError('Failed to navigate to product detail: $e');
                  }
                },
        ),
      ),
    );
  }

  Widget _buildSubtitle(AppLocalizations l10n) {
    final sb = StringBuffer()
      ..write('${widget.item.quantity} ${widget.item.unit}')
      ..write(' · ${widget.item.location}');
    if (widget.item.expiryDate != null) {
      sb.write(' · ${l10n.expiryPrefix}: ${widget.item.expiryDate}');
    }
    return Text(sb.toString());
  }

  Widget _buildPriceLine(AppLocalizations l10n) {
    final settings = ref.watch(settingsProvider);
    if (!settings.priceTrackingEnabled) return const SizedBox.shrink();

    final priceAsync = ref.watch(latestPriceProvider(widget.item.barcode));
    return priceAsync.whenOrNull(
          data: (price) {
            if (price == null) return const SizedBox.shrink();
            final repo = ref.read(priceRepositoryProvider);
            final formatted = repo.formatPrice(price.price, price.currency);
            return Padding(
              padding: const EdgeInsets.only(top: 2),
              child: PriceMask(
                formattedPrice: formatted,
                child: Text(
                  formatted,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          },
        ) ??
        const SizedBox.shrink();
  }

  Widget _buildLeadingImage() {
    return FutureBuilder<String?>(
      future: _cachedImageFuture,
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          return ClipOval(
            child: Image.file(
              File(snapshot.data!),
              width: 40,
              height: 40,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _fallbackIcon(),
            ),
          );
        }
        if (widget.item.productImageUrl != null) {
          final pixelRatio = MediaQuery.devicePixelRatioOf(context);
          return ClipOval(
            child: Image.network(
              widget.item.productImageUrl!,
              width: 40,
              height: 40,
              cacheWidth: (40 * pixelRatio).round(),
              cacheHeight: (40 * pixelRatio).round(),
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  width: 40,
                  height: 40,
                  color: Colors.grey.shade300,
                );
              },
              errorBuilder: (context, error, stackTrace) => _fallbackIcon(),
            ),
          );
        }
        return _fallbackIcon();
      },
    );
  }

  Widget _fallbackIcon() {
    return const CircleAvatar(child: Icon(Icons.fastfood));
  }
}
