import 'package:dio/dio.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/services/product_api_service.dart';

import 'exceptions.dart';

class UpcItemDbApi implements ProductApiService {
  UpcItemDbApi(this._dio);
  final Dio _dio;

  @override
  Future<Product> getByBarcode(String barcode) async {
    final url = 'https://api.upcitemdb.com/prod/trial/lookup?upc=$barcode';
    final response = await _dio.get(url);
    final data = response.data as Map<String, dynamic>;

    final items = data['items'] as List<dynamic>?;
    if (items == null || items.isEmpty) {
      throw ProductNotFoundException('Product not found: $barcode');
    }

    final item = items.first as Map<String, dynamic>;
    return _parseProduct(item);
  }

  Product _parseProduct(Map<String, dynamic> json) {
    return Product(
      barcode: json['ean'] as String? ?? '',
      name: json['title'] as String? ?? 'Unknown',
      brand: json['brand'] as String?,
      imageUrl: (json['images'] as List<dynamic>?)?.first as String?,
      category: json['category'] as String?,
      // UPCitemdb provides no nutrition, ingredients, or serving size
      lastSynced: DateTime.now().millisecondsSinceEpoch,
    );
  }
}
