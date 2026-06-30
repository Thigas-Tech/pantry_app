import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/models/inventory_with_product.dart';
import 'package:pantry_app/providers/product_repository_provider.dart';
import 'package:pantry_app/screens/product_detail_screen.dart';

/// A tappable card representing one inventory item on the home screen.
///
/// Shows the product image (or a placeholder icon), the product name, a
/// subtitle with quantity, location, and expiry date, and a small coloured
/// dot indicating whether the item is expired.
///
/// The product image is wrapped in a [Hero] so that it smoothly animates
/// into the product detail screen when the card is tapped.
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
          tag: item.barcode, // same tag used in ProductDetailScreen
          child: CircleAvatar(
            backgroundImage: item.productImageUrl != null
                ? NetworkImage(item.productImageUrl!)
                : null,
            child: item.productImageUrl == null
                ? const Icon(Icons.fastfood)
                : null,
          ),
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
          } on Exception {
            // Silently ignore errors.
          }
        },
      ),
    );
  }
}
