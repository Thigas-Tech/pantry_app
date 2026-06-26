import 'package:flutter/material.dart';
import 'package:pantry_app/models/product.dart';

class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({required this.product, super.key});
  final Product product;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(product.name)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            if (product.imageUrl != null)
              Image.network(product.imageUrl!, height: 200),
            _infoRow('Barcode', product.barcode),
            if (product.brand != null) _infoRow('Brand', product.brand!),
            if (product.category != null)
              _infoRow('Category', product.category!),
            const Divider(),
            _infoRow('Serving size', product.servingSize ?? 'N/A'),
            _infoRow('Energy', '${product.energyKcal ?? '-'} kcal/100g'),
            _infoRow('Protein', '${product.proteinG ?? '-'} g'),
            _infoRow('Carbs', '${product.carbsG ?? '-'} g'),
            _infoRow('Fat', '${product.fatG ?? '-'} g'),
            _infoRow('Fiber', '${product.fiberG ?? '-'} g'),
            _infoRow('Salt', '${product.saltG ?? '-'} g'),
            const Divider(),
            if (product.ingredients != null)
              Text('Ingredients: ${product.ingredients}'),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text('$label:')),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
