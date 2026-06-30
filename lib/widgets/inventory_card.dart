import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/models/inventory_with_product.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/providers/inventory_provider.dart';
import 'package:pantry_app/providers/product_repository_provider.dart';
import 'package:pantry_app/screens/product_detail_screen.dart';

/// A tappable card representing one inventory item on the home screen.
///
/// Shows the product image (or a placeholder icon), the product name, a
/// subtitle with quantity, location, and expiry date, and a small coloured
/// dot indicating whether the item is expired.
///
/// The product image is wrapped in a [Hero] so that it smoothly animates
/// into the product detail screen when the card is tapped. While the image
/// loads, a grey placeholder circle is shown; on error a fallback icon is
/// displayed.
class InventoryCard extends StatelessWidget {
  /// Creates an [InventoryCard] for the given [item].
  const InventoryCard({required this.item, super.key});

  /// The inventory item to display.
  final InventoryWithProduct item;

  @override
  Widget build(BuildContext context) {
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
          child: _buildLeadingImage(),
        ),
        title: Text(item.productName ?? item.barcode),
        subtitle: Text(
          '''${item.quantity} ${item.unit} · ${item.location}${item.expiryDate != null ? " · Exp: ${item.expiryDate}" : ""}''',
        ),
        trailing: Icon(
          Icons.circle,
          color: isExpired ? Colors.red : Colors.grey.shade300,
          size: 12,
        ),
        onTap: () async {
          final repo = ProviderScope.containerOf(
            context,
          ).read(productRepositoryProvider);
          try {
            final product = await repo.getProduct(item.barcode);
            if (!context.mounted) return;
            await Navigator.of(context).push<void>(
              MaterialPageRoute(
                builder: (_) => ProductDetailScreen(product: product),
              ),
            );
            // Refresh the home screen when we come back.
            if (context.mounted) {
              ProviderScope.containerOf(
                context,
              ).invalidate(inventoryWithProductProvider);
            }
          } on Exception {
            // Silently ignore errors.
          }
        },
      ),
    );
  }

  /// Builds the leading image widget.
  ///
  /// When [Product.imageUrl] is available, a [ClipOval] wraps an
  /// [Image.network] that shows a grey container while loading and a
  /// fallback icon on error. If no URL is present, a simple fallback
  /// icon is displayed.
  Widget _buildLeadingImage() {
    if (item.productImageUrl == null) {
      return const CircleAvatar(child: Icon(Icons.fastfood));
    }

    return ClipOval(
      child: Image.network(
        item.productImageUrl!,
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          // Show a grey placeholder while the image loads.
          return Container(
            width: 40,
            height: 40,
            color: Colors.grey.shade300,
          );
        },
        errorBuilder: (context, error, stackTrace) {
          // If the image fails to load, show a fallback icon.
          return Container(
            width: 40,
            height: 40,
            color: Colors.grey.shade300,
            child: const Icon(Icons.fastfood, size: 24),
          );
        },
      ),
    );
  }
}
