import 'dart:typed_data';

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
/// loads, a grey placeholder circle is visible and fades into the actual
/// image via [FadeInImage].
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
            // Invalidate so the home screen refreshes when we come back.
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
  /// When [Product.imageUrl] is available, a grey [ClipOval] placeholder
  /// is shown. A [FadeInImage] fades the real product image on top once it
  /// has loaded. If the image URL is absent, a fallback icon is displayed.
  Widget _buildLeadingImage() {
    if (item.productImageUrl != null) {
      return ClipOval(
        child: Container(
          color: Colors.grey.shade300,
          width: 40,
          height: 40,
          child: FadeInImage(
            placeholder: MemoryImage(Uint8List.fromList(kTransparentImage)),
            image: NetworkImage(item.productImageUrl!),
            fit: BoxFit.cover,
            imageErrorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.fastfood);
            },
          ),
        ),
      );
    }
    return const CircleAvatar(child: Icon(Icons.fastfood));
  }
}

/// A transparent 1x1 PNG – used as the initial placeholder so the grey
/// background of the parent container is visible while the network image
/// loads.
const kTransparentImage = <int>[
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0A,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0x00,
  0x00,
  0x00,
  0x02,
  0x00,
  0x01,
  0xE5,
  0x27,
  0xDE,
  0xFC,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
];
