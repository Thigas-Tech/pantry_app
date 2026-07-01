import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/l10n/app_localizations.dart';
import 'package:pantry_app/models/inventory_with_product.dart';
import 'package:pantry_app/providers/image_cache_provider.dart';
import 'package:pantry_app/providers/inventory_provider.dart';
import 'package:pantry_app/providers/product_repository_provider.dart';
import 'package:pantry_app/screens/product_detail_screen.dart';
import 'package:pantry_app/utils/logger.dart';

/// A tappable card representing one inventory item on the home screen.
///
/// Shows the product image (or a placeholder icon), the product name, a
/// subtitle with quantity, location, and expiry date, and a small coloured
/// dot indicating whether the item is expired.
///
/// The product image is wrapped in a [Hero] so that it smoothly animates
/// into the product detail screen when the card is tapped. The image is
/// loaded from a local cache (WebP format) when available; otherwise a
/// placeholder is shown while the network image is fetched and cached.
class InventoryCard extends ConsumerWidget {
  /// Creates an [InventoryCard] for the given [item].
  const InventoryCard({required this.item, super.key});

  /// The inventory item to display.
  final InventoryWithProduct item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isExpired =
        item.expiryDate != null &&
        DateTime.tryParse(item.expiryDate!)?.isBefore(DateTime.now()) == true;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Hero(
          tag: item.barcode,
          child: _buildLeadingImage(ref),
        ),
        title: Text(item.productName ?? item.barcode),
        subtitle: Text(
          '''${item.quantity} ${item.unit} · ${item.location}${item.expiryDate != null ? " · ${l10n.expiryPrefix}: ${item.expiryDate}" : ""}''',
        ),
        trailing: Icon(
          Icons.circle,
          color: isExpired ? Colors.red : Colors.grey.shade300,
          size: 12,
        ),
        onTap: () async {
          logInfo('Inventory card tapped: ${item.barcode}');
          final repo = ref.read(productRepositoryProvider);
          try {
            final product = await repo.getProduct(item.barcode);
            if (!context.mounted) return;
            await Navigator.of(context).push<void>(
              MaterialPageRoute(
                builder: (_) => ProductDetailScreen(product: product),
              ),
            );
            if (context.mounted) {
              ref.invalidate(inventoryWithProductProvider);
            }
          } on Exception catch (e) {
            logError('Failed to navigate to product detail: $e');
          }
        },
      ),
    );
  }

  /// Builds the leading image widget, loading from cache or network.
  Widget _buildLeadingImage(WidgetRef ref) {
    final imageCache = ref.watch(imageCacheProvider);
    return FutureBuilder<String?>(
      future: imageCache.cacheImage(item.productImageUrl, item.barcode),
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
        // Still loading or failed; show placeholder.
        if (item.productImageUrl != null) {
          return ClipOval(
            child: Image.network(
              item.productImageUrl!,
              width: 40,
              height: 40,
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
